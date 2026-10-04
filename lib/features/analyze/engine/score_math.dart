import '../domain/analysis_models.dart';

/// Deterministic Careerly score math. Same inputs always produce the same total.
abstract final class ScoreMath {
  static const engineVersion = 'local-rules-1.1.0';

  static const weights = <ScoreCategoryId, double>{
    ScoreCategoryId.atsCompatibility: 0.20,
    ScoreCategoryId.contentImpact: 0.20,
    ScoreCategoryId.experiencePresentation: 0.15,
    ScoreCategoryId.skillsRelevance: 0.15,
    ScoreCategoryId.structureReadability: 0.10,
    ScoreCategoryId.languageGrammar: 0.10,
    ScoreCategoryId.basicsContact: 0.10,
  };

  static int clamp(num value) => value.round().clamp(0, 100);

  /// Weighted sum using [weights]. Missing categories count as 0.
  static int overall(Map<ScoreCategoryId, int> scores) {
    var total = 0.0;
    for (final entry in weights.entries) {
      total += (scores[entry.key] ?? 0) * entry.value;
    }
    return clamp(total);
  }

  static ParserConfidence confidenceBand(int score) {
    if (score >= 85) return ParserConfidence.high;
    if (score >= 60) return ParserConfidence.medium;
    return ParserConfidence.low;
  }
}
