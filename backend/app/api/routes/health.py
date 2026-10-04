from fastapi import APIRouter
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
