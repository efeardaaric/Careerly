from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class FindingSeverity(str, Enum):
    critical = "critical"
    improve = "improve"
    good = "good"


class SectionStatus(str, Enum):
    detected = "detected"
    missing = "missing"
    needsReview = "needsReview"


class ParserConfidence(str, Enum):
    high = "high"
    medium = "medium"
    low = "low"


class ScoreCategoryId(str, Enum):
    atsCompatibility = "atsCompatibility"
    contentImpact = "contentImpact"
    experiencePresentation = "experiencePresentation"
    skillsRelevance = "skillsRelevance"
    structureReadability = "structureReadability"
    languageGrammar = "languageGrammar"
    basicsContact = "basicsContact"


class ResumeSectionOut(BaseModel):
    id: str
    key: str
    title: str
    status: SectionStatus
    preview: str | None = None
    note: str | None = None


class ParsedResumeOut(BaseModel):
    resumeId: str
    sections: list[ResumeSectionOut]
    confidence: ParserConfidence
    engineVersion: str


class ScoreCategoryOut(BaseModel):
    id: ScoreCategoryId
    score: int = Field(ge=0, le=100)
    weight: float
    summary: str


class AnalysisFindingOut(BaseModel):
    id: str
    severity: FindingSeverity
    title: str
    whyItMatters: str
    evidence: str
    recommendedAction: str
    categoryId: ScoreCategoryId
    beforeText: str | None = None
    afterText: str | None = None
    supportsAiImprove: bool = False


class ResumeAnalysisOut(BaseModel):
    id: str
    resumeId: str
    overallScore: int = Field(ge=0, le=100)
    confidence: ParserConfidence
    categories: list[ScoreCategoryOut]
    findings: list[AnalysisFindingOut]
    workingWell: list[str]
    topImprovementIds: list[str]
    engineVersion: str
    analyzedAt: str
    fileName: str


class AnalyzeResponse(BaseModel):
    """Flutter-compatible envelope: parse + score in one temporary pipeline."""

    resumeId: str
    fileName: str
    parsed: ParsedResumeOut
    analysis: ResumeAnalysisOut
    warnings: list[str] = Field(default_factory=list)
    analysisVersion: str


class HealthResponse(BaseModel):
    status: str = "ok"


class ErrorResponse(BaseModel):
    code: str
    message: str
    details: dict[str, Any] | None = None
