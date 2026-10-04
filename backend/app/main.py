import logging
import time
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.router import api_router
from app.core.config import get_settings
from app.core.security import configure_logging
from app.db.session import init_db

configure_logging()
settings = get_settings()
logger = logging.getLogger("careerly.api")


@asynccontextmanager
async def lifespan(_app: FastAPI):
    # Dev/test create tables. Production uses Alembic (`alembic upgrade head`).
    init_db()
    yield


app = FastAPI(
    title="Careerly API",
    version=settings.scoring_engine_version,
    description="CV parse and deterministic scoring. The Flutter app never calls a model provider.",
    lifespan=lifespan,
)


@app.middleware("http")
async def request_context(request: Request, call_next):
    request_id = request.headers.get("x-request-id") or str(uuid.uuid4())
    started = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        logger.exception("request_failed request_id=%s route=%s", request_id, request.url.path)
        response = JSONResponse(
            status_code=500,
            content={"error": {"code": "ANALYSIS_FAILED", "message": "Analysis failed."}},
        )
    response.headers["X-Request-Id"] = request_id
    logger.info(
        "request request_id=%s route=%s status=%s duration_ms=%s",
        request_id,
        request.url.path,
        response.status_code,
        int((time.perf_counter() - started) * 1000),
    )
    return response

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/")
async def root() -> dict[str, str]:
    return {
        "service": "careerly-api",
        "health": "/health",
        "parse": f"{settings.api_prefix}/cvs/parse",
        "docs": "/docs",
    }
