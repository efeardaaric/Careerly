import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../data/api_resume_analysis_repository.dart';
import '../data/cv_file_validator.dart';
import '../domain/analysis_models.dart';
import '../domain/resume_analysis_repository.dart';

class AnalysisUiState extends Equatable {
  const AnalysisUiState({
    this.phase = AnalysisPhase.initial,
    this.selectedFile,
    this.processingStage,
    this.parsed,
    this.analysis,
    this.failure,
    this.validationError,
    this.isBusy = false,
  });

  final AnalysisPhase phase;
  final SelectedCvFile? selectedFile;
  final AnalysisProcessingStage? processingStage;
  final ParsedResume? parsed;
  final ResumeAnalysis? analysis;
  final AnalysisFailure? failure;
  final CvValidationError? validationError;
  final bool isBusy;

  bool get hasCompletedAnalysis =>
      analysis != null && phase == AnalysisPhase.completed;

  AnalysisUiState copyWith({
    AnalysisPhase? phase,
    SelectedCvFile? selectedFile,
    bool clearFile = false,
    AnalysisProcessingStage? processingStage,
    bool clearProcessingStage = false,
    ParsedResume? parsed,
    ResumeAnalysis? analysis,
    AnalysisFailure? failure,
    bool clearFailure = false,
    CvValidationError? validationError,
    bool clearValidationError = false,
    bool? isBusy,
  }) {
    return AnalysisUiState(
      phase: phase ?? this.phase,
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      processingStage: clearProcessingStage
          ? null
          : (processingStage ?? this.processingStage),
      parsed: parsed ?? this.parsed,
      analysis: analysis ?? this.analysis,
      failure: clearFailure ? null : (failure ?? this.failure),
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    selectedFile,
    processingStage,
    parsed,
    analysis,
    failure,
    validationError,
    isBusy,
  ];
}

class AnalysisController extends StateNotifier<AnalysisUiState> {
  AnalysisController({
    required this._repository,
    required this._store,
    this.stageDelay = const Duration(milliseconds: 550),
  }) : super(const AnalysisUiState()) {
    _restore();
  }

  final ResumeAnalysisRepository _repository;
  final LocalStore _store;
  final Duration stageDelay;
  bool _cancelRequested = false;
  int _runToken = 0;

  static const _storageKey = 'last_resume_analysis_json';

  void _restore() {
    final raw = _store.readString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final analysis = _analysisFromJson(map);
      state = state.copyWith(
        phase: AnalysisPhase.completed,
        analysis: analysis,
      );
    } catch (_) {
      // Ignore corrupt cache.
    }
  }

