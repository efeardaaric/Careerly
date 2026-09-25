from __future__ import annotations

import asyncio

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.builder_ai import MockBuilderAI, validate_rewrite_suggestion
from app.services.builder_document_text import resume_document_to_plain_text

client = TestClient(app)


def _sample_document() -> dict:
    return {
        "id": "doc_demo",
        "title": "Aylin Demir CV",
        "language": "en",
        "templateId": "classicAts",
        "personal": {
            "fullName": "Aylin Demir",
            "email": "aylin.demir@email.com",
            "phone": "",
            "location": "Istanbul",
            "linkedin": "",
            "website": "",
        },
        "summary": "Computer Science student seeking internship opportunities in software.",
        "education": [
            {
                "id": "e1",
                "school": "University",
                "degree": "B.Sc. Computer Science",
                "field": "",
                "startDate": "",
                "endDate": "2027",
                "details": "",
            }
        ],
        "experience": [
            {
                "id": "x1",
                "organization": "Campus Club",
                "title": "Marketing Intern",
                "location": "",
                "startDate": "2025",
                "endDate": "",
                "bullets": ["Supported event promotion for student community"],
            }
        ],
        "projects": [
            {
                "id": "p1",
                "name": "Campus Event App",
                "url": "",
                "bullets": ["Built a campus event app using Flutter and Firebase"],
                "tech": ["Flutter", "Firebase"],
            }
        ],
        "skillGroups": [
            {"id": "s1", "label": "Technical", "skills": ["Flutter", "Dart", "Python"]}
        ],
        "languages": [{"id": "l1", "name": "Turkish", "level": "Native"}],
        "certifications": [],
        "awards": [],
        "customSections": [],
        "sectionOrder": [
            "personal",
            "summary",
            "education",
            "experience",
            "projects",
            "skills",
            "languages",
            "certifications",
            "awards",
        ],
        "sectionVisibility": {
            "personal": True,
            "summary": True,
            "education": True,
            "experience": True,
            "projects": True,
            "skills": True,
            "languages": True,
            "certifications": True,
            "awards": True,
        },
        "createdAt": "2026-01-01T00:00:00Z",
        "updatedAt": "2026-01-01T00:00:00Z",
    }


def test_mock_rewrite_asks_for_metric_not_invent():
    ai = MockBuilderAI()
    out = asyncio.run(
        ai.rewrite(
            mode="improve",
            text="Built a campus event app using Flutter and Firebase",
            locale="en",
        )
    )
    assert out["needsUserFact"] is True
    assert out["suggested"] == "Built a campus event app using Flutter and Firebase"
    assert "invent" in out["why"].lower() or "number" in out["why"].lower()


def test_validate_strips_invented_digits():
    out = validate_rewrite_suggestion(
        original="Built a campus app",
        raw={
            "suggested": "Built a campus app used by 500 students",
            "why": "added impact",
            "needsUserFact": False,
        },
        locale="en",
    )
    assert out["needsUserFact"] is True
    assert "500" not in out["suggested"]


def test_plain_text_preserves_content():
    text = resume_document_to_plain_text(_sample_document())
    assert "Aylin Demir" in text
    assert "Flutter" in text
    assert "Campus Event App" in text


def test_rewrite_endpoint_mock():
    res = client.post(
        "/api/v1/builder/rewrite",
        json={
            "mode": "improve",
            "text": "Supported event promotion for student community",
            "locale": "en",
        },
        headers={"X-User-Id": "builder_test_user", "X-Request-Id": "req_builder_rw_001"},
    )
    assert res.status_code == 200
    body = res.json()["suggestion"]
    assert body["original"]
    assert "needsUserFact" in body


def test_check_endpoint_reuses_scoring():
    res = client.post(
        "/api/v1/builder/check",
        json={"document": _sample_document(), "locale": "en"},
        headers={"X-User-Id": "builder_check_user", "X-Request-Id": "req_builder_ck_001"},
    )
    assert res.status_code == 200
    data = res.json()
    assert "analysis" in data
    assert "overallScore" in data["analysis"]
    assert "Aylin Demir" in data["plainText"]


def test_translate_requires_pro_or_passes_with_verify():
    from app.services.subscription_verification import reset_subscriptions_for_tests
    from app.services.usage_tracker import reset_usage_store_for_tests

    reset_subscriptions_for_tests()
    reset_usage_store_for_tests()

    # Free tier: translation gated (free_limit=0)
    denied = client.post(
        "/api/v1/builder/translate",
        json={"targetLanguage": "tr", "document": _sample_document()},
        headers={"X-User-Id": "builder_free_tr", "X-Request-Id": "req_builder_tr_deny"},
    )
    assert denied.status_code == 403

    verified = client.post(
        "/api/v1/billing/subscriptions/verify",
        headers={"X-User-Id": "builder_pro_tr"},
        json={
            "userId": "builder_pro_tr",
            "platform": "android",
            "productId": "careerly_pro_monthly",
            "purchaseToken": "mock_pro_token",
        },
    )
    assert verified.status_code == 200, verified.text
    assert verified.json()["tier"] == "pro"

    ok = client.post(
        "/api/v1/builder/translate",
        json={"targetLanguage": "tr", "document": _sample_document()},
        headers={"X-User-Id": "builder_pro_tr", "X-Request-Id": "req_builder_tr_ok1"},
    )
    assert ok.status_code == 200, ok.text
    doc = ok.json()["document"]
    assert doc["language"] == "tr"
    assert doc["personal"]["fullName"] == "Aylin Demir"  # proper noun preserved
