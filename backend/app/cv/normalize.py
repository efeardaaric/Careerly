"""Deterministic text cleanup. Does not lowercase the document."""

from __future__ import annotations

import re
import unicodedata


def normalize_text(text: str) -> str:
    cleaned = text.replace("\r\n", "\n").replace("\r", "\n")
    cleaned = cleaned.replace("\u00a0", " ").replace("\u200b", "")
    cleaned = unicodedata.normalize("NFC", cleaned)
    cleaned = cleaned.replace("•", "\n- ").replace("●", "\n- ").replace("▪", "\n- ")
    cleaned = re.sub(r"[ \t]+", " ", cleaned)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned.strip()


def fold_heading(value: str) -> str:
    table = str.maketrans(
        {
            "ç": "c",
            "Ç": "c",
            "ğ": "g",
            "Ğ": "g",
            "ı": "i",
            "İ": "i",
            "I": "i",
            "ö": "o",
            "Ö": "o",
            "ş": "s",
            "Ş": "s",
            "ü": "u",
            "Ü": "u",
        }
    )
    folded = value.translate(table).lower()
    folded = re.sub(r"[^a-z0-9 ]", " ", folded)
    return re.sub(r"\s+", " ", folded).strip()
