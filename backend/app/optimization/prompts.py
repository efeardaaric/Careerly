"""Rewrite prompts. One prompt per mode; bump PROMPT_VERSION when any text changes."""

from __future__ import annotations

PROMPT_VERSION = "rewrite-2026-10-01"

TRUTH_RULES = """
You rewrite one CV line for Careerly.
Never invent numbers, percentages, revenue, user counts, employers, projects,
job titles, dates, education, certifications, technologies, tools,
responsibilities, achievements, or skills.
Use only facts present in the original line or the CV context provided.
If a measurable result would help but is not given, do not add one.
Keep the language of the original line (Turkish stays Turkish).
Return only JSON with keys:
  suggested (string), reason (string), factsAdded (array of strings), confidence (0-1).
List in factsAdded every fact in suggested that is not in the original line or CV context.
""".strip()

MODES: dict[str, str] = {
    "impact": (
        "Make the line more outcome-oriented: start with a strong action verb and state what "
        "was delivered. Do not add results that are not stated."
    ),
    "concise": "Shorten the line. Remove filler and repetition. Keep every fact.",
    "professional": "Improve tone and word choice so it reads professionally. Keep every fact.",
    "job_targeted": (
        "Use vocabulary from the target job only where the CV already supports it. "
        "Never add a job skill or tool the CV does not mention."
    ),
    "grammar": "Fix grammar, spelling, and punctuation only. Do not change meaning or wording otherwise.",
}

DEFAULT_MODE = "impact"


def rewrite_prompt(mode: str, text: str, cv_context: str, job_context: str | None) -> str:
    instruction = MODES.get(mode, MODES[DEFAULT_MODE])
    parts = [f"Mode: {mode}", instruction, f"Original line:\n{text}"]
    if cv_context:
        parts.append(f"CV context (facts you may use):\n{cv_context[:4000]}")
    if mode == "job_targeted" and job_context:
        parts.append(f"Target job (vocabulary only, not facts about the user):\n{job_context[:2000]}")
    return "\n\n".join(parts)
