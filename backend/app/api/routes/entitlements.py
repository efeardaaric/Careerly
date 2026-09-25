from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth import AuthPrincipal, require_principal
from app.core.config import Settings, get_settings
from app.schemas.entitlements import (
    EntitlementsResponse,
    ErrorResponse,
    RecordUsageRequest,
    RecordUsageResponse,
    UsageCounterOut,
    UsageResponse,
    VerifySubscriptionRequest,
    VerifySubscriptionResponse,
)
from app.services import usage_tracker
from app.services.entitlement_policy import build_entitlement_snapshot, decide_access
from app.services.plan_limits import FeatureId as LimitFeatureId
from app.services.subscription_verification import (
    get_subscription_verifier,
    get_user_subscription,
    set_user_subscription,
)

router = APIRouter(prefix="/billing", tags=["billing-entitlements"])


@router.get(
    "/entitlements",
    response_model=EntitlementsResponse,
    responses={400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}},
)
async def get_entitlements(
    principal: AuthPrincipal = Depends(require_principal),
) -> EntitlementsResponse:
    uid = principal.user_id
    tier, status, product_id, expires_at = get_user_subscription(uid)
    snap = build_entitlement_snapshot(
        user_id=uid,
        tier=tier,
        status=status,
        product_id=product_id,
        expires_at=expires_at,
        source="server",
    )
    return EntitlementsResponse(entitlement=snap)


@router.get("/usage", response_model=UsageResponse)
async def get_usage(
    principal: AuthPrincipal = Depends(require_principal),
) -> UsageResponse:
    uid = principal.user_id
    tier, status, _, _ = get_user_subscription(uid)
    rows = [UsageCounterOut(**r) for r in usage_tracker.list_usage(uid, tier)]
    return UsageResponse(usage=rows, tier=tier, status=status)


@router.post(
    "/usage/record",
    response_model=RecordUsageResponse,
    responses={403: {"model": ErrorResponse}, 400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}},
)
async def record_usage(
    body: RecordUsageRequest,
    principal: AuthPrincipal = Depends(require_principal),
) -> RecordUsageResponse:
    # IDOR prevention: never trust body.userId — bind to verified principal.
    uid = principal.user_id
    if body.userId.strip() and body.userId.strip() != uid:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "idor_blocked",
                "message": "userId in body must match authenticated principal.",
            },
        )
    tier, status, _, _ = get_user_subscription(uid)
    feature = LimitFeatureId(body.featureId.value)

    decision = decide_access(user_id=uid, feature=feature, tier=tier, status=status)
    if not decision.allowed:
        raise HTTPException(
            status_code=403,
            detail={
                "code": (decision.reason.value if decision.reason else "denied"),
                "message": "Feature not allowed under current plan.",
                "decision": decision.model_dump(),
            },
        )

    recorded, duplicate, used = usage_tracker.record_usage(
        user_id=uid,
        feature=feature,
        request_id=body.requestId,
        tier=tier,
    )
    decision = decide_access(user_id=uid, feature=feature, tier=tier, status=status)
    usage_row = next(
        (u for u in usage_tracker.list_usage(uid, tier) if u["featureId"] == feature.value),
        {
            "featureId": feature.value,
            "used": used,
            "limit": decision.limit,
            "remaining": decision.remaining,
            "resetAt": decision.resetAt,
            "period": "month",
        },
    )
    return RecordUsageResponse(
        recorded=recorded,
        duplicate=duplicate,
        decision=decision,
        usage=UsageCounterOut(**usage_row),
    )


@router.post(
    "/subscriptions/verify",
    response_model=VerifySubscriptionResponse,
    responses={401: {"model": ErrorResponse}, 403: {"model": ErrorResponse}},
)
async def verify_subscription(
    body: VerifySubscriptionRequest,
    settings: Settings = Depends(get_settings),
    principal: AuthPrincipal = Depends(require_principal),
) -> VerifySubscriptionResponse:
    uid = principal.user_id
    if body.userId.strip() and body.userId.strip() != uid:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "idor_blocked",
                "message": "Cannot verify subscription for another user.",
            },
        )
    verifier = get_subscription_verifier(settings)
    # Force verified user id to principal.
    body = body.model_copy(update={"userId": uid})
    result = await verifier.verify(body)
    if result.verified:
        set_user_subscription(
            uid,
            tier=result.tier,
            status=result.status,
            product_id=result.productId,
            expires_at=result.expiresAt,
        )
    return result


@router.post(
    "/access/check",
    response_model=RecordUsageResponse,
    responses={401: {"model": ErrorResponse}},
)
async def check_access(
    body: RecordUsageRequest,
    principal: AuthPrincipal = Depends(require_principal),
) -> RecordUsageResponse:
    """Pre-flight check without recording usage."""
    uid = principal.user_id
    if body.userId.strip() and body.userId.strip() != uid:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "idor_blocked",
                "message": "userId in body must match authenticated principal.",
            },
        )
    tier, status, _, _ = get_user_subscription(uid)
    feature = LimitFeatureId(body.featureId.value)
    decision = decide_access(user_id=uid, feature=feature, tier=tier, status=status)
    usage_row = next(
        (u for u in usage_tracker.list_usage(uid, tier) if u["featureId"] == feature.value),
        {
            "featureId": feature.value,
            "used": decision.used,
            "limit": decision.limit,
            "remaining": decision.remaining,
            "resetAt": decision.resetAt,
            "period": "month",
        },
    )
    return RecordUsageResponse(
        recorded=False,
        duplicate=False,
        decision=decision,
        usage=UsageCounterOut(**usage_row),
    )
