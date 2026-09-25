"""Schema validation/normalization of AI content signals."""

from __future__ import annotations

from typing import Any

from app.schemas.analysis import FindingSeverity, ScoreCategoryId
from app.services.scoring_weights import clamp_score

ALLOWED_CATEGORIES = {c.value for c in ScoreCategoryId}
ALLOWED_SEVERITIES = {s.value for s in FindingSeverity}


def validate_ai_payload(raw: dict[str, Any]) -> dict[str, Any]:
    """Ensure AI output is structured and does not include overallScore."""
    if "overallScore" in raw or "overall_score" in raw:
        raw = {k: v for k, v in raw.items() if k not in {"overallScore", "overall_score"}}

    cleaned_findings: list[dict[str, Any]] = []
    for item in raw.get("findings") or []:
        if not isinstance(item, dict):
            continue
        category = item.get("categoryId") or item.get("category_id")
        severity = item.get("severity", "improve")
        if category not in ALLOWED_CATEGORIES:
            continue
        if severity not in ALLOWED_SEVERITIES:
            severity = "improve"
        cleaned_findings.append(
            {
                "id": str(item.get("id") or f"ai_{len(cleaned_findings)}"),
                "severity": severity,
                "title": str(item.get("title") or "Improvement opportunity")[:160],
                "whyItMatters": str(item.get("whyItMatters") or item.get("why") or "")[:500],
                "evidence": str(item.get("evidence") or "")[:400],
                "recommendedAction": str(item.get("recommendedAction") or item.get("action") or "")[
                    :500
                ],
                "categoryId": category,
                "beforeText": item.get("beforeText"),
                "afterText": item.get("afterText"),
                "supportsAiImprove": bool(item.get("supportsAiImprove", False)),
            }
        )

    def _hint(block_name: str, default: float) -> tuple[float, str]:
        block = raw.get(block_name) or {}
        if not isinstance(block, dict):
            return default, ""
        hint = block.get("scoreHint", block.get("score", default))
        try:
            score = float(hint)
        except (TypeError, ValueError):
            score = default
        summary = str(block.get("summary") or "")[:240]
        return float(clamp_score(score)), summary

    working = [str(x) for x in (raw.get("workingWell") or []) if str(x).strip()][:6]

    return {
        "contentImpact": _hint("contentImpact", 70),
        "experiencePresentation": _hint("experiencePresentation", 68),
        "skillsRelevance": _hint("skillsRelevance", 74),
        "structureReadability": _hint("structureReadability", 78),
        "languageGrammar": _hint("languageGrammar", 80),
        "findings": cleaned_findings,
        "workingWell": working,
    }
