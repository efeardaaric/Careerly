"""Durable usage counters with atomic limits and per-user request idempotency."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import HTTPException
from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from app.db.billing import billing_session, insert_for
from app.db.models import UsageCounter, UsageRequest
from app.services.plan_limits import PLAN_LIMITS, FeatureId, SubscriptionTier


def _period_key(period: str, now: datetime | None = None) -> str:
    now = now or datetime.now(UTC)
    if period == "month":
        return f"{now.year}-{now.month:02d}"
    if period == "lifetime":
        return "lifetime"
    return "none"


def _reset_at(period: str, now: datetime | None = None) -> datetime | None:
    now = now or datetime.now(UTC)
    if period != "month":
        return None
    if now.month == 12:
        return datetime(now.year + 1, 1, 1, tzinfo=UTC)
    return datetime(now.year, now.month + 1, 1, tzinfo=UTC)


def reset_usage_store_for_tests() -> None:
    with billing_session() as session:
        session.execute(delete(UsageRequest))
        session.execute(delete(UsageCounter))


def get_used(user_id: str, feature: FeatureId, session: Session | None = None) -> int:
    limit = PLAN_LIMITS[feature]
    period = _period_key(limit.period)
    with billing_session(session) as database:
        return database.scalar(select(UsageCounter.count).where(
            UsageCounter.user_id == user_id,
            UsageCounter.feature_id == feature.value,
            UsageCounter.period == period,
        )) or 0


def is_duplicate(user_id: str, feature: FeatureId, request_id: str) -> bool:
    with billing_session() as session:
        row = session.get(UsageRequest, (user_id, request_id))
        return bool(
            row and row.feature_id == feature.value
            and row.period == _period_key(PLAN_LIMITS[feature].period)
        )


def list_usage(user_id: str, tier: SubscriptionTier) -> list[dict]:
    out: list[dict] = []
    for feature, limit in PLAN_LIMITS.items():
        if not limit.metered and feature == FeatureId.readOwnCv:
            continue
        used = get_used(user_id, feature)
        cap = limit.pro_limit if tier == SubscriptionTier.pro else limit.free_limit
        remaining = None if cap is None else max(0, cap - used)
        out.append(
            {
                "featureId": feature.value,
                "used": used,
                "limit": cap,
                "remaining": remaining,
                "resetAt": (
                    _reset_at(limit.period).isoformat() if _reset_at(limit.period) else None
                ),
                "period": limit.period,
            }
        )
    return out


def record_usage(
    *,
    user_id: str,
    feature: FeatureId,
    request_id: str,
    tier: SubscriptionTier,
    session: Session | None = None,
) -> tuple[bool, bool, int]:
    """Returns (recorded, duplicate, used_after).

    Idempotent: same request_id does not double-charge.
    """
    limit = PLAN_LIMITS[feature]
    if not limit.metered:
        return False, False, get_used(user_id, feature)

    period = _period_key(limit.period)
    cap = limit.pro_limit if tier == SubscriptionTier.pro else limit.free_limit
    with billing_session(session) as database:
        inserted = database.execute(
            insert_for(database, UsageRequest).values(
                user_id=user_id, request_id=request_id,
                feature_id=feature.value, period=period,
            ).on_conflict_do_nothing()
        )
        if inserted.rowcount == 0:
            prior = database.get(UsageRequest, (user_id, request_id))
            if prior.feature_id != feature.value or prior.period != period:
                raise HTTPException(
                    status_code=409,
                    detail={"code": "request_id_conflict", "message": "Request ID already used."},
                )
            return False, True, get_used(user_id, feature, database)
        database.execute(
            insert_for(database, UsageCounter).values(
                user_id=user_id, feature_id=feature.value, period=period, count=0,
            ).on_conflict_do_nothing()
        )
        statement = update(UsageCounter).where(
            UsageCounter.user_id == user_id,
            UsageCounter.feature_id == feature.value,
            UsageCounter.period == period,
        )
        if cap is not None:
            statement = statement.where(UsageCounter.count < cap)
        result = database.execute(statement.values(count=UsageCounter.count + 1))
        if result.rowcount == 0:
            raise HTTPException(
                status_code=403,
                detail={"code": "limitReached", "message": "Plan limit reached."},
            )
        return True, False, get_used(user_id, feature, database)


def peek_remaining(user_id: str, feature: FeatureId, tier: SubscriptionTier) -> tuple[int, int | None, int | None]:
    """Returns (used, limit, remaining)."""
    limit = PLAN_LIMITS[feature]
    used = get_used(user_id, feature)
    cap = limit.pro_limit if tier == SubscriptionTier.pro else limit.free_limit
    remaining = None if cap is None else max(0, cap - used)
    return used, cap, remaining
