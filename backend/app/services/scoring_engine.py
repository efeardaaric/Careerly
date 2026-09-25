"""Scoring engine — owns final category + overall scores."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from app.schemas.analysis import (
    AnalysisFindingOut,
    FindingSeverity,
    ResumeAnalysisOut,
    ScoreCategoryId,
    ScoreCategoryOut,
)
from app.services.ats_engine import AtsResult
from app.services.resume_normalizer import NormalizedResume
from app.services.scoring_weights import (
    SCORE_WEIGHTS,
    CategorySignal,
    clamp_score,
    weighted_overall,
)


def _basics_score(normalized: NormalizedResume) -> tuple[float, str]:
    score = 60.0
    bits: list[str] = []
    if normalized.has_email:
        score += 25
        bits.append("email detected")
    if normalized.has_phone:
        score += 10
        bits.append("phone detected")
    if normalized.word_count >= 180:
        score += 5
    summary = (
        "Contact basics look solid."
        if normalized.has_email
        else "Contact basics need a clearer email."
    )
    if bits:
        summary = f"{summary} ({', '.join(bits)})"
    return float(clamp_score(score)), summary


def build_resume_analysis(
    *,
    normalized: NormalizedResume,
    ats: AtsResult,
    ai: dict[str, Any],
    file_name: str,
    analysis_version: str,
) -> ResumeAnalysisOut:
    basics_score, basics_summary = _basics_score(normalized)

    content_score, content_summary = ai["contentImpact"]
    exp_score, exp_summary = ai["experiencePresentation"]
    skills_score, skills_summary = ai["skillsRelevance"]
    structure_score, structure_summary = ai["structureReadability"]
    language_score, language_summary = ai["languageGrammar"]

    signals = [
        CategorySignal(ScoreCategoryId.atsCompatibility, ats.score, ats.summary),
        CategorySignal(ScoreCategoryId.contentImpact, content_score, content_summary),
        CategorySignal(ScoreCategoryId.experiencePresentation, exp_score, exp_summary),
        CategorySignal(ScoreCategoryId.skillsRelevance, skills_score, skills_summary),
        CategorySignal(ScoreCategoryId.structureReadability, structure_score, structure_summary),
        CategorySignal(ScoreCategoryId.languageGrammar, language_score, language_summary),
        CategorySignal(ScoreCategoryId.basicsContact, basics_score, basics_summary),
    ]
    overall = weighted_overall(signals)

    categories = [
        ScoreCategoryOut(
            id=s.category_id,
            score=clamp_score(s.score),
            weight=SCORE_WEIGHTS[s.category_id],
            summary=s.summary or "—",
        )
        for s in signals
    ]

    findings: list[AnalysisFindingOut] = []
    for f in ats.findings:
        findings.append(
            AnalysisFindingOut(
                id=f.id,
                severity=f.severity,
                title=f.title,
                whyItMatters=f.why,
                evidence=f.evidence,
                recommendedAction=f.action,
                categoryId=f.category_id,
                supportsAiImprove=False,
            )
        )
    for item in ai.get("findings") or []:
        findings.append(
            AnalysisFindingOut(
                id=item["id"],
                severity=FindingSeverity(item["severity"]),
                title=item["title"],
                whyItMatters=item["whyItMatters"],
                evidence=item["evidence"],
                recommendedAction=item["recommendedAction"],
                categoryId=ScoreCategoryId(item["categoryId"]),
                beforeText=item.get("beforeText"),
                afterText=item.get("afterText"),
                supportsAiImprove=bool(item.get("supportsAiImprove")),
            )
        )

    # Prefer critical/improve for top improvements, max 3.
    priority = [
        f for f in findings if f.severity in {FindingSeverity.critical, FindingSeverity.improve}
    ]
    top_ids = [f.id for f in priority[:3]]

    working = list(ai.get("workingWell") or [])
    if ats.contact_ok and "Contact block includes email." not in working:
        working.insert(0, "Contact email was detectable as plain text.")
    has_projects = any(
        s.key == "projects" and s.status.value != "missing" for s in normalized.sections
    )
    mentions_projects = any("project" in w.lower() or "proje" in w.lower() for w in working)
    if has_projects and not mentions_projects:
        working.append("Projects section is present — strong for early-career profiles.")

    return ResumeAnalysisOut(
        id=f"analysis_{normalized.resume_id}",
        resumeId=normalized.resume_id,
        overallScore=overall,
        confidence=normalized.confidence,
        categories=categories,
        findings=findings,
        workingWell=working[:6],
        topImprovementIds=top_ids,
        engineVersion=analysis_version,
        analyzedAt=datetime.now(UTC).isoformat(),
        fileName=file_name,
    )
