"""Category weights. Overall is the weighted sum, then rounded.

Unknown and not_applicable rules are excluded from a category's denominator.
They are never treated as a pass.
"""

WEIGHTS = {
    "atsCompatibility": 0.20,
    "contentImpact": 0.20,
    "experiencePresentation": 0.15,
    "skillsRelevance": 0.15,
    "structureReadability": 0.10,
    "languageGrammar": 0.10,
    "basicsContact": 0.10,
}


def category_score(earned: float, possible: float) -> int:
    if possible <= 0:
        return 0
    return round(earned / possible * 100)


def overall_score(scores: dict[str, int]) -> int:
    total = sum(scores[key] * WEIGHTS[key] for key in WEIGHTS)
    return round(total)
