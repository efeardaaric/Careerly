"""End-to-end temporary analysis pipeline — no permanent CV storage."""

from __future__ import annotations

from app.core.config import Settings
from app.core.security import get_logger
from app.providers.ai_provider import AIProvider
from app.schemas.analysis import (
    AnalyzeResponse,
    ParsedResumeOut,
    ResumeSectionOut,
    SectionStatus,
)
from app.services.ai_analysis_service import validate_ai_payload
from app.services.ats_engine import run_ats_engine
from app.services.document_parser import DocumentParseError, extract_text
from app.services.resume_normalizer import normalize_resume
from app.services.scoring_engine import build_resume_analysis

logger = get_logger(__name__)


class AnalysisPipelineError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code
        super().__init__(message)


async def analyze_resume_bytes(
    *,
    filename: str,
    data: bytes,
    locale: str = "en",
    career_stage: str | None = None,
    target_role: str | None = None,
    settings: Settings,
    ai_provider: AIProvider,
) -> AnalyzeResponse:
    max_bytes = settings.max_upload_bytes
    if len(data) > max_bytes:
        raise AnalysisPipelineError(
            "file_too_large",
            f"File exceeds maximum size of {max_bytes} bytes.",
            status_code=413,
        )

    try:
        extracted = extract_text(filename, data)
    except DocumentParseError as exc:
        raise AnalysisPipelineError(exc.code, exc.message, status_code=400) from exc

    # Low-text / likely scan — still return structured analysis with warning.
    warnings = list(extracted.warnings)

    normalized = normalize_resume(extracted.text, locale=locale)
    ats = run_ats_engine(extracted.text, normalized, locale=locale)

    sections_meta = [
        {
            "key": s.key,
            "status": s.status.value,
            "preview": (s.preview or "")[:120],
        }
        for s in normalized.sections
    ]

    # Truncate text sent to AI; never log it.
    ai_raw = await ai_provider.analyze_content(
        {
            "locale": locale,
            "career_stage": career_stage,
            "target_role": target_role,
            "sections_meta": sections_meta,
            "text": extracted.text[:12000],
        }
    )
    ai = validate_ai_payload(ai_raw)

    analysis = build_resume_analysis(
        normalized=normalized,
        ats=ats,
        ai=ai,
        file_name=filename,
        analysis_version=settings.analysis_version,
    )

    parsed = ParsedResumeOut(
        resumeId=normalized.resume_id,
        confidence=normalized.confidence,
        engineVersion=settings.analysis_version,
        sections=[
            ResumeSectionOut(
                id=f"sec_{s.key}",
                key=s.key,
                title=s.title,
                status=SectionStatus(s.status.value),
                preview=s.preview,
                note=s.note,
            )
            for s in normalized.sections
        ],
    )

    logger.info(
        "analysis_completed resume_id=%s ext=%s warnings=%s overall=%s version=%s",
        normalized.resume_id,
        extracted.extension,
        warnings,
        analysis.overallScore,
        settings.analysis_version,
    )

    return AnalyzeResponse(
        resumeId=normalized.resume_id,
        fileName=filename,
        parsed=parsed,
        analysis=analysis,
        warnings=warnings,
        analysisVersion=settings.analysis_version,
    )
