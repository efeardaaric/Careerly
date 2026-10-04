"""Deterministic CV pipeline. Fixtures are fictional."""

from __future__ import annotations

import io

import fitz
from docx import Document
from fastapi.testclient import TestClient

from app.cv.dates import parse_date_token
from app.cv.parser import extract_contact, parse_cv
from app.cv.sections import detect_sections, match_heading
from app.main import app
from app.scoring.weights import overall_score
from app.services.plan_limits import FeatureId
from app.services.usage_tracker import get_used

client = TestClient(app)

ADA = """
Ada Yilmaz
ada.yilmaz@example.com
+90 555 010 2030

Summary
Computer science student building small tools.

Experience
Software Intern | Example Labs | Sep 2024 - Present
- Built a campus event list used by 40 students
- Developed a Python export script

Projects
Study Planner
- Designed a study planner for course deadlines

Education
B.Sc. Computer Science | Example University | 2022 - 2026

Skills
Flutter, Dart, Python, SQL
"""

DENIZ = """
Deniz Kaya
deniz.kaya@example.com

Ozet
Bilgisayar muhendisligi ogrencisi.

Is Deneyimi
Stajyer | Ornek Sirket | Eyl 2024 - Halen
- Gelistirdim kucuk bir kayit formu

Egitim
Lisans | Ornek Universite | 2022 - 2026

Yetenekler
Python, SQL
"""


def _pdf(text: str) -> bytes:
    document = fitz.open()
    page = document.new_page()
    page.insert_textbox(fitz.Rect(48, 48, 560, 800), text, fontsize=11)
    buffer = io.BytesIO()
    document.save(buffer)
    document.close()
    return buffer.getvalue()


def _docx(text: str) -> bytes:
    document = Document()
    for line in text.strip().splitlines():
        document.add_paragraph(line)
    buffer = io.BytesIO()
    document.save(buffer)
    return buffer.getvalue()


def test_health_names_the_service():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["service"] == "careerly-api"


def test_overall_score_example_is_78():
    score = overall_score(
        {
            "atsCompatibility": 84,
            "contentImpact": 72,
            "experiencePresentation": 68,
            "skillsRelevance": 76,
            "structureReadability": 80,
            "languageGrammar": 82,
            "basicsContact": 90,
        }
    )
    assert score == 78


def test_same_cv_scores_the_same():
    first = parse_cv(ADA)
    second = parse_cv(ADA)
    assert first.parser_confidence == second.parser_confidence
    from app.scoring.engine import score_structured

    left = score_structured(first.to_dict(), career_stage="student")
    right = score_structured(second.to_dict(), career_stage="student")
    assert left["overallScore"] == right["overallScore"]
    assert left["scores"] == right["scores"]


def test_parser_confidence_is_deterministic():
    from app.cv.confidence import parser_confidence as confidence

    kwargs = {
        "extraction_ok": True,
        "scanned": False,
        "detected_core": 4,
        "classified_ratio": 0.8,
        "has_email": True,
        "has_phone": True,
        "date_quality": 1,
    }
    assert confidence(**kwargs) == confidence(**kwargs)
    assert 0 <= confidence(**kwargs) <= 100


def test_english_and_turkish_headings():
    assert match_heading("Work Experience") == "experience"
    assert match_heading("İş Deneyimi") == "experience"
    assert match_heading("Eğitim") == "education"
    assert match_heading("Yetenekler") == "skills"
    assert match_heading("This is a normal sentence about my work.") is None
    _, sections = detect_sections(ADA)
    assert "experience" in {section.type for section in sections}
    _, turkish = detect_sections(DENIZ)
    kinds = {section.type for section in turkish}
    assert "experience" in kinds
    assert "education" in kinds


def test_contact_and_dates():
    contact = extract_contact(ADA)
    assert contact["email"] == "ada.yilmaz@example.com"
    assert contact["phone"]
    assert parse_date_token("Sep 2024")["month"] == 9
    assert parse_date_token("Eylül 2024")["month"] == 9
    assert parse_date_token("09/2024")["year"] == 2024
    assert parse_date_token("2024-09")["month"] == 9
    assert parse_date_token("Halen")["precision"] == "present"
    assert parse_date_token("Present")["precision"] == "present"


