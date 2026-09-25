"""Deterministic ATS checks — no fabricated layout claims."""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from app.schemas.analysis import FindingSeverity, ScoreCategoryId
from app.services.resume_normalizer import NormalizedResume

# Heuristic keywords that often break naive ATS parsers when used as sole structure.
SUSPICIOUS_LAYOUT_HINTS = re.compile(
    r"\b(text.?box|text frame|columns?:|multi[- ]column)\b",
    re.IGNORECASE,
)


@dataclass
class AtsFinding:
    id: str
    severity: FindingSeverity
    title: str
    why: str
    evidence: str
    action: str
    category_id: ScoreCategoryId = ScoreCategoryId.atsCompatibility


@dataclass
class AtsResult:
    score: float
    summary: str
    findings: list[AtsFinding] = field(default_factory=list)
    has_standard_headings: bool = True
    contact_ok: bool = True


def run_ats_engine(text: str, normalized: NormalizedResume, *, locale: str = "en") -> AtsResult:
    findings: list[AtsFinding] = []
    score = 88.0

    detected_keys = {s.key for s in normalized.sections if s.status.value != "missing"}
    required = {"contact", "education", "experience", "skills"}
    missing_required = required - detected_keys
    if missing_required:
        score -= 8 * len(missing_required)
        findings.append(
            AtsFinding(
                id="ats_missing_sections",
                severity=FindingSeverity.critical,
                title=(
                    "Add standard core sections"
                    if locale.startswith("en")
                    else "Standart temel bölümleri ekleyin"
                ),
                why=(
                    "ATS parsers and recruiters expect clear Contact, Education, Experience, and Skills blocks."
                    if locale.startswith("en")
                    else "ATS ve işe alımcılar net İletişim, Eğitim, Deneyim ve Beceriler bölümleri bekler."
                ),
                evidence=f"Missing: {', '.join(sorted(missing_required))}",
                action=(
                    "Use standard headings and keep content in plain text."
                    if locale.startswith("en")
                    else "Standart başlıklar kullanın ve içeriği düz metinde tutun."
                ),
            )
        )

    if not normalized.has_email:
        score -= 12
        findings.append(
            AtsFinding(
                id="ats_missing_email",
                severity=FindingSeverity.critical,
                title=(
                    "Make email address parser-visible"
                    if locale.startswith("en")
                    else "E-postayı ayrıştırılabilir yapın"
                ),
                why=(
                    "Contact detection relies on plain-text email, not images or headers alone."
                    if locale.startswith("en")
                    else "İletişim tespiti görsellerden değil düz metin e-postadan çalışır."
                ),
                evidence="No email pattern detected in extracted text.",
                action=(
                    "Add a professional email in the contact block as selectable text."
                    if locale.startswith("en")
                    else "İletişim bölümüne seçilebilir metin olarak profesyonel bir e-posta ekleyin."
                ),
            )
        )

    # Only flag layout when text literally suggests multi-column/textbox wording.
    # Never invent two-column detection without evidence.
    if SUSPICIOUS_LAYOUT_HINTS.search(text):
        score -= 6
        findings.append(
            AtsFinding(
                id="ats_layout_hint",
                severity=FindingSeverity.improve,
                title=(
                    "Avoid complex layout wording in the CV body"
                    if locale.startswith("en")
                    else "CV gövdesinde karmaşık yerleşim ifadelerinden kaçının"
                ),
                why=(
                    "Decorative or multi-column layouts often reduce extractability."
                    if locale.startswith("en")
                    else "Süslü veya çok sütunlu yerleşimler ayrıştırmayı zorlaştırır."
                ),
                evidence="Layout-related wording found in extracted text.",
                action=(
                    "Prefer a single-column, ATS-safe template."
                    if locale.startswith("en")
                    else "Tek sütunlu, ATS-güvenli bir şablon tercih edin."
                ),
            )
        )

    summary_section = next((s for s in normalized.sections if s.key == "summary"), None)
    if summary_section and summary_section.status.value == "needsReview":
        score -= 4
        findings.append(
            AtsFinding(
                id="ats_summary_heading",
                severity=FindingSeverity.improve,
                title=(
                    "Use a standard Summary heading"
                    if locale.startswith("en")
                    else "Standart bir Özet başlığı kullanın"
                ),
                why=(
                    "Unusual or incomplete summary blocks can hide content from screeners."
                    if locale.startswith("en")
                    else "Alışılmadık veya eksik özet blokları içeriği gizleyebilir."
                ),
                evidence=summary_section.note or "Summary needs review",
                action=(
                    "Rename to Summary / Professional Summary and keep it concise."
                    if locale.startswith("en")
                    else "Özet / Profesyonel Özet olarak adlandırın ve kısa tutun."
                ),
            )
        )

    score = max(0.0, min(100.0, score))
    if score >= 85:
        summary = (
            "Mostly parser-safe structure with clear contact signals."
            if locale.startswith("en")
            else "Çoğunlukla ayrıştırıcıya uygun yapı ve net iletişim sinyalleri."
        )
    elif score >= 70:
        summary = (
            "Solid ATS foundation with a few extractability gaps."
            if locale.startswith("en")
            else "Sağlam ATS temeli; birkaç ayrıştırılabilirlik boşluğu var."
        )
    else:
        summary = (
            "Important ATS gaps should be fixed before applying."
            if locale.startswith("en")
            else "Başvurmadan önce önemli ATS boşlukları düzeltilmeli."
        )

    return AtsResult(
        score=score,
        summary=summary,
        findings=findings,
        has_standard_headings=not missing_required,
        contact_ok=normalized.has_email,
    )
