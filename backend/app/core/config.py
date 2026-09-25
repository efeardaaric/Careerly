from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = "dev"
    api_prefix: str = "/api/v1"
    max_upload_bytes: int = 10 * 1024 * 1024
    ai_provider: str = "mock"  # mock | openai
    openai_api_key: str | None = None
    openai_base_url: str = "https://api.openai.com/v1"
    openai_model: str = "gpt-4o-mini"
    cors_origins: str = "*"
    log_level: str = "INFO"
    analysis_version: str = "analysis-engine-3.0.0"
    job_match_version: str = "job-match-engine-4.0.0"
    # mock | production (production stub until store credentials exist)
    subscription_verifier: str = "mock"
    # dev | hmac — production requires hmac + AUTH_TOKEN_SECRET
    auth_mode: str = "dev"
    auth_token_secret: str | None = None

    @property
    def is_production(self) -> bool:
        return self.app_env.lower().strip() in {"production", "prod"}

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @model_validator(mode="after")
    def _assert_production_safety(self) -> "Settings":
        if not self.is_production:
            return self
        errors: list[str] = []
        if (self.ai_provider or "").lower() == "mock":
            errors.append(
                "AI_PROVIDER=mock is forbidden when APP_ENV=production "
                "(scoring must not use fixture AI). Set AI_PROVIDER=openai "
                "and OPENAI_API_KEY (EXTERNAL ACTION)."
            )
        if (self.subscription_verifier or "").lower() == "mock":
            errors.append(
                "SUBSCRIPTION_VERIFIER=mock is forbidden in production. "
                "EXTERNAL ACTION: configure store verification credentials."
            )
        if self.cors_origins.strip() == "*":
            errors.append(
                "CORS_ORIGINS=* is forbidden in production. "
                "EXTERNAL ACTION: set explicit allowlist."
            )
        if (self.auth_mode or "").lower() != "hmac":
            errors.append(
                "AUTH_MODE must be hmac when APP_ENV=production "
                "(client X-User-Id is not trusted)."
            )
        if not (self.auth_token_secret or "").strip():
            errors.append(
                "AUTH_TOKEN_SECRET is required when APP_ENV=production. "
                "EXTERNAL ACTION: provision a strong secret (do not commit it)."
            )
        if errors:
            raise ValueError(" | ".join(errors))
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
