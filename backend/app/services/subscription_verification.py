"""Subscription verification interface.

Production App Store / Play verification requires store credentials and is NOT
faked here. Mock verifier is for local/dev/CI only.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import UTC, datetime, timedelta

from app.core.config import Settings, get_settings
from app.core.security import get_logger
from app.schemas.entitlements import (
    SubscriptionStatus,
    SubscriptionTier,
    VerifySubscriptionRequest,
    VerifySubscriptionResponse,
)

logger = get_logger(__name__)


class SubscriptionVerifier(ABC):
    @abstractmethod
    async def verify(self, request: VerifySubscriptionRequest) -> VerifySubscriptionResponse:
        raise NotImplementedError


class MockSubscriptionVerifier(SubscriptionVerifier):
    """Deterministic mock — never claims productionReady=True."""

    async def verify(self, request: VerifySubscriptionRequest) -> VerifySubscriptionResponse:
        token = (request.purchaseToken or request.receiptData or "").lower()
        # Dev tokens for testing states
        if "expired" in token or "expired" in (request.transactionId or "").lower():
            return VerifySubscriptionResponse(
                verified=True,
                tier=SubscriptionTier.free,
                status=SubscriptionStatus.expired,
                productId=request.productId,
                expiresAt=(datetime.now(UTC) - timedelta(days=1)).isoformat(),
                message="Mock: subscription expired. Own CV data remains readable.",
                productionReady=False,
            )
        if "billing" in token:
            return VerifySubscriptionResponse(
                verified=True,
                tier=SubscriptionTier.pro,
                status=SubscriptionStatus.billingIssue,
                productId=request.productId,
                expiresAt=(datetime.now(UTC) + timedelta(days=7)).isoformat(),
                message="Mock: billing issue — free limits apply until resolved.",
                productionReady=False,
            )
        if request.productId.startswith("careerly_pro") or "pro" in token:
            return VerifySubscriptionResponse(
                verified=True,
                tier=SubscriptionTier.pro,
                status=SubscriptionStatus.active,
                productId=request.productId,
                expiresAt=(datetime.now(UTC) + timedelta(days=30)).isoformat(),
                message="Mock verification succeeded (not production).",
                productionReady=False,
            )
        return VerifySubscriptionResponse(
            verified=False,
            tier=SubscriptionTier.free,
            status=SubscriptionStatus.none,
            productId=request.productId,
            message="Mock: purchase not recognized.",
            productionReady=False,
        )


class ProductionSubscriptionVerifierStub(SubscriptionVerifier):
    """Placeholder until App Store / Play credentials are wired.

    Documents what remains: validate receipt with Apple/Google, map product IDs,
    persist entitlement server-side, rotate secrets via env.
    """

    async def verify(self, request: VerifySubscriptionRequest) -> VerifySubscriptionResponse:
        logger.warning(
            "production_verifier_stub platform=%s product=%s — store credentials not configured",
            request.platform,
            request.productId,
        )
        return VerifySubscriptionResponse(
            verified=False,
            tier=SubscriptionTier.free,
            status=SubscriptionStatus.none,
            productId=request.productId,
            message=(
                "Store verification not configured. Set SUBSCRIPTION_VERIFIER=mock for "
                "local testing, or provide Apple/Google credentials for production."
            ),
            productionReady=False,
        )


# Simple in-memory subscription state for mock users (dev).
_USER_SUBS: dict[str, dict] = {}


def get_user_subscription(user_id: str) -> tuple[SubscriptionTier, SubscriptionStatus, str | None, str | None]:
    row = _USER_SUBS.get(user_id)
    if not row:
        return SubscriptionTier.free, SubscriptionStatus.none, None, None
    return (
        SubscriptionTier(row["tier"]),
        SubscriptionStatus(row["status"]),
        row.get("productId"),
        row.get("expiresAt"),
    )


def set_user_subscription(
    user_id: str,
    *,
    tier: SubscriptionTier,
    status: SubscriptionStatus,
    product_id: str | None,
    expires_at: str | None,
) -> None:
    _USER_SUBS[user_id] = {
        "tier": tier.value,
        "status": status.value,
        "productId": product_id,
        "expiresAt": expires_at,
    }


def reset_subscriptions_for_tests() -> None:
    _USER_SUBS.clear()


def get_subscription_verifier(settings: Settings | None = None) -> SubscriptionVerifier:
    settings = settings or get_settings()
    mode = getattr(settings, "subscription_verifier", "mock").lower().strip()
    if mode == "production":
        return ProductionSubscriptionVerifierStub()
    return MockSubscriptionVerifier()
