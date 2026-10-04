import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/analytics/billing_analytics.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/local_store.dart';
import '../../analyze/application/analysis_controller.dart';
import '../../analyze/domain/analysis_models.dart';
import '../../analyze/domain/product_scores.dart';
import '../data/cv_version_store.dart';
import '../data/suggestion_repository.dart';
import '../domain/cv_suggestion.dart';
import '../domain/cv_version.dart';
import '../domain/suggestion_rules.dart';

class ScoreChange {
  const ScoreChange({required this.before, required this.after});

  final ProductScores before;
  final ProductScores after;
}

class OptimizationState extends Equatable {
  const OptimizationState({
    this.loading = false,
    this.applying = false,
    this.rewritingId,
    this.suggestions = const [],
    this.aiAvailable = false,
    this.errorKey,
    this.lastChange,
    this.versions = const [],
  });

  final bool loading;
  final bool applying;
  final String? rewritingId;
  final List<CvSuggestion> suggestions;
  final bool aiAvailable;

  /// Localization key for a non-blocking message. Never a raw API error.
  final String? errorKey;
  final ScoreChange? lastChange;
  final List<CvVersion> versions;

  int get decidedCount =>
      suggestions.where((s) => s.replacement != null).length;

  OptimizationState copyWith({
    bool? loading,
    bool? applying,
    String? rewritingId,
    bool clearRewriting = false,
    List<CvSuggestion>? suggestions,
    bool? aiAvailable,
    String? errorKey,
    bool clearError = false,
    ScoreChange? lastChange,
    List<CvVersion>? versions,
  }) {
    return OptimizationState(
      loading: loading ?? this.loading,
      applying: applying ?? this.applying,
      rewritingId: clearRewriting ? null : (rewritingId ?? this.rewritingId),
      suggestions: suggestions ?? this.suggestions,
      aiAvailable: aiAvailable ?? this.aiAvailable,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      lastChange: lastChange ?? this.lastChange,
      versions: versions ?? this.versions,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    applying,
    rewritingId,
    suggestions,
    aiAvailable,
    errorKey,
    lastChange,
    versions,
  ];
}

class OptimizationController extends StateNotifier<OptimizationState> {
  OptimizationController(this._ref, this._repository, this._versions)
    : super(const OptimizationState()) {
    state = state.copyWith(versions: _readVersions());
  }

  final Ref _ref;
  final SuggestionRepository _repository;
  final CvVersionStore _versions;
  int _generation = 0;