  Future<void> selectFile(SelectedCvFile file) async {
    state = state.copyWith(
      phase: AnalysisPhase.validating,
      selectedFile: file,
      clearFailure: true,
      clearValidationError: true,
      isBusy: true,
    );
    try {
      await _repository.validateCvFile(file);
      state = state.copyWith(phase: AnalysisPhase.ready, isBusy: false);
    } on CvValidationException catch (e) {
      state = state.copyWith(
        phase: AnalysisPhase.fileSelected,
        validationError: e.error,
        isBusy: false,
      );
    } catch (_) {
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        failure: const AnalysisFailure(
          code: 'validate_failed',
          messageKey: 'analyzeErrorGeneric',
        ),
        isBusy: false,
      );
    }
  }

  void clearSelection() {
    _cancelRequested = true;
    state = state.copyWith(
      phase: state.analysis != null
          ? AnalysisPhase.completed
          : AnalysisPhase.initial,
      clearFile: true,
      clearValidationError: true,
      clearFailure: true,
      clearProcessingStage: true,
      isBusy: false,
    );
  }

  Future<void> startAnalysis() async {
    final file = state.selectedFile;
    if (file == null) return;
    _cancelRequested = false;
    final token = ++_runToken;

    state = state.copyWith(
      phase: AnalysisPhase.processing,
      processingStage: AnalysisProcessingStage.readingStructure,
      clearFailure: true,
      isBusy: true,
    );

    try {
      // Kick off repository work immediately so stages reflect a real wait,
      // not a fabricated completion percentage.
      final parseFuture = _repository.parseResume(file);
      await _advanceStages(token);
      if (_cancelRequested || token != _runToken) return;

      final parsed = await parseFuture;
      if (_cancelRequested || token != _runToken) return;

      state = state.copyWith(
        phase: AnalysisPhase.reviewRequired,
        parsed: parsed,
        clearProcessingStage: true,
        isBusy: false,
      );
    } on CvValidationException catch (e) {
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        validationError: e.error,
        failure: AnalysisFailure(
          code: e.error.name,
          messageKey: 'analyzeErrorGeneric',
        ),
        clearProcessingStage: true,
        isBusy: false,
      );
    } catch (_) {
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        failure: const AnalysisFailure(
          code: 'parse_failed',
          messageKey: 'analyzeErrorGeneric',
        ),
        clearProcessingStage: true,
        isBusy: false,
      );
    }
  }

  Future<void> _advanceStages(int token) async {
    const stages = AnalysisProcessingStage.values;
    for (final stage in stages) {
      if (_cancelRequested || token != _runToken) return;
      state = state.copyWith(processingStage: stage);
      if (stageDelay > Duration.zero) {
        await Future<void>.delayed(stageDelay);
      }
    }
  }

  void cancelProcessing() {
    _cancelRequested = true;
    _runToken++;
    state = state.copyWith(
      phase: AnalysisPhase.ready,
      clearProcessingStage: true,
      isBusy: false,
    );
  }

  void updateSectionStatus(String sectionId, SectionStatus status) {
    final parsed = state.parsed;
    if (parsed == null) return;
    final sections = parsed.sections
        .map((s) => s.id == sectionId ? s.copyWith(status: status) : s)
        .toList();
    state = state.copyWith(parsed: parsed.copyWith(sections: sections));
  }

  Future<void> confirmReviewAndScore() async {
    final file = state.selectedFile;
    final parsed = state.parsed;
    if (file == null || parsed == null) return;

    state = state.copyWith(isBusy: true, clearFailure: true);
    try {
      final analysis = await _repository.analyzeResume(
        file: file,
        parsed: parsed,
      );
      await _persist(analysis);
      state = state.copyWith(
        phase: AnalysisPhase.completed,
        analysis: analysis,
        isBusy: false,
      );
    } catch (_) {
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        failure: const AnalysisFailure(
          code: 'analyze_failed',
          messageKey: 'analyzeErrorGeneric',
        ),
        isBusy: false,
      );
    }
  }

  Future<void> reanalyzeNewFile() async {
    state = state.copyWith(
      phase: AnalysisPhase.initial,
      clearFile: true,
      clearValidationError: true,
      clearFailure: true,
      clearProcessingStage: true,
      isBusy: false,
    );
  }

  Future<void> clearPersistedAnalysis() async {
    await _store.remove(_storageKey);
    state = const AnalysisUiState();
  }

  /// Hydrate from Builder structured check — no file re-upload.
  Future<void> applyExternalAnalysis(ResumeAnalysis analysis) async {
    await _persist(analysis);
    state = state.copyWith(
      phase: AnalysisPhase.completed,
      analysis: analysis,
      clearFailure: true,
      clearProcessingStage: true,
      isBusy: false,
    );
  }

  Future<void> _persist(ResumeAnalysis analysis) async {
    await _store.writeString(
      _storageKey,
      jsonEncode(_analysisToJson(analysis)),
    );
  }

  Map<String, dynamic> _analysisToJson(ResumeAnalysis a) {
    return {
      'id': a.id,
      'resumeId': a.resumeId,
      'overallScore': a.overallScore,
      'confidence': a.confidence.name,
      'engineVersion': a.engineVersion,
      'analyzedAt': a.analyzedAt.toIso8601String(),
      'fileName': a.fileName,
      'topImprovementIds': a.topImprovementIds,
      'workingWell': a.workingWell,
      'categories': a.categories
          .map(
            (c) => {
              'id': c.id.name,
              'score': c.score,
              'weight': c.weight,
              'summary': c.summary,
            },
          )
          .toList(),
      'findings': a.findings
          .map(
            (f) => {
              'id': f.id,
              'severity': f.severity.name,
              'title': f.title,
              'whyItMatters': f.whyItMatters,
              'evidence': f.evidence,
              'recommendedAction': f.recommendedAction,
              'categoryId': f.categoryId.name,
              'beforeText': f.beforeText,
              'afterText': f.afterText,
              'supportsAiImprove': f.supportsAiImprove,
            },
          )
          .toList(),
    };
  }

  ResumeAnalysis _analysisFromJson(Map<String, dynamic> map) {
    return ResumeAnalysis(
      id: map['id'] as String,
      resumeId: map['resumeId'] as String,
      overallScore: map['overallScore'] as int,
      confidence: ParserConfidence.values.firstWhere(
        (e) => e.name == map['confidence'],
      ),
      engineVersion: map['engineVersion'] as String,
      analyzedAt: DateTime.parse(map['analyzedAt'] as String),
      fileName: map['fileName'] as String,
      topImprovementIds: (map['topImprovementIds'] as List).cast<String>(),
      workingWell: (map['workingWell'] as List).cast<String>(),
      categories: (map['categories'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (c) => ScoreCategory(
              id: ScoreCategoryId.values.firstWhere((e) => e.name == c['id']),
              score: c['score'] as int,
              weight: (c['weight'] as num).toDouble(),
              summary: c['summary'] as String,
            ),
          )
          .toList(),
      findings: (map['findings'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (f) => AnalysisFinding(
              id: f['id'] as String,
              severity: FindingSeverity.values.firstWhere(
                (e) => e.name == f['severity'],
              ),
              title: f['title'] as String,
              whyItMatters: f['whyItMatters'] as String,
              evidence: f['evidence'] as String,
              recommendedAction: f['recommendedAction'] as String,
              categoryId: ScoreCategoryId.values.firstWhere(
                (e) => e.name == f['categoryId'],
              ),
              beforeText: f['beforeText'] as String?,
              afterText: f['afterText'] as String?,
              supportsAiImprove: f['supportsAiImprove'] as bool? ?? false,
            ),
          )
          .toList(),
    );
  }
}

final analysisControllerProvider =
    StateNotifierProvider<AnalysisController, AnalysisUiState>((ref) {
      return AnalysisController(
        repository: ref.watch(resumeAnalysisRepositoryProvider),
        store: ref.watch(localStoreProvider),
      );
    });
