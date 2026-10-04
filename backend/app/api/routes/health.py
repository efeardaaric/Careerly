from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory
from fastapi import APIRouter, HTTPException
from sqlalchemy import text

from app.db.session import get_engine
from app.schemas.analysis import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    database = "ok"
    try:
        with get_engine().connect() as connection:
            connection.execute(text("SELECT 1"))
    except Exception:  # noqa: BLE001 — health stays up when the database is down
        database = "unavailable"
    return HealthResponse(status="ok", service="careerly-api", database=database)


@router.get("/ready", response_model=HealthResponse)
def readiness() -> HealthResponse:
    try:
        backend_root = Path(__file__).resolve().parents[3]
        config = Config(str(backend_root / "alembic.ini"))
        config.set_main_option("script_location", str(backend_root / "alembic"))
        expected_revision = ScriptDirectory.from_config(config).get_current_head()
        with get_engine().connect() as connection:
            revision = connection.execute(text("SELECT version_num FROM alembic_version")).scalar()
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Database or migrations unavailable.") from exc
    if revision != expected_revision:
        raise HTTPException(status_code=503, detail="Database migrations are not current.")
    return HealthResponse(status="ok", service="careerly-api", database="ok")
