"""Parser confidence. Same text always yields the same number.

Weights:
- extraction quality 25%
- section detection 30%
- contact detection 15%
- classified text ratio 20%
- date structure 10%
"""

from __future__ import annotations

CORE = ("summary", "experience", "education", "skills")


def parser_confidence(
    *,
    extraction_ok: bool,
    scanned: bool,
    detected_core: int,
    classified_ratio: float,
    has_email: bool,
    has_phone: bool,
    date_quality: float,
) -> int:
    extraction = 0.0 if scanned else (1.0 if extraction_ok else 0.2)
    sections = detected_core / len(CORE)
    contact = (0.7 if has_email else 0.0) + (0.3 if has_phone else 0.0)
    classified = max(0.0, min(1.0, classified_ratio))
    dates = max(0.0, min(1.0, date_quality))
    score = (
        extraction * 0.25
        + sections * 0.30
        + contact * 0.15
        + classified * 0.20
        + dates * 0.10
    )
    return round(score * 100)


def confidence_band(score: int) -> str:
    if score >= 85:
        return "high"
    if score >= 60:
        return "medium"
    return "low"
