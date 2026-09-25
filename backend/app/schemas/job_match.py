from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class SkillEvidenceStatus(str, Enum):
    matched = "matched"
    partial = "partial"
    notDemonstrated = "notDemonstrated"
    unclear = "unclear"


class JobMatchCategoryId(str, Enum):
    coreSkills = "coreSkills"
    experienceProjects = "experienceProjects"
    responsibilities = "responsibilities"
    education = "education"
    tools = "tools"
    languageOther = "languageOther"


class ResumeSnapshotIn(BaseModel):
    resumeId: str
    fileName: str | None = None
    skills: list[str] = Field(default_factory=list)
    experienceBullets: list[str] = Field(default_factory=list)
    projectBullets: list[str] = Field(default_factory=list)
    education: list[str] = Field(default_factory=list)
    tools: list[str] = Field(default_factory=list)
    languages: list[str] = Field(default_factory=list)
    summary: str | None = None
    sectionKeys: list[str] = Field(default_factory=list)


class JobMatchRequest(BaseModel):
    resume: ResumeSnapshotIn
    jobTitle: str
    jobDescription: str = Field(min_length=20)
    company: str | None = None
    jobUrl: str | None = None  # metadata only — never scraped
    locale: str = "en"
    careerStage: str | None = None


class SkillMatchItemOut(BaseModel):
    skill: str
    status: SkillEvidenceStatus
    required: bool = True
    evidence: str | None = None
    note: str | None = None


class MatchCategoryOut(BaseModel):
    id: JobMatchCategoryId
    score: int = Field(ge=0, le=100)
    weight: float
    summary: str


class MatchRecommendationOut(BaseModel):
    id: str
    title: str
    body: str
    kind: str  # cv_improvement | learning | verification
    beforeText: str | None = None
    afterText: str | None = None


class JobMatchResultOut(BaseModel):
    id: str
    resumeId: str
    jobTitle: str
    company: str | None = None
    jobUrl: str | None = None
    overallMatchScore: int = Field(ge=0, le=100)
    scoreDisclaimer: str
    categories: list[MatchCategoryOut]
    skillMatches: list[SkillMatchItemOut]
    keywordsCovered: list[str]
    keywordsMissing: list[str]
    recommendations: list[MatchRecommendationOut]
    verificationQuestions: list[str]
    learningOpportunities: list[str]
    workingWell: list[str]
    engineVersion: str
    matchedAt: str


class JobMatchResponse(BaseModel):
    match: JobMatchResultOut
    warnings: list[str] = Field(default_factory=list)
    analysisVersion: str


class ErrorResponse(BaseModel):
    code: str
    message: str
    details: dict[str, Any] | None = None
