from app.scoring.common import finish, rule

_SOFT = {
    "communication",
    "teamwork",
    "hardworking",
    "leadership",
    "microsoft office",
    "ms office",
    "iletişim",
    "iletisim",
    "takım çalışması",
    "takim calismasi",
    "sorumluluk",
}


def score_skills(structured: dict, target_fields: list[str] | None = None) -> object:
    skills = [item.get("name", "") for item in structured.get("skills") or [] if item.get("name")]
    lowered = [name.lower() for name in skills]
    unique = len(set(lowered))
    duplicates = len(lowered) - unique
    soft = sum(1 for name in lowered if name in _SOFT)
    specific = unique - soft
    fields = [field.lower() for field in (target_fields or [])]
    aligned = 0
    if fields:
        aligned = sum(1 for name in lowered if any(field in name or name in field for field in fields))
    rules = [
        rule(
            "skills_section",
            "passed" if skills else "failed",
            30 if skills else 0,
            30,
            f"{len(skills)} skill(s) were parsed." if skills else "No skills section was parsed.",
            "A skills section exists.",
        ),
        rule(
            "specific_skills",
            "passed" if specific >= 4 else "partial" if specific else "failed",
            30 if specific >= 4 else (12 if specific else 0),
            30,
            f"{specific} skill(s) are more specific than a generic soft-skill label.",
            "Skills are specific.",
        ),
        rule(
            "duplicates",
            "passed" if skills and duplicates == 0 else "partial" if skills else "failed",
            20 if skills and duplicates == 0 else (8 if skills else 0),
            20,
            f"{duplicates} duplicate skill label(s).",
            "Skill labels are not repeated.",
        ),
        rule(
            "target_alignment",
            "passed" if aligned else ("not_applicable" if not fields else "partial"),
            20 if aligned else 0,
            20,
            f"{aligned} skill label(s) overlap the selected target fields."
            if fields
            else "No target field was provided, so relevance is not scored.",
            "Alignment is only scored when a target field exists.",
        ),
    ]
    return finish(
        "skillsRelevance",
        "Skills Presentation",
        rules,
        [],
        "Without a job description this category scores how skills are presented, not universal relevance.",
    )
