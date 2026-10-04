"""Subscription verification interface.

Production App Store / Play verification requires store credentials and is NOT
faked here. Mock verifier is for local/dev/CI only.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import UTC, datetime, timedelta

from sqlalchemy import delete

from app.core.config import Settings, get_settings
from app.core.security import get_logger
from app.db.billing import billing_session, insert_for
from app.db.models import UserSubscription
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


def get_user_subscription(user_id: str) -> tuple[SubscriptionTier, SubscriptionStatus, str | None, str | None]:
    with billing_session() as session:
        row = session.get(UserSubscription, user_id)
        if not row:
            return SubscriptionTier.free, SubscriptionStatus.none, None, None
        status = SubscriptionStatus(row.status)
        if row.expires_at:
            expiry = datetime.fromisoformat(row.expires_at)
            if expiry.tzinfo is None:
                expiry = expiry.replace(tzinfo=UTC)
            if expiry <= datetime.now(UTC):
                status = SubscriptionStatus.expired
        tier = SubscriptionTier(row.tier)
        if status != SubscriptionStatus.active:
            tier = SubscriptionTier.free
        return tier, status, row.product_id, row.expires_at


def set_user_subscription(
    user_id: str,
    *,
    tier: SubscriptionTier,
    status: SubscriptionStatus,
    product_id: str | None,
    expires_at: str | None,
) -> None:
    values = {
        "tier": tier.value, "status": status.value,
        "product_id": product_id, "expires_at": expires_at,
    }
    with billing_session() as session:
        session.execute(
            insert_for(session, UserSubscription).values(user_id=user_id, **values)
            .on_conflict_do_update(index_elements=["user_id"], set_=values)
        )


def reset_subscriptions_for_tests() -> None:
    with billing_session() as session:
        session.execute(delete(UserSubscription))


def get_subscription_verifier(settings: Settings | None = None) -> SubscriptionVerifier:
    settings = settings or get_settings()
    mode = getattr(settings, "subscription_verifier", "mock").lower().strip()
    if mode == "production":
        return ProductionSubscriptionVerifierStub()
    return MockSubscriptionVerifier()
