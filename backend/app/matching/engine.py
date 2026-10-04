"""Job match compares a saved StructuredCV with a job description.

This module is a boundary only. Scoring a CV does not call it.
"""

from __future__ import annotations


def match_cv(structured_cv: dict, job_description: str) -> dict:
    raise NotImplementedError(
        "Job match uses the saved structured CV. It is not part of CV scoring."
    )
