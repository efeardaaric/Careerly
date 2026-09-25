"""Normalize extracted CV text into structured sections (EN + TR headings)."""

from __future__ import annotations

import re
import uuid
from dataclasses import dataclass, field

from app.schemas.analysis import ParserConfidence, SectionStatus

# Canonical section keys → bilingual heading patterns (lowercase match).
SECTION_PATTERNS: dict[str, tuple[str, list[str]]] = {
    "contact": (
        "Contact",
        ["contact", "iletisim", "iletişim", "kişisel bilgiler", "personal details"],
    ),
    "summary": (
        "Summary",
        [
            "summary",
            "professional summary",
            "profile",
            "objective",
            "özet",
            "profil",
            "kariyer hedefi",
            "about me",
            "hakkımda",
        ],
    ),
    "education": (
        "Education",
        ["education", "eğitim", "egitim", "academic", "akademik"],
    ),
    "experience": (
        "Experience",
        [
            "experience",
            "work experience",
            "employment",
            "deneyim",
            "iş deneyimi",
            "is deneyimi",
            "professional experience",
        ],
    ),
    "projects": (
        "Projects",
        ["projects", "projeler", "personal projects", "selected projects"],
    ),
    "skills": (
        "Skills",
        ["skills", "technical skills", "beceriler", "yetenekler", "teknik beceriler"],
    ),
    "languages": (
        "Languages",
        ["languages", "dil", "diller", "language skills"],
    ),
    "certifications": (
        "Certifications",
        ["certifications", "certificates", "sertifikalar", "sertifika"],
    ),
    "awards": (
        "Awards / activities",
        [
            "awards",
            "activities",
            "volunteer",
            "ödüller",
            "aktiviteler",
            "gönüllü",
            "gonullu",
            "extracurricular",
        ],
    ),
}

EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
PHONE_RE = re.compile(r"(\+?\d[\d\s().-]{7,}\d)")


@dataclass
class NormalizedSection:
    key: str
    title: str
    status: SectionStatus
    preview: str | None = None
    note: str | None = None
    body: str = ""


@dataclass
class NormalizedResume:
    resume_id: str
    sections: list[NormalizedSection] = field(default_factory=list)
    confidence: ParserConfidence = ParserConfidence.medium
    has_email: bool = False
    has_phone: bool = False
    word_count: int = 0
    locale_hint: str = "en"


def _match_heading(line: str) -> str | None:
    cleaned = line.strip().lower().rstrip(":")
    if len(cleaned) > 48:
        return None
    for key, (_title, patterns) in SECTION_PATTERNS.items():
        for pattern in patterns:
            if cleaned == pattern or cleaned.startswith(pattern + " "):
                return key
    return None


def normalize_resume(text: str, *, locale: str = "en") -> NormalizedResume:
    resume_id = f"resume_{uuid.uuid4().hex[:12]}"
    lines = [ln.strip() for ln in text.splitlines()]
    has_email = bool(EMAIL_RE.search(text))
    has_phone = bool(PHONE_RE.search(text))
    word_count = len(re.findall(r"\w+", text, flags=re.UNICODE))

    buckets: dict[str, list[str]] = {key: [] for key in SECTION_PATTERNS}
    current: str | None = None
    preamble: list[str] = []

    for line in lines:
        if not line:
            continue
        heading = _match_heading(line)
        if heading:
            current = heading
            continue
        if current:
            buckets[current].append(line)
        else:
            preamble.append(line)

    # Contact often lives in preamble.
    if preamble and not buckets["contact"]:
        buckets["contact"] = preamble[:6]
    elif preamble:
        buckets["contact"] = preamble[:4] + buckets["contact"]

    sections: list[NormalizedSection] = []
    detected_count = 0
    for key, (title, _) in SECTION_PATTERNS.items():
        body = "\n".join(buckets[key]).strip()
        if body:
            detected_count += 1
            preview = body.split("\n")[0][:140]
            status = SectionStatus.detected
            note = None
            # Soft skills mixed into skills — flag for review, don't invent content.
            if key == "skills" and re.search(
                r"\b(teamwork|communication|leadership|takım|iletisim|iletişim)\b",
                body,
                re.IGNORECASE,
            ):
                status = SectionStatus.needsReview
                note = (
                    "Soft skills appear mixed with tools — consider separating them."
                    if locale.startswith("en")
                    else "Yumuşak beceriler araçlarla karışık görünüyor — ayırmayı düşünün."
                )
            if key == "summary" and len(body) < 40:
                status = SectionStatus.needsReview
                note = (
                    "Summary looks very short; confirm it is complete."
                    if locale.startswith("en")
                    else "Özet çok kısa görünüyor; tamamlandığını doğrulayın."
                )
            sections.append(
                NormalizedSection(
                    key=key,
                    title=title,
                    status=status,
                    preview=preview,
                    note=note,
                    body=body,
                )
            )
        else:
            note = None
            if key == "certifications":
                note = (
                    "No certifications section detected."
                    if locale.startswith("en")
                    else "Sertifika bölümü tespit edilmedi."
                )
            sections.append(
                NormalizedSection(
                    key=key,
                    title=title,
                    status=SectionStatus.missing,
                    preview=None,
                    note=note,
                    body="",
                )
            )

    if not has_email:
        # Mark contact needs review rather than inventing an email.
        for section in sections:
            if section.key == "contact":
                section.status = SectionStatus.needsReview
                section.note = (
                    "Could not confidently detect an email address."
                    if locale.startswith("en")
                    else "E-posta adresi güvenle tespit edilemedi."
                )

    if detected_count >= 6 and has_email:
        confidence = ParserConfidence.high
    elif detected_count >= 3:
        confidence = ParserConfidence.medium
    else:
        confidence = ParserConfidence.low

    return NormalizedResume(
        resume_id=resume_id,
        sections=sections,
        confidence=confidence,
        has_email=has_email,
        has_phone=has_phone,
        word_count=word_count,
        locale_hint=locale,
    )
