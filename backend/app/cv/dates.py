"""Conservative date recognition. Original strings are preserved."""

from __future__ import annotations

import re

_PRESENT = {
    "present",
    "current",
    "now",
    "halen",
    "devam",
    "gunumuz",
    "günümüz",
    "simdi",
    "şimdi",
}
_MONTHS = {
    "jan": 1,
    "january": 1,
    "feb": 2,
    "february": 2,
    "mar": 3,
    "march": 3,
    "apr": 4,
    "april": 4,
    "may": 5,
    "jun": 6,
    "june": 6,
    "jul": 7,
    "july": 7,
    "aug": 8,
    "august": 8,
    "sep": 9,
    "sept": 9,
    "september": 9,
    "oct": 10,
    "october": 10,
    "nov": 11,
    "november": 11,
    "dec": 12,
    "december": 12,
    "eyl": 9,
    "eylul": 9,
    "eylül": 9,
    "ocak": 1,
    "subat": 2,
    "şubat": 2,
    "mart": 3,
    "nisan": 4,
    "mayis": 5,
    "mayıs": 5,
    "haziran": 6,
    "temmuz": 7,
    "agustos": 8,
    "ağustos": 8,
    "ekim": 10,
    "kasim": 11,
    "kasım": 11,
    "aralik": 12,
    "aralık": 12,
}


def parse_date_token(raw: str) -> dict | None:
    text = raw.strip()
    if not text:
        return None
    lower = text.lower()
    if lower in _PRESENT:
        return {"original": text, "precision": "present", "year": None, "month": None}
    year_only = re.fullmatch(r"(19|20)\d{2}", text)
    if year_only:
        return {"original": text, "precision": "year", "year": int(text), "month": None}
    month_year = re.fullmatch(r"([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+((?:19|20)\d{2})", text)
    if month_year and month_year.group(1).lower() in _MONTHS:
        return {
            "original": text,
            "precision": "month",
            "year": int(month_year.group(2)),
            "month": _MONTHS[month_year.group(1).lower()],
        }
    numeric = re.fullmatch(r"(0?[1-9]|1[0-2])[/-]((?:19|20)\d{2})", text)
    if numeric:
        return {
            "original": text,
            "precision": "month",
            "year": int(numeric.group(2)),
            "month": int(numeric.group(1)),
        }
    iso = re.fullmatch(r"((?:19|20)\d{2})-(0?[1-9]|1[0-2])", text)
    if iso:
        return {
            "original": text,
            "precision": "month",
            "year": int(iso.group(1)),
            "month": int(iso.group(2)),
        }
    return None


def date_structure_score(text: str) -> float:
    tokens = re.findall(
        r"(?:19|20)\d{2}|[A-Za-zÇĞİÖŞÜçğıöşü]+\s+(?:19|20)\d{2}|(?:0?[1-9]|1[0-2])[/-](?:19|20)\d{2}",
        text,
    )
    if not tokens:
        return 0.4
    parsed = sum(1 for token in tokens if parse_date_token(token.strip()))
    return parsed / max(len(tokens), 1)
