import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/analyze/application/analysis_controller.dart';
import 'package:careerly/features/analyze/data/cv_file_validator.dart';
import 'package:careerly/features/analyze/data/mock_analysis_fixture.dart';
import 'package:careerly/features/analyze/data/mock_resume_analysis_repository.dart';
import 'package:careerly/features/analyze/domain/analysis_models.dart';

void main() {
  group('CvFileValidator', () {
    const validator = CvFileValidator();

    test('accepts pdf under 10MB', () {
      expect(
        () => validator.validate(
          name: 'cv.pdf',
          extension: 'pdf',
          sizeBytes: 1024,
        ),
        returnsNormally,
      );
    });

    test('rejects invalid extension', () {
      expect(
        () => validator.validate(
          name: 'cv.txt',
          extension: 'txt',
          sizeBytes: 1024,
        ),
        throwsA(
          isA<CvValidationException>().having(
            (e) => e.error,
            'error',
            CvValidationError.invalidExtension,
          ),
        ),
      );
    });

    test('rejects oversized file', () {
      expect(
        () => validator.validate(
          name: 'cv.pdf',
          extension: 'pdf',
          sizeBytes: CvFileRules.maxBytes + 1,
        ),
        throwsA(
          isA<CvValidationException>().having(
            (e) => e.error,
            'error',
            CvValidationError.tooLarge,
          ),
        ),
      );
    });
  });

  group('MockAnalysisFixture scores', () {
    test('uses fixture overall 78 and ATS 84', () {
      final analysis = MockAnalysisFixture.analysis(
        resumeId: 'r1',
        fileName: 'aylin-cv.pdf',
      );
      expect(analysis.overallScore, 78);
      expect(analysis.category(ScoreCategoryId.atsCompatibility)?.score, 84);
      expect(analysis.topImprovements.length, lessThanOrEqualTo(3));
      expect(analysis.topImprovements, isNotEmpty);
    });
  });

  group('MockResumeAnalysisRepository', () {
    test('parse then analyze returns fixture', () async {
      final repo = MockResumeAnalysisRepository(simulateDelay: false);
      const file = SelectedCvFile(
        name: 'aylin-cv.pdf',
        extension: 'pdf',
        sizeBytes: 2048,
        path: null,
      );
      final parsed = await repo.parseResume(file);
      final analysis = await repo.analyzeResume(file: file, parsed: parsed);
      expect(parsed.sections, isNotEmpty);
      expect(analysis.overallScore, 78);
      expect(analysis.fileName, 'aylin-cv.pdf');
    });
  });

  group('AnalysisController state machine', () {
    late AnalysisController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.create();
      controller = AnalysisController(
        repository: MockResumeAnalysisRepository(simulateDelay: false),
        store: store,
        stageDelay: Duration.zero,
      );
    });

    tearDown(() => controller.dispose());

    test('selectFile moves to ready on valid file', () async {
      await controller.selectFile(
        const SelectedCvFile(
          name: 'cv.docx',
          extension: 'docx',
          sizeBytes: 4096,
          path: null,
        ),
      );
      expect(controller.state.phase, AnalysisPhase.ready);
      expect(controller.state.selectedFile?.extension, 'docx');
    });

    test('invalid file sets validation error', () async {
      await controller.selectFile(
        const SelectedCvFile(
          name: 'notes.txt',
          extension: 'txt',
          sizeBytes: 100,
          path: null,
        ),
      );
      expect(
        controller.state.validationError,
        CvValidationError.invalidExtension,
      );
      expect(controller.state.phase, AnalysisPhase.fileSelected);
    });

    test('startAnalysis reaches reviewRequired then completed', () async {
      await controller.selectFile(
        const SelectedCvFile(
          name: 'cv.pdf',
          extension: 'pdf',
          sizeBytes: 2048,
          path: null,
        ),
      );
      await controller.startAnalysis();
      expect(controller.state.phase, AnalysisPhase.reviewRequired);
      expect(controller.state.parsed, isNotNull);

      await controller.confirmReviewAndScore();
      expect(controller.state.phase, AnalysisPhase.completed);
      expect(controller.state.analysis?.overallScore, 78);
    });
  });
}
