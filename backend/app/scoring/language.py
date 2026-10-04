import re

from app.scoring.common import bullets_from, finish, rule


def score_language(structured: dict) -> object:
    bullets = bullets_from(structured, ("experience", "projects", "summary"))
    if not bullets:
        text = " ".join(
            section.get("body", "")
            for section in structured.get("sections") or []
            if section.get("status") != "missing"
        )
        bullets = [line.strip() for line in text.split("\n") if len(line.strip()) >= 12][:30]
    long_ones = sum(1 for bullet in bullets if len(bullet) > 240)
    repeated = 0
    for bullet in bullets:
        words = re.findall(r"[A-Za-zÇĞİÖŞÜçğıöşü']+", bullet.lower())
        for index in range(len(words) - 1):
            if words[index] == words[index + 1] and len(words[index]) > 2:
                repeated += 1
                break
    openings = [" ".join(bullet.split()[:2]).lower() for bullet in bullets if bullet.split()]
    duplicate_openings = len(openings) - len(set(openings))
    applicable = bool(bullets)
    rules = [
        rule(
            "bullet_length",
            "passed" if applicable and long_ones == 0 else "partial" if applicable else "not_applicable",
            40 if applicable and long_ones == 0 else (20 if applicable else 0),
            40,
            f"{long_ones} of {len(bullets)} lines exceed 240 characters.",
            "Lines stay within a readable length.",
        ),
        rule(
            "repeated_words",
            "passed" if applicable and repeated == 0 else "partial" if applicable else "not_applicable",
            30 if applicable and repeated == 0 else (12 if applicable else 0),
            30,
            f"{repeated} line(s) repeat a word immediately.",
            "Immediate word repetition is limited.",
        ),
        rule(
            "duplicate_openings",
            "passed" if applicable and duplicate_openings == 0 else "partial" if applicable else "not_applicable",
            30 if applicable and duplicate_openings == 0 else (12 if applicable else 0),
            30,
            f"{duplicate_openings} bullet opening(s) are repeated.",
            "Bullet openings are not copied.",
        ),
    ]
    return finish(
        "languageGrammar",
        "Language & Grammar",
        rules,
        [],
        "Only deterministic formatting checks run here. Grammar errors are not invented when AI is off.",
    )