  void clearUserData() {
    _generation++;
    state = const OptimizationState();
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  Future<void> load() async {
    final generation = _generation;
    final analysis = _ref.read(analysisControllerProvider).analysis;
    final evidence = _ref.read(analysisControllerProvider).evidence;
    if (analysis == null || evidence == null) {
      state = state.copyWith(suggestions: const [], errorKey: 'optimizeNoCv');
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    SuggestionBatch batch;
    try {
      batch = await _repository.suggestions(
        resumeId: analysis.resumeId,
        evidence: evidence,
      );
    } catch (_) {
      batch = SuggestionBatch(
        suggestions: SuggestionRules.build(evidence.sections),
        aiAvailable: false,
      );
    }
    if (!_isCurrent(generation)) return;
    state = state.copyWith(
      loading: false,
      suggestions: batch.suggestions,
      aiAvailable: batch.aiAvailable,
      versions: _readVersions(),
    );
    BillingAnalytics.track('suggestion_viewed', {
      'count': batch.suggestions.length,
    });
  }

  void accept(String id) {
    final item = _find(id);
    if (item?.suggestedText == null) return;
    _update(
      id,
      (s) => s.copyWith(status: SuggestionStatus.accepted, clearEdited: true),
    );
    BillingAnalytics.track('suggestion_accepted', {'kind': item!.kind.name});
  }

  void edit(String id, String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    _update(
      id,
      (s) => s.copyWith(status: SuggestionStatus.edited, editedText: value),
    );
    BillingAnalytics.track('suggestion_edited', {'kind': _find(id)?.kind.name});
  }

  void reject(String id) {
    _update(
      id,
      (s) => s.copyWith(status: SuggestionStatus.rejected, clearEdited: true),
    );
    BillingAnalytics.track('suggestion_rejected', {
      'kind': _find(id)?.kind.name,
    });
  }

  void undo(String id) {
    _update(
      id,
      (s) => s.copyWith(status: SuggestionStatus.pending, clearEdited: true),
    );
  }

  Future<void> rewrite(
    String id,
    RewriteMode mode, {
    String? jobContext,
  }) async {
    final generation = _generation;
    final item = _find(id);
    final analysis = _ref.read(analysisControllerProvider).analysis;
    if (item == null || analysis == null) return;
    state = state.copyWith(rewritingId: id, clearError: true);
    try {
      final result = await _repository.rewrite(
        resumeId: analysis.resumeId,
        text: item.originalText,
        mode: mode,
        jobContext: jobContext,
      );
      if (!_isCurrent(generation)) return;
      if (result.accepted) {
        _update(
          id,
          (s) => s.copyWith(
            suggestedText: result.suggested,
            source: 'ai',
            status: SuggestionStatus.pending,
            clearEdited: true,
          ),
        );
      } else {
        state = state.copyWith(errorKey: 'optimizeAiKeptOriginal');
      }
    } on AppException catch (error) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        errorKey: error.code == 'AI_DISABLED'
            ? 'optimizeAiUnavailable'
            : 'optimizeAiFailed',
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(errorKey: 'optimizeAiFailed');
    } finally {
      if (_isCurrent(generation)) {
        state = state.copyWith(clearRewriting: true);
      }
    }
  }

  /// Applies decided lines, then re-runs the scoring engine on the edited CV.
  Future<bool> applyAndRescore() async {
    final generation = _generation;
    final analysisState = _ref.read(analysisControllerProvider);
    final analysis = analysisState.analysis;
    final evidence = analysisState.evidence;
    final decided = state.suggestions
        .where((s) => s.replacement != null)
        .toList();
    if (analysis == null || evidence == null || decided.isEmpty) return false;

    state = state.copyWith(applying: true, clearError: true);
    BillingAnalytics.track('optimization_started', {'changes': decided.length});
    final before = ProductScores.fromAnalysis(analysis);
    await _ensureOriginal(analysis, evidence, before);
    if (!_isCurrent(generation)) return false;
    final edited = SuggestionRules.apply(evidence, decided);
    try {
      final next = await _ref
          .read(analysisControllerProvider.notifier)
          .rescoreEdited(edited);
      if (!_isCurrent(generation)) return false;
      if (next == null) throw StateError('no analysis');
      final after = ProductScores.fromAnalysis(next);
      await _saveVersion(
        CvVersion(
          id: const Uuid().v4(),
          resumeId: next.resumeId,
          type: CvVersionType.optimized,
          label: next.fileName,
          createdAt: DateTime.now(),
          evidence: edited,
          cvQuality: after.cvQuality,
          atsReadability: after.atsReadability,
        ),
      );
      if (!_isCurrent(generation)) return false;
      state = state.copyWith(
        applying: false,
        lastChange: ScoreChange(before: before, after: after),
        versions: _readVersions(),
      );
      BillingAnalytics.track('optimization_completed', {
        'qualityDelta': after.cvQuality - before.cvQuality,
      });
      await load();
      return true;
    } catch (_) {
      if (!_isCurrent(generation)) return false;
      state = state.copyWith(
        applying: false,
        errorKey: 'optimizeRescoreFailed',
      );
      return false;
    }
  }

  /// Re-scores a saved version. The score comes from the engine, not the snapshot.
  Future<bool> restore(CvVersion version) async {
    final generation = _generation;
    final analysis = _ref.read(analysisControllerProvider).analysis;
    if (analysis == null) return false;
    state = state.copyWith(applying: true, clearError: true);
    final before = ProductScores.fromAnalysis(analysis);
    try {
      final next = await _ref
          .read(analysisControllerProvider.notifier)
          .rescoreEdited(version.evidence);
      if (!_isCurrent(generation)) return false;
      if (next == null) throw StateError('no analysis');
      state = state.copyWith(
        applying: false,
        lastChange: ScoreChange(
          before: before,
          after: ProductScores.fromAnalysis(next),
        ),
      );
      await load();
      return true;
    } catch (_) {
      if (!_isCurrent(generation)) return false;
      state = state.copyWith(
        applying: false,
        errorKey: 'optimizeRescoreFailed',
      );
      return false;
    }
  }

  void clearMessage() => state = state.copyWith(clearError: true);

  CvSuggestion? _find(String id) {
    for (final s in state.suggestions) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _update(String id, CvSuggestion Function(CvSuggestion) change) {
    state = state.copyWith(
      suggestions: [
        for (final s in state.suggestions) s.id == id ? change(s) : s,
      ],
    );
  }

  Future<void> _ensureOriginal(
    ResumeAnalysis analysis,
    CvEvidence evidence,
    ProductScores scores,
  ) async {
    final exists = _readVersions().any(
      (v) =>
          v.resumeId == analysis.resumeId && v.type == CvVersionType.original,
    );
    if (exists) return;
    await _saveVersion(
      CvVersion(
        id: const Uuid().v4(),
        resumeId: analysis.resumeId,
        type: CvVersionType.original,
        label: analysis.fileName,
        createdAt: analysis.analyzedAt,
        evidence: evidence,
        cvQuality: scores.cvQuality,
        atsReadability: scores.atsReadability,
      ),
    );
  }

  List<CvVersion> _readVersions() => _versions.read();

  Future<void> _saveVersion(CvVersion version) => _versions.add(version);
}

final optimizationControllerProvider =
    StateNotifierProvider.autoDispose<
      OptimizationController,
      OptimizationState
    >((ref) {
      final controller = OptimizationController(
        ref,
        ref.watch(suggestionRepositoryProvider),
        ref.watch(cvVersionStoreProvider),
      );
      final store = ref.watch(localStoreProvider);
      store.addUserDataResetListener(controller.clearUserData);
      ref.onDispose(
        () => store.removeUserDataResetListener(controller.clearUserData),
      );
      return controller;
    });
