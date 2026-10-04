import 'analysis_models.dart';

/// Abstraction for CV parse + analysis. Swap mock → API without UI rewrite.
abstract class ResumeAnalysisRepository {
  /// Validates file metadata before analysis. Does not call AI.
  Future<void> validateCvFile(SelectedCvFile file);

  /// Mock or remote parse. Returns structured sections for user review.
  Future<ParsedResume> parseResume(
    SelectedCvFile file, {
    void Function(AnalysisProcessingStage stage)? onStage,
  });

  /// Mock or remote scoring. Must not invent experience beyond fixture/backend.
  Future<ResumeAnalysis> analyzeResume({
    required SelectedCvFile file,
    required ParsedResume parsed,
  });
}
