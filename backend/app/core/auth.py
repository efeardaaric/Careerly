"""Request authentication — production binds user id from verified token only."""

from __future__ import annotations

import hashlib
import hmac
import time
from dataclasses import dataclass

from fastapi import Depends, Header, HTTPException

from app.core.config import Settings, get_settings


@dataclass(frozen=True)
class AuthPrincipal:
    user_id: str
    auth_mode: str


def _unauthorized(message: str) -> HTTPException:
    return HTTPException(
        status_code=401,
        detail={"code": "unauthorized", "message": message},
    )


def verify_bearer_token(token: str, *, settings: Settings) -> str:
    """Return verified user_id from Bearer token.

    Supported formats:
    - AUTH_MODE=dev: `dev:<user_id>` (local/CI only)
    - AUTH_MODE=hmac: `v1.<user_id>.<exp>.<sig>` where
      sig = hex(HMAC_SHA256(secret, f"{user_id}.{exp}"))
    """
    mode = (settings.auth_mode or "dev").lower().strip()
    if mode == "dev":
        if settings.is_production:
            raise _unauthorized(
                "AUTH_MODE=dev is forbidden when APP_ENV=production."
            )
        if token.startswith("dev:"):
            uid = token[4:].strip()
            if not uid:
                raise _unauthorized("Empty dev token user id.")
            return uid
        if token.strip():
            return token.strip()
        raise _unauthorized("Missing token.")

    if mode == "hmac":
        secret = settings.auth_token_secret
        if not secret:
            raise _unauthorized(
                "EXTERNAL ACTION REQUIRED: set AUTH_TOKEN_SECRET for AUTH_MODE=hmac."
            )
        parts = token.split(".")
        if len(parts) != 4 or parts[0] != "v1":
            raise _unauthorized("Malformed access token.")
        _, user_id, exp_s, sig = parts
        try:
            exp = int(exp_s)
        except ValueError as exc:
            raise _unauthorized("Invalid token expiry.") from exc
        if exp < int(time.time()):
            raise _unauthorized("Token expired.")
        expected = hmac.new(
            secret.encode("utf-8"),
            f"{user_id}.{exp}".encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(expected, sig):
            raise _unauthorized("Invalid token signature.")
        if not user_id.strip():
            raise _unauthorized("Empty user id in token.")
        return user_id

    raise _unauthorized(f"Unsupported AUTH_MODE={mode}.")


def mint_hmac_token(user_id: str, *, secret: str, ttl_seconds: int = 3600) -> str:
    """Test helper — mint a valid HMAC token."""
    exp = int(time.time()) + ttl_seconds
    sig = hmac.new(
        secret.encode("utf-8"),
        f"{user_id}.{exp}".encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return f"v1.{user_id}.{exp}.{sig}"


async def require_principal(
    authorization: str | None = Header(default=None),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    settings: Settings = Depends(get_settings),
) -> AuthPrincipal:
    """Resolve authenticated principal.

    Production (APP_ENV=production): Authorization Bearer required; X-User-Id ignored.
    Dev: Bearer preferred; else X-User-Id for local TestClient compatibility.
    """
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization.split(" ", 1)[1].strip()
        user_id = verify_bearer_token(token, settings=settings)
        return AuthPrincipal(user_id=user_id, auth_mode=settings.auth_mode)

    if settings.is_production:
        raise _unauthorized(
            "Authorization Bearer token required in production. "
            "Client-supplied X-User-Id is not accepted."
        )

    uid = (x_user_id or "anonymous").strip() or "anonymous"
    return AuthPrincipal(user_id=uid, auth_mode="dev-header")
