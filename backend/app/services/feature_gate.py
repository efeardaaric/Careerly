"""Shared helpers to gate cost features on the server (never trust client isPro)."""

from __future__ import annotations

import uuid

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.services import usage_tracker
from app.services.entitlement_policy import decide_access
from app.services.plan_limits import FeatureId
from app.services.subscription_verification import get_user_subscription


def resolve_user_id(x_user_id: str | None) -> str:
    """Deprecated for production HTTP — prefer AuthPrincipal from require_principal."""
    return (x_user_id or "anonymous").strip() or "anonymous"


def assert_feature_allowed(
    *,
    user_id: str,
    feature: FeatureId,
) -> None:
    tier, status, _, _ = get_user_subscription(user_id)
    decision = decide_access(user_id=user_id, feature=feature, tier=tier, status=status)
    if not decision.allowed:
        raise HTTPException(
            status_code=403,
            detail={
                "code": decision.reason.value if decision.reason else "denied",
                "message": "Plan limit reached or Pro required.",
                "decision": decision.model_dump(),
            },
        )


def record_feature_usage(
    *,
    user_id: str,
    feature: FeatureId,
    request_id: str | None,
    session: Session | None = None,
) -> None:
    request_id = str(uuid.uuid4())
    tier, _, _, _ = get_user_subscription(user_id)
    usage_tracker.record_usage(
        user_id=user_id,
        feature=feature,
        request_id=request_id,
        tier=tier,
        session=session,
    )
