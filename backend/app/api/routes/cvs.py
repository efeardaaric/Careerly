"""Two-stage CV API: parse, correct, then score."""

from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.ai.service import build_ai_service
from app.core.auth import AuthPrincipal, require_principal
from app.core.config import Settings, get_settings
from app.cv.extractor import CVFileError
from app.db.models import CVAnalysis, CVDocument
from app.db.session import get_db
from app.optimization.suggestions import SUGGESTIONS_VERSION, build_suggestions
from app.services.cv_pipeline import (
    analyze_document,
    flutter_parse_payload,
    owned_document,
    parse_upload,
    update_parsed,
)
from app.services.feature_gate import assert_feature_allowed, record_feature_usage
from app.services.plan_limits import FeatureId

router = APIRouter(prefix="/cvs", tags=["cvs"])


class ParsedPatch(BaseModel):
    sections: list[dict] | None = None
    contact: dict | None = None
    summary: str | None = None


class RewriteRequest(BaseModel):
    section: str | None = None
    item_id: str | None = None
    text: str = Field(min_length=1, max_length=2000)
    rewrite_goal: str = "clarity"
    mode: Literal["impact", "concise", "professional", "job_targeted", "grammar"] | None = None
    job_context: str | None = Field(default=None, max_length=8000)


def _cv_context(document: CVDocument) -> str:
    sections = (document.structured_data or {}).get("sections") or []
    return "\n".join(str(section.get("body") or "") for section in sections)


def _fields(raw: str | None) -> list[str]:
    if not raw:
        return []
    return [part.strip() for part in raw.split(",") if part.strip()]


def _error(exc: CVFileError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.message}},
    )


@router.post("/parse")
async def parse_cv_upload(
    file: UploadFile = File(...),
    career_stage: str | None = Form(None),
    target_fields: str | None = Form(None),
    cv_language: str | None = Form(None),
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    del cv_language  # stored later from detected language, not a client claim
    data = await file.read()
    try:
        return parse_upload(
            session,
            filename=file.filename or "cv.pdf",
            data=data,
            mime_type=file.content_type,
            user_id=principal.user_id,
            career_stage=career_stage,
            target_fields=_fields(target_fields),
            settings=settings,
        )
    except CVFileError as exc:
        return _error(exc)
    finally:
        del data


@router.get("")
def list_cvs(
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    rows = session.scalars(
        select(CVDocument)
        .where(CVDocument.user_id == principal.user_id)
        .order_by(CVDocument.created_at.desc())
    ).all()
    return {
        "cvs": [
            {
                "id": row.id,
                "displayName": row.display_name,
                "fileType": "pdf" if "pdf" in row.mime_type else "docx",
                "fileSize": row.file_size,
                "detectedLanguage": row.detected_language,
                "parserConfidence": round(row.parser_confidence),
                "parseStatus": row.parse_status,
                "latestAnalysisId": row.latest_analysis_id,
            }
            for row in rows
        ]
    }


@router.get("/{cv_id}")
def get_cv(
    cv_id: str,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    try:
        document = owned_document(session, cv_id, principal.user_id)
    except CVFileError as exc:
        return _error(exc)
    return flutter_parse_payload(document, settings)


@router.patch("/{cv_id}/parsed")
def patch_parsed(
    cv_id: str,
    body: ParsedPatch,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    try:
        document = owned_document(session, cv_id, principal.user_id)
    except CVFileError as exc:
        return _error(exc)
    update_parsed(session, document, body.model_dump(exclude_none=True))
    return flutter_parse_payload(document, settings)


@router.post("/{cv_id}/analyze")
def analyze_cv(
    cv_id: str,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    ai = build_ai_service(settings)
    try:
        document = owned_document(session, cv_id, principal.user_id)
        assert_feature_allowed(user_id=principal.user_id, feature=FeatureId.cvAnalysis)
        record_feature_usage(
            user_id=principal.user_id, feature=FeatureId.cvAnalysis,
            request_id=None, session=session,
        )
        return analyze_document(session, document, settings=settings, ai=ai)
    except CVFileError as exc:
        return _error(exc)


@router.post("/{cv_id}/reanalyze")
def reanalyze_cv(
    cv_id: str,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    return analyze_cv(cv_id, settings, principal, session)


@router.get("/{cv_id}/analysis")
def get_analysis(
    cv_id: str,
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    try:
        document = owned_document(session, cv_id, principal.user_id)
    except CVFileError as exc:
        return _error(exc)
    if not document.latest_analysis_id:
        return JSONResponse(
            status_code=404,
            content={"error": {"code": "ANALYSIS_NOT_FOUND", "message": "This CV has not been analyzed."}},
        )
    row = session.get(CVAnalysis, document.latest_analysis_id)
    if row is None:
        return JSONResponse(
            status_code=404,
            content={"error": {"code": "ANALYSIS_NOT_FOUND", "message": "This CV has not been analyzed."}},
        )
    return row.payload.get("analysis") or {}


@router.get("/{cv_id}/analysis/debug")
def debug_analysis(
    cv_id: str,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    if settings.is_production:
        raise HTTPException(status_code=404, detail="Not found")
    try:
        document = owned_document(session, cv_id, principal.user_id)
    except CVFileError as exc:
        return _error(exc)
    row = session.get(CVAnalysis, document.latest_analysis_id) if document.latest_analysis_id else None
    if row is None:
        return JSONResponse(
            status_code=404,
            content={"error": {"code": "ANALYSIS_NOT_FOUND", "message": "This CV has not been analyzed."}},
        )
    return {"engineVersion": row.engine_version, "rules": row.payload.get("rules") or []}


@router.delete("/{cv_id}")
def delete_cv(
    cv_id: str,
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    try:
        document = owned_document(session, cv_id, principal.user_id)
    except CVFileError as exc:
        return _error(exc)
    session.delete(document)
    return {"deleted": True}


@router.post("/{cv_id}/rewrite")
def rewrite_bullet(
    cv_id: str,
    body: RewriteRequest,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    try:
        document = owned_document(session, cv_id, principal.user_id)
    except CVFileError as exc:
        return _error(exc)
    if not settings.ai_enabled:
        return JSONResponse(
            status_code=503,
            content={
                "error": {
                    "code": "AI_DISABLED",
                    "message": "AI rewrite is turned off. The score does not depend on it.",
                }
            },
        )
    ai = build_ai_service(settings)
    assert_feature_allowed(user_id=principal.user_id, feature=FeatureId.aiRewrite)
    if body.mode == "job_targeted":
        assert_feature_allowed(user_id=principal.user_id, feature=FeatureId.jobTailor)
    record_feature_usage(
        user_id=principal.user_id, feature=FeatureId.aiRewrite,
        request_id=None, session=session,
    )
    if body.mode is None:
        return ai.rewrite(body.text, body.rewrite_goal)
    return ai.rewrite_structured(
        body.text,
        body.mode,
        cv_context=_cv_context(document),
        job_context=body.job_context,
    )


@router.post("/{cv_id}/suggestions")
def cv_suggestions(
    cv_id: str,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
    session: Session = Depends(get_db),
) -> dict:
    try:
        document = owned_document(session, cv_id, principal.user_id)
    except CVFileError as exc:
        return _error(exc)
    sections = (document.structured_data or {}).get("sections") or []
    return {
        "resumeId": document.id,
        "engineVersion": SUGGESTIONS_VERSION,
        "aiAvailable": bool(settings.ai_enabled and (settings.openai_api_key or "").strip()),
        "suggestions": build_suggestions(sections),
    }
