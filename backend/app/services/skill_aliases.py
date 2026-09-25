"""Maintainable skill / tool alias map — not a huge taxonomy."""

from __future__ import annotations

# canonical -> aliases (lowercase)
SKILL_ALIASES: dict[str, list[str]] = {
    "python": ["py", "python3"],
    "javascript": ["js", "ecmascript"],
    "typescript": ["ts"],
    "flutter": ["flutter sdk"],
    "dart": ["dartlang"],
    "react": ["react.js", "reactjs"],
    "node.js": ["nodejs", "node"],
    "sql": ["structured query language", "t-sql", "pl/sql"],
    "postgresql": ["postgres", "psql"],
    "mongodb": ["mongo"],
    "aws": ["amazon web services"],
    "docker": ["containers", "containerization"],
    "kubernetes": ["k8s"],
    "figma": ["figma design"],
    "excel": ["microsoft excel", "ms excel"],
    "git": ["github", "gitlab", "version control"],
    "java": ["jvm"],
    "c#": ["csharp", "c sharp", ".net"],
    "machine learning": ["ml", "機械学習"],
    "data analysis": ["data analytics", "analiz"],
    "communication": ["iletisim", "iletişim", "written communication"],
    "teamwork": ["collaboration", "takım çalışması", "takim calismasi"],
}


def canonicalize(term: str) -> str:
    cleaned = " ".join(term.strip().lower().split())
    if not cleaned:
        return cleaned
    for canonical, aliases in SKILL_ALIASES.items():
        if cleaned == canonical or cleaned in aliases:
            return canonical
    return cleaned


def expand_terms(terms: list[str]) -> set[str]:
    out: set[str] = set()
    for term in terms:
        canon = canonicalize(term)
        if not canon:
            continue
        out.add(canon)
        for alias in SKILL_ALIASES.get(canon, []):
            out.add(alias)
        out.add(term.strip().lower())
    return out
