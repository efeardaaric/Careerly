from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class SubscriptionTier(str, Enum):
    free = "free"
    pro = "pro"


class SubscriptionStatus(str, Enum):
    active = "active"
    expired = "expired"
    billingIssue = "billingIssue"
    none = "none"


class FeatureId(str, Enum):
    cvAnalysis = "cvAnalysis"
    jobMatch = "jobMatch"
    aiRewrite = "aiRewrite"
    builderCv = "builderCv"
    premiumTemplate = "premiumTemplate"
    translation = "translation"
    jobTailor = "jobTailor"
    readOwnCv = "readOwnCv"


class AccessDeniedReason(str, Enum):
    limitReached = "limitReached"
    requiresPro = "requiresPro"
    billingIssue = "billingIssue"
    subscriptionExpired = "subscriptionExpired"
    offlineStale = "offlineStale"


class AccessDecisionOut(BaseModel):
    featureId: FeatureId
    allowed: bool
    reason: AccessDeniedReason | None = None
    remaining: int | None = None
    limit: int | None = None
    used: int = 0
    resetAt: str | None = None
    requiredTier: SubscriptionTier = SubscriptionTier.pro
    upgradeContext: str | None = None


class UsageCounterOut(BaseModel):
    featureId: FeatureId
    used: int
    limit: int | None = None
    remaining: int | None = None
    resetAt: str | None = None
    period: str


class EntitlementSnapshotOut(BaseModel):
    userId: str
    tier: SubscriptionTier
    status: SubscriptionStatus
    productId: str | None = None
    expiresAt: str | None = None
    decisions: list[AccessDecisionOut]
    usage: list[UsageCounterOut]
    cachedAt: str
    source: str  # server | mock | cache


class EntitlementsResponse(BaseModel):
    entitlement: EntitlementSnapshotOut


class UsageResponse(BaseModel):
    usage: list[UsageCounterOut]
    tier: SubscriptionTier
    status: SubscriptionStatus


class RecordUsageRequest(BaseModel):
    userId: str = "anonymous"
    featureId: FeatureId
    requestId: str = Field(min_length=8, max_length=128)
    tierHint: SubscriptionTier | None = None  # ignored for authority — server decides
    metadata: dict[str, Any] | None = None


class RecordUsageResponse(BaseModel):
    recorded: bool
    duplicate: bool = False
    decision: AccessDecisionOut
    usage: UsageCounterOut


class VerifySubscriptionRequest(BaseModel):
    userId: str = "anonymous"
    platform: str  # ios | android | web | mock
    productId: str
    purchaseToken: str | None = None
    receiptData: str | None = None
    transactionId: str | None = None


class VerifySubscriptionResponse(BaseModel):
    verified: bool
    tier: SubscriptionTier
    status: SubscriptionStatus
    productId: str | None = None
    expiresAt: str | None = None
    message: str
    productionReady: bool = False


class ErrorResponse(BaseModel):
    code: str
    message: str
    details: dict[str, Any] | None = None
