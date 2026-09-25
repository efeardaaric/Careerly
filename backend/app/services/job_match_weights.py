"""Job Match scoring weights — AI must NOT produce final match score."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class JobMatchCategoryId(str, Enum):
    coreSkills = "coreSkills"
    experienceProjects = "experienceProjects"
    responsibilities = "responsibilities"
    education = "education"
    tools = "tools"
    languageOther = "languageOther"


JOB_MATCH_WEIGHTS: dict[JobMatchCategoryId, float] = {
    JobMatchCategoryId.coreSkills: 0.30,
    JobMatchCategoryId.experienceProjects: 0.25,
    JobMatchCategoryId.responsibilities: 0.20,
    JobMatchCategoryId.education: 0.10,
    JobMatchCategoryId.tools: 0.10,
    JobMatchCategoryId.languageOther: 0.05,
}


def clamp_score(value: float) -> int:
    return int(max(0, min(100, round(value))))


@dataclass(frozen=True)
class MatchCategorySignal:
    category_id: JobMatchCategoryId
    score: float
    summary: str


def weighted_match_overall(signals: list[MatchCategorySignal]) -> int:
    by_id = {s.category_id: s for s in signals}
    total = 0.0
    weight_sum = 0.0
    for cat_id, weight in JOB_MATCH_WEIGHTS.items():
        signal = by_id.get(cat_id)
        if signal is None:
            continue
        total += signal.score * weight
        weight_sum += weight
    if weight_sum <= 0:
        return 0
    return clamp_score(total / weight_sum)
