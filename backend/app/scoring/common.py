"""Shared helpers for category scorers."""

from __future__ import annotations

import re

from app.scoring.types import CategoryResult, FindingDraft, RuleResult
from app.scoring.weights import category_score

_YEAR = re.compile(r"^(?:19|20)\d{2}$")
_MEASURABLE = re.compile(
    r"(\d+(?:[.,]\d+)?\s*%|[$€£₺]\s*\d|\d+\s*(?:users|customers|people|hours|days|weeks|ms|seconds|requests|kişi|müşteri|saat|gün|hafta))",
    re.IGNORECASE,
)
_NUMBER = re.compile(r"\d+(?:[.,]\d+)?")


def measurable(bullet: str) -> bool:
    if _MEASURABLE.search(bullet):
        return True
    for number in _NUMBER.findall(bullet):
        if not _YEAR.fullmatch(number):
            return True
    return False


def finish(key: str, title: str, rules: list[RuleResult], findings: list[FindingDraft], summary: str) -> CategoryResult:
    earned = 0.0
    possible = 0.0
    for rule in rules:
        if rule.status in {"unknown", "not_applicable"}:
            continue
        earned += rule.score_contribution
        possible += rule.max_contribution
    return CategoryResult(
        key=key,
        title=title,
        score=category_score(earned, possible),
        earned_points=earned,
        possible_points=possible,
        rules=rules,
        findings=findings,
        summary=summary,
    )


def rule(
    key: str,
    status: str,
    earned: float,
    maximum: float,
    evidence: str,
    message: str,
    confidence: float = 1.0,
) -> RuleResult:
    return RuleResult(
        key=key,
        passed=status == "passed",
        status=status,
        score_contribution=earned if status not in {"unknown", "not_applicable"} else 0,
        max_contribution=maximum,
        confidence=confidence,
        evidence=evidence,
        message=message,
    )


def active_sections(structured: dict) -> list[dict]:
    return [
        section
        for section in structured.get("sections") or []
        if section.get("status") not in {"missing"} and (section.get("body") or "").strip()
    ]


def section_body(structured: dict, key: str) -> str:
    return "\n".join(
        section.get("body", "")
        for section in active_sections(structured)
        if section.get("key") == key
    ).strip()


def bullets_from(structured: dict, keys: tuple[str, ...]) -> list[str]:
    found: list[str] = []
    for key in keys:
        for line in section_body(structured, key).split("\n"):
            cleaned = re.sub(r"^[-•*·]\s*", "", line).strip()
            if len(cleaned) >= 8:
                found.append(cleaned)
    for item in structured.get("experiences") or []:
        if "experience" in keys:
            found.extend(b for b in item.get("bullets") or [] if len(b) >= 8)
    for item in structured.get("projects") or []:
        if "projects" in keys:
            found.extend(b for b in item.get("bullets") or [] if len(b) >= 8)
    # Preserve order, drop duplicates.
    seen: set[str] = set()
    unique: list[str] = []
    for bullet in found:
        marker = bullet.lower()
        if marker not in seen:
            seen.add(marker)
            unique.append(bullet)
    return unique
