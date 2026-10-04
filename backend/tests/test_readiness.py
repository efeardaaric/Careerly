from fastapi.testclient import TestClient
from sqlalchemy import text

from app.db.session import get_engine
from app.main import app

client = TestClient(app)


def stamp_database(revision):
    with get_engine().begin() as connection:
        connection.execute(text("CREATE TABLE alembic_version (version_num VARCHAR(32))"))
        connection.execute(
            text("INSERT INTO alembic_version VALUES (:revision)"), {"revision": revision},
        )


def test_ready_requires_migrations():
    response = client.get("/ready")
    assert response.status_code == 503


def test_ready_rejects_old_schema():
    stamp_database("0001_cv_pipeline")
    assert client.get("/ready").status_code == 503


def test_ready_accepts_current_schema():
    stamp_database("0002_billing_persistence")
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json()["database"] == "ok"
