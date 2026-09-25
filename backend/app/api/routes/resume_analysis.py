from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile

from app.core.auth import AuthPrincipal, require_principal
from app.core.config import Settings, get_settings
from app.providers.ai_provider import AIProvider, get_ai_provider
from app.schemas.analysis import AnalyzeResponse, ErrorResponse
from app.services.analysis_pipeline import AnalysisPipelineError, analyze_resume_bytes
from app.services.feature_gate import assert_feature_allowed, record_feature_usage
from app.services.plan_limits import FeatureId

router = APIRouter(prefix="/resumes", tags=["resume-analysis"])


def _ai_provider(settings: Settings = Depends(get_settings)) -> AIProvider:
    return get_ai_provider(settings)


@router.post(
    "/analyze",
    response_model=AnalyzeResponse,
    responses={
        400: {"model": ErrorResponse},
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        413: {"model": ErrorResponse},
    },
)
async def analyze_resume(
    file: UploadFile = File(...),
    locale: str = Form("en"),
    career_stage: str | None = Form(None),
    target_role: str | None = Form(None),
    request_id: str | None = Form(None),
    settings: Settings = Depends(get_settings),
    ai: AIProvider = Depends(_ai_provider),
    principal: AuthPrincipal = Depends(require_principal),
    x_request_id: str | None = Header(default=None, alias="X-Request-Id"),
) -> AnalyzeResponse:
    user_id = principal.user_id
    assert_feature_allowed(user_id=user_id, feature=FeatureId.cvAnalysis)

    filename = file.filename or "resume.bin"
    data = await file.read()
    # Discard bytes after processing — no permanent storage by design.
    try:
        result = await analyze_resume_bytes(
            filename=filename,
            data=data,
            locale=locale or "en",
            career_stage=career_stage,
            target_role=target_role,
            settings=settings,
            ai_provider=ai,
        )
    except AnalysisPipelineError as exc:
        raise HTTPException(
            status_code=exc.status_code,
            detail={"code": exc.code, "message": exc.message},
        ) from exc
    finally:
        del data

    record_feature_usage(
        user_id=user_id,
        feature=FeatureId.cvAnalysis,
        request_id=request_id or x_request_id,
    )
    return result
