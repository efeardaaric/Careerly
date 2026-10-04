"""Parse, correct, and score a CV. Temporary files are deleted. Raw text is not stored."""

from __future__ import annotations

import logging
import os
import re
import tempfile
import uuid
from datetime import UTC, datetime
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.ai.service import AIService
from app.core.config import Settings
from app.cv.confidence import confidence_band
from app.cv.extractor import CVFileError, extract
from app.cv.parser import StructuredCV, parse_cv
from app.db.models import AnalysisFinding, CVAnalysis, CVAnalysisCategory, CVDocument, User
from app.scoring.engine import score_structured
from app.scoring.weights import WEIGHTS

logger = logging.getLogger("careerly.cv")

_ALLOWED = {
    ".pdf": "application/pdf",
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}
_CANONICAL_HEADINGS = {
    "summary": "Summary",
    "experience": "Experience",
    "education": "Education",
    "skills": "Skills",
    "projects": "Projects",
    "certifications": "Certifications",
    "languages": "Languages",
    "awards": "Awards",
    "volunteer": "Volunteer",
    "publications": "Publications",
}


def display_name(filename: str) -> str:
    stem = Path(filename).name
    previous = None
    while previous != stem:
        previous = stem
        stem = re.sub(r"\.(pdf|docx)$", "", stem, flags=re.IGNORECASE)
    stem = re.sub(r"\s*\(\d+\)$", "", stem).strip()
    return stem or "CV"


def parse_upload(
    session: Session,
    *,
    filename: str,
    data: bytes,
    mime_type: str | None,
    user_id: str,
    career_stage: str | None,
    target_fields: list[str],
    settings: Settings,
) -> dict:
    suffix = _validate(filename, data, mime_type, settings)
    path = _write_temp(data, suffix)
    try:
        extracted = extract(path, mime_type)
        structured = parse_cv(
            extracted.text,
            extraction_method=extracted.extraction_method,
            page_count=extracted.page_count,
            contains_tables=extracted.contains_tables,
        )
    finally:
        _delete_temp(path)

    payload = structured.to_dict()
    _attach_context(payload, career_stage, target_fields)
    user = _ensure_user(session, user_id, career_stage, target_fields)
    document = CVDocument(
        user_id=user.external_auth_id,
        original_file_name=Path(filename).name[:260],
        display_name=display_name(filename),
        mime_type=_ALLOWED[suffix],
        file_size=len(data),
        detected_language=structured.detected_language,
        parse_status="parsed",
        parser_confidence=structured.parser_confidence,
        parser_version=settings.parser_version,
        structured_data=payload,
    )
    session.add(document)
    session.flush()
    logger.info(
        "cv_parsed file_type=%s file_size=%s parser_confidence=%s parser_version=%s",
        suffix,
        len(data),
        structured.parser_confidence,
        settings.parser_version,
    )
    return flutter_parse_payload(document, settings)


def update_parsed(session: Session, document: CVDocument, patch: dict) -> dict:
    data = dict(document.structured_data or {})
    if patch.get("contact"):
        contact = dict(data.get("contact") or {})
        contact.update({key: value for key, value in patch["contact"].items()})
        data["contact"] = contact
    if patch.get("summary") is not None:
        data["summary"] = {"text": patch["summary"]}
    if patch.get("sections") is not None:
        data["sections"] = patch["sections"]
    data = refresh_from_sections(data)
    document.structured_data = data
    document.parser_confidence = float(data.get("parserConfidence") or 0)
    document.detected_language = data.get("detectedLanguage") or document.detected_language
    document.parse_status = "corrected"
    session.flush()
    return data


