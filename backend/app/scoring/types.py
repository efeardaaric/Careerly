from dataclasses import dataclass, field


@dataclass
class RuleResult:
    key: str
    passed: bool
    status: str
    score_contribution: float
    max_contribution: float
    confidence: float
    evidence: str
    message: str
    metadata: dict = field(default_factory=dict)


@dataclass
class FindingDraft:
    category: str
    severity: str
    title: str
    description: str
    evidence: str
    recommendation: str
    source_section: str | None = None
    can_auto_fix: bool = False


@dataclass
class CategoryResult:
    key: str
    title: str
    score: int
    earned_points: float
    possible_points: float
    rules: list[RuleResult]
    findings: list[FindingDraft]
    summary: str
