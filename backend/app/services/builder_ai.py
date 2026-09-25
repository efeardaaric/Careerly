"""Builder rewrite / translate AI — never invents facts; never auto-applies."""

from __future__ import annotations

import json
import re
from copy import deepcopy
from typing import Any

import httpx

from app.core.config import Settings, get_settings
from app.core.security import get_logger

logger = get_logger(__name__)

REWRITE_SYSTEM_PROMPT = """You are Careerly's CV writing assistant.
Return ONLY valid JSON with keys: suggested, why, needsUserFact (bool), missingFactPrompt (string|null).
Rules:
- Never invent employers, degrees, metrics, skills, dates, certifications, or tools.
- If a measurable outcome would help but no number is in the original text, set needsUserFact=true,
  keep suggested equal to original (or only light clarity edits), and ask for the real fact in missingFactPrompt.
- Do not claim the user worked somewhere new.
- Preserve meaning; improve clarity / professionalism / concision per mode.
- Write why and missingFactPrompt in the requested locale (en or tr).
- suggested must stay in the same language as the input text unless translating.
"""

TRANSLATE_SYSTEM_PROMPT = """You are Careerly's CV translator (TR↔EN).
Return ONLY valid JSON: { "document": <translated ResumeDocument> }.
Rules:
- Translate narrative fields (summary, titles, bullets, section labels in content).
- Preserve proper nouns: person names, company names, product names, school names, emails, URLs, tech skill tokens (Flutter, Python, etc.).
- Do not invent new content. Keep structure, ids, templateId, sectionOrder, visibility identical.
- Set language to the target language code.
"""


def validate_rewrite_suggestion(
    *,
    original: str,
    raw: dict[str, Any],
    locale: str,
) -> dict[str, Any]:
    tr = locale.startswith("tr")
    suggested = str(raw.get("suggested") or original).strip() or original
    why = str(raw.get("why") or "").strip()
    needs = bool(raw.get("needsUserFact", False))
    prompt = raw.get("missingFactPrompt")
    prompt_s = str(prompt).strip() if prompt else None

    # Soft anti-fabrication: if original has no digits but suggested adds digits → force ask.
    if not re.search(r"\d", original) and re.search(r"\d", suggested):
        needs = True
        suggested = original
        prompt_s = prompt_s or (
            "Kaç kişi / ne değişti? Yalnızca gerçek rakam yazın."
            if tr
            else "How many people / what changed? Real number only."
        )
        why = (
            "Ölçülebilir sonuç güçlendirir — sayıyı uydurmayız."
            if tr
            else "A measurable outcome would help — we will not invent a number."
        )

    if not why:
        why = (
            "Anlam korunarak netlik artırıldı."
            if tr
            else "Clarity improved while preserving meaning."
        )

    return {
        "original": original,
        "suggested": suggested[:4000],
        "why": why[:500],
        "needsUserFact": needs,
        "missingFactPrompt": (prompt_s[:300] if prompt_s else None),
    }


