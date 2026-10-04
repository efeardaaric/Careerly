import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker

from app.db import session as database
from app.db.models import Base
from app.schemas.entitlements import SubscriptionStatus, SubscriptionTier
from app.services.plan_limits import FeatureId
from app.services.subscription_verification import get_user_subscription, set_user_subscription
from app.services.usage_tracker import get_used, record_usage


def _record(user="durable-user", request="persistent-request"):
    return record_usage(
        user_id=user, feature=FeatureId.cvAnalysis, request_id=request,
        tier=SubscriptionTier.free,
    )


def test_billing_survives_engine_restart(tmp_path, monkeypatch):
    url = f"sqlite:///{tmp_path / 'billing.db'}"
    engine = create_engine(url)
    Base.metadata.create_all(engine)
    monkeypatch.setattr(database, "_engine", engine)
    monkeypatch.setattr(database, "_SessionLocal", sessionmaker(bind=engine))
    _record()
    set_user_subscription(
        "durable-user", tier=SubscriptionTier.pro, status=SubscriptionStatus.active,
        product_id="careerly_pro_monthly",
        expires_at=(datetime.now(UTC) + timedelta(days=1)).isoformat(),
    )
    engine.dispose()
    restarted = create_engine(url)
    monkeypatch.setattr(database, "_engine", restarted)
    monkeypatch.setattr(database, "_SessionLocal", sessionmaker(bind=restarted))
    try:
        assert get_used("durable-user", FeatureId.cvAnalysis) == 1
        assert get_user_subscription("durable-user")[:2] == (
            SubscriptionTier.pro, SubscriptionStatus.active,
        )
        assert _record() == (False, True, 1)
    finally:
        restarted.dispose()


def test_expiry_downgrades_stored_active_subscription():
    set_user_subscription(
        "expired-user", tier=SubscriptionTier.pro, status=SubscriptionStatus.active,
        product_id="careerly_pro_monthly",
        expires_at=(datetime.now(UTC) - timedelta(seconds=1)).isoformat(),
    )
    assert get_user_subscription("expired-user")[:2] == (
        SubscriptionTier.free, SubscriptionStatus.expired,
    )


def test_request_ids_are_scoped_to_users():
    assert _record("alice")[0] is True
    assert _record("bob")[0] is True


def test_request_id_cannot_be_reused_for_another_feature():
    _record()
    with pytest.raises(HTTPException) as error:
        record_usage(
            user_id="durable-user", feature=FeatureId.jobMatch,
            request_id="persistent-request", tier=SubscriptionTier.free,
        )
    assert error.value.status_code == 409
    assert get_used("durable-user", FeatureId.jobMatch) == 0


def test_duplicate_at_limit_does_not_charge_again():
    _record(request="first-request")
    _record(request="second-request")
    assert _record(request="second-request") == (False, True, 2)
    with pytest.raises(HTTPException) as error:
        _record(request="third-request")
    assert error.value.status_code == 403
    assert get_used("durable-user", FeatureId.cvAnalysis) == 2


def test_usage_rolls_back_with_cv_transaction():
    with database.get_session_factory()() as session:
        record_usage(
            user_id="rollback-user", feature=FeatureId.cvAnalysis,
            request_id="rollback-request", tier=SubscriptionTier.free, session=session,
        )
        session.rollback()
    assert get_used("rollback-user", FeatureId.cvAnalysis) == 0


def test_concurrent_workers_cannot_exceed_cap(tmp_path, monkeypatch):
    engine = create_engine(
        f"sqlite:///{tmp_path / 'concurrent.db'}", connect_args={"timeout": 15},
    )
    Base.metadata.create_all(engine)
    monkeypatch.setattr(database, "_engine", engine)
    monkeypatch.setattr(database, "_SessionLocal", sessionmaker(bind=engine))

    def attempt(request_number):
        try:
            return _record(request=f"worker-request-{request_number}")[0]
        except HTTPException as error:
            assert error.status_code == 403
            return False

    try:
        with ThreadPoolExecutor(max_workers=6) as workers:
            assert sum(workers.map(attempt, range(6))) == 2
        assert get_used("durable-user", FeatureId.cvAnalysis) == 2
    finally:
        engine.dispose()


def test_alembic_billing_upgrade_and_downgrade(tmp_path):
    url = f"sqlite:///{tmp_path / 'migration.db'}"
    environment = {**os.environ, "DATABASE_URL": url, "APP_ENV": "dev"}
    backend = Path(__file__).resolve().parents[1]
    for target in ["0001_cv_pipeline", "head"]:
        subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", target],
            cwd=backend, env=environment, check=True, capture_output=True,
        )
    engine = create_engine(url)
    try:
        assert {"usage_counters", "usage_requests", "user_subscriptions"} <= set(
            inspect(engine).get_table_names()
        )
        subprocess.run(
            [sys.executable, "-m", "alembic", "downgrade", "0001_cv_pipeline"],
            cwd=backend, env=environment, check=True, capture_output=True,
        )
        assert "usage_counters" not in inspect(engine).get_table_names()
        assert "cv_documents" in inspect(engine).get_table_names()
    finally:
        engine.dispose()
