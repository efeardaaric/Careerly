from app.scoring.common import active_sections, finish, rule

_PREFERRED = ("summary", "experience", "projects", "education", "skills")


def score_structure(structured: dict) -> object:
    sections = active_sections(structured)
    keys = [section.get("key") for section in sections]
    present = set(keys)
    core = sum(1 for key in ("experience", "education", "skills") if key in present)
    long_blocks = sum(1 for section in sections if len(section.get("body") or "") > 1800)
    indexes = [keys.index(key) for key in _PREFERRED if key in keys]
    ordered = indexes == sorted(indexes)
    rules = [
        rule(
            "recognized_sections",
            "passed" if core >= 3 else "partial" if core else "failed",
            40 if core >= 3 else (18 if core else 0),
            40,
            f"{core} of 3 core sections (experience, education, skills) were recognized.",
            "Core sections are present.",
        ),
        rule(
            "logical_order",
            "passed" if ordered and len(indexes) >= 2 else "partial" if indexes else "unknown",
            20 if ordered and len(indexes) >= 2 else (8 if indexes else 0),
            20,
            "Recognized sections follow a common reading order."
            if ordered
            else "Section order could not be confirmed.",
            "Section order is readable.",
            confidence=0.7 if indexes else 0.3,
        ),
        rule(
            "block_length",
            "passed" if sections and long_blocks == 0 else "partial" if sections else "failed",
            20 if sections and long_blocks == 0 else (8 if sections else 0),
            20,
            f"{long_blocks} section(s) exceed 1800 characters.",
            "Sections are not one unbroken block.",
        ),
        rule(
            "section_count",
            "passed" if len(sections) >= 3 else "partial" if sections else "failed",
            20 if len(sections) >= 3 else (8 if sections else 0),
            20,
            f"{len(sections)} section(s) were classified.",
            "The document is split into sections.",
        ),
    ]
    return finish(
        "structureReadability",
        "Structure & Readability",
        rules,
        [],
        "This score uses textual structure only. Font, color, and column layout are not measured.",
    )
