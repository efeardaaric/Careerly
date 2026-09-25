from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import get_settings
from app.core.security import configure_logging

configure_logging()
settings = get_settings()

app = FastAPI(
    title="Careerly Analysis API",
    version=settings.analysis_version,
    description="Temporary CV analysis pipeline. No AI keys ship in the Flutter client.",
)

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
        "service": "careerly-backend",
        "health": "/health",
        "analyze": f"{settings.api_prefix}/resumes/analyze",
    }
