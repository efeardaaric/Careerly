from uuid import uuid4

import httpx
import pytest
from fastapi import HTTPException

from app.core.auth import require_principal, verify_supabase_token
from app.core.config import Settings


def supabase_settings(**overrides):
    return Settings(
        auth_mode="supabase",
        supabase_url="https://example.supabase.co",
        supabase_publishable_key="sb_publishable_test",
        **overrides,
    )


def mock_auth(monkeypatch, status, payload):
    original = httpx.AsyncClient

    def respond(request):
        assert str(request.url) == "https://example.supabase.co/auth/v1/user"
        assert request.headers["apikey"] == "sb_publishable_test"
        assert request.headers["authorization"] == "Bearer signed-token"
        return httpx.Response(status, json=payload)

    monkeypatch.setattr(
        httpx, "AsyncClient",
        lambda **kwargs: original(transport=httpx.MockTransport(respond), **kwargs),
    )


@pytest.mark.asyncio
async def test_verified_uuid_overrides_spoofed_header(monkeypatch):
    user_id = str(uuid4())
    mock_auth(monkeypatch, 200, {"id": user_id})
    principal = await require_principal(
        authorization="Bearer signed-token",
        x_user_id="another-user",
        settings=supabase_settings(),
    )
    assert principal.user_id == user_id


@pytest.mark.asyncio
async def test_supabase_requires_bearer_even_in_development():
    with pytest.raises(HTTPException) as error:
        await require_principal(
            authorization=None, x_user_id="spoofed", settings=supabase_settings(),
        )
    assert error.value.status_code == 401


@pytest.mark.asyncio
@pytest.mark.parametrize("status,expected", [(401, 401), (403, 401), (500, 503), (302, 503)])
async def test_supabase_errors_fail_closed(monkeypatch, status, expected):
    mock_auth(monkeypatch, status, {})
    with pytest.raises(HTTPException) as error:
        await verify_supabase_token("signed-token", settings=supabase_settings())
    assert error.value.status_code == expected


@pytest.mark.asyncio
async def test_invalid_identity_rejected(monkeypatch):
    mock_auth(monkeypatch, 200, {"id": "not-a-uuid"})
    with pytest.raises(HTTPException) as error:
        await verify_supabase_token("signed-token", settings=supabase_settings())
    assert error.value.status_code == 401


def test_production_supabase_does_not_require_hmac_secret():
    settings = supabase_settings(
        app_env="production", ai_provider="openai",
        subscription_verifier="production", cors_origins="https://app.example.com",
    )
    assert settings.auth_token_secret is None


@pytest.mark.parametrize("overrides", [
    {"supabase_url": "http://example.supabase.co", "supabase_publishable_key": "key"},
    {"supabase_url": "https://example.supabase.co"},
])
def test_missing_or_insecure_configuration_rejected(overrides):
    with pytest.raises(ValueError):
        Settings(auth_mode="supabase", **overrides)
