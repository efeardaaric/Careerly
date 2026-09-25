"""Parse and normalize pasted job / internship descriptions."""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from app.services.skill_aliases import canonicalize

SECTION_HINTS = {
    "requirements": [
        "requirements",
        "qualifications",
        "what you'll need",
        "you have",
        "aranan nitelikler",
        "gereksinimler",
        "zorunlu",
    ],
    "preferred": [
        "preferred",
        "nice to have",
        "bonus",
        "plus",
        "tercihen",
        "tercih edilen",
    ],
    "responsibilities": [
        "responsibilities",
        "what you'll do",
        "role",
        "görevler",
        "sorumluluklar",
        "is tanimi",
        "iş tanımı",
    ],
    "tools": [
        "tools",
        "tech stack",
        "technologies",
        "teknolojiler",
        "araçlar",
    ],
    "education": [
        "education",
        "eğitim",
        "egitim",
    ],
    "language": [
        "language",
        "languages",
        "dil",
        "diller",
    ],
}

REQUIRED_MARKERS = re.compile(
    r"\b(required|must have|zorunlu|şart|sart)\b",
    re.IGNORECASE,
)
PREFERRED_MARKERS = re.compile(
    r"\b(preferred|nice to have|bonus|tercihen|artı|arti)\b",
    re.IGNORECASE,
)
BULLET_RE = re.compile(r"^[\s]*([•\-\*\u2022]|\d+[.)])\s*(.+)$")
TOKEN_RE = re.compile(r"[A-Za-zÀ-ÖØ-öø-ÿ+#.]{2,}")


@dataclass
class ParsedJobDescription:
    title: str
    company: str | None
    raw_text: str
    required_skills: list[str] = field(default_factory=list)
    preferred_skills: list[str] = field(default_factory=list)
    responsibilities: list[str] = field(default_factory=list)
    tools: list[str] = field(default_factory=list)
    education_keywords: list[str] = field(default_factory=list)
    language_keywords: list[str] = field(default_factory=list)
    keywords: list[str] = field(default_factory=list)


def _heading_bucket(line: str) -> str | None:
    low = line.strip().lower().rstrip(":")
    if len(low) > 60:
        return None
    for bucket, hints in SECTION_HINTS.items():
        for hint in hints:
            if low == hint or low.startswith(hint):
                return bucket
    return None


_PAREN_MARKERS = re.compile(
    r"\((required|preferred|must have|zorunlu|tercihen|nice to have)\)",
    re.IGNORECASE,
)
_STOP = {"build", "with", "from", "the", "and", "for", "code", "mobile", "features"}


def _extract_skillish(line: str) -> list[str]:
    cleaned = _PAREN_MARKERS.sub("", line)
    cleaned = REQUIRED_MARKERS.sub("", cleaned)
    cleaned = PREFERRED_MARKERS.sub("", cleaned)
    parts = re.split(r"[,;/|]| and | ve ", cleaned)
    out: list[str] = []
    for part in parts:
        token = part.strip(" .:-()")
        if len(token.split()) > 2:
            for word in TOKEN_RE.findall(token):
                if len(word) <= 24:
                    out.append(canonicalize(word))
            continue
        if 1 < len(token) <= 40:
            out.append(canonicalize(token))
    return [t for t in out if t and t not in _STOP]


def parse_job_description(
    *,
    title: str,
    description: str,
    company: str | None = None,
) -> ParsedJobDescription:
    text = description.replace("\r\n", "\n").strip()
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]

    required: list[str] = []
    preferred: list[str] = []
    responsibilities: list[str] = []
    tools: list[str] = []
    education_from_section: list[str] = []
    language_from_section: list[str] = []
    current: str | None = None

    for line in lines:
        bucket = _heading_bucket(line)
        if bucket:
            current = bucket
            continue

        bullet = BULLET_RE.match(line)
        content = bullet.group(2) if bullet else line

        if PREFERRED_MARKERS.search(content) or current == "preferred":
            preferred.extend(_extract_skillish(content))
        elif REQUIRED_MARKERS.search(content) or current == "requirements":
            required.extend(_extract_skillish(content))
        elif current == "tools":
            tools.extend(_extract_skillish(content))
        elif current == "education":
            education_from_section.extend(_extract_skillish(content))
        elif current == "language":
            language_from_section.extend(_extract_skillish(content))
        elif current == "responsibilities" or bullet:
            responsibilities.append(content[:200])
            # Responsibilities often embed tools/skills
            required.extend(_extract_skillish(content))

    # Fallback: scan whole text for skill-like tokens if lists empty
    if not required and not preferred:
        for line in lines:
            required.extend(_extract_skillish(line))

    education_keywords = education_from_section + [
        canonicalize(t)
        for t in re.findall(
            r"\b(bachelor|master|degree|b\.?sc|m\.?sc|lisans|yüksek lisans|computer science|yazılım)\b",
            text,
            flags=re.IGNORECASE,
        )
    ]
    language_keywords = language_from_section + [
        canonicalize(t)
        for t in re.findall(
            r"\b(english|turkish|almanca|german|french|ingilizce|türkçe|turkce)\b",
            text,
            flags=re.IGNORECASE,
        )
    ]

    def _uniq(items: list[str]) -> list[str]:
        seen: set[str] = set()
        out: list[str] = []
        for item in items:
            if item and item not in seen:
                seen.add(item)
                out.append(item)
        return out

    required_u = _uniq(required)[:30]
    preferred_u = _uniq([p for p in preferred if p not in required_u])[:20]
    tools_u = _uniq(tools)[:20]
    keywords = _uniq(required_u + preferred_u + tools_u)[:40]

    return ParsedJobDescription(
        title=title.strip() or "Untitled role",
        company=company.strip() if company else None,
        raw_text=text,
        required_skills=required_u,
        preferred_skills=preferred_u,
        responsibilities=_uniq(responsibilities)[:20],
        tools=tools_u,
        education_keywords=_uniq(education_keywords),
        language_keywords=_uniq(language_keywords),
        keywords=keywords,
    )