def analyze_document(
    session: Session,
    document: CVDocument,
    *,
    settings: Settings,
    ai: AIService,
) -> dict:
    data = refresh_from_sections(dict(document.structured_data or {}))
    context = data.get("context") or {}
    scored = score_structured(
        data,
        career_stage=context.get("careerStage"),
        target_fields=context.get("targetFields") or [],
    )
    findings = [_finding_dict(item) for item in scored["findings"]]
    if settings.ai_enabled:
        findings = [_safe_enrich(ai, item) for item in findings]
    analysis_id = str(uuid.uuid4())
    now = datetime.now(UTC).isoformat()
    band = confidence_band(round(document.parser_confidence))
    response = {
        "id": analysis_id,
        "resumeId": document.id,
        "overallScore": scored["overallScore"],
        "confidence": band,
        "categories": [
            {
                "id": category.key,
                "score": category.score,
                "weight": WEIGHTS[category.key],
                "summary": category.summary,
            }
            for category in scored["categories"]
        ],
        "findings": findings,
        "workingWell": scored["strengths"],
        "topImprovementIds": [item["id"] for item in findings[:3]],
        "engineVersion": settings.scoring_engine_version,
        "analyzedAt": now,
        "fileName": document.display_name,
    }
    row = CVAnalysis(
        id=analysis_id,
        cv_id=document.id,
        overall_score=response["overallScore"],
        ats_score=_category_score(response, "atsCompatibility"),
        content_impact_score=_category_score(response, "contentImpact"),
        experience_score=_category_score(response, "experiencePresentation"),
        skills_score=_category_score(response, "skillsRelevance"),
        structure_score=_category_score(response, "structureReadability"),
        language_score=_category_score(response, "languageGrammar"),
        basics_score=_category_score(response, "basicsContact"),
        parser_confidence=document.parser_confidence,
        engine_version=settings.scoring_engine_version,
        summary=response["categories"][0]["summary"] if response["categories"] else None,
        payload={
            "analysis": response,
            "rules": [
                {
                    "category": category.key,
                    "key": item.key,
                    "status": item.status,
                    "earned": item.score_contribution,
                    "max": item.max_contribution,
                }
                for category in scored["categories"]
                for item in category.rules
            ],
        },
    )
    session.add(row)
    for category in scored["categories"]:
        session.add(
            CVAnalysisCategory(
                analysis_id=analysis_id,
                key=category.key,
                title=category.title,
                score=category.score,
                weight=WEIGHTS[category.key],
                earned_points=category.earned_points,
                possible_points=category.possible_points,
                summary=category.summary,
            )
        )
    for item in findings:
        session.add(
            AnalysisFinding(
                id=item["id"],
                analysis_id=analysis_id,
                category=item["categoryId"],
                severity=item["severity"],
                title=item["title"],
                description=item["whyItMatters"],
                evidence=item["evidence"],
                recommendation=item["recommendedAction"],
                source_section=item.get("sourceSection"),
                can_auto_fix=1 if item["supportsAiImprove"] else 0,
            )
        )
    document.latest_analysis_id = analysis_id
    document.parse_status = "analyzed"
    document.structured_data = data
    session.flush()
    logger.info(
        "cv_analyzed parser_confidence=%s engine_version=%s overall=%s",
        round(document.parser_confidence),
        settings.scoring_engine_version,
        response["overallScore"],
    )
    return response


def flutter_parse_payload(document: CVDocument, settings: Settings) -> dict:
    data = document.structured_data or {}
    contact = data.get("contact") or {}
    summary = data.get("summary") or {}
    summary_text = summary.get("text") if isinstance(summary, dict) else None
    band = confidence_band(round(document.parser_confidence))
    sections = []
    for section in data.get("sections") or []:
        body = section.get("body") or ""
        sections.append(
            {
                "id": section.get("id"),
                "key": section.get("key"),
                "title": section.get("title") or section.get("key"),
                "status": _section_status(section.get("status")),
                "preview": body[:160] or None,
                "note": section.get("note"),
            }
        )
    return {
        "resumeId": document.id,
        "fileName": document.display_name,
        "confidence": band,
        "engineVersion": settings.parser_version,
        "parserConfidence": round(document.parser_confidence),
        "detectedLanguage": document.detected_language,
        "sections": sections,
        "evidence": {
            "originalFileName": document.original_file_name,
            "displayName": document.display_name,
            "rawText": "",
            "parserConfidenceScore": round(document.parser_confidence),
            "detectedLanguage": document.detected_language,
            "fullName": contact.get("fullName"),
            "email": contact.get("email"),
            "phone": contact.get("phone"),
            "location": contact.get("location"),
            "linkedIn": contact.get("linkedIn"),
            "github": contact.get("github"),
            "portfolio": contact.get("portfolio"),
            "summary": summary_text,
            "sections": data.get("sections") or [],
        },
        "parsed": {
            "contact": contact,
            "summary": summary,
            "experiences": data.get("experiences") or [],
            "education": data.get("education") or [],
            "projects": data.get("projects") or [],
            "skills": data.get("skills") or [],
            "certifications": data.get("certifications") or [],
            "languages": data.get("languages") or [],
            "links": data.get("links") or [],
        },
    }


