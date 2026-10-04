"""Deterministic CV line suggestions. Never adds facts; asks the user when a fact is missing."""

from __future__ import annotations

import hashlib
import re

SUGGESTIONS_VERSION = "suggestions-1.0.0"

TARGET_SECTIONS = {"experience", "projects", "volunteer"}
MAX_SUGGESTIONS = 12
MAX_METRIC_QUESTIONS = 4
LONG_LINE_WORDS = 32

_BULLET = re.compile(r"^\s*(?:[-•*▪●◦–—]|\d+[.)])\s*")
_YEAR = re.compile(r"\b(?:19|20)\d{2}\b")
_DIGIT = re.compile(r"\d")
_WEAK_EN = re.compile(
    r"^(?:responsible for|worked on|helped(?: with)?|assisted(?: with| in)?|involved in|"
    r"duties included|tasks included|participated in|in charge of)\b",
    re.IGNORECASE,
)
_WEAK_TR = re.compile(
    r"(?:sorumlu(?:ydum|yum)?|görev aldım|yardımcı oldum|destek oldum|katıldım|ilgilendim)\b",
    re.IGNORECASE,
)
_FIRST_PERSON = re.compile(r"^(?:I|My)\s+", re.IGNORECASE)
_FILLERS = (
    (re.compile(r"\bin order to\b", re.IGNORECASE), "to"),
    (re.compile(r"\butilized\b", re.IGNORECASE), "used"),
    (re.compile(r"\butilize\b", re.IGNORECASE), "use"),
    (re.compile(r"\bdue to the fact that\b", re.IGNORECASE), "because"),
)


def _strip_marker(line: str) -> str:
    return _BULLET.sub("", line).strip()


def clean_line(text: str) -> str:
    """Language-safe cleanup: spacing, first-person opener, filler phrases, capitalisation."""
    value = re.sub(r"\s+", " ", text).strip()
    value = _FIRST_PERSON.sub("", value)
    for pattern, replacement in _FILLERS:
        value = pattern.sub(replacement, value)
    value = re.sub(r"\s+([,.;:])", r"\1", value)
    if value and value[0].islower():
        value = value[0].upper() + value[1:]
    return value


def _candidate(line: str) -> bool:
    words = line.split()
    if len(line) < 20 or len(words) < 4:
        return False
    return not (_YEAR.search(line) or line.endswith(":"))


def _id(section_id: str, text: str) -> str:
    return hashlib.sha1(f"{section_id}:{text}".encode()).hexdigest()[:12]


def _classify(line: str, metric_budget: int) -> tuple[str, str] | None:
    if _WEAK_EN.search(line) or _WEAK_TR.search(line):
        return "weakOpening", "high"
    if _FIRST_PERSON.search(line):
        return "firstPerson", "medium"
    if len(line.split()) > LONG_LINE_WORDS:
        return "tooLong", "medium"
    if not _DIGIT.search(line) and metric_budget > 0:
        return "noMetric", "medium"
    if clean_line(line) != line:
        return "formatting", "low"
    return None


def build_suggestions(sections: list[dict]) -> list[dict]:
    suggestions: list[dict] = []
    seen: set[str] = set()
    metric_budget = MAX_METRIC_QUESTIONS
    for section in sections:
        key = section.get("key") or ""
        if key not in TARGET_SECTIONS or section.get("status") == "missing":
            continue
        section_id = str(section.get("id") or key)
        for raw in str(section.get("body") or "").splitlines():
            line = _strip_marker(raw)
            if not _candidate(line) or line in seen:
                continue
            classified = _classify(line, metric_budget)
            if classified is None:
                continue
            kind, impact = classified
            if kind == "noMetric":
                metric_budget -= 1
            cleaned = clean_line(line)
            seen.add(line)
            suggestions.append(
                {
                    "id": _id(section_id, line),
                    "sectionId": section_id,
                    "sectionKey": key,
                    "originalText": line,
                    "suggestedText": cleaned if cleaned != line else None,
                    "kind": kind,
                    "impact": impact,
                    "needsUserFact": kind in {"weakOpening", "noMetric"},
                    "source": "rules",
                }
            )
    order = {"high": 0, "medium": 1, "low": 2}
    suggestions.sort(key=lambda item: order[item["impact"]])
    return suggestions[:MAX_SUGGESTIONS]
