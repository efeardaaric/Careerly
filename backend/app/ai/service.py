"""AI enrichment. Scores never come from this layer."""

from __future__ import annotations

import json
import logging
import re
from typing import Any, Protocol

import httpx

from app.core.config import Settings
from app.optimization.guardrails import validate_rewrite
from app.optimization.prompts import PROMPT_VERSION, TRUTH_RULES, rewrite_prompt

logger = logging.getLogger("careerly.ai")

_NUMBER = re.compile(r"\d+(?:[.,]\d+)?%?")

REWRITE_RULES = """
Never invent numbers, percentages, revenue, user counts, employers, projects,
job titles, education, certifications, technologies, responsibilities,
achievements, or skills. Only rewrite using facts already supplied.
If a measurable result is missing, say to add one only if the user can verify it.
Do not produce a Careerly score or any numeric rating.
""".strip()


class AIProvider(Protocol):
    def generate_explanation(self, finding: dict) -> str | None: ...

    def rewrite_bullet(self, text: str, goal: str) -> str | None: ...

    def rewrite_json(self, prompt: str) -> Any: ...


class DisabledAI:
    def generate_explanation(self, finding: dict) -> str | None:
        return None

    def rewrite_bullet(self, text: str, goal: str) -> str | None:
        return None

    def rewrite_json(self, prompt: str) -> Any:
        return None


class OpenAIProvider:
    def __init__(self, settings: Settings) -> None:
        self._key = settings.openai_api_key or ""
        self._model = settings.openai_model
        self._base = settings.openai_base_url.rstrip("/")

    def generate_explanation(self, finding: dict) -> str | None:
        prompt = (
            f"{REWRITE_RULES}\n\nRewrite this finding in one sentence. "
            "Do not add facts.\n"
            f"Title: {finding.get('title')}\n"
            f"Evidence: {finding.get('evidence')}\n"
        )
        return self._chat(prompt)

    def rewrite_bullet(self, text: str, goal: str) -> str | None:
        prompt = (
            f"{REWRITE_RULES}\n\nGoal: {goal}\nOriginal bullet:\n{text}\n"
            "Return only the rewritten bullet."
        )
        suggestion = self._chat(prompt)
        if suggestion and _introduces_new_numbers(text, suggestion):
            logger.info("ai_rewrite_rejected reason=new_numbers")
            return None
        return suggestion

    def rewrite_json(self, prompt: str) -> Any:
        content = self._chat(prompt, system=TRUTH_RULES, json_mode=True)
        if content is None:
            return None
        try:
            return json.loads(content)
        except ValueError:
            logger.info("ai_rewrite_malformed")
            return None

    def _chat(self, prompt: str, *, system: str = REWRITE_RULES, json_mode: bool = False) -> str | None:
        body: dict[str, Any] = {
            "model": self._model,
            "temperature": 0,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": prompt},
            ],
        }
        if json_mode:
            body["response_format"] = {"type": "json_object"}
        try:
            response = httpx.post(
                f"{self._base}/chat/completions",
                headers={"Authorization": f"Bearer {self._key}"},
                json=body,
                timeout=20,
            )
            response.raise_for_status()
            return response.json()["choices"][0]["message"]["content"].strip()
        except Exception:  # noqa: BLE001 — provider failures must not change the score
            logger.info("ai_provider_failed")
            return None


def _introduces_new_numbers(original: str, suggestion: str) -> bool:
    original_numbers = set(_NUMBER.findall(original))
    return any(number not in original_numbers for number in _NUMBER.findall(suggestion))


class AIService:
    def __init__(self, provider: AIProvider) -> None:
        self._provider = provider

    def enrich_finding(self, finding: dict) -> dict:
        text = self._provider.generate_explanation(finding)
        if not text:
            return finding
        updated = dict(finding)
        updated["whyItMatters"] = text
        return updated

    def rewrite(self, text: str, goal: str) -> dict:
        suggestion = self._provider.rewrite_bullet(text, goal)
        warnings = []
        if suggestion is None:
            warnings.append("AI rewrite is unavailable. The original text is unchanged.")
            suggestion = text
        return {"original": text, "suggestion": suggestion, "warnings": warnings}

    def rewrite_structured(
        self,
        text: str,
        mode: str,
        *,
        cv_context: str = "",
        job_context: str | None = None,
    ) -> dict:
        raw = self._provider.rewrite_json(rewrite_prompt(mode, text, cv_context, job_context))
        result = validate_rewrite(
            original=text,
            raw=raw,
            context=cv_context,
            mode=mode,
            prompt_version=PROMPT_VERSION,
        )
        result["suggestion"] = result["suggested"]
        if result["warnings"]:
            logger.info("ai_rewrite_flagged mode=%s warnings=%s", mode, ",".join(result["warnings"]))
        return result


def build_ai_service(settings: Settings) -> AIService:
    if not settings.ai_enabled:
        return AIService(DisabledAI())
    if not (settings.openai_api_key or "").strip():
        logger.warning("AI_ENABLED without OPENAI_API_KEY; enrichment disabled")
        return AIService(DisabledAI())
    return AIService(OpenAIProvider(settings))
