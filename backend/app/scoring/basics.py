from app.scoring.common import finish, rule
from app.scoring.types import FindingDraft

_SOFTWARE = {"software", "data", "ai", "cybersecurity", "engineering", "game"}
_PORTFOLIO = {"design", "marketing", "product", "content"}


def score_basics(structured: dict, target_fields: list[str] | None = None) -> object:
    contact = structured.get("contact") or {}
    fields = {item.lower() for item in (target_fields or [])}
    software = bool(fields & _SOFTWARE)
    portfolio_relevant = bool(fields & _PORTFOLIO) or software
    checks = [
        ("name", "fullName", 20, True, "A name was not clearly detected."),
        ("email", "email", 25, True, "No email address was detected."),
        ("phone", "phone", 15, True, "No phone number was detected."),
        ("location", "location", 10, True, "No location was detected."),
        ("linkedin", "linkedIn", 15, True, "No LinkedIn URL was detected."),
    ]
    rules = []
    findings: list[FindingDraft] = []
    for key, field, maximum, required, missing in checks:
        present = bool(contact.get(field))
        rules.append(
            rule(
                key,
                "passed" if present else "failed",
                maximum if present else 0,
                maximum,
                f"{field} is present." if present else missing,
                missing if not present else f"{field} is present.",
            )
        )
        if required and not present and key in {"email", "name"}:
            findings.append(
                FindingDraft(
                    category="basicsContact",
                    severity="critical" if key == "email" else "improve",
                    title="Missing email" if key == "email" else "Name not detected",
                    description="Recruiters and parsers need a reliable way to identify you.",
                    evidence=missing,
                    recommendation="Add this only if it appears on your CV.",
                    source_section="contact",
                )
            )
    github = bool(contact.get("github"))
    rules.append(
        rule(
            "github",
            "passed" if github else ("failed" if software else "not_applicable"),
            10 if github else 0,
            10,
            "GitHub URL detected." if github else "GitHub is not required for this target field.",
            "GitHub helps software and data applications.",
        )
    )
    portfolio = bool(contact.get("portfolio"))
    rules.append(
        rule(
            "portfolio",
            "passed" if portfolio else ("failed" if portfolio_relevant else "not_applicable"),
            5 if portfolio else 0,
            5,
            "A portfolio URL was detected." if portfolio else "Portfolio is not required for this target.",
            "A portfolio URL is useful when the role expects public work.",
        )
    )
    return finish(
        "basicsContact",
        "Basics & Contact",
        rules,
        findings,
        "Contact checks use only values extracted from the CV. Missing GitHub is ignored outside software-like targets.",
    )
