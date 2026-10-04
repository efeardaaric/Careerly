"""Rule-based structured CV. Never invents employers, metrics, or skills."""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from app.cv.confidence import parser_confidence
from app.cv.dates import date_structure_score, parse_date_token
from app.cv.normalize import normalize_text
from app.cv.sections import TITLES, DetectedSection, detect_sections

_EMAIL = re.compile(r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", re.IGNORECASE)
_PHONE = re.compile(
    r"(?:\+\d{1,3}[\s.-]?)?(?:\(?\d{2,4}\)?[\s.-]?)\d{3}[\s.-]?\d{2,4}[\s.-]?\d{2,4}"
)
_URL = re.compile(r"https?://[^\s<>]+|(?:www\.)[^\s<>]+", re.IGNORECASE)
_LINKEDIN = re.compile(r"(?:https?://)?(?:www\.)?linkedin\.com/in/[^\s<>]+", re.IGNORECASE)
_GITHUB = re.compile(r"(?:https?://)?(?:www\.)?github\.com/[^\s<>]+", re.IGNORECASE)
_DATE_SPAN = re.compile(
    r"((?:[A-Za-zÇĞİÖŞÜçğıöşü]+\s+)?(?:19|20)\d{2}|(?:0?[1-9]|1[0-2])[/-](?:19|20)\d{2})"
    r"\s*[-–—to]+\s*"
    r"((?:[A-Za-zÇĞİÖŞÜçğıöşü]+\s+)?(?:19|20)\d{2}|(?:0?[1-9]|1[0-2])[/-](?:19|20)\d{2}|Present|Current|Now|Halen|Devam|Günümüz|Şimdi)",
    re.IGNORECASE,
)


@dataclass
class StructuredCV:
    contact: dict = field(default_factory=dict)
    summary: str = ""
    experiences: list = field(default_factory=list)
    education: list = field(default_factory=list)
    projects: list = field(default_factory=list)
    skills: list = field(default_factory=list)
    certifications: list = field(default_factory=list)
    languages: list = field(default_factory=list)
    links: list = field(default_factory=list)
    custom_sections: list = field(default_factory=list)
    sections: list = field(default_factory=list)
    detected_language: str = "en"
    parser_confidence: int = 0
    source_metadata: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "contact": self.contact,
            "summary": {"text": self.summary} if self.summary else {},
            "experiences": self.experiences,
            "education": self.education,
            "projects": self.projects,
            "skills": self.skills,
            "certifications": self.certifications,
            "languages": self.languages,
            "links": self.links,
            "customSections": self.custom_sections,
            "sections": self.sections,
            "detectedLanguage": self.detected_language,
            "parserConfidence": self.parser_confidence,
            "sourceMetadata": self.source_metadata,
        }


def parse_cv(
    raw_text: str,
    *,
    extraction_method: str = "text",
    page_count: int | None = None,
    contains_tables: bool = False,
) -> StructuredCV:
    text = normalize_text(raw_text)
    language = _language(text)
    preamble, detected = detect_sections(text)
    contact = extract_contact(preamble if preamble.strip() else "\n".join(text.split("\n")[:8]))
    by_type: dict[str, list[DetectedSection]] = {}
    for section in detected:
        by_type.setdefault(section.type, []).append(section)

    experiences = _entries(by_type.get("experience", []), "experience")
    projects = _entries(by_type.get("projects", []), "project")
    education = _entries(by_type.get("education", []), "education")
    skills = _skills(by_type.get("skills", []))
    summary = " ".join(section.content for section in by_type.get("summary", [])).strip()
    certifications = _lines(by_type.get("certifications", []))
    languages = _lines(by_type.get("languages", []))
    custom = [
        {
            "key": section.type,
            "title": section.original_heading,
            "body": section.content,
        }
        for section in detected
        if section.type in {"awards", "volunteer", "publications"}
    ]
    classified = sum(len(section.content) for section in detected)
    total = max(len(text), 1)
    date_quality = date_structure_score(text)
    core = sum(1 for key in ("summary", "experience", "education", "skills") if by_type.get(key))
    confidence = parser_confidence(
        extraction_ok=True,
        scanned=False,
        detected_core=core,
        classified_ratio=classified / total,
        has_email=bool(contact.get("email")),
        has_phone=bool(contact.get("phone")),
        date_quality=date_quality,
    )
    sections = [
        {
            "id": f"section_{index}",
            "key": section.type,
            "title": section.original_heading or TITLES.get(section.type, section.type),
            "body": section.content,
            "status": "detected" if section.state == "detected" else "lowConfidence",
            "confidence": section.confidence,
        }
        for index, section in enumerate(detected)
    ]
    return StructuredCV(
        contact=contact,
        summary=summary,
        experiences=experiences,
        education=education,
        projects=projects,
        skills=skills,
        certifications=[{"name": item} for item in certifications],
        languages=[{"name": item} for item in languages],
        links=contact.get("links", []),
        custom_sections=custom,
        sections=sections,
        detected_language=language,
        parser_confidence=confidence,
        source_metadata={
            "extractionMethod": extraction_method,
            "pageCount": page_count,
            "containsTables": contains_tables,
            "dateQuality": round(date_quality, 3),
        },
    )


