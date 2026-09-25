"""Server-side entitlement policy — owns access decisions (not the client)."""

from __future__ import annotations

from datetime import UTC, datetime

from app.schemas.entitlements import (
    AccessDecisionOut,
    AccessDeniedReason,
    EntitlementSnapshotOut,
    SubscriptionStatus,
    UsageCounterOut,
)
from app.schemas.entitlements import (
    FeatureId as SchemaFeatureId,
)
from app.schemas.entitlements import (
    SubscriptionTier as SchemaTier,
)
from app.services import usage_tracker
from app.services.plan_limits import PLAN_LIMITS, FeatureId, SubscriptionTier


def _to_schema_feature(f: FeatureId) -> SchemaFeatureId:
    return SchemaFeatureId(f.value)


def _to_schema_tier(t: SubscriptionTier) -> SchemaTier:
    return SchemaTier(t.value)


def decide_access(
    *,
    user_id: str,
    feature: FeatureId,
    tier: SubscriptionTier,
    status: SubscriptionStatus,
) -> AccessDecisionOut:
    # Own CV data is never locked.
    if feature == FeatureId.readOwnCv:
        return AccessDecisionOut(
            featureId=_to_schema_feature(feature),
            allowed=True,
            remaining=None,
            limit=None,
            used=0,
            requiredTier=SchemaTier.free,
            upgradeContext=None,
        )

    if status == SubscriptionStatus.billingIssue and tier == SubscriptionTier.pro:
        # Soft: still allow free-tier limits while billing is broken.
        tier = SubscriptionTier.free

    if status == SubscriptionStatus.expired:
        tier = SubscriptionTier.free

    limit_def = PLAN_LIMITS[feature]
    used, cap, remaining = usage_tracker.peek_remaining(user_id, feature, tier)

    # Boolean gates (premium-only features with free_limit=0)
    if not limit_def.metered and cap == 0:
        return AccessDecisionOut(
            featureId=_to_schema_feature(feature),
            allowed=False,
            reason=AccessDeniedReason.requiresPro,
            remaining=0,
            limit=0,
            used=used,
            requiredTier=SchemaTier.pro,
            upgradeContext=f"upgrade_for_{feature.value}",
        )

    if cap is not None and used >= cap:
        reason = AccessDeniedReason.limitReached
        if status == SubscriptionStatus.expired:
            reason = AccessDeniedReason.subscriptionExpired
        elif status == SubscriptionStatus.billingIssue:
            reason = AccessDeniedReason.billingIssue
        return AccessDecisionOut(
            featureId=_to_schema_feature(feature),
            allowed=False,
            reason=reason,
            remaining=0,
            limit=cap,
            used=used,
            resetAt=usage_tracker._reset_at(limit_def.period).isoformat()
            if usage_tracker._reset_at(limit_def.period)
            else None,
            requiredTier=SchemaTier.pro,
            upgradeContext=f"limit_{feature.value}",
        )

    return AccessDecisionOut(
        featureId=_to_schema_feature(feature),
        allowed=True,
        remaining=remaining,
        limit=cap,
        used=used,
        resetAt=usage_tracker._reset_at(limit_def.period).isoformat()
        if usage_tracker._reset_at(limit_def.period)
        else None,
        requiredTier=SchemaTier.free if tier == SubscriptionTier.free else SchemaTier.pro,
        upgradeContext=None,
    )


def build_entitlement_snapshot(
    *,
    user_id: str,
    tier: SubscriptionTier,
    status: SubscriptionStatus,
    product_id: str | None = None,
    expires_at: str | None = None,
    source: str = "server",
) -> EntitlementSnapshotOut:
    decisions = [
        decide_access(user_id=user_id, feature=f, tier=tier, status=status)
        for f in FeatureId
        if f != FeatureId.readOwnCv
    ]
    # Always include readOwnCv as allowed
    decisions.append(
        decide_access(
            user_id=user_id,
            feature=FeatureId.readOwnCv,
            tier=tier,
            status=status,
        )
    )
    usage_rows = [
        UsageCounterOut(**row)
        for row in usage_tracker.list_usage(user_id, tier)
    ]
    return EntitlementSnapshotOut(
        userId=user_id,
        tier=_to_schema_tier(tier),
        status=status,
        productId=product_id,
        expiresAt=expires_at,
        decisions=decisions,
        usage=usage_rows,
        cachedAt=datetime.now(UTC).isoformat(),
        source=source,
    )
