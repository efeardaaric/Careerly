"""SQLAlchemy models. PostgreSQL is authoritative; SQLite is the local default."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import JSON, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


def _uuid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.now(UTC)


class Base(DeclarativeBase):
    pass


class UsageCounter(Base):
    __tablename__ = "usage_counters"

    user_id: Mapped[str] = mapped_column(String(128), primary_key=True)
    feature_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    period: Mapped[str] = mapped_column(String(32), primary_key=True)
    count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class UsageRequest(Base):
    __tablename__ = "usage_requests"

    user_id: Mapped[str] = mapped_column(String(128), primary_key=True)
    request_id: Mapped[str] = mapped_column(String(200), primary_key=True)
    feature_id: Mapped[str] = mapped_column(String(64), nullable=False)
    period: Mapped[str] = mapped_column(String(32), nullable=False)


class UserSubscription(Base):
    __tablename__ = "user_subscriptions"

    user_id: Mapped[str] = mapped_column(String(128), primary_key=True)
    tier: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    product_id: Mapped[str | None] = mapped_column(String(120))
    expires_at: Mapped[str | None] = mapped_column(String(64))


JSONType = JSON().with_variant(JSONB, "postgresql")


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    external_auth_id: Mapped[str | None] = mapped_column(String(128), unique=True)
    email: Mapped[str | None] = mapped_column(String(320))
    first_name: Mapped[str | None] = mapped_column(String(120))
    display_name: Mapped[str | None] = mapped_column(String(160))
    career_stage: Mapped[str | None] = mapped_column(String(40))
    opportunity_type: Mapped[str | None] = mapped_column(String(40))
    target_fields: Mapped[list] = mapped_column(JSONType, default=list)
    cv_languages: Mapped[list] = mapped_column(JSONType, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now, onupdate=_now
    )


class CVDocument(Base):
    __tablename__ = "cv_documents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str | None] = mapped_column(String(128), index=True)
    original_file_name: Mapped[str] = mapped_column(String(260))
    display_name: Mapped[str] = mapped_column(String(260))
    mime_type: Mapped[str] = mapped_column(String(120))
    file_size: Mapped[int] = mapped_column(Integer)
    detected_language: Mapped[str] = mapped_column(String(16), default="en")
    parse_status: Mapped[str] = mapped_column(String(32), default="parsed")
    parser_confidence: Mapped[float] = mapped_column(Float, default=0)
    parser_version: Mapped[str] = mapped_column(String(32), default="1.0.0")
    structured_data: Mapped[dict] = mapped_column(JSONType, default=dict)
    latest_analysis_id: Mapped[str | None] = mapped_column(String(36))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now, onupdate=_now
    )

    analyses: Mapped[list[CVAnalysis]] = relationship(
        back_populates="document",
        cascade="all, delete-orphan",
    )


class CVAnalysis(Base):
    __tablename__ = "cv_analyses"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    cv_id: Mapped[str] = mapped_column(ForeignKey("cv_documents.id"), index=True)
    overall_score: Mapped[int] = mapped_column(Integer)
    ats_score: Mapped[int] = mapped_column(Integer)
    content_impact_score: Mapped[int] = mapped_column(Integer)
    experience_score: Mapped[int] = mapped_column(Integer)
    skills_score: Mapped[int] = mapped_column(Integer)
    structure_score: Mapped[int] = mapped_column(Integer)
    language_score: Mapped[int] = mapped_column(Integer)
    basics_score: Mapped[int] = mapped_column(Integer)
    parser_confidence: Mapped[float] = mapped_column(Float)
    engine_version: Mapped[str] = mapped_column(String(32))
    summary: Mapped[str | None] = mapped_column(Text)
    payload: Mapped[dict] = mapped_column(JSONType, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    document: Mapped[CVDocument] = relationship(back_populates="analyses")
    categories: Mapped[list[CVAnalysisCategory]] = relationship(
        back_populates="analysis", cascade="all, delete-orphan"
    )
    findings: Mapped[list[AnalysisFinding]] = relationship(
        back_populates="analysis", cascade="all, delete-orphan"
    )


class CVAnalysisCategory(Base):
    __tablename__ = "cv_analysis_categories"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    analysis_id: Mapped[str] = mapped_column(ForeignKey("cv_analyses.id"), index=True)
    key: Mapped[str] = mapped_column(String(64))
    title: Mapped[str] = mapped_column(String(120))
    score: Mapped[int] = mapped_column(Integer)
    weight: Mapped[float] = mapped_column(Float)
    earned_points: Mapped[float] = mapped_column(Float, default=0)
    possible_points: Mapped[float] = mapped_column(Float, default=0)
    summary: Mapped[str] = mapped_column(Text, default="")

    analysis: Mapped[CVAnalysis] = relationship(back_populates="categories")


class AnalysisFinding(Base):
    __tablename__ = "analysis_findings"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    analysis_id: Mapped[str] = mapped_column(ForeignKey("cv_analyses.id"), index=True)
    category: Mapped[str] = mapped_column(String(64))
    severity: Mapped[str] = mapped_column(String(32))
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text, default="")
    evidence: Mapped[str] = mapped_column(Text, default="")
    recommendation: Mapped[str] = mapped_column(Text, default="")
    source_section: Mapped[str | None] = mapped_column(String(64))
    can_auto_fix: Mapped[int] = mapped_column(Integer, default=0)
    extra: Mapped[dict] = mapped_column(JSONType, default=dict)

    analysis: Mapped[CVAnalysis] = relationship(back_populates="findings")
