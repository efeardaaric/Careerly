"""Reject rewrites that add facts the user never provided."""

from __future__ import annotations

import re
from typing import Any

_NUMBER = re.compile(r"\d+(?:[.,]\d+)?%?")
_TERM = re.compile(r"[A-Za-zÇĞİÖŞÜçğıöşü][\w+#.\-/]*")


def _fold(value: str) -> str:
    return value.casefold().strip(".,;:()[]\"'")


def facts_added(original: str, suggested: str, context: str = "") -> list[str]:
    """Numbers and proper-noun-like terms in `suggested` missing from original + context."""
    known = f"{original}\n{context}"
    known_numbers = set(_NUMBER.findall(known))
    known_terms = {_fold(term) for term in _TERM.findall(known)}
    added: list[str] = []
    for number in _NUMBER.findall(suggested):
        if number not in known_numbers and number not in added:
            added.append(number)
    for index, term in enumerate(_TERM.findall(suggested)):
        folded = _fold(term)
        if not folded or folded in known_terms:
            continue
        looks_named = (index > 0 and term[0].isupper()) or any(ch in term for ch in "+#") or (
            "." in term.strip(".") and len(term) > 2
        )
        if looks_named and term not in added:
            added.append(term)
    return added


def validate_rewrite(
    *,
    original: str,
    raw: Any,
    context: str,
    mode: str,
    prompt_version: str,
) -> dict[str, Any]:
    """Return a safe rewrite payload. Malformed or fact-adding output keeps the original."""
    base = {
        "original": original,
        "suggested": original,
        "reason": "",
        "factsAdded": [],
        "confidence": 0.0,
        "accepted": False,
        "mode": mode,
        "promptVersion": prompt_version,
        "warnings": [],
    }
    if not isinstance(raw, dict) or not isinstance(raw.get("suggested"), str):
        base["warnings"].append("malformed_ai_response")
        return base
    suggested = raw["suggested"].strip()[:2000]
    if not suggested:
        base["warnings"].append("empty_suggestion")
        return base
    declared = raw.get("factsAdded")
    declared_list = [str(item) for item in declared] if isinstance(declared, list) else []
    detected = facts_added(original, suggested, context)
    flagged = declared_list + [item for item in detected if item not in declared_list]
    try:
        confidence = max(0.0, min(1.0, float(raw.get("confidence", 0))))
    except (TypeError, ValueError):
        confidence = 0.0
    base["reason"] = str(raw.get("reason") or "")[:300]
    base["confidence"] = confidence
    base["factsAdded"] = flagged
    if flagged:
        base["warnings"].append("facts_added")
        return base
    if suggested == original:
        base["warnings"].append("no_change")
        return base
    base["suggested"] = suggested
    base["accepted"] = True
    return base
