"""Logging helpers — never log raw CV text or secrets."""

from __future__ import annotations

import logging
import re

from app.core.config import get_settings

_EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
_PHONE = re.compile(r"\+?\d[\d\s().-]{7,}\d")
_BEARER = re.compile(r"(?i)(bearer\s+)[A-Za-z0-9._\-+=/:]+")
_API_KEY = re.compile(r"(?i)(api[_-]?key|secret|token)([\"']?\s*[:=]\s*[\"']?)([^\s\"']+)")


class PiiRedactingFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.msg, str):
            record.msg = redact_pii(record.msg)
        if record.args:
            try:
                record.args = tuple(
                    redact_pii(a) if isinstance(a, str) else a for a in record.args
                )
            except TypeError:
                pass
        return True


def configure_logging() -> None:
    settings = get_settings()
    root = logging.getLogger()
    if not root.handlers:
        logging.basicConfig(
            level=getattr(logging, settings.log_level.upper(), logging.INFO),
            format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
        )
    for handler in logging.root.handlers:
        handler.addFilter(PiiRedactingFilter())


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)


def redact_pii(text: str) -> str:
    """Scrub emails, phones, bearer tokens, and key-like assignments."""
    redacted = _EMAIL.sub("[email]", text)
    redacted = _PHONE.sub("[phone]", redacted)
    redacted = _BEARER.sub(r"\1[redacted]", redacted)
    redacted = _API_KEY.sub(r"\1\2[redacted]", redacted)
    return redacted
