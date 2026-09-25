"""Job Match AI signals — never returns final overallMatchScore."""

from __future__ import annotations

import json
from typing import Any

import httpx

from app.core.config import Settings, get_settings
from app.core.security import get_logger

logger = get_logger(__name__)

JOB_MATCH_SYSTEM_PROMPT = """You are Careerly's job-match analyst.
Return ONLY valid JSON matching the schema.
Compare the candidate's CV evidence to the job description.
Never invent skills, employers, metrics, degrees, or tools.
If a requirement is absent from the CV, say it is "not demonstrated in the CV" — do NOT say the person lacks the skill.
Do NOT compute or return overallMatchScore / overall score. Scoring is owned by Careerly's engine.
Prefer student/early-career friendly framing when career_stage is student/intern/new graduate.
Write in the requested locale (en or tr).
"""


def validate_job_match_ai(raw: dict[str, Any]) -> dict[str, Any]:
    raw = {
        k: v
        for k, v in raw.items()
        if k
        not in {
            "overallMatchScore",
            "overall_score",
            "overallScore",
            "matchScore",
        }
    }

    def _hint(name: str, default: float) -> tuple[float, str]:
        block = raw.get(name) or {}
        if not isinstance(block, dict):
            return default, ""
        try:
            score = float(block.get("scoreHint", block.get("score", default)))
        except (TypeError, ValueError):
            score = default
        score = max(0.0, min(100.0, score))
        return score, str(block.get("summary") or "")[:240]

    recs = []
    for item in raw.get("recommendations") or []:
        if not isinstance(item, dict):
            continue
        recs.append(
            {
                "id": str(item.get("id") or f"rec_{len(recs)}"),
                "title": str(item.get("title") or "")[:160],
                "body": str(item.get("body") or "")[:500],
                "kind": str(item.get("kind") or "cv_improvement"),
                "beforeText": item.get("beforeText"),
                "afterText": item.get("afterText"),
            }
        )

    return {
        "experienceProjects": _hint("experienceProjects", 65),
        "responsibilities": _hint("responsibilities", 60),
        "recommendations": recs[:8],
        "verificationQuestions": [
            str(q)[:200] for q in (raw.get("verificationQuestions") or []) if str(q).strip()
        ][:5],
        "learningOpportunities": [
            str(q)[:200] for q in (raw.get("learningOpportunities") or []) if str(q).strip()
        ][:5],
        "workingWell": [str(q)[:200] for q in (raw.get("workingWell") or []) if str(q).strip()][:5],
        "unclearSkills": [
            str(q).lower() for q in (raw.get("unclearSkills") or []) if str(q).strip()
        ][:10],
    }


