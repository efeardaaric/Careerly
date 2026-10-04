"""AutoFix guardrails and deterministic suggestions. Fixtures are fictional."""

from __future__ import annotations

from app.ai.service import AIService
from app.optimization.guardrails import facts_added, validate_rewrite
from app.optimization.suggestions import build_suggestions, clean_line


def _section(body: str, key: str = "experience") -> dict:
    return {"id": f"s-{key}", "key": key, "title": key.title(), "body": body, "status": "detected"}


def test_weak_opening_is_flagged_and_asks_for_facts():
    out = build_suggestions([_section("- Responsible for social media accounts of the club")])
    assert out[0]["kind"] == "weakOpening"
    assert out[0]["impact"] == "high"
    assert out[0]["needsUserFact"] is True
    assert out[0]["suggestedText"] is None


def test_first_person_is_cleaned_without_new_facts():
    out = build_suggestions([_section("- I developed a Flutter app for 40 students")])
    assert out[0]["kind"] == "firstPerson"
    assert out[0]["suggestedText"] == "Developed a Flutter app for 40 students"
    assert facts_added(out[0]["originalText"], out[0]["suggestedText"]) == []


def test_lines_with_dates_and_skills_sections_are_ignored():
    out = build_suggestions(
        [
            _section("Software Intern | Example Labs | Sep 2024 - Present"),
            _section("Flutter, Dart, Python, SQL and many more tools", key="skills"),
        ]
    )
    assert out == []


def test_metric_questions_are_capped():
    body = "\n".join(f"- Prepared weekly report number {chr(65 + i)} for the team" for i in range(8))
    out = build_suggestions([_section(body)])
    assert sum(1 for item in out if item["kind"] == "noMetric") == 4


def test_suggestion_ids_are_stable():
    section = _section("- Worked on the onboarding flow for new members")
    assert build_suggestions([section])[0]["id"] == build_suggestions([section])[0]["id"]


def test_clean_line_replaces_fillers_only():
    assert clean_line("utilized Excel in order to track tasks") == "Used Excel to track tasks"


def test_facts_added_detects_new_numbers_and_tools():
    added = facts_added("Managed social media", "Managed social media, increasing engagement by 40% with Hootsuite")
    assert "40%" in added
    assert "Hootsuite" in added


def test_facts_from_cv_context_are_allowed():
    added = facts_added(
        "Worked on reports with Power BI",
        "Built Power BI reports using SQL",
        context="Skills: SQL, Excel",
    )
    assert added == []


def test_validate_rejects_fabricated_metric():
    out = validate_rewrite(
        original="Managed social media",
        raw={"suggested": "Grew followers by 35%", "reason": "", "factsAdded": [], "confidence": 0.9},
        context="",
        mode="impact",
        prompt_version="t",
    )
    assert out["accepted"] is False
    assert out["suggested"] == "Managed social media"
    assert "35%" in out["factsAdded"]


def test_validate_rejects_declared_facts():
    out = validate_rewrite(
        original="Supported reporting",
        raw={"suggested": "Supported reporting", "factsAdded": ["revenue"], "confidence": 1},
        context="",
        mode="impact",
        prompt_version="t",
    )
    assert out["accepted"] is False


def test_validate_handles_malformed_payload():
    for raw in (None, "text", {"suggested": 3}, {"suggested": "   "}):
        out = validate_rewrite(original="x y z", raw=raw, context="", mode="grammar", prompt_version="t")
        assert out["accepted"] is False
        assert out["suggested"] == "x y z"


def test_validate_accepts_truthful_rewrite_and_clamps_confidence():
    out = validate_rewrite(
        original="Worked on reports with Power BI",
        raw={
            "suggested": "Built and maintained Power BI reports",
            "reason": "Clearer action",
            "factsAdded": [],
            "confidence": 4,
        },
        context="",
        mode="impact",
        prompt_version="t",
    )
    assert out["accepted"] is True
    assert out["confidence"] == 1.0


class _FakeProvider:
    def __init__(self, payload):
        self.payload = payload

    def generate_explanation(self, finding):
        return None

    def rewrite_bullet(self, text, goal):
        return None

    def rewrite_json(self, prompt):
        return self.payload


def test_service_structured_rewrite_keeps_original_on_fabrication():
    service = AIService(_FakeProvider({"suggested": "Led a team of 12", "factsAdded": []}))
    out = service.rewrite_structured("Helped the team", "impact")
    assert out["accepted"] is False
    assert out["suggestion"] == "Helped the team"
