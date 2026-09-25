from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app
from app.services.plan_limits import PLAN_LIMITS, STORE_PRODUCT_IDS, FeatureId
from app.services.subscription_verification import reset_subscriptions_for_tests
from app.services.usage_tracker import reset_usage_store_for_tests

client = TestClient(app)


def setup_function() -> None:
    reset_usage_store_for_tests()
    reset_subscriptions_for_tests()


def test_plan_limits_configured():
    assert FeatureId.cvAnalysis in PLAN_LIMITS
    assert PLAN_LIMITS[FeatureId.cvAnalysis].free_limit == 2
    assert PLAN_LIMITS[FeatureId.jobMatch].free_limit == 1
    assert "monthly" in STORE_PRODUCT_IDS


def test_entitlements_endpoint_free_default():
    res = client.get(
        "/api/v1/billing/entitlements",
        headers={"X-User-Id": "user_a"},
    )
    assert res.status_code == 200
    data = res.json()["entitlement"]
    assert data["tier"] == "free"
    assert data["status"] == "none"
    cv = next(d for d in data["decisions"] if d["featureId"] == "cvAnalysis")
    assert cv["allowed"] is True
    assert cv["remaining"] == 2
    read = next(d for d in data["decisions"] if d["featureId"] == "readOwnCv")
    assert read["allowed"] is True


def test_usage_record_idempotent():
    headers = {"X-User-Id": "user_b"}
    body = {
        "userId": "user_b",
        "featureId": "cvAnalysis",
        "requestId": "req_idempotent_001",
    }
    r1 = client.post("/api/v1/billing/usage/record", json=body, headers=headers)
    assert r1.status_code == 200
    assert r1.json()["recorded"] is True
    assert r1.json()["duplicate"] is False

    r2 = client.post("/api/v1/billing/usage/record", json=body, headers=headers)
    assert r2.status_code == 200
    assert r2.json()["duplicate"] is True
    assert r2.json()["usage"]["used"] == 1


def test_free_limit_blocks_third_analysis():
    uid = "user_limit"
    headers = {"X-User-Id": uid}
    for i in range(2):
        res = client.post(
            "/api/v1/billing/usage/record",
            headers=headers,
            json={
                "userId": uid,
                "featureId": "cvAnalysis",
                "requestId": f"req_limit_{i}_abcdef",
            },
        )
        assert res.status_code == 200, res.text

    blocked = client.post(
        "/api/v1/billing/usage/record",
        headers=headers,
        json={
            "userId": uid,
            "featureId": "cvAnalysis",
            "requestId": "req_limit_2_abcdef",
        },
    )
    assert blocked.status_code == 403
    assert blocked.json()["detail"]["code"] == "limitReached"


def test_premium_template_requires_pro():
    res = client.post(
        "/api/v1/billing/access/check",
        headers={"X-User-Id": "user_c"},
        json={
            "userId": "user_c",
            "featureId": "premiumTemplate",
            "requestId": "req_template_check1",
        },
    )
    assert res.status_code == 200
    assert res.json()["decision"]["allowed"] is False
    assert res.json()["decision"]["reason"] == "requiresPro"


def test_mock_subscription_verify_pro():
    res = client.post(
        "/api/v1/billing/subscriptions/verify",
        headers={"X-User-Id": "user_pro"},
        json={
            "userId": "user_pro",
            "platform": "mock",
            "productId": "careerly_pro_monthly",
            "purchaseToken": "mock_pro_token",
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["verified"] is True
    assert data["tier"] == "pro"
    assert data["productionReady"] is False

    ent = client.get(
        "/api/v1/billing/entitlements",
        headers={"X-User-Id": "user_pro"},
    )
    assert ent.json()["entitlement"]["tier"] == "pro"
    cv = next(
        d
        for d in ent.json()["entitlement"]["decisions"]
        if d["featureId"] == "cvAnalysis"
    )
    assert cv["limit"] is None


def test_expired_keeps_read_own_cv():
    client.post(
        "/api/v1/billing/subscriptions/verify",
        headers={"X-User-Id": "user_exp"},
        json={
            "userId": "user_exp",
            "platform": "mock",
            "productId": "careerly_pro_monthly",
            "purchaseToken": "mock_expired",
        },
    )
    ent = client.get(
        "/api/v1/billing/entitlements",
        headers={"X-User-Id": "user_exp"},
    ).json()["entitlement"]
    assert ent["status"] == "expired"
    read = next(d for d in ent["decisions"] if d["featureId"] == "readOwnCv")
    assert read["allowed"] is True
