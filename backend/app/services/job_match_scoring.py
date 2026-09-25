"""Job Match scoring engine — owns overallMatchScore (AI must not)."""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

from app.schemas.job_match import (
    JobMatchCategoryId,
    JobMatchResultOut,
    MatchCategoryOut,
    MatchRecommendationOut,
    ResumeSnapshotIn,
    SkillEvidenceStatus,
    SkillMatchItemOut,
)
from app.services.job_description_parser import ParsedJobDescription
from app.services.job_match_hybrid import HybridMatchResult
from app.services.job_match_weights import (
    JOB_MATCH_WEIGHTS,
    MatchCategorySignal,
    clamp_score,
    weighted_match_overall,
)
from app.services.job_match_weights import (
    JobMatchCategoryId as WeightCat,
)


def _blend(deterministic: float, ai_hint: float, weight_ai: float = 0.35) -> float:
    return (1.0 - weight_ai) * deterministic + weight_ai * ai_hint


def _hint_pair(block: object, default: float) -> tuple[float, str]:
    if isinstance(block, tuple) and len(block) >= 2:
        try:
            return float(block[0]), str(block[1] or "")
        except (TypeError, ValueError):
            return default, str(block[1] if len(block) > 1 else "")
    if isinstance(block, dict):
        try:
            score = float(block.get("scoreHint", block.get("score", default)))
        except (TypeError, ValueError):
            score = default
        return score, str(block.get("summary") or "")
    return default, ""


def build_job_match_result(
    *,
    resume: ResumeSnapshotIn,
    job: ParsedJobDescription,
    hybrid: HybridMatchResult,
    ai: dict,
    locale: str,
    engine_version: str,
    job_url: str | None = None,
) -> JobMatchResultOut:
    tr = locale.lower().startswith("tr")
    exp_hint, exp_summary = _hint_pair(ai.get("experienceProjects"), 65.0)
    resp_hint, resp_summary = _hint_pair(ai.get("responsibilities"), 60.0)

    exp_score = _blend(hybrid.experience_overlap, exp_hint, 0.4)
    resp_score = _blend(hybrid.experience_overlap * 0.9, resp_hint, 0.45)

    signals = [
        MatchCategorySignal(
            WeightCat.coreSkills,
            hybrid.core_skills_score,
            (
                "Temel beceriler ilanla kısmen örtüşüyor."
                if tr
                else "Core skills partially align with the posting."
            ),
        ),
        MatchCategorySignal(
            WeightCat.experienceProjects,
            exp_score,
            exp_summary
            or (
                "Projeler/deneyim bazı sorumluluklarla örtüşüyor."
                if tr
                else "Projects/experience overlap some responsibilities."
            ),
        ),
        MatchCategorySignal(
            WeightCat.responsibilities,
            resp_score,
            resp_summary
            or (
                "Sorumluluk uyumu karmaşık — kanıtı netleştirin."
                if tr
                else "Responsibility alignment is mixed — clarify evidence."
            ),
        ),
        MatchCategorySignal(
            WeightCat.education,
            hybrid.education_score,
            (
                "Eğitim anahtar kelimeleri CV'de arandı."
                if tr
                else "Education keywords checked against your CV."
            ),
        ),
        MatchCategorySignal(
            WeightCat.tools,
            hybrid.tools_score,
            (
                "Araç/teknoloji eşleşmesi hesaplandı."
                if tr
                else "Tools/tech overlap computed from the posting."
            ),
        ),
        MatchCategorySignal(
            WeightCat.languageOther,
            hybrid.language_score,
            (
                "Dil ve diğer gereksinimler değerlendirildi."
                if tr
                else "Language and other requirements evaluated."
            ),
        ),
    ]

    overall = weighted_match_overall(signals)

    unclear = {str(s).lower() for s in (ai.get("unclearSkills") or [])}
    skill_matches: list[SkillMatchItemOut] = []
    for item in hybrid.skill_matches:
        if item.status == SkillEvidenceStatus.notDemonstrated and item.skill.lower() in unclear:
            skill_matches.append(
                item.model_copy(
                    update={
                        "status": SkillEvidenceStatus.unclear,
                        "note": (
                            "CV'nizden net değil — doğrulamaya değer."
                            if tr
                            else "Unclear from your CV — worth confirming."
                        ),
                    }
                )
            )
        else:
            skill_matches.append(item)

    categories = [
        MatchCategoryOut(
            id=JobMatchCategoryId(s.category_id.value),
            score=clamp_score(s.score),
            weight=JOB_MATCH_WEIGHTS[s.category_id],
            summary=s.summary,
        )
        for s in signals
    ]

    recommendations: list[MatchRecommendationOut] = []
    for rec in ai.get("recommendations") or []:
        if not isinstance(rec, dict):
            continue
        recommendations.append(
            MatchRecommendationOut(
                id=str(rec.get("id") or f"rec_{len(recommendations)}"),
                title=str(rec.get("title") or "")[:160],
                body=str(rec.get("body") or "")[:500],
                kind=str(rec.get("kind") or "cv_improvement"),
                beforeText=rec.get("beforeText"),
                afterText=rec.get("afterText"),
            )
        )

    disclaimer = (
        "Bu eşleşme skoru hizalanmayı gösterir; işe alınma olasılığı değildir."
        if tr
        else "This match score shows alignment with the posting — not hiring probability."
    )

    return JobMatchResultOut(
        id=f"jm_{uuid4().hex[:12]}",
        resumeId=resume.resumeId,
        jobTitle=job.title,
        company=job.company,
        jobUrl=job_url,
        overallMatchScore=overall,
        scoreDisclaimer=disclaimer,
        categories=categories,
        skillMatches=skill_matches,
        keywordsCovered=hybrid.keywords_covered,
        keywordsMissing=hybrid.keywords_missing,
        recommendations=recommendations[:8],
        verificationQuestions=list(ai.get("verificationQuestions") or [])[:5],
        learningOpportunities=list(ai.get("learningOpportunities") or [])[:5],
        workingWell=list(ai.get("workingWell") or [])[:5],
        engineVersion=engine_version,
        matchedAt=datetime.now(UTC).isoformat(),
    )