def test_parse_docx_then_analyze_is_stable():
    response = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("Ada Yilmaz CV.docx", _docx(ADA), "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
        data={"career_stage": "student", "target_fields": "software"},
        headers={"X-User-Id": "ada-test"},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert "Aylin" not in response.text
    assert body["evidence"]["email"] == "ada.yilmaz@example.com"
    assert body["evidence"]["rawText"] == ""
    cv_id = body["resumeId"]
    patched = client.patch(
        f"/api/v1/cvs/{cv_id}/parsed",
        json={"sections": body["evidence"]["sections"]},
        headers={"X-User-Id": "ada-test"},
    )
    assert patched.status_code == 200
    first = client.post(f"/api/v1/cvs/{cv_id}/analyze", headers={"X-User-Id": "ada-test"})
    assert first.status_code == 200, first.text
    analysis = first.json()
    assert analysis["engineVersion"] == "1.0.0"
    assert isinstance(analysis["overallScore"], int)
    keys = {item["id"] for item in analysis["categories"]}
    assert "atsCompatibility" in keys
    again = client.get(f"/api/v1/cvs/{cv_id}/analysis", headers={"X-User-Id": "ada-test"})
    assert again.json()["overallScore"] == analysis["overallScore"]
    stored = client.get(f"/api/v1/cvs/{cv_id}", headers={"X-User-Id": "ada-test"})
    assert stored.status_code == 200
    assert stored.json()["resumeId"] == cv_id


def test_pdf_upload_extracts_text():
    response = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("Deniz Kaya.pdf", _pdf(ADA), "application/pdf")},
        headers={"X-User-Id": "deniz-test"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["evidence"]["email"] == "ada.yilmaz@example.com"


def test_rejects_large_and_unsupported_files():
    big = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("big.pdf", b"x" * (10 * 1024 * 1024 + 1), "application/pdf")},
        headers={"X-User-Id": "ada-test"},
    )
    assert big.status_code == 413
    assert big.json()["error"]["code"] == "CV_TOO_LARGE"
    notes = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("notes.txt", b"hello", "text/plain")},
        headers={"X-User-Id": "ada-test"},
    )
    assert notes.status_code == 415
    assert notes.json()["error"]["code"] == "UNSUPPORTED_CV_TYPE"
    legacy = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("old.doc", b"not-a-doc", "application/msword")},
        headers={"X-User-Id": "ada-test"},
    )
    assert legacy.status_code == 415


def test_scanned_corrupt_and_invalid_docx():
    blank = fitz.open()
    blank.new_page()
    buffer = io.BytesIO()
    blank.save(buffer)
    blank.close()
    scanned = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("scan.pdf", buffer.getvalue(), "application/pdf")},
        headers={"X-User-Id": "ada-test"},
    )
    assert scanned.status_code == 422
    assert scanned.json()["error"]["code"] == "SCANNED_DOCUMENT_DETECTED"
    corrupt = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("bad.pdf", b"%PDF-1.4 not a real pdf", "application/pdf")},
        headers={"X-User-Id": "ada-test"},
    )
    assert corrupt.status_code == 422
    assert corrupt.json()["error"]["code"] == "CV_EXTRACTION_FAILED"
    invalid = client.post(
        "/api/v1/cvs/parse",
        files={
            "file": (
                "bad.docx",
                b"not a docx",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            )
        },
        headers={"X-User-Id": "ada-test"},
    )
    assert invalid.status_code == 422


