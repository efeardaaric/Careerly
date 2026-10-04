"""Deterministic Careerly score. Identical input and engine version => identical score."""

from __future__ import annotations

from app.scoring.ats import score_ats
from app.scoring.basics import score_basics
from app.scoring.content import score_content
from app.scoring.experience import score_experience
from app.scoring.language import score_language
from app.scoring.skills import score_skills
from app.scoring.structure import score_structure
from app.scoring.types import CategoryResult, FindingDraft
from app.scoring.weights import WEIGHTS, overall_score

ENGINE_VERSION = "1.0.0"
_SEVERITY_RANK = {"critical": 0, "improve": 1, "good": 2}


def is_early_career(stage: str | None) -> bool:
    if not stage:
        return True
    token = "".join(ch for ch in stage.lower() if ch.isalpha())
    return token in {"student", "intern", "newgraduate", "careerchanger"}


def score_structured(
    structured: dict,
    *,
    career_stage: str | None = None,
    target_fields: list[str] | None = None,
) -> dict:
    early = is_early_career(career_stage)
    categories: list[CategoryResult] = [
        score_ats(structured),
        score_content(structured, early_career=early),
        score_experience(structured, early_career=early),
        score_skills(structured, target_fields),
        score_structure(structured),
        score_language(structured),
        score_basics(structured, target_fields),
    ]
    scores = {category.key: category.score for category in categories}
    findings: list[FindingDraft] = []
    strengths: list[str] = []
    for category in categories:
        findings.extend(category.findings)
        for item in category.rules:
            if item.passed and item.max_contribution >= 15 and item.evidence:
                strengths.append(item.evidence)
    findings.sort(key=lambda item: _SEVERITY_RANK.get(item.severity, 9))
    return {
        "engineVersion": ENGINE_VERSION,
        "overallScore": overall_score(scores),
        "categories": categories,
        "scores": scores,
        "findings": findings[:12],
        "strengths": strengths[:6],
        "weights": WEIGHTS,
    }
