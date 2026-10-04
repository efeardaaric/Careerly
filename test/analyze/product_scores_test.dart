import 'package:careerly/features/analyze/domain/analysis_models.dart';
import 'package:careerly/features/analyze/domain/product_scores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ResumeAnalysis analysis(List<ScoreCategory> categories) {
    return ResumeAnalysis(
      id: 'a',
      resumeId: 'cv',
      overallScore: 70,
      confidence: ParserConfidence.high,
      categories: categories,
      findings: const [],
      workingWell: const [],
      topImprovementIds: const [],
      engineVersion: '1.0.0',
      analyzedAt: DateTime.utc(2026),
      fileName: 'Ada Yilmaz CV',
    );
  }

  ScoreCategory cat(ScoreCategoryId id, int score) {
    return ScoreCategory(id: id, score: score, weight: 0.1, summary: '');
  }

  test('CV quality excludes ATS and uses product weights', () {
    final scores = ProductScores.fromAnalysis(
      analysis([
        cat(ScoreCategoryId.atsCompatibility, 40),
        cat(ScoreCategoryId.contentImpact, 100),
        cat(ScoreCategoryId.experiencePresentation, 100),
        cat(ScoreCategoryId.skillsRelevance, 100),
        cat(ScoreCategoryId.structureReadability, 100),
        cat(ScoreCategoryId.languageGrammar, 100),
        cat(ScoreCategoryId.basicsContact, 100),
      ]),
    );
    expect(scores.atsReadability, 40);
    expect(scores.cvQuality, 100);
    expect(scores.quality.fold<int>(0, (sum, slice) => sum + slice.possible), 100);
  });

  test('missing preferred-style category does not divide by zero', () {
    final scores = ProductScores.fromAnalysis(
      analysis([
        cat(ScoreCategoryId.contentImpact, 50),
      ]),
    );
    expect(scores.cvQuality, 52);
    expect(scores.atsReadability, isNull);
    expect(scoreBand(49), ScoreBand.needsWork);
    expect(scoreBand(85), ScoreBand.excellent);
  });
}
