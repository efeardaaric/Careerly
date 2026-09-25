from __future__ import annotations

import io

import pytest
from docx import Document
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.main import app
from app.providers.ai_provider import MockAIProvider
from app.schemas.analysis import ScoreCategoryId
from app.services.ai_analysis_service import validate_ai_payload
from app.services.analysis_pipeline import analyze_resume_bytes
from app.services.ats_engine import run_ats_engine
from app.services.document_parser import DocumentParseError, extract_text
from app.services.resume_normalizer import normalize_resume
from app.services.scoring_weights import SCORE_WEIGHTS, CategorySignal, weighted_overall

client = TestClient(app)


def _sample_cv_text() -> str:
    return """
Aylin Demir
aylin.demir@email.com
Istanbul

Summary
Computer Science student seeking internship opportunities in software.

Education
B.Sc. Computer Science · Expected 2027

Experience
Marketing Intern · Campus Club · 2025
- Supported event promotion for student community

Projects
Campus Event App
- Built a campus event app using Flutter and Firebase

Skills
Flutter, Dart, Python, teamwork, MS Office

Languages
Turkish (Native), English (B2)

Awards / activities
Volunteer · Coding Club mentor
"""


def _docx_bytes(text: str) -> bytes:
    doc = Document()
    for line in text.strip().splitlines():
        doc.add_paragraph(line)
    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()


def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


def test_normalize_detects_sections_en():
    normalized = normalize_resume(_sample_cv_text(), locale="en")
    keys = {s.key for s in normalized.sections if s.status.value == "detected"}
    assert "contact" in keys
    assert "education" in keys
    assert "projects" in keys
    assert normalized.has_email is True


def test_ats_engine_scores_without_inventing_columns():
    normalized = normalize_resume(_sample_cv_text(), locale="en")
    ats = run_ats_engine(_sample_cv_text(), normalized, locale="en")
    assert 0 <= ats.score <= 100
    assert all("two-column" not in f.evidence.lower() for f in ats.findings)


def test_validate_ai_strips_overall_score():
    cleaned = validate_ai_payload(
        {
            "overallScore": 99,
            "contentImpact": {"scoreHint": 70, "summary": "ok"},
            "findings": [],
            "workingWell": [],
        }
    )
    assert "overallScore" not in cleaned
    assert cleaned["contentImpact"][0] == 70


def test_scoring_weights_sum_to_one():
    assert abs(sum(SCORE_WEIGHTS.values()) - 1.0) < 1e-9


def test_weighted_overall_clamped():
    overall = weighted_overall(
        [
            CategorySignal(ScoreCategoryId.atsCompatibility, 100, "a"),
            CategorySignal(ScoreCategoryId.contentImpact, 0, "b"),
            CategorySignal(ScoreCategoryId.experiencePresentation, 50, "c"),
            CategorySignal(ScoreCategoryId.skillsRelevance, 50, "d"),
            CategorySignal(ScoreCategoryId.structureReadability, 50, "e"),
            CategorySignal(ScoreCategoryId.languageGrammar, 50, "f"),
            CategorySignal(ScoreCategoryId.basicsContact, 50, "g"),
        ]
    )
    assert 0 <= overall <= 100


def test_pipeline_with_mock_ai_no_paid_calls():
    import asyncio

    settings = Settings(ai_provider="mock", analysis_version="test-engine")
    data = _docx_bytes(_sample_cv_text())
    result = asyncio.run(
        analyze_resume_bytes(
            filename="aylin.docx",
            data=data,
            locale="en",
            career_stage="student",
            target_role="internship",
            settings=settings,
            ai_provider=MockAIProvider(),
        )
    )
    assert 0 <= result.analysis.overallScore <= 100
    assert result.parsed.sections
    assert result.analysis.engineVersion == "test-engine"
    weights = {c.id.value: c.weight for c in result.analysis.categories}
    assert weights["atsCompatibility"] == 0.25


def test_analyze_endpoint_multipart():
    data = _docx_bytes(_sample_cv_text())
    res = client.post(
        "/api/v1/resumes/analyze",
        files={
            "file": (
                "aylin.docx",
                data,
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            )
        },
        data={"locale": "en", "career_stage": "student"},
    )
    assert res.status_code == 200, res.text
    body = res.json()
    assert "analysis" in body and "parsed" in body
    assert body["analysis"]["overallScore"] is not None
    assert "overallScore" not in (body.get("ai") or {})


def test_reject_bad_extension():
    res = client.post(
        "/api/v1/resumes/analyze",
        files={"file": ("notes.txt", b"hello world " * 20, "text/plain")},
        data={"locale": "en"},
    )
    assert res.status_code == 400


def test_empty_pdf_like_bytes_warn_or_error():
    with pytest.raises(DocumentParseError):
        extract_text("empty.pdf", b"")
