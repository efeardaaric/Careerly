"""Structured CV check — reuses ATS + scoring engines (no second scoring system)."""

from __future__ import annotations

from typing import Any

from app.core.config import Settings
from app.providers.ai_provider import get_ai_provider
from app.schemas.builder import StructuredCheckResponse
from app.services.ai_analysis_service import validate_ai_payload
from app.services.ats_engine import run_ats_engine
from app.services.builder_document_text import resume_document_to_plain_text
from app.services.resume_normalizer import normalize_resume
from app.services.scoring_engine import build_resume_analysis


async def check_structured_document(
    *,
    document: dict[str, Any],
    locale: str,
    career_stage: str | None,
    settings: Settings,
) -> StructuredCheckResponse:
    text = resume_document_to_plain_text(document)
    personal = document.get("personal") or {}
    name = str(personal.get("fullName") or "CV").strip() or "CV"
    file_name = f"{name.replace(' ', '_')}_structured.txt"
    resume_id = str(document.get("id") or "builder_doc")

    normalized = normalize_resume(text, locale=locale)
    # Keep builder document id when present for traceability.
    if document.get("id"):
        normalized.resume_id = resume_id  # type: ignore[attr-defined]

    ats = run_ats_engine(text, normalized, locale=locale)
    ai_provider = get_ai_provider(settings)
    ai_raw = await ai_provider.analyze_content(
        {
            "locale": locale,
            "career_stage": career_stage,
            "target_role": None,
            "sections_meta": [
                {"key": s.key, "status": s.status.value, "preview": (s.preview or "")[:120]}
                for s in normalized.sections
            ],
            "text": text[:12000],
        }
    )
    ai = validate_ai_payload(ai_raw)
    analysis = build_resume_analysis(
        normalized=normalized,
        ats=ats,
        ai=ai,
        file_name=file_name,
        analysis_version=settings.analysis_version,
    )

    return StructuredCheckResponse(
        resumeId=resume_id,
        fileName=file_name,
        analysis=analysis.model_dump(),
        warnings=["Checked structured Builder CV — no file re-upload."],
        analysisVersion=settings.analysis_version,
        plainText=text,
    )
