import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import session as database
from app.db.models import Base


@pytest.fixture(autouse=True)
def isolated_database(monkeypatch):
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    monkeypatch.setattr(database, "_engine", engine)
    monkeypatch.setattr(
        database, "_SessionLocal",
        sessionmaker(bind=engine, autoflush=False, expire_on_commit=False),
    )
    yield
    engine.dispose()