def test_rewrite_is_disabled_without_ai():
    parsed = parse_cv(ADA)
    assert parsed.parser_confidence == parse_cv(ADA).parser_confidence
    response = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("Alex Morgan.docx", _docx(ADA), "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
        headers={"X-User-Id": "alex-test"},
    )
    cv_id = response.json()["resumeId"]
    rewrite = client.post(
        f"/api/v1/cvs/{cv_id}/rewrite",
        json={"text": "Built a campus event list used by 40 students", "rewrite_goal": "clarity"},
        headers={"X-User-Id": "alex-test"},
    )
    assert rewrite.status_code == 503
    assert rewrite.json()["error"]["code"] == "AI_DISABLED"

    suggestions = client.post(f"/api/v1/cvs/{cv_id}/suggestions", headers={"X-User-Id": "alex-test"})
    assert suggestions.status_code == 200
    body = suggestions.json()
    assert body["aiAvailable"] is False
    for item in body["suggestions"]:
        assert item["source"] == "rules"
        assert item["impact"] in {"high", "medium", "low"}

    other = client.post(f"/api/v1/cvs/{cv_id}/suggestions", headers={"X-User-Id": "someone-else"})
    assert other.status_code == 404


def _stored_cv(user_id):
    response = client.post(
        "/api/v1/cvs/parse",
        files={"file": ("test.docx", _docx(ADA),
                         "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
        headers={"X-User-Id": user_id},
    )
    assert response.status_code == 200
    return response.json()["resumeId"]


def test_new_cv_api_enforces_analysis_cap_and_keeps_read_access():
    user_id = "new-api-limit-user"
    cv_id = _stored_cv(user_id)
    headers = {"X-User-Id": user_id, "X-Request-Id": "reused-client-request"}
    for _ in range(2):
        assert client.post(f"/api/v1/cvs/{cv_id}/analyze", headers=headers).status_code == 200
    assert client.post(f"/api/v1/cvs/{cv_id}/reanalyze", headers=headers).status_code == 403
    assert get_used(user_id, FeatureId.cvAnalysis) == 2
    assert client.get(f"/api/v1/cvs/{cv_id}/analysis", headers=headers).status_code == 200


def test_failed_cv_scoring_does_not_charge(monkeypatch):
    user_id = "failed-score-user"
    cv_id = _stored_cv(user_id)

    def fail_scoring(*args, **kwargs):
        raise RuntimeError("test scoring failure")

    monkeypatch.setattr("app.api.routes.cvs.analyze_document", fail_scoring)
    response = client.post(f"/api/v1/cvs/{cv_id}/analyze", headers={"X-User-Id": user_id})
    assert response.status_code == 500
    assert get_used(user_id, FeatureId.cvAnalysis) == 0


def test_cv_rewrite_cap_and_targeted_pro_gate(monkeypatch):
    from app.core.config import Settings, get_settings

    user_id = "rewrite-limit-user"
    cv_id = _stored_cv(user_id)
    monkeypatch.setitem(app.dependency_overrides, get_settings, lambda: Settings(ai_enabled=True))

    class FakeAI:
        def rewrite(self, text, goal):
            return {"suggestion": text}

    monkeypatch.setattr("app.api.routes.cvs.build_ai_service", lambda settings: FakeAI())
    headers = {"X-User-Id": user_id}
    targeted = client.post(
        f"/api/v1/cvs/{cv_id}/rewrite", headers=headers,
        json={"text": "Built a tool", "mode": "job_targeted"},
    )
    assert targeted.status_code == 403
    assert get_used(user_id, FeatureId.aiRewrite) == 0
    for _ in range(3):
        response = client.post(
            f"/api/v1/cvs/{cv_id}/rewrite", headers=headers, json={"text": "Built a tool"},
        )
        assert response.status_code == 200
    assert client.post(
        f"/api/v1/cvs/{cv_id}/rewrite", headers=headers, json={"text": "Built a tool"},
    ).status_code == 403


def test_disabled_rewrite_does_not_charge():
    user_id = "disabled-rewrite-user"
    cv_id = _stored_cv(user_id)
    response = client.post(
        f"/api/v1/cvs/{cv_id}/rewrite", headers={"X-User-Id": user_id},
        json={"text": "Built a tool"},
    )
    assert response.status_code == 503
    assert get_used(user_id, FeatureId.aiRewrite) == 0
