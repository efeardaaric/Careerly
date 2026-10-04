from fastapi import APIRouter

from app.api.routes import builder, cvs, entitlements, health, job_match, resume_analysis
from app.core.config import get_settings

api_router = APIRouter()
api_router.include_router(health.router)

settings = get_settings()
api_router.include_router(resume_analysis.router, prefix=settings.api_prefix)
api_router.include_router(cvs.router, prefix=settings.api_prefix)
api_router.include_router(job_match.router, prefix=settings.api_prefix)
api_router.include_router(builder.router, prefix=settings.api_prefix)
api_router.include_router(entitlements.router, prefix=settings.api_prefix)
