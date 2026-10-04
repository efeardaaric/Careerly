import 'dart:convert';
import 'dart:async';

import 'package:careerly/app/session/session_controller.dart';
import 'package:careerly/core/config/app_config.dart';

import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/analyze/data/api_resume_analysis_repository.dart';
import 'package:careerly/features/analyze/domain/analysis_models.dart';
import 'package:careerly/features/analyze/domain/resume_analysis_repository.dart';
import 'package:careerly/features/optimization/application/optimization_controller.dart';
import 'package:careerly/features/optimization/data/suggestion_repository.dart';
import 'package:careerly/features/optimization/domain/cv_suggestion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ResumeAnalysis _analysis(int content) {
  return ResumeAnalysis(
    id: 'a$content',
    resumeId: 'cv-1',
    overallScore: content,
    confidence: ParserConfidence.high,
    categories: [
      ScoreCategory(
        id: ScoreCategoryId.atsCompatibility,
        score: 90,
        weight: 0.2,
        summary: '',
      ),
      ScoreCategory(
        id: ScoreCategoryId.contentImpact,
        score: content,
        weight: 0.2,
        summary: '',
      ),
    ],
    findings: const [],
    workingWell: const [],
    topImprovementIds: const [],
    engineVersion: '1.0.0',
    analyzedAt: DateTime.utc(2026),
    fileName: 'Ada Yilmaz CV',
  );
}

const _evidence = CvEvidence(
  originalFileName: 'Ada Yilmaz CV.pdf',
  displayName: 'Ada Yilmaz CV',
  rawText: '',
  parserConfidenceScore: 90,
  detectedLanguage: 'en',
  sections: [
    CvTextSection(
      id: 's1',
      key: 'experience',
      title: 'Experience',
      body: '- I developed a Flutter app for 40 students',
      status: SectionStatus.detected,
      confidence: 1,
    ),
  ],
);

/// Returns whatever score the "engine" decides; records the text it scored.
class _EngineFake implements ResumeAnalysisRepository {
  _EngineFake(this.nextScore);

  int nextScore;
  CvEvidence? scored;

  @override
  Future<ResumeAnalysis> analyzeResume({
    required SelectedCvFile file,
    required ParsedResume parsed,
  }) async {
    scored = parsed.evidence;
    return _analysis(nextScore);
  }

  @override
  Future<ParsedResume> parseResume(
    SelectedCvFile file, {
    void Function(AnalysisProcessingStage stage)? onStage,
  }) => throw UnimplementedError();

  @override
  Future<void> validateCvFile(SelectedCvFile file) async {}
}

Future<(ProviderContainer, _EngineFake)> _setup(
  int engineScore, {
  SuggestionRepository? suggestions,
}) async {
  SharedPreferences.setMockInitialValues({
    'active_cv_record_json': jsonEncode({
      'analysis': {
        'id': 'a60',
        'resumeId': 'cv-1',
        'overallScore': 60,
        'confidence': 'high',
        'engineVersion': '1.0.0',
        'analyzedAt': '2026-01-01T00:00:00.000Z',
        'fileName': 'Ada Yilmaz CV',
        'topImprovementIds': <String>[],
        'workingWell': <String>[],
        'categories': [
          {'id': 'atsCompatibility', 'score': 90, 'weight': 0.2, 'summary': ''},
          {'id': 'contentImpact', 'score': 60, 'weight': 0.2, 'summary': ''},
        ],
        'findings': <Object>[],
      },
      'evidence': _evidence.toJson(),
    }),
  });
  final store = await LocalStore.create();
  final engine = _EngineFake(engineScore);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      resumeAnalysisRepositoryProvider.overrideWithValue(engine),
      suggestionRepositoryProvider.overrideWithValue(
        suggestions ?? const LocalSuggestionRepository(),
      ),
    ],
  );
  return (container, engine);
}

class _DelayedSuggestions extends LocalSuggestionRepository {
  final pending = Completer<SuggestionBatch>();

