from app.scoring.common import bullets_from, finish, measurable, rule, section_body
from app.scoring.types import FindingDraft
from app.scoring.verbs import starts_with_action


def score_experience(structured: dict, *, early_career: bool) -> object:
    items = list(structured.get("experiences") or [])
    projects = list(structured.get("projects") or [])
    considered = items + (projects if early_career or not items else [])
    body = section_body(structured, "experience") or section_body(structured, "projects")
    bullets = bullets_from(structured, ("experience", "projects") if early_career else ("experience",))
    titled = sum(1 for item in considered if item.get("title"))
    orgs = sum(1 for item in considered if item.get("organization"))
    dated = sum(1 for item in considered if item.get("start") or item.get("end"))
    outcomes = sum(1 for bullet in bullets if measurable(bullet) or starts_with_action(bullet))
    has_history = bool(considered) or len(body) >= 20
    rules = [
        rule(
            "history_present",
            "passed" if has_history else "failed",
            25 if has_history else 0,
            25,
            f"{len(items)} experience item(s) and {len(projects)} project item(s).",
            "Early-career projects count when full-time roles are limited."
            if early_career
            else "A work history is present.",
        ),
        rule(
            "role_clarity",
            "passed" if titled else "partial" if has_history else "failed",
            20 if titled else (8 if has_history else 0),
            20,
            f"{titled} item(s) include a role or project title.",
            "Roles are named.",
        ),
        rule(
            "organization_clarity",
            "passed" if orgs else "partial" if has_history else "failed",
            15 if orgs else (6 if has_history else 0),
            15,
            f"{orgs} item(s) include an organization.",
            "Organizations are named.",
        ),
        rule(
            "date_clarity",
            "passed" if dated else "partial" if has_history else "failed",
            20 if dated else (6 if has_history else 0),
            20,
            f"{dated} item(s) include a recognized date.",
            "Dates are recognizable.",
        ),
        rule(
            "outcome_language",
            "passed" if bullets and outcomes / len(bullets) >= 0.4 else "partial" if outcomes else "failed",
            20 if bullets and outcomes / max(len(bullets), 1) >= 0.4 else (8 if outcomes else 0),
            20,
            f"{outcomes} of {len(bullets)} bullets show an action or measurable outcome.",
            "Bullets describe outcomes.",
        ),
    ]
    findings: list[FindingDraft] = []
    if not has_history:
        findings.append(
            FindingDraft(
                category="experiencePresentation",
                severity="critical",
                title="No experience content detected",
                description="The scorer did not find an experience or project block to evaluate.",
                evidence="Experience and project sections are empty or missing.",
                recommendation="Add the roles or projects that are already true for you.",
                source_section="experience",
            )
        )
    return finish(
        "experiencePresentation",
        "Experience Presentation",
        rules,
        findings,
        "Projects count toward early-career experience. Missing senior tenure is not penalized on its own.",
    )
