from __future__ import annotations

from fastapi import APIRouter, Depends, Header, HTTPException

from app.core.auth import AuthPrincipal, require_principal
from app.core.config import Settings, get_settings
from app.schemas.job_match import ErrorResponse, JobMatchRequest, JobMatchResponse
from app.services.feature_gate import assert_feature_allowed, record_feature_usage
from app.services.job_match_pipeline import JobMatchPipelineError, run_job_match
from app.services.plan_limits import FeatureId

router = APIRouter(prefix="/jobs", tags=["job-match"])


@router.post(
    "/match",
    response_model=JobMatchResponse,
    responses={
        400: {"model": ErrorResponse},
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
    },
)
async def match_job(
    body: JobMatchRequest,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    x_request_id: str | None = Header(default=None, alias="X-Request-Id"),
) -> JobMatchResponse:
    """Compare a structured resume snapshot to a pasted job description.

    Job URL is metadata only — never scraped.
    overallMatchScore is owned by the scoring engine, not the LLM.
    """
    user_id = principal.user_id
    assert_feature_allowed(user_id=user_id, feature=FeatureId.jobMatch)

    try:
        result = await run_job_match(request=body, settings=settings)
    except JobMatchPipelineError as exc:
        raise HTTPException(
            status_code=exc.status_code,
            detail={"code": exc.code, "message": exc.message},
        ) from exc

    record_feature_usage(
        user_id=user_id,
        feature=FeatureId.jobMatch,
        request_id=x_request_id,
    )
    return result
