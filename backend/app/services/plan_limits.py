"""Configurable Free / Pro plan limits — not permanent business law.

Tune via settings / env; keep product identifiers separate from displayed prices.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class FeatureId(str, Enum):
    cvAnalysis = "cvAnalysis"
    jobMatch = "jobMatch"
    aiRewrite = "aiRewrite"
    builderCv = "builderCv"
    premiumTemplate = "premiumTemplate"
    translation = "translation"
    jobTailor = "jobTailor"
    # Read-only own CV data is never gated.
    readOwnCv = "readOwnCv"


class SubscriptionTier(str, Enum):
    free = "free"
    pro = "pro"


@dataclass(frozen=True)
class FeatureLimit:
    """None limit means unlimited for that tier."""

    free_limit: int | None
    pro_limit: int | None
    period: str = "month"  # month | lifetime | none
    metered: bool = True


# Central Free/Pro matrix — change here, not in widgets.
PLAN_LIMITS: dict[FeatureId, FeatureLimit] = {
    FeatureId.cvAnalysis: FeatureLimit(free_limit=2, pro_limit=None, period="month"),
    FeatureId.jobMatch: FeatureLimit(free_limit=1, pro_limit=None, period="month"),
    FeatureId.aiRewrite: FeatureLimit(free_limit=3, pro_limit=None, period="month"),
    FeatureId.builderCv: FeatureLimit(
        free_limit=1, pro_limit=None, period="lifetime", metered=True
    ),
    FeatureId.premiumTemplate: FeatureLimit(
        free_limit=0, pro_limit=None, period="none", metered=False
    ),
    FeatureId.translation: FeatureLimit(
        free_limit=0, pro_limit=None, period="none", metered=False
    ),
    FeatureId.jobTailor: FeatureLimit(
        free_limit=0, pro_limit=None, period="none", metered=False
    ),
    FeatureId.readOwnCv: FeatureLimit(
        free_limit=None, pro_limit=None, period="none", metered=False
    ),
}

STORE_PRODUCT_IDS = {
    "monthly": "careerly_pro_monthly",
    "yearly": "careerly_pro_yearly",
}
