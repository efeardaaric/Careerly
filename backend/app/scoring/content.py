from app.scoring.common import bullets_from, finish, measurable, rule
from app.scoring.types import FindingDraft
from app.scoring.verbs import starts_with_action

_WEAK = (
    "responsible for",
    "worked on",
    "helped with",
    "various tasks",
    "görev aldım",
    "gorev aldim",
    "çalıştım",
    "calistim",
)


def score_content(structured: dict, *, early_career: bool) -> object:
    keys = ("experience", "projects", "volunteer") if early_career else ("experience", "projects")
    bullets = bullets_from(structured, keys)
    total = len(bullets)
    quantified = sum(1 for bullet in bullets if measurable(bullet))
    actions = sum(1 for bullet in bullets if starts_with_action(bullet))
    weak = sum(1 for bullet in bullets if any(phrase in bullet.lower() for phrase in _WEAK))
    quant_ratio = quantified / total if total else 0
    action_ratio = actions / total if total else 0
    rules = [
        rule(
            "bullet_count",
            "passed" if total >= 4 else "partial" if total >= 1 else "failed",
            20 if total >= 4 else (10 if total >= 1 else 0),
            20,
            f"{total} experience/project bullets were read.",
            "Enough bullets exist to judge impact.",
        ),
        rule(
            "quantified_results",
            "passed" if quant_ratio >= 0.35 else "partial" if quantified else "failed",
            round(30 * min(1, quant_ratio / 0.35), 2) if total else 0,
            30,
            f"{quantified} of {total} experience/project bullets includes a measurable result.",
            "Measurable results are present.",
        ),
        rule(
            "action_verbs",
            "passed" if action_ratio >= 0.5 else "partial" if actions else "failed",
            round(25 * min(1, action_ratio / 0.5), 2) if total else 0,
            25,
            f"{actions} of {total} bullets start with a recognized action verb.",
            "Bullets lead with a concrete action.",
        ),
        rule(
            "weak_phrasing",
            "passed" if total and weak == 0 else "partial" if total else "failed",
            15 if total and weak == 0 else (8 if total and weak < total else 0),
            15,
            f"{weak} of {total} bullets use a generic opener.",
            "Generic openers are limited.",
        ),
    ]
    findings = []
    if total and quantified < max(1, total // 3):
        findings.append(
            FindingDraft(
                category="contentImpact",
                severity="improve",
                title="Limited measurable impact",
                description="Careerly only counts results that are already written in the CV.",
                evidence=f"{quantified} of {total} experience/project bullets includes a measurable result.",
                recommendation="Where possible, add a verified result, scale, count or outcome.",
                source_section="experience",
            )
        )
    return finish(
        "contentImpact",
        "Content & Impact",
        rules,
        findings,
        "Impact is scored from bullet counts, action verbs, and numbers already present. No metric is invented.",
    )
