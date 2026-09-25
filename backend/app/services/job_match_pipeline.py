"""End-to-end Job Match pipeline — no scraping; no raw CV/JD in logs."""

from __future__ import annotations

from app.core.config import Settings
from app.core.security import get_logger
from app.schemas.job_match import JobMatchRequest, JobMatchResponse
from app.services.job_description_parser import parse_job_description
from app.services.job_match_ai import get_job_match_ai, validate_job_match_ai
from app.services.job_match_hybrid import hybrid_match
from app.services.job_match_scoring import build_job_match_result

logger = get_logger(__name__)


class JobMatchPipelineError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code
        super().__init__(message)


async def run_job_match(
    *,
    request: JobMatchRequest,
    settings: Settings,
) -> JobMatchResponse:
    description = (request.jobDescription or "").strip()
    if len(description) < 20:
        raise JobMatchPipelineError(
            "job_description_too_short",
            "Paste a fuller job description (at least ~20 characters).",
            status_code=400,
        )

    job = parse_job_description(
        title=request.jobTitle or "Untitled role",
        description=description,
        company=request.company,
    )

    hybrid = hybrid_match(
        resume=request.resume,
        job=job,
        locale=request.locale or "en",
    )

    missing = [
        m.skill for m in hybrid.skill_matches if m.required and m.status.value == "notDemonstrated"
    ]

    ai_client = get_job_match_ai(settings)
    # Truncated payloads only — never log raw CV/JD text.
    ai_raw = await ai_client.analyze(
        {
            "locale": request.locale or "en",
            "career_stage": request.careerStage,
            "job_title": job.title,
            "missing_skills": missing[:8],
            "resume": {
                "resumeId": request.resume.resumeId,
                "skills": request.resume.skills[:40],
                "tools": request.resume.tools[:20],
                "education": request.resume.education[:10],
                "languages": request.resume.languages[:10],
                "experienceBullets": request.resume.experienceBullets[:12],
                "projectBullets": request.resume.projectBullets[:12],
                "summary": (request.resume.summary or "")[:400],
            },
            "job_description": description[:8000],
        }
    )
    ai = validate_job_match_ai(ai_raw if isinstance(ai_raw, dict) else {})

    match = build_job_match_result(
        resume=request.resume,
        job=job,
        hybrid=hybrid,
        ai=ai,
        locale=request.locale or "en",
        engine_version=settings.job_match_version,
        job_url=request.jobUrl,
    )

    warnings: list[str] = []
    if request.jobUrl:
        warnings.append("JOB_URL_METADATA_ONLY")
    if not job.required_skills and not job.preferred_skills:
        warnings.append("FEW_SKILLS_EXTRACTED")

    logger.info(
        "job_match_completed match_id=%s resume_id=%s score=%s skills=%s version=%s",
        match.id,
        request.resume.resumeId,
        match.overallMatchScore,
        len(match.skillMatches),
        settings.job_match_version,
    )

    return JobMatchResponse(
        match=match,
        warnings=warnings,
        analysisVersion=settings.job_match_version,
    )
