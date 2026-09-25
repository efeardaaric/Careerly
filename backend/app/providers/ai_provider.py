"""AI provider abstraction. OpenAI-compatible HTTP or deterministic mock."""

from __future__ import annotations

import json
from abc import ABC, abstractmethod
from typing import Any

import httpx

from app.core.config import Settings, get_settings
from app.core.security import get_logger

logger = get_logger(__name__)

# Location of system prompt for operators / auditors.
AI_SYSTEM_PROMPT = """You are Careerly's career writing analyst.
Return ONLY valid JSON matching the required schema.
Never invent employers, degrees, metrics, skills, dates, or certifications.
If evidence is missing, say so and recommend asking the user — do not fabricate.
Prefer student- and early-career friendly framing: projects, coursework, volunteering count.
Do NOT compute or return an overallScore. Scoring is owned by Careerly's scoring engine.
Write feedback in the requested locale (en or tr).
Be concise, constructive, and specific.
"""


class AIProvider(ABC):
    @abstractmethod
    async def analyze_content(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Return structured AI signals only — never final overall score."""


class MockAIProvider(AIProvider):
    """Deterministic structured signals for local/CI — no paid API calls."""

    async def analyze_content(self, payload: dict[str, Any]) -> dict[str, Any]:
        locale = payload.get("locale", "en")
        career_stage = (payload.get("career_stage") or "student").lower()
        studentish = career_stage in {
            "student",
            "intern",
            "newgraduate",
            "new_graduate",
        }
        tr = locale.startswith("tr")

        return {
            "contentImpact": {
                "scoreHint": 72 if studentish else 70,
                "summary": (
                    "Aktiviteler net; etki metrikleri hâlâ zayıf."
                    if tr
                    else "Clear activities, but impact metrics are still thin."
                ),
            },
            "experiencePresentation": {
                "scoreHint": 68 if studentish else 74,
                "summary": (
                    "Staj ve projeler daha keskin sonuç dili istiyor."
                    if tr
                    else "Internship and projects need sharper outcome language."
                ),
            },
            "skillsRelevance": {
                "scoreHint": 76,
                "summary": (
                    "Araçlar iyi listelenmiş; yumuşak becerileri kanıtlı maddelere taşıyın."
                    if tr
                    else "Solid tools listed; move soft skills into evidenced bullets."
                ),
            },
            "structureReadability": {
                "scoreHint": 80,
                "summary": (
                    "Okunabilir sıra ve tutarlı bölümleme."
                    if tr
                    else "Readable order with consistent sectioning."
                ),
            },
            "languageGrammar": {
                "scoreHint": 82,
                "summary": (
                    "Genel olarak net profesyonel dil; küçük cilalar kaldı."
                    if tr
                    else "Generally clear professional language with minor polish left."
                ),
            },
            "findings": [
                {
                    "id": "ai_impact",
                    "severity": "improve",
                    "title": (
                        "Proje işini ölçülebilir sonuca çevirin"
                        if tr
                        else "Turn project work into measurable outcomes"
                    ),
                    "whyItMatters": (
                        "Erken kariyer CV'leri, ne inşa ettiğinizden çok ne değiştirdiğinizi gösterince öne çıkar."
                        if tr
                        else "Early-career CVs stand out when projects show what changed because of your work."
                    ),
                    "evidence": (
                        "Proje maddeleri sonuç yerine teknoloji listeliyor."
                        if tr
                        else "Project bullets list tech stack without outcomes."
                    ),
                    "recommendedAction": (
                        "Gerçek bir sayınız varsa bir somut sonuç ekleyin; yoksa uydurmayın."
                        if tr
                        else "Add one concrete outcome only if you have the real number."
                    ),
                    "categoryId": "experiencePresentation",
                    "beforeText": (
                        "Flutter ve Firebase ile kampüs etkinlik uygulaması geliştirdim."
                        if tr
                        else "Built a campus event app using Flutter and Firebase."
                    ),
                    "afterText": (
                        "120+ öğrencinin RSVP yaptığı Flutter kampüs etkinlik uygulamasını geliştirdim."
                        if tr
                        else "Built a Flutter campus event app used by 120+ students to RSVP and receive updates."
                    ),
                    "supportsAiImprove": True,
                },
                {
                    "id": "ai_skills_mix",
                    "severity": "improve",
                    "title": (
                        "Araçları yumuşak becerilerden ayırın"
                        if tr
                        else "Separate tools from soft skills"
                    ),
                    "whyItMatters": (
                        "Karışık beceri listeleri ATS anahtar kelime eşleşmesini ve insan taramasını zorlaştırır."
                        if tr
                        else "Mixed skill lists make ATS keyword matching and human scanning harder."
                    ),
                    "evidence": (
                        "Yumuşak beceriler teknik araçlarla yan yana görünüyor."
                        if tr
                        else "Soft skills appear beside technical tools."
                    ),
                    "recommendedAction": (
                        "Teknik araçları Skills'te tutun; yumuşak becerileri deneyim maddelerine taşıyın."
                        if tr
                        else "Keep technical tools in Skills; move soft skills into experience bullets with proof."
                    ),
                    "categoryId": "skillsRelevance",
                    "supportsAiImprove": True,
                },
            ],
            "workingWell": [
                (
                    "Projeler bölümü mevcut — öğrenciler ve stajyerler için güçlü."
                    if tr
                    else "Projects section is present — strong for students and interns."
                ),
                (
                    "Dil genel olarak profesyonel ve anlaşılır."
                    if tr
                    else "Language is generally professional and understandable."
                ),
            ],
        }


class OpenAICompatibleProvider(AIProvider):
    def __init__(self, settings: Settings):
        self._settings = settings

    async def analyze_content(self, payload: dict[str, Any]) -> dict[str, Any]:
        if not self._settings.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is not configured")

        schema_hint = {
            "contentImpact": {"scoreHint": 0, "summary": ""},
            "experiencePresentation": {"scoreHint": 0, "summary": ""},
            "skillsRelevance": {"scoreHint": 0, "summary": ""},
            "structureReadability": {"scoreHint": 0, "summary": ""},
            "languageGrammar": {"scoreHint": 0, "summary": ""},
            "findings": [],
            "workingWell": [],
        }
        user_msg = (
            f"Locale: {payload.get('locale')}\n"
            f"Career stage: {payload.get('career_stage')}\n"
            f"Target role: {payload.get('target_role')}\n"
            f"Detected sections JSON: {json.dumps(payload.get('sections_meta', []))}\n"
            f"Resume text (do not invent beyond this):\n{payload.get('text', '')[:12000]}\n"
            f"Respond with JSON shaped like: {json.dumps(schema_hint)}"
        )
        body = {
            "model": self._settings.openai_model,
            "temperature": 0.2,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": AI_SYSTEM_PROMPT},
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
        parsed = json.loads(content)
        # Hard ban: strip any overallScore the model might sneak in.
        parsed.pop("overallScore", None)
        parsed.pop("overall_score", None)
        return parsed


def get_ai_provider(settings: Settings | None = None) -> AIProvider:
    settings = settings or get_settings()
    provider = settings.ai_provider.lower().strip()
    if provider == "openai":
        logger.info("Using OpenAI-compatible AI provider (model=%s)", settings.openai_model)
        return OpenAICompatibleProvider(settings)
    logger.info("Using MockAIProvider")
    return MockAIProvider()
