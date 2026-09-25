"""Deterministic hybrid skill / keyword matching against a resume snapshot."""

from __future__ import annotations

from dataclasses import dataclass, field

from app.schemas.job_match import ResumeSnapshotIn, SkillEvidenceStatus, SkillMatchItemOut
from app.services.job_description_parser import ParsedJobDescription
from app.services.skill_aliases import canonicalize, expand_terms


@dataclass
class HybridMatchResult:
    skill_matches: list[SkillMatchItemOut] = field(default_factory=list)
    keywords_covered: list[str] = field(default_factory=list)
    keywords_missing: list[str] = field(default_factory=list)
    core_skills_score: float = 0.0
    tools_score: float = 0.0
    education_score: float = 0.0
    language_score: float = 0.0
    experience_overlap: float = 0.0


def _resume_corpus(resume: ResumeSnapshotIn) -> str:
    parts = [
        resume.summary or "",
        " ".join(resume.skills),
        " ".join(resume.tools),
        " ".join(resume.experienceBullets),
        " ".join(resume.projectBullets),
        " ".join(resume.education),
        " ".join(resume.languages),
    ]
    return " ".join(parts).lower()


def _status_for_term(term: str, corpus: str, resume_terms: set[str]) -> SkillEvidenceStatus:
    canon = canonicalize(term)
    aliases = expand_terms([term])
    if canon in resume_terms or any(a in resume_terms for a in aliases):
        return SkillEvidenceStatus.matched
    # Partial: mentioned in prose but not in skills list
    if any(a in corpus for a in aliases if len(a) >= 3):
        return SkillEvidenceStatus.partial
    return SkillEvidenceStatus.notDemonstrated


def hybrid_match(
    *,
    resume: ResumeSnapshotIn,
    job: ParsedJobDescription,
    locale: str = "en",
) -> HybridMatchResult:
    corpus = _resume_corpus(resume)
    resume_terms = expand_terms(resume.skills + resume.tools + resume.languages)

    skill_matches: list[SkillMatchItemOut] = []
    covered: list[str] = []
    missing: list[str] = []

    def _note(status: SkillEvidenceStatus, required: bool) -> str:
        tr = locale.startswith("tr")
        if status == SkillEvidenceStatus.matched:
            return "Demonstrated in your CV." if not tr else "CV'nizde gösterilmiş."
        if status == SkillEvidenceStatus.partial:
            return (
                "Mentioned, but evidence could be clearer."
                if not tr
                else "Geçiyor, ancak kanıt daha net olabilir."
            )
        if status == SkillEvidenceStatus.unclear:
            return (
                "Unclear from your CV — worth confirming."
                if not tr
                else "CV'nizden net değil — doğrulamaya değer."
            )
        # Absence of evidence ≠ "you don't know"
        if required:
            return "Not demonstrated in your CV." if not tr else "CV'nizde gösterilmemiş."
        return (
            "Not demonstrated in your CV (preferred)."
            if not tr
            else "CV'nizde gösterilmemiş (tercih)."
        )

    for skill in job.required_skills:
        status = _status_for_term(skill, corpus, resume_terms)
        skill_matches.append(
            SkillMatchItemOut(
                skill=skill,
                status=status,
                required=True,
                evidence=None,
                note=_note(status, True),
            )
        )
        if status in {SkillEvidenceStatus.matched, SkillEvidenceStatus.partial}:
            covered.append(skill)
        else:
            missing.append(skill)

    for skill in job.preferred_skills:
        status = _status_for_term(skill, corpus, resume_terms)
        skill_matches.append(
            SkillMatchItemOut(
                skill=skill,
                status=status,
                required=False,
                note=_note(status, False),
            )
        )
        if status in {SkillEvidenceStatus.matched, SkillEvidenceStatus.partial}:
            covered.append(skill)
        elif skill not in missing:
            missing.append(skill)

    def _ratio(items: list[str], required: bool = True) -> float:
        subset = [m for m in skill_matches if m.required == required]
        if not subset:
            return 70.0 if not items else 50.0
        score = 0.0
        for m in subset:
            if m.status == SkillEvidenceStatus.matched:
                score += 1.0
            elif m.status == SkillEvidenceStatus.partial:
                score += 0.55
            elif m.status == SkillEvidenceStatus.unclear:
                score += 0.25
        return 100.0 * score / len(subset)

    core = _ratio(job.required_skills, required=True)
    # Blend preferred lightly
    if job.preferred_skills:
        pref = _ratio(job.preferred_skills, required=False)
        core = 0.75 * core + 0.25 * pref

    tools_terms = expand_terms(job.tools)
    tools_hit = sum(1 for t in tools_terms if t in corpus or t in resume_terms)
    tools_score = 100.0 * tools_hit / max(1, len(tools_terms)) if tools_terms else 72.0

    edu_terms = expand_terms(job.education_keywords)
    edu_hit = sum(1 for t in edu_terms if t in corpus)
    education_score = 100.0 * edu_hit / max(1, len(edu_terms)) if edu_terms else 75.0

    lang_terms = expand_terms(job.language_keywords)
    lang_hit = sum(1 for t in lang_terms if t in corpus or t in resume_terms)
    language_score = 100.0 * lang_hit / max(1, len(lang_terms)) if lang_terms else 70.0

    # Rough experience overlap via keyword hits in bullets
    exp_text = " ".join(resume.experienceBullets + resume.projectBullets).lower()
    resp_hits = 0
    for resp in job.responsibilities[:12]:
        tokens = [canonicalize(t) for t in resp.split() if len(t) > 4][:6]
        if any(t in exp_text for t in tokens):
            resp_hits += 1
    experience_overlap = (
        100.0 * resp_hits / max(1, min(12, len(job.responsibilities)))
        if job.responsibilities
        else 65.0
    )

    return HybridMatchResult(
        skill_matches=skill_matches,
        keywords_covered=list(dict.fromkeys(covered)),
        keywords_missing=list(dict.fromkeys(missing)),
        core_skills_score=core,
        tools_score=tools_score,
        education_score=education_score,
        language_score=language_score,
        experience_overlap=experience_overlap,
    )
