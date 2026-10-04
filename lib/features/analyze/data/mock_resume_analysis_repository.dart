import '../domain/analysis_models.dart';
import '../domain/resume_analysis_repository.dart';
import 'cv_file_validator.dart';
import 'mock_analysis_fixture.dart';

/// Phase 2 mock analysis.
/// Path: lib/features/analyze/data/mock_resume_analysis_repository.dart
class MockResumeAnalysisRepository implements ResumeAnalysisRepository {
  MockResumeAnalysisRepository({
    this._validator = const CvFileValidator(),
    this.simulateDelay = true,
  });

  final CvFileValidator _validator;
  final bool simulateDelay;

  /// Isolated mock timing — not UI animation.
  static const parseDelay = Duration(milliseconds: 900);
  static const analyzeDelay = Duration(milliseconds: 700);

  @override
  Future<void> validateCvFile(SelectedCvFile file) async {
    _validator.validate(
      name: file.name,
      extension: file.extension,
      sizeBytes: file.sizeBytes,
    );
  }

  @override
  Future<ParsedResume> parseResume(
    SelectedCvFile file, {
    void Function(AnalysisProcessingStage stage)? onStage,
  }) async {
    await validateCvFile(file);
    if (simulateDelay) {
      await Future<void>.delayed(parseDelay);
    }
    final resumeId = 'resume_${file.name.hashCode.abs()}';
    return MockAnalysisFixture.parsedResume(resumeId: resumeId);
  }

  @override
  Future<ResumeAnalysis> analyzeResume({
    required SelectedCvFile file,
    required ParsedResume parsed,
  }) async {
    if (simulateDelay) {
      await Future<void>.delayed(analyzeDelay);
    }
    return MockAnalysisFixture.analysis(
      resumeId: parsed.resumeId,
      fileName: file.name,
    );
  }
}
