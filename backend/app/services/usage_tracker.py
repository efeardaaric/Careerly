"""In-memory usage tracker with request-id idempotency.

Phase 6: temporary store suitable for mock/dev. Production should swap for durable DB.
Never log CV/JD/prompt content — only featureId + requestId + counts.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime
from threading import Lock

from app.core.security import get_logger
from app.services.plan_limits import PLAN_LIMITS, FeatureId, SubscriptionTier

logger = get_logger(__name__)


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


@dataclass
class UsageStore:
    # userId -> featureId -> periodKey -> count
    counts: dict[str, dict[str, dict[str, int]]] = field(default_factory=dict)
    # requestId -> recorded payload fingerprint
    seen_requests: dict[str, str] = field(default_factory=dict)
    lock: Lock = field(default_factory=Lock)


_STORE = UsageStore()


def reset_usage_store_for_tests() -> None:
    with _STORE.lock:
        _STORE.counts.clear()
        _STORE.seen_requests.clear()


def get_used(user_id: str, feature: FeatureId) -> int:
    limit = PLAN_LIMITS[feature]
    period = _period_key(limit.period)
    with _STORE.lock:
        return _STORE.counts.get(user_id, {}).get(feature.value, {}).get(period, 0)


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
) -> tuple[bool, bool, int]:
    """Returns (recorded, duplicate, used_after).

    Idempotent: same request_id does not double-charge.
    """
    limit = PLAN_LIMITS[feature]
    if not limit.metered:
        return False, False, get_used(user_id, feature)

    period = _period_key(limit.period)
    fingerprint = f"{user_id}:{feature.value}:{period}"

    with _STORE.lock:
        prior = _STORE.seen_requests.get(request_id)
        if prior == fingerprint:
            used = _STORE.counts.get(user_id, {}).get(feature.value, {}).get(period, 0)
            logger.info(
                "usage_duplicate user=%s feature=%s request_id=%s used=%s",
                user_id,
                feature.value,
                request_id[:12],
                used,
            )
            return False, True, used

        if prior is not None:
            # Same request id reused for different action — treat as duplicate reject.
            used = _STORE.counts.get(user_id, {}).get(feature.value, {}).get(period, 0)
            return False, True, used

        bucket = _STORE.counts.setdefault(user_id, {}).setdefault(feature.value, {})
        used = bucket.get(period, 0) + 1
        bucket[period] = used
        _STORE.seen_requests[request_id] = fingerprint

        # Bound memory of request ids
        if len(_STORE.seen_requests) > 5000:
            # Drop arbitrary oldest half by rebuilding
            keys = list(_STORE.seen_requests.keys())[:2500]
            for k in keys:
                _STORE.seen_requests.pop(k, None)

    logger.info(
        "usage_recorded user=%s feature=%s request_id=%s used=%s",
        user_id,
        feature.value,
        request_id[:12],
        used,
    )
    return True, False, used


def peek_remaining(user_id: str, feature: FeatureId, tier: SubscriptionTier) -> tuple[int, int | None, int | None]:
    """Returns (used, limit, remaining)."""
    limit = PLAN_LIMITS[feature]
    used = get_used(user_id, feature)
    cap = limit.pro_limit if tier == SubscriptionTier.pro else limit.free_limit
    remaining = None if cap is None else max(0, cap - used)
    return used, cap, remaining