def validate_translated_document(
    source: dict[str, Any],
    target_lang: str,
    raw_doc: dict[str, Any],
) -> dict[str, Any]:
    """Keep identity/structure; only accept translated narrative fields."""
    out = deepcopy(source)
    out["language"] = target_lang
    # Preserve personal contact identity fields from source.
    personal = dict(out.get("personal") or {})
    src_personal = source.get("personal") or {}
    for key in ("fullName", "email", "phone", "linkedin", "website"):
        if key in src_personal:
            personal[key] = src_personal[key]
    if isinstance(raw_doc.get("personal"), dict) and raw_doc["personal"].get("location"):
        personal["location"] = str(raw_doc["personal"]["location"])
    out["personal"] = personal

    if isinstance(raw_doc.get("summary"), str):
        out["summary"] = raw_doc["summary"]

    def _map_list(key: str, fields: list[str], bullet_keys: list[str] | None = None) -> None:
        src_list = source.get(key) or []
        raw_list = raw_doc.get(key) or []
        if not isinstance(src_list, list):
            return
        merged = []
        for i, item in enumerate(src_list):
            if not isinstance(item, dict):
                continue
            copy = dict(item)
            raw_item = raw_list[i] if i < len(raw_list) and isinstance(raw_list[i], dict) else {}
            for f in fields:
                if f in raw_item and isinstance(raw_item[f], str):
                    copy[f] = raw_item[f]
            if bullet_keys:
                for bk in bullet_keys:
                    if bk in raw_item and isinstance(raw_item[bk], list):
                        copy[bk] = [str(x) for x in raw_item[bk]]
            merged.append(copy)
        out[key] = merged

    _map_list("education", ["school", "degree", "field", "details"])
    _map_list("experience", ["organization", "title", "location"], ["bullets"])
    _map_list("projects", ["name"], ["bullets", "tech"])
    _map_list("skillGroups", ["label"], ["skills"])
    _map_list("languages", ["name", "level"])
    _map_list("certifications", ["name", "issuer"])
    _map_list("awards", ["title"])
    _map_list("customSections", ["title"], ["bullets"])

    out["id"] = source.get("id")
    out["templateId"] = source.get("templateId")
    out["sectionOrder"] = source.get("sectionOrder")
    out["sectionVisibility"] = source.get("sectionVisibility")
    out["parentDocumentId"] = source.get("id")
    return out


class MockBuilderAI:
    async def rewrite(
        self,
        *,
        mode: str,
        text: str,
        locale: str,
        section_key: str | None = None,
        notes: str | None = None,
    ) -> dict[str, Any]:
        tr = locale.startswith("tr")
        looks_metric_free = not re.search(r"\d", text)
        if looks_metric_free and mode == "improve":
            return validate_rewrite_suggestion(
                original=text,
                raw={
                    "suggested": text,
                    "why": (
                        "Ölçülebilir bir sonuç eklemek güçlendirir — sayıyı uydurmayız."
                        if tr
                        else "A measurable outcome would strengthen this — we will not invent a number."
                    ),
                    "needsUserFact": True,
                    "missingFactPrompt": (
                        "Kaç kişi kullandı veya ne değişti? (yalnızca gerçek rakam)"
                        if tr
                        else "How many people used it, or what changed? (real number only)"
                    ),
                },
                locale=locale,
            )

        if mode == "concise":
            suggested = text if len(text) <= 90 else text[:87].rstrip() + "…"
        elif mode == "professional":
            suggested = (
                text.replace("geliştirdim", "geliştirdim ve teslim ettim")
                .replace("Built", "Designed and delivered")
                .replace("Supported", "Contributed to")
            )
        elif mode == "from_notes" and notes:
            # Only rephrase notes — never invent employers/metrics.
            suggested = notes.strip()
            if not suggested.endswith("."):
                suggested += "."
        else:
            suggested = text if text.endswith(".") else f"{text}."

        return validate_rewrite_suggestion(
            original=text,
            raw={
                "suggested": suggested,
                "why": (
                    "Anlam korunarak netlik artırıldı; yeni işveren/metrik eklenmedi."
                    if tr
                    else "Clarity improved while preserving meaning — no new employers or metrics added."
                ),
                "needsUserFact": False,
                "missingFactPrompt": None,
            },
            locale=locale,
        )

    async def translate(
        self, *, document: dict[str, Any], target_language: str
    ) -> dict[str, Any]:
        tr = target_language == "tr"
        source = deepcopy(document)

        def map_phrase(s: str) -> str:
            if not s or not s.strip():
                return s
            pairs = [
                (
                    "Computer Science student seeking internship opportunities in software.",
                    "Yazılım alanında staj arayan Bilgisayar Mühendisliği öğrencisi.",
                ),
                (
                    "Supported event promotion for student community",
                    "Öğrenci topluluğu için etkinlik tanıtımına destek oldum.",
                ),
                (
                    "Built a campus event app using Flutter and Firebase",
                    "Flutter ve Firebase ile kampüs etkinlik uygulaması geliştirdim.",
                ),
                (
                    "Marketing Intern",
                    "Pazarlama Stajyeri",
                ),
                (
                    "Volunteer · Coding Club mentor",
                    "Gönüllü · Coding Club mentor",
                ),
                ("Technical", "Teknik"),
                ("Tools", "Araçlar"),
                ("Turkish", "Türkçe"),
                ("Native", "Ana dil"),
                ("English", "İngilizce"),
            ]
            out = s
            for en, tr_s in pairs:
                if tr:
                    out = out.replace(en, tr_s)
                else:
                    out = out.replace(tr_s, en)
            return out

        raw = deepcopy(source)
        raw["summary"] = map_phrase(str(raw.get("summary") or ""))
        for exp in raw.get("experience") or []:
            if isinstance(exp, dict):
                exp["title"] = map_phrase(str(exp.get("title") or ""))
                exp["bullets"] = [map_phrase(str(b)) for b in (exp.get("bullets") or [])]
        for proj in raw.get("projects") or []:
            if isinstance(proj, dict):
                proj["bullets"] = [map_phrase(str(b)) for b in (proj.get("bullets") or [])]
        for aw in raw.get("awards") or []:
            if isinstance(aw, dict):
                aw["title"] = map_phrase(str(aw.get("title") or ""))
        for g in raw.get("skillGroups") or []:
            if isinstance(g, dict):
                g["label"] = map_phrase(str(g.get("label") or ""))
        for lang in raw.get("languages") or []:
            if isinstance(lang, dict):
                lang["name"] = map_phrase(str(lang.get("name") or ""))
                lang["level"] = map_phrase(str(lang.get("level") or ""))

        return validate_translated_document(source, target_language, raw)