  @override
  Future<SuggestionBatch> suggestions({
    required String resumeId,
    required CvEvidence evidence,
  }) => pending.future;
}

void main() {
  setUpAll(AppConfig.bootstrap);
  test(
    'accepting does not change scores; only the engine result does',
    () async {
      final (container, engine) = await _setup(60);
      addTearDown(container.dispose);
      final sub = container.listen(optimizationControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(
        optimizationControllerProvider.notifier,
      );

      await controller.load();
      final item = container
          .read(optimizationControllerProvider)
          .suggestions
          .single;
      controller.accept(item.id);
      expect(container.read(optimizationControllerProvider).lastChange, isNull);

      expect(await controller.applyAndRescore(), isTrue);
      final change = container.read(optimizationControllerProvider).lastChange!;
      expect(change.before.cvQuality, change.after.cvQuality);
      expect(
        engine.scored!.sections.single.body,
        '- Developed a Flutter app for 40 students',
      );
    },
  );

  test(
    'score change reflects the re-run engine and keeps an original version',
    () async {
      final (container, _) = await _setup(80);
      addTearDown(container.dispose);
      final sub = container.listen(optimizationControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(
        optimizationControllerProvider.notifier,
      );

      await controller.load();
      final item = container
          .read(optimizationControllerProvider)
          .suggestions
          .single;
      controller.edit(item.id, 'Developed a Flutter app used by 40 students');
      await controller.applyAndRescore();

      final state = container.read(optimizationControllerProvider);
      expect(state.lastChange!.before.cvQuality, 60);
      expect(state.lastChange!.after.cvQuality, 80);
      expect(
        state.versions.first.evidence.sections.single.body,
        _evidence.sections.single.body,
      );
      expect(state.versions.length, 2);
    },
  );

  test('nothing decided means nothing applied', () async {
    final (container, engine) = await _setup(90);
    addTearDown(container.dispose);
    final sub = container.listen(optimizationControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final controller = container.read(optimizationControllerProvider.notifier);
    await controller.load();
    final item = container
        .read(optimizationControllerProvider)
        .suggestions
        .single;
    controller.reject(item.id);
    expect(item.status, SuggestionStatus.pending);
    expect(await controller.applyAndRescore(), isFalse);
    expect(engine.scored, isNull);
  });

  for (final action in ['signOut', 'reset', 'delete']) {
    test('$action clears optimization state and versions', () async {
      final (container, _) = await _setup(80);
      addTearDown(container.dispose);
      final subscription = container.listen(
        optimizationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = container.read(
        optimizationControllerProvider.notifier,
      );
      await controller.load();
      controller.accept(
        container.read(optimizationControllerProvider).suggestions.single.id,
      );
      await controller.applyAndRescore();
      expect(
        container.read(optimizationControllerProvider).versions,
        isNotEmpty,
      );
      final session = container.read(sessionProvider.notifier);
      switch (action) {
        case 'signOut':
          await session.signOutMock();
        case 'reset':
          await session.resetDemo();
        case 'delete':
          await session.deleteLocalAccount();
      }
      expect(
        container.read(optimizationControllerProvider),
        const OptimizationState(),
      );
      expect(
        container.read(localStoreProvider).readString('cv_versions_json'),
        isNull,
      );
    });
  }

  test(
    'suggestions completing after sign out do not restore old data',
    () async {
      final repository = _DelayedSuggestions();
      final (container, _) = await _setup(80, suggestions: repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        optimizationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = container.read(
        optimizationControllerProvider.notifier,
      );
      final loading = controller.load();
      await container.read(sessionProvider.notifier).signOutMock();
      repository.pending.complete(
        await const LocalSuggestionRepository().suggestions(
          resumeId: 'cv-1',
          evidence: _evidence,
        ),
      );
      await loading;
      expect(
        container.read(optimizationControllerProvider),
        const OptimizationState(),
      );
    },
  );
}
