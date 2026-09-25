"""CV Builder API — rewrite, translate, structured ATS check."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Header, HTTPException

from app.core.auth import AuthPrincipal, require_principal
from app.core.config import Settings, get_settings
from app.schemas.builder import (
    ErrorResponse,
    RewriteRequest,
    RewriteResponse,
    RewriteSuggestionOut,
    StructuredCheckRequest,
    StructuredCheckResponse,
    TranslateRequest,
    TranslateResponse,
)
from app.services.builder_ai import get_builder_ai
from app.services.builder_check_pipeline import check_structured_document
from app.services.feature_gate import assert_feature_allowed, record_feature_usage
from app.services.plan_limits import FeatureId

router = APIRouter(prefix="/builder", tags=["builder"])


@router.post(
    "/rewrite",
    response_model=RewriteResponse,
    responses={400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
async def rewrite_text(
    body: RewriteRequest,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    x_request_id: str | None = Header(default=None, alias="X-Request-Id"),
) -> RewriteResponse:
    """Suggest a rewrite — never auto-applied; never invents metrics."""
    user_id = principal.user_id
    assert_feature_allowed(user_id=user_id, feature=FeatureId.aiRewrite)

    ai = get_builder_ai(settings)
    raw = await ai.rewrite(
        mode=body.mode,
        text=body.text,
        locale=body.locale,
        section_key=body.sectionKey,
        notes=body.notes,
    )
    record_feature_usage(
        user_id=user_id,
        feature=FeatureId.aiRewrite,
        request_id=x_request_id,
    )
    return RewriteResponse(suggestion=RewriteSuggestionOut(**raw))


@router.post(
    "/translate",
    response_model=TranslateResponse,
    responses={400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
async def translate_document(
    body: TranslateRequest,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    x_request_id: str | None = Header(default=None, alias="X-Request-Id"),
) -> TranslateResponse:
    """Create a translated CV version (TR↔EN). Proper nouns preserved."""
    user_id = principal.user_id
    assert_feature_allowed(user_id=user_id, feature=FeatureId.translation)

    if not isinstance(body.document, dict) or not body.document:
        raise HTTPException(
            status_code=400,
            detail={"code": "invalid_document", "message": "document is required"},
        )

    ai = get_builder_ai(settings)
    doc = await ai.translate(
        document=body.document,
        target_language=body.targetLanguage,
    )
    record_feature_usage(
        user_id=user_id,
        feature=FeatureId.translation,
        request_id=x_request_id,
    )
    return TranslateResponse(document=doc)


@router.post(
    "/check",
    response_model=StructuredCheckResponse,
    responses={400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
async def check_structured_cv(
    body: StructuredCheckRequest,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    x_request_id: str | None = Header(default=None, alias="X-Request-Id"),
) -> StructuredCheckResponse:
    """ATS + scoring on structured Builder data — same engines as file analyze."""
    user_id = principal.user_id
    assert_feature_allowed(user_id=user_id, feature=FeatureId.cvAnalysis)

    if not isinstance(body.document, dict) or not body.document:
        raise HTTPException(
            status_code=400,
            detail={"code": "invalid_document", "message": "document is required"},
        )

    result = await check_structured_document(
        document=body.document,
        locale=body.locale,
        career_stage=body.careerStage,
        settings=settings,
    )
    record_feature_usage(
        user_id=user_id,
        feature=FeatureId.cvAnalysis,
        request_id=x_request_id,
    )
    return result