class OpenAIBuilderAI:
    def __init__(self, settings: Settings):
        self._settings = settings

    async def rewrite(
        self,
        *,
        mode: str,
        text: str,
        locale: str,
        section_key: str | None = None,
        notes: str | None = None,
    ) -> dict[str, Any]:
        payload = {
            "mode": mode,
            "locale": locale,
            "sectionKey": section_key,
            "text": text,
            "notes": notes,
        }
        raw = await self._chat(REWRITE_SYSTEM_PROMPT, payload)
        return validate_rewrite_suggestion(original=text, raw=raw, locale=locale)

    async def translate(
        self, *, document: dict[str, Any], target_language: str
    ) -> dict[str, Any]:
        payload = {"targetLanguage": target_language, "document": document}
        raw = await self._chat(TRANSLATE_SYSTEM_PROMPT, payload)
        doc = raw.get("document") if isinstance(raw, dict) else None
        if not isinstance(doc, dict):
            doc = document
        return validate_translated_document(document, target_language, doc)

    async def _chat(self, system: str, payload: dict[str, Any]) -> dict[str, Any]:
        api_key = self._settings.openai_api_key
        if not api_key:
            raise RuntimeError("OPENAI_API_KEY missing")
        body = {
            "model": self._settings.openai_model,
            "temperature": 0.2,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": json.dumps(payload)},
            ],
        }
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
        url = f"{self._settings.openai_base_url.rstrip('/')}/chat/completions"
        async with httpx.AsyncClient(timeout=60.0) as client:
            res = await client.post(url, headers=headers, json=body)
            res.raise_for_status()
            data = res.json()
        content = data["choices"][0]["message"]["content"]
        return json.loads(content)


def get_builder_ai(settings: Settings | None = None) -> MockBuilderAI | OpenAIBuilderAI:
    settings = settings or get_settings()
    if (settings.ai_provider or "").lower() == "openai":
        return OpenAIBuilderAI(settings)
    return MockBuilderAI()
