from __future__ import annotations

import os

import pytest
from fastapi.testclient import TestClient

# Ensure production validator does not fire during normal imports.
os.environ.setdefault("APP_ENV", "dev")
os.environ.setdefault("AUTH_MODE", "dev")

from app.core.auth import mint_hmac_token, verify_bearer_token
from app.core.config import Settings
from app.main import app

client = TestClient(app)


def test_dev_accepts_x_user_id_header():
    res = client.get("/api/v1/billing/entitlements", headers={"X-User-Id": "user_a"})
    assert res.status_code == 200
    assert res.json()["entitlement"]["userId"] == "user_a"


def test_dev_bearer_dev_token_binds_user():
    res = client.get(
        "/api/v1/billing/entitlements",
        headers={"Authorization": "Bearer dev:user_bearer"},
    )
    assert res.status_code == 200
    assert res.json()["entitlement"]["userId"] == "user_bearer"


def test_hmac_token_roundtrip():
    settings = Settings(
        app_env="dev",
        auth_mode="hmac",
        auth_token_secret="unit-test-secret-not-for-prod",
        ai_provider="mock",
        subscription_verifier="mock",
        cors_origins="*",
    )
    token = mint_hmac_token("alice", secret=settings.auth_token_secret)  # type: ignore[arg-type]
    uid = verify_bearer_token(token, settings=settings)
    assert uid == "alice"


def test_idor_record_usage_rejects_mismatched_body_user():
    # Authenticated as user_a but body claims user_b → 403
    res = client.post(
        "/api/v1/billing/usage/record",
        headers={"X-User-Id": "user_a", "X-Request-Id": "req_idor_001234"},
        json={
            "userId": "user_b",
            "featureId": "cvAnalysis",
            "requestId": "req_idor_001234",
        },
    )
    assert res.status_code == 403
    assert res.json()["detail"]["code"] == "idor_blocked"


def test_production_settings_reject_mock_ai():
    with pytest.raises(ValueError, match="AI_PROVIDER"):
        Settings(
            app_env="production",
            ai_provider="mock",
            subscription_verifier="production",
            cors_origins="https://app.example.com",
            auth_mode="hmac",
            auth_token_secret="x" * 32,
        )


def test_hmac_mode_rejects_empty_token():
    settings = Settings(
        app_env="dev",
        ai_provider="mock",
        subscription_verifier="mock",
        cors_origins="*",
        auth_mode="hmac",
        auth_token_secret="y" * 32,
    )
    from fastapi import HTTPException

    with pytest.raises(HTTPException):
        verify_bearer_token("", settings=settings)