class MockJobMatchAI:
    async def analyze(self, payload: dict[str, Any]) -> dict[str, Any]:
        tr = str(payload.get("locale", "en")).startswith("tr")
        missing = payload.get("missing_skills") or []
        return {
            "experienceProjects": {
                "scoreHint": 68,
                "summary": (
                    "Projeler rolün bazı sorumluluklarıyla örtüşüyor; sonuç dili güçlendirilebilir."
                    if tr
                    else "Projects overlap some role responsibilities; outcome language can be stronger."
                ),
            },
            "responsibilities": {
                "scoreHint": 62,
                "summary": (
                    "Bazı görev alanları CV'de kısmen yansıyor; kanıt netleştirilmeli."
                    if tr
                    else "Some responsibility themes appear partially; evidence should be clearer."
                ),
            },
            "recommendations": [
                {
                    "id": "jm_rec_impact",
                    "title": (
                        "Proje maddesini role yaklaştırın"
                        if tr
                        else "Align a project bullet to the role"
                    ),
                    "body": (
                        "İlanda geçen bir sorumluluğu, yalnızca doğruysa ölçülebilir bir sonuçla bağlayın."
                        if tr
                        else "Tie one real project outcome to a responsibility in the posting — only if true."
                    ),
                    "kind": "cv_improvement",
                    "beforeText": (
                        "Flutter ile kampüs uygulaması geliştirdim."
                        if tr
                        else "Built a campus app with Flutter."
                    ),
                    "afterText": (
                        "Flutter ile 120+ öğrencinin kullandığı kampüs etkinlik uygulamasını geliştirdim."
                        if tr
                        else "Built a Flutter campus events app used by 120+ students for RSVPs."
                    ),
                },
                {
                    "id": "jm_rec_learn",
                    "title": (
                        f"Öğrenme fırsatı: {missing[0]}"
                        if missing and tr
                        else (
                            f"Learning opportunity: {missing[0]}"
                            if missing
                            else (
                                "Eksik kanıt için öğrenme planı"
                                if tr
                                else "Learning plan for undemonstrated skills"
                            )
                        )
                    ),
                    "body": (
                        "CV'de gösterilmeyen bir gereksinim için kısa, dürüst bir öğrenme adımı ekleyin — uydurma deneyim yazmayın."
                        if tr
                        else "For a requirement not demonstrated in your CV, add an honest learning step — never invent experience."
                    ),
                    "kind": "learning",
                },
            ],
            "verificationQuestions": [
                (
                    f"{missing[0]} deneyiminiz var mı? Varsa hangi projede?"
                    if missing and tr
                    else (
                        f"Do you have experience with {missing[0]}? If yes, in which project?"
                        if missing
                        else (
                            "Bu rol için en güçlü projeniz hangisi?"
                            if tr
                            else "Which project best supports this role?"
                        )
                    )
                )
            ],
            "learningOpportunities": [
                (
                    f"{missing[0]} için küçük bir demo veya kurs notu eklemeyi düşünün."
                    if missing and tr
                    else (
                        f"Consider a small demo or course note for {missing[0]}."
                        if missing
                        else (
                            "İlandaki araçlardan birini dürüstçe öğrenme planına alın."
                            if tr
                            else "Pick one undemonstrated tool from the posting for an honest learning plan."
                        )
                    )
                )
            ],
            "workingWell": [
                (
                    "CV'de projeler bölümü mevcut — staj/öğrenci başvuruları için güçlü."
                    if tr
                    else "Projects section is present — strong for internship/student applications."
                )
            ],
            "unclearSkills": [],
        }


class OpenAIJobMatchAI:
    def __init__(self, settings: Settings):
        self._settings = settings

    async def analyze(self, payload: dict[str, Any]) -> dict[str, Any]:
        if not self._settings.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is not configured")
        schema = {
            "experienceProjects": {"scoreHint": 0, "summary": ""},
            "responsibilities": {"scoreHint": 0, "summary": ""},
            "recommendations": [],
            "verificationQuestions": [],
            "learningOpportunities": [],
            "workingWell": [],
            "unclearSkills": [],
        }
        user_msg = (
            f"Locale: {payload.get('locale')}\n"
            f"Career stage: {payload.get('career_stage')}\n"
            f"Job title: {payload.get('job_title')}\n"
            f"Missing skills (deterministic): {payload.get('missing_skills')}\n"
            f"Resume snapshot JSON: {json.dumps(payload.get('resume'))[:8000]}\n"
            f"Job description (do not invent beyond this):\n{str(payload.get('job_description', ''))[:8000]}\n"
            f"Respond with JSON like: {json.dumps(schema)}"
        )
        body = {
            "model": self._settings.openai_model,
            "temperature": 0.2,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": JOB_MATCH_SYSTEM_PROMPT},
                {"role": "user", "content": user_msg},
            ],
        }
        headers = {
            "Authorization": f"Bearer {self._settings.openai_api_key}",
            "Content-Type": "application/json",
        }
        url = f"{self._settings.openai_base_url.rstrip('/')}/chat/completions"
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, headers=headers, json=body)
            response.raise_for_status()
            data = response.json()
        content = data["choices"][0]["message"]["content"]
        return json.loads(content)


def get_job_match_ai(settings: Settings | None = None):
    settings = settings or get_settings()
    if settings.ai_provider.lower().strip() == "openai":
        logger.info("Job Match AI: OpenAI-compatible provider")
        return OpenAIJobMatchAI(settings)
    logger.info("Job Match AI: mock provider")
    return MockJobMatchAI()
