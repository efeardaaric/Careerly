"""CV Builder request/response schemas — structured ResumeDocument JSON."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class RewriteRequest(BaseModel):
    mode: Literal["improve", "concise", "professional", "from_notes"] = "improve"
    text: str = Field(min_length=1, max_length=4000)
    locale: str = "en"
    sectionKey: str | None = None
    notes: str | None = Field(default=None, max_length=2000)


class RewriteSuggestionOut(BaseModel):
    original: str
    suggested: str
    why: str
    needsUserFact: bool = False
    missingFactPrompt: str | None = None


class RewriteResponse(BaseModel):
    suggestion: RewriteSuggestionOut


class TranslateRequest(BaseModel):
    targetLanguage: Literal["en", "tr"]
    document: dict[str, Any]


class TranslateResponse(BaseModel):
    document: dict[str, Any]


class StructuredCheckRequest(BaseModel):
    document: dict[str, Any]
    locale: str = "en"
    careerStage: str | None = None


class StructuredCheckResponse(BaseModel):
    """Reuses the same AnalyzeResponse shape fields for ATS/scoring — no second engine."""

    resumeId: str
    fileName: str
    analysis: dict[str, Any]
    warnings: list[str] = []
    analysisVersion: str
    plainText: str = Field(
        description="Searchable text used for ATS — same content templates render."
    )


class ErrorResponse(BaseModel):
    code: str
    message: str