def _phone(text: str) -> re.Match[str] | None:
    for match in _PHONE.finditer(text):
        digits = re.sub(r"\D", "", match.group(0))
        if 10 <= len(digits) <= 15:
            return match
    return None


def _looks_like_name(line: str) -> bool:
    if not line or len(line) > 60:
        return False
    if any(ch.isdigit() for ch in line) or any(ch in line for ch in "@/|:"):
        return False
    words = line.split()
    return 2 <= len(words) <= 5


def _language(text: str) -> str:
    folded = text.lower()
    hits = sum(
        token in folded
        for token in (" ve ", " ile ", "deneyim", "eğitim", "yetenek", "projeler")
    )
    return "tr" if hits >= 2 else "en"


def extract_contact(text: str) -> dict:
    email = _EMAIL.search(text)
    phone = _phone(text)
    linkedin = _LINKEDIN.search(text)
    github = _GITHUB.search(text)
    links = [match.group(0).rstrip(".,)") for match in _URL.finditer(text)]
    name = None
    for line in text.split("\n")[:6]:
        candidate = line.strip()
        if _looks_like_name(candidate):
            name = candidate
            break
    return {
        "fullName": name,
        "email": email.group(0) if email else None,
        "phone": phone.group(0).strip() if phone else None,
        "location": None,
        "linkedIn": linkedin.group(0) if linkedin else None,
        "github": github.group(0) if github else None,
        "portfolio": next(
            (link for link in links if "linkedin" not in link and "github" not in link),
            None,
        ),
        "links": links,
    }


def _entries(sections: list[DetectedSection], kind: str) -> list[dict]:
    items: list[dict] = []
    for section in sections:
        block: list[str] = []
        for line in section.content.split("\n"):
            if _looks_like_heading(line) and block:
                items.append(_entry(block, kind, len(items)))
                block = [line]
            else:
                block.append(line)
        if any(line.strip() for line in block):
            items.append(_entry(block, kind, len(items)))
    return items


def _looks_like_heading(line: str) -> bool:
    return bool(_DATE_SPAN.search(line)) or (len(line) < 80 and line.endswith("|"))


def _entry(lines: list[str], kind: str, index: int) -> dict:
    heading = next((line.strip() for line in lines if line.strip()), "")
    bullets = [
        line.strip().lstrip("-• ").strip()
        for line in lines[1:]
        if line.strip().startswith(("-", "•")) or (line.strip() and line != heading)
    ]
    bullets = [bullet for bullet in bullets if bullet and bullet != heading]
    span = _DATE_SPAN.search(heading)
    start = parse_date_token(span.group(1)) if span else None
    end = parse_date_token(span.group(2)) if span else None
    title_part = heading.split("|")[0].strip()
    org_part = heading.split("|")[1].strip() if "|" in heading else None
    if org_part and span:
        org_part = _DATE_SPAN.sub("", org_part).strip(" -–—")
    return {
        "id": f"{kind}_{index}",
        "title": title_part,
        "organization": org_part or None,
        "start": start,
        "end": end,
        "bullets": bullets[:12],
        "raw": "\n".join(line for line in lines if line.strip()),
    }


def _skills(sections: list[DetectedSection]) -> list[dict]:
    seen: set[str] = set()
    skills: list[dict] = []
    for section in sections:
        chunks = re.split(r"[,•|\n]", section.content)
        for chunk in chunks:
            name = chunk.strip(" -•\t")
            key = name.lower()
            if 1 < len(name) < 48 and key not in seen:
                seen.add(key)
                skills.append({"name": name})
    return skills


def _lines(sections: list[DetectedSection]) -> list[str]:
    values = []
    for section in sections:
        for line in re.split(r"[,•|\n]", section.content):
            cleaned = line.strip(" -•\t")
            if cleaned:
                values.append(cleaned)
    return values
