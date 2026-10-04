from app.scoring.common import active_sections, finish, rule
from app.scoring.types import FindingDraft


def score_ats(structured: dict) -> "object":
    sections = active_sections(structured)
    keys = {section.get("key") for section in sections}
    text_len = sum(len(section.get("body") or "") for section in sections)
    contact = structured.get("contact") or {}
    date_quality = float((structured.get("sourceMetadata") or {}).get("dateQuality") or 0)
    confidence = int(structured.get("parserConfidence") or 0)
    rules = [
        rule(
            "text_extractable",
            "passed" if text_len >= 40 else "failed",
            20 if text_len >= 40 else 0,
            20,
            f"Extracted section text length is {text_len} characters.",
            "The file contains extractable text.",
        ),
        rule(
            "email_readable",
            "passed" if contact.get("email") else "failed",
            15 if contact.get("email") else 0,
            15,
            "An email address was read from the CV." if contact.get("email") else "No email address was detected.",
            "Email is readable by a parser.",
        ),
        rule(
            "phone_readable",
            "passed" if contact.get("phone") else "failed",
            10 if contact.get("phone") else 0,
            10,
            "A phone number was read from the CV." if contact.get("phone") else "No phone number was detected.",
            "Phone is readable by a parser.",
        ),
        rule(
            "recognized_headings",
            "passed" if len(keys) >= 3 else "partial" if keys else "failed",
            20 if len(keys) >= 3 else (8 if keys else 0),
            20,
            f"{len(keys)} recognized section heading(s).",
            "Standard headings help ATS map content.",
        ),
        rule(
            "experience_section",
            "passed" if "experience" in keys or "projects" in keys else "failed",
            15 if "experience" in keys or "projects" in keys else 0,
            15,
            "Experience or projects heading detected."
            if "experience" in keys or "projects" in keys
            else "Neither experience nor projects was detected.",
            "Work history is findable.",
        ),
        rule(
            "education_section",
            "passed" if "education" in keys else "failed",
            10 if "education" in keys else 0,
            10,
            "Education heading detected." if "education" in keys else "Education heading was not detected.",
            "Education is findable.",
        ),
        rule(
            "skills_section",
            "passed" if "skills" in keys else "failed",
            10 if "skills" in keys else 0,
            10,
            "Skills heading detected." if "skills" in keys else "Skills heading was not detected.",
            "Skills are findable.",
        ),
        rule(
            "date_parsing",
            "passed" if date_quality >= 0.6 else "partial" if date_quality > 0 else "failed",
            10 if date_quality >= 0.6 else (4 if date_quality > 0 else 0),
            10,
            f"Date recognition quality is {date_quality:.2f}.",
            "Dates use a recognizable pattern.",
        ),
    ]
    # Parser confidence is evidence, not a fake layout claim.
    rules.append(
        rule(
            "parser_confidence",
            "passed" if confidence >= 70 else "partial" if confidence >= 40 else "failed",
            10 if confidence >= 70 else (5 if confidence >= 40 else 0),
            10,
            f"Parser confidence is {confidence}.",
            "The parser could structure most of the document.",
        )
    )
    findings = []
    if "experience" not in keys and "projects" not in keys:
        findings.append(
            FindingDraft(
                category="atsCompatibility",
                severity="critical",
                title="Experience heading not detected",
                description="Parsers need a recognizable experience or projects heading.",
                evidence="No experience or projects section was classified.",
                recommendation="Add a heading such as Experience or Projects.",
                source_section="experience",
            )
        )
    return finish(
        "atsCompatibility",
        "ATS Compatibility",
        rules,
        findings,
        "Checks only signals this parser can verify. Layout claims such as single-column are not scored.",
    )