def refresh_from_sections(data: dict) -> dict:
    """Rebuild items from the section keys the user confirmed."""
    kept_sections = list(data.get("sections") or [])
    contact = dict(data.get("contact") or {})
    lines: list[str] = []
    for field in ("fullName", "email", "phone", "location", "linkedIn", "github", "portfolio"):
        if contact.get(field):
            lines.append(str(contact[field]))
    for section in kept_sections:
        if section.get("status") == "missing":
            continue
        key = section.get("key") or "custom"
        lines.append(_CANONICAL_HEADINGS.get(key, section.get("title") or key))
        lines.append(section.get("body") or "")
    parsed: StructuredCV = parse_cv("\n".join(lines)) if lines else StructuredCV()
    refreshed = parsed.to_dict()
    merged_contact = dict(refreshed.get("contact") or {})
    merged_contact.update({key: value for key, value in contact.items() if value})
    refreshed["contact"] = merged_contact
    refreshed["sections"] = kept_sections
    refreshed["context"] = data.get("context") or {}
    refreshed["detectedLanguage"] = data.get("detectedLanguage") or refreshed["detectedLanguage"]
    return refreshed


def owned_document(session: Session, cv_id: str, user_id: str) -> CVDocument:
    document = session.get(CVDocument, cv_id)
    if document is None or document.user_id != user_id:
        raise CVFileError("CV_NOT_FOUND", "CV not found.", status_code=404)
    return document


def _validate(filename: str, data: bytes, mime_type: str | None, settings: Settings) -> str:
    if not data:
        raise CVFileError("CV_TEXT_EXTRACTION_FAILED", "We couldn't read text from this CV.")
    if len(data) > settings.max_upload_bytes:
        raise CVFileError(
            "CV_TOO_LARGE",
            "This file is larger than 10 MB.",
            status_code=413,
        )
    suffix = Path(filename or "").suffix.lower()
    if suffix not in _ALLOWED:
        raise CVFileError(
            "UNSUPPORTED_CV_TYPE",
            "Please upload a PDF or DOCX file.",
            status_code=415,
        )
    if (
        mime_type
        and mime_type not in {
            "application/octet-stream",
            "application/pdf",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/zip",
        }
        and suffix == ".pdf"
        and mime_type.startswith("image/")
    ):
        raise CVFileError(
            "UNSUPPORTED_CV_TYPE",
            "Please upload a PDF or DOCX file.",
            status_code=415,
        )
    return suffix


def _write_temp(data: bytes, suffix: str) -> str:
    handle, path = tempfile.mkstemp(prefix="careerly-", suffix=suffix)
    try:
        os.write(handle, data)
    finally:
        os.close(handle)
    return path


def _delete_temp(path: str) -> None:
    try:
        os.remove(path)
    except OSError:
        logger.info("temp_cv_cleanup_failed")


def _ensure_user(
    session: Session,
    user_id: str,
    career_stage: str | None,
    target_fields: list[str],
) -> User:
    user = session.scalar(select(User).where(User.external_auth_id == user_id))
    if user is None:
        user = User(
            external_auth_id=user_id,
            career_stage=career_stage,
            target_fields=target_fields,
        )
        session.add(user)
        session.flush()
    elif career_stage or target_fields:
        if career_stage:
            user.career_stage = career_stage
        if target_fields:
            user.target_fields = target_fields
    return user


def _attach_context(payload: dict, career_stage: str | None, target_fields: list[str]) -> None:
    payload["context"] = {
        "careerStage": career_stage,
        "targetFields": target_fields,
    }


def _section_status(value: str | None) -> str:
    allowed = {"detected", "missing", "needsReview", "lowConfidence", "userCorrected"}
    if value in allowed:
        return value
    if value == "low_confidence":
        return "lowConfidence"
    return "detected"


def _finding_dict(item) -> dict:
    severity = item.severity if item.severity in {"critical", "improve", "good"} else "improve"
    return {
        "id": str(uuid.uuid4()),
        "severity": severity,
        "title": item.title,
        "whyItMatters": item.description,
        "evidence": item.evidence,
        "recommendedAction": item.recommendation,
        "categoryId": item.category,
        "beforeText": None,
        "afterText": None,
        "supportsAiImprove": False,
        "sourceSection": item.source_section,
    }


def _safe_enrich(ai: AIService, finding: dict) -> dict:
    try:
        return ai.enrich_finding(finding)
    except Exception:  # noqa: BLE001 — explanation enrichment is optional
        logger.info("ai_enrichment_skipped")
        return finding


def _category_score(response: dict, key: str) -> int:
    for category in response["categories"]:
        if category["id"] == key:
            return int(category["score"])
    return 0
