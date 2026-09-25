import 'package:careerly/features/analyze/data/cv_file_validator.dart';
import 'package:careerly/features/analyze/data/mock_analysis_fixture.dart';
import 'package:careerly/features/analyze/data/mock_resume_analysis_repository.dart';
import 'package:careerly/features/analyze/domain/analysis_models.dart';
import 'package:careerly/features/analyze/domain/resume_analysis_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('repository switching contract', () {
    test('mock repository satisfies ResumeAnalysisRepository', () {
      final ResumeAnalysisRepository repo = MockResumeAnalysisRepository(
        simulateDelay: false,
      );
      expect(repo, isA<ResumeAnalysisRepository>());
    });

    test('mock parse/analyze still returns fixture scores', () async {
      final repo = MockResumeAnalysisRepository(simulateDelay: false);
      const file = SelectedCvFile(
        name: 'cv.pdf',
        extension: 'pdf',
        sizeBytes: 2048,
        path: null,
      );
      final parsed = await repo.parseResume(file);
      final analysis = await repo.analyzeResume(file: file, parsed: parsed);
      expect(analysis.overallScore, 78);
      expect(analysis.category(ScoreCategoryId.atsCompatibility)?.score, 84);
    });
  });

  group('AnalyzeApiEnvelope mapping shape', () {
    test('fixture JSON-like map maps to domain models', () {
      final analysis = MockAnalysisFixture.analysis(
        resumeId: 'r1',
        fileName: 'a.pdf',
      );
      expect(analysis.overallScore, inInclusiveRange(0, 100));
      expect(analysis.categories, isNotEmpty);
      expect(analysis.topImprovements.length, lessThanOrEqualTo(3));
    });
  });

  group('CvFileRules', () {
    test('central 10MB limit', () {
      expect(CvFileRules.maxBytes, 10 * 1024 * 1024);
      expect(CvFileRules.isAllowedExtension('PDF'), isTrue);
      expect(CvFileRules.isAllowedExtension('docx'), isTrue);
      expect(CvFileRules.isAllowedExtension('doc'), isFalse);
    });
  });
}
