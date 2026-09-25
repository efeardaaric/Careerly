import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/jobs/application/job_match_controller.dart';
import 'package:careerly/features/jobs/data/mock_job_match_fixture.dart';
import 'package:careerly/features/jobs/data/mock_job_match_repository.dart';
import 'package:careerly/features/jobs/data/resume_snapshot_builder.dart';
import 'package:careerly/features/jobs/domain/job_match_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JobMatchResult mapping', () {
    test('fromJson/toJson round-trip keeps score and statuses', () {
      final resume = ResumeSnapshotBuilder.fromAnalyzedCv(
        resumeId: 'res_1',
        fileName: 'cv.pdf',
        overallScore: 78,
      );
      final original = MockJobMatchFixture.result(
        resume: resume,
        jobTitle: 'Software Intern',
        company: 'Campus Labs',
      );
      final mapped = JobMatchResult.fromJson(original.toJson());
      expect(mapped.overallMatchScore, original.overallMatchScore);
      expect(mapped.skillMatches.length, original.skillMatches.length);
      expect(
        mapped.skillMatches
            .where((s) => s.status == SkillEvidenceStatus.notDemonstrated)
            .every(
              (s) => (s.note ?? '').toLowerCase().contains('not demonstrated'),
            ),
        isTrue,
      );
      expect(mapped.scoreDisclaimer.toLowerCase().contains('hiring'), isTrue);
      expect(mapped.scoreDisclaimer.toLowerCase().contains('not'), isTrue);
    });
  });

  group('MockJobMatchRepository', () {
    test(
      'returns deterministic weighted score without inventing SQL',
      () async {
        final repo = MockJobMatchRepository(delay: Duration.zero);
        final resume = ResumeSnapshotBuilder.fromAnalyzedCv(
          resumeId: 'res_1',
          fileName: 'cv.pdf',
        );
        final result = await repo.matchJob(
          JobMatchInput(
            resume: resume,
            jobTitle: 'Intern',
            jobDescription: 'Requires Flutter and SQL for internship.',
          ),
        );
        expect(result.overallMatchScore, inInclusiveRange(0, 100));
        final sql = result.skillMatches.where((s) => s.skill == 'SQL');
        expect(sql, isNotEmpty);
        expect(sql.first.status, SkillEvidenceStatus.notDemonstrated);
        expect(
          result.categories
              .map((c) => c.weight)
              .fold<double>(0, (a, b) => a + b),
          closeTo(1.0, 0.001),
        );
      },
    );
  });

  group('JobMatchController save', () {
    test('persists saved matches in LocalStore', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.create();
      final resume = ResumeSnapshotBuilder.fromAnalyzedCv(
        resumeId: 'res_1',
        fileName: 'cv.pdf',
      );
      final controller = JobMatchController(
        repository: MockJobMatchRepository(delay: Duration.zero),
        store: store,
        readAnalysis: () => resume,
        readLocale: () => 'en',
        readCareerStage: () => 'student',
        stageDelay: Duration.zero,
      );
      controller.startNewMatch();
      controller.selectResume(resume);
      controller.continueToJobForm();
      controller.updateJobTitle('Intern');
      controller.updateJobDescription(
        'Flutter intern role with Dart, Git, and SQL required for mobile work.',
      );
      await controller.runMatch();
      expect(controller.state.phase, JobMatchPhase.results);
      expect(controller.state.result, isNotNull);
      await controller.saveCurrentMatch();
      expect(controller.state.savedMatches, isNotEmpty);
      expect(controller.state.phase, JobMatchPhase.list);

      final raw = store.readString(JobMatchController.storageKey);
      expect(raw, isNotNull);
      expect(raw!.contains('overallMatchScore'), isTrue);
    });
  });
}
