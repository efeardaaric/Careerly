"""Central scoring weights — Careerly readiness score (product §8).

LLM output must NEVER set overallScore. The scoring engine owns final numbers.
"""

from __future__ import annotations

from dataclasses import dataclass

from app.schemas.analysis import ScoreCategoryId

# Explicit weight table — keep in sync with product document.
SCORE_WEIGHTS: dict[ScoreCategoryId, float] = {
    ScoreCategoryId.atsCompatibility: 0.25,
    ScoreCategoryId.contentImpact: 0.20,
    ScoreCategoryId.experiencePresentation: 0.15,
    ScoreCategoryId.skillsRelevance: 0.15,
    ScoreCategoryId.structureReadability: 0.10,
    ScoreCategoryId.languageGrammar: 0.10,
    ScoreCategoryId.basicsContact: 0.05,
}


def clamp_score(value: float) -> int:
    return int(max(0, min(100, round(value))))


@dataclass(frozen=True)
class CategorySignal:
    category_id: ScoreCategoryId
    score: float
    summary: str


def weighted_overall(signals: list[CategorySignal]) -> int:
    if not signals:
        return 0
    by_id = {s.category_id: s for s in signals}
    total = 0.0
    weight_sum = 0.0
    for cat_id, weight in SCORE_WEIGHTS.items():
        signal = by_id.get(cat_id)
        if signal is None:
            continue
        total += signal.score * weight
        weight_sum += weight
    if weight_sum <= 0:
        return 0
    # Normalize if some categories missing.
    return clamp_score(total / weight_sum)
