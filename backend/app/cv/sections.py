"""English and Turkish CV heading detection. Exact normalized match only."""

from __future__ import annotations

from dataclasses import dataclass

from app.cv.normalize import fold_heading

ALIASES: dict[str, tuple[str, ...]] = {
    "summary": (
        "summary",
        "professional summary",
        "profile",
        "about me",
        "about",
        "ozet",
        "profesyonel ozet",
        "profil",
        "hakkimda",
    ),
    "experience": (
        "experience",
        "work experience",
        "professional experience",
        "employment",
        "employment history",
        "work history",
        "deneyim",
        "is deneyimi",
        "profesyonel deneyim",
        "calisma deneyimi",
    ),
    "education": (
        "education",
        "academic background",
        "academic history",
        "egitim",
        "egitim bilgileri",
        "akademik gecmis",
    ),
    "skills": (
        "skills",
        "technical skills",
        "core skills",
        "competencies",
        "yetenekler",
        "yetkinlikler",
        "teknik yetenekler",
        "teknik beceriler",
    ),
    "projects": (
        "projects",
        "project experience",
        "personal projects",
        "projeler",
        "proje deneyimi",
    ),
    "certifications": (
        "certifications",
        "certificates",
        "sertifikalar",
        "sertifika",
    ),
    "languages": (
        "languages",
        "diller",
        "yabanci diller",
    ),
    "awards": ("awards", "honors", "oduller"),
    "volunteer": (
        "volunteer",
        "volunteer experience",
        "gonulluluk",
        "gonullu calismalar",
    ),
    "publications": ("publications", "yayinlar"),
}

_LOOKUP = {fold_heading(phrase): key for key, phrases in ALIASES.items() for phrase in phrases}

TITLES = {
    "summary": "Summary",
    "experience": "Experience",
    "education": "Education",
    "skills": "Skills",
    "projects": "Projects",
    "certifications": "Certifications",
    "languages": "Languages",
    "awards": "Awards",
    "volunteer": "Volunteer",
    "publications": "Publications",
    "contact": "Contact",
}


@dataclass
class DetectedSection:
    type: str
    original_heading: str
    normalized_heading: str
    content: str
    confidence: float
    start_position: int
    end_position: int
    state: str


def match_heading(line: str) -> str | None:
    folded = fold_heading(line)
    if not folded or len(folded) > 48:
        return None
    if any(char.isdigit() for char in folded):
        return None
    return _LOOKUP.get(folded)


def detect_sections(text: str) -> tuple[str, list[DetectedSection]]:
    lines = text.split("\n")
    preamble: list[str] = []
    sections: list[DetectedSection] = []
    current_key: str | None = None
    current_heading = ""
    current_lines: list[str] = []
    cursor = 0

    def close(end: int) -> None:
        nonlocal current_key, current_lines, current_heading
        if current_key is None:
            return
        body = "\n".join(current_lines).strip()
        state = "detected" if len(body) >= 12 else "low_confidence"
        sections.append(
            DetectedSection(
                type=current_key,
                original_heading=current_heading,
                normalized_heading=fold_heading(current_heading),
                content=body,
                confidence=0.92 if state == "detected" else 0.55,
                start_position=max(0, end - len(body)),
                end_position=end,
                state=state,
            )
        )
        current_key = None
        current_lines = []

    for line in lines:
        stripped = line.strip()
        key = match_heading(stripped) if stripped else None
        if key:
            close(cursor)
            current_key = key
            current_heading = stripped
            current_lines = []
        elif current_key is None:
            if stripped:
                preamble.append(stripped)
        elif stripped:
            current_lines.append(stripped)
        cursor += len(line) + 1
    close(cursor)
    return "\n".join(preamble), sections
