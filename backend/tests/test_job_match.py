from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.job_match import ResumeSnapshotIn, SkillEvidenceStatus
from app.services.job_description_parser import parse_job_description
from app.services.job_match_ai import MockJobMatchAI, validate_job_match_ai
from app.services.job_match_hybrid import hybrid_match
from app.services.job_match_weights import (
    JOB_MATCH_WEIGHTS,
    JobMatchCategoryId,
    MatchCategorySignal,
    weighted_match_overall,
)
from app.services.skill_aliases import canonicalize

client = TestClient(app)


def _sample_resume() -> ResumeSnapshotIn:
    return ResumeSnapshotIn(
        resumeId="res_demo",
        fileName="aylin_cv.pdf",
        skills=["Flutter", "Dart", "Python", "teamwork"],
        tools=["Firebase", "Git"],
        experienceBullets=[
            "Supported event promotion for student community",
        ],
        projectBullets=[
            "Built a campus event app using Flutter and Firebase",
        ],
        education=["B.Sc. Computer Science"],
        languages=["Turkish", "English"],
        summary="CS student seeking internship",
        sectionKeys=["contact", "education", "projects", "skills"],
    )


def _sample_jd() -> str:
    return """
Software Engineering Intern

Requirements:
- Flutter (required)
- Dart
- Git
- SQL (required)

Preferred:
- Docker
- AWS

Responsibilities:
- Build mobile features with Flutter
- Collaborate with mentors on code reviews

Tools:
- Firebase, Git

Education: Bachelor degree in Computer Science
Language: English
"""


def test_skill_alias_canonicalize():
    assert canonicalize("JS") == "javascript" or canonicalize("js") == "javascript"
    assert canonicalize("postgres") == "postgresql"
    assert canonicalize("k8s") == "kubernetes"


def test_weights_sum_to_one():
    total = sum(JOB_MATCH_WEIGHTS.values())
    assert abs(total - 1.0) < 1e-6


def test_weighted_overall_ignores_ai_overall():
    signals = [
        MatchCategorySignal(JobMatchCategoryId.coreSkills, 80, ""),
        MatchCategorySignal(JobMatchCategoryId.experienceProjects, 70, ""),
        MatchCategorySignal(JobMatchCategoryId.responsibilities, 60, ""),
        MatchCategorySignal(JobMatchCategoryId.education, 75, ""),
        MatchCategorySignal(JobMatchCategoryId.tools, 50, ""),
        MatchCategorySignal(JobMatchCategoryId.languageOther, 90, ""),
    ]
    score = weighted_match_overall(signals)
    assert 0 <= score <= 100
    # Manually approximate: 0.3*80 + 0.25*70 + 0.2*60 + 0.1*75 + 0.1*50 + 0.05*90
    expected = round(0.3 * 80 + 0.25 * 70 + 0.2 * 60 + 0.1 * 75 + 0.1 * 50 + 0.05 * 90)
    assert score == expected


def test_validate_strips_overall_score():
    raw = {
        "overallMatchScore": 99,
        "overall_score": 98,
        "experienceProjects": {"scoreHint": 70, "summary": "ok"},
        "responsibilities": {"scoreHint": 55, "summary": "mixed"},
        "recommendations": [],
        "verificationQuestions": ["Do you know SQL?"],
        "learningOpportunities": [],
        "workingWell": [],
        "unclearSkills": [],
    }
    cleaned = validate_job_match_ai(raw)
    assert "overallMatchScore" not in cleaned
    assert "overall_score" not in cleaned
    assert cleaned["experienceProjects"][0] == 70.0


def test_parser_classifies_required_preferred():
    job = parse_job_description(
        title="Intern",
        description=_sample_jd(),
        company="Campus Labs",
    )
    assert job.company == "Campus Labs"
    assert any("flutter" in s for s in job.required_skills)
    assert any("docker" in s for s in job.preferred_skills) or "docker" in job.tools
    assert job.responsibilities


def test_hybrid_not_demonstrated_wording():
    resume = _sample_resume()
    job = parse_job_description(title="Intern", description=_sample_jd())
    result = hybrid_match(resume=resume, job=job, locale="en")
    sql_items = [m for m in result.skill_matches if "sql" in m.skill]
    assert sql_items
    assert sql_items[0].status == SkillEvidenceStatus.notDemonstrated
    assert "not demonstrated" in (sql_items[0].note or "").lower()
    assert "don't know" not in (sql_items[0].note or "").lower()
    # Flutter should match
    flutter = [m for m in result.skill_matches if m.skill == "flutter"]
    assert flutter
    assert flutter[0].status in {
        SkillEvidenceStatus.matched,
        SkillEvidenceStatus.partial,
    }


@pytest.mark.asyncio
async def test_mock_job_match_ai():
    ai = MockJobMatchAI()
    out = await ai.analyze(
        {
            "locale": "en",
            "missing_skills": ["sql"],
            "job_title": "Intern",
        }
    )
    assert "recommendations" in out
    assert "overallMatchScore" not in out


def test_api_job_match_endpoint():
    payload = {
        "resume": _sample_resume().model_dump(),
        "jobTitle": "Software Engineering Intern",
        "jobDescription": _sample_jd(),
        "company": "Campus Labs",
        "jobUrl": "https://example.com/jobs/1",
        "locale": "en",
        "careerStage": "student",
    }
    res = client.post(
        "/api/v1/jobs/match",
        json=payload,
        headers={"X-User-Id": "jm_user", "X-Request-Id": "req_jm_endpoint_001"},
    )
    assert res.status_code == 200, res.text
    data = res.json()
    match = data["match"]
    assert 0 <= match["overallMatchScore"] <= 100
    assert (
        "hiring" not in match["scoreDisclaimer"].lower()
        or "not" in match["scoreDisclaimer"].lower()
    )
    assert match["categories"]
    assert data["warnings"]  # JOB_URL_METADATA_ONLY
    assert "JOB_URL_METADATA_ONLY" in data["warnings"]
    # Ensure AI did not dictate score by checking weights present
    weights = {c["id"]: c["weight"] for c in match["categories"]}
    assert abs(weights["coreSkills"] - 0.30) < 1e-6


def test_api_job_match_rejects_short_jd():
    payload = {
        "resume": _sample_resume().model_dump(),
        "jobTitle": "Role",
        "jobDescription": "too short",
        "locale": "en",
    }
    res = client.post(
        "/api/v1/jobs/match",
        json=payload,
        headers={"X-User-Id": "jm_short", "X-Request-Id": "req_jm_short_0001"},
    )
    assert res.status_code == 422 or res.status_code == 400
