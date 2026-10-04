import 'analysis_models.dart';

/// Product view of an existing analysis.
///
/// CV Quality excludes ATS checks. ATS Readability is only the ATS category.
/// Neither number is an employer's ATS result.
class ProductScoreSlice {
  const ProductScoreSlice({
    required this.title,
    required this.earned,
    required this.possible,
  });

  final String title;
  final int earned;
  final int possible;
}

class ProductScores {
  const ProductScores({
    required this.cvQuality,
    required this.atsReadability,
    required this.quality,
  });

  final int cvQuality;
  final int? atsReadability;
  final List<ProductScoreSlice> quality;

  static const _qualityWeights = <ScoreCategoryId, int>{
    ScoreCategoryId.contentImpact: 25,
    ScoreCategoryId.experiencePresentation: 20,
    ScoreCategoryId.skillsRelevance: 15,
    ScoreCategoryId.structureReadability: 15,
    ScoreCategoryId.languageGrammar: 15,
    ScoreCategoryId.basicsContact: 10,
  };

  factory ProductScores.fromAnalysis(ResumeAnalysis analysis) {
    final byId = {for (final category in analysis.categories) category.id: category.score};
    var earned = 0;
    var possible = 0;
    final slices = <ProductScoreSlice>[];
    for (final entry in _qualityWeights.entries) {
      final score = byId[entry.key];
      if (score == null) continue;
      final points = (score / 100 * entry.value).round();
      earned += points;
      possible += entry.value;
      slices.add(
        ProductScoreSlice(
          title: entry.key.name,
          earned: points,
          possible: entry.value,
        ),
      );
    }
    final quality = possible == 0 ? 0 : (earned / possible * 100).round().clamp(0, 100);
    return ProductScores(
      cvQuality: quality,
      atsReadability: byId[ScoreCategoryId.atsCompatibility],
      quality: slices,
    );
  }
}

enum ScoreBand { needsWork, developing, strong, excellent }

ScoreBand scoreBand(int score) {
  if (score >= 85) return ScoreBand.excellent;
  if (score >= 70) return ScoreBand.strong;
  if (score >= 50) return ScoreBand.developing;
  return ScoreBand.needsWork;
}
