import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/local_store.dart';
import '../data/api_resume_analysis_repository.dart';
import '../data/cv_file_validator.dart';
import '../domain/analysis_models.dart';
import '../domain/resume_analysis_repository.dart';
import '../engine/local_cv_analysis_engine.dart';

class AnalysisUiState extends Equatable {
  const AnalysisUiState({
    this.phase = AnalysisPhase.initial,
    this.selectedFile,
    this.processingStage,
    this.parsed,
    this.analysis,
    this.evidence,
    this.failure,
    this.validationError,
    this.isBusy = false,
  });

  final AnalysisPhase phase;
  final SelectedCvFile? selectedFile;
  final AnalysisProcessingStage? processingStage;
  final ParsedResume? parsed;
  final ResumeAnalysis? analysis;
  final CvEvidence? evidence;
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
    CvEvidence? evidence,
    bool clearEvidence = false,
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
      evidence: clearEvidence ? null : (evidence ?? this.evidence),
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
    evidence,
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
    assert(stageDelay >= Duration.zero);
    _restore();
  }

  final ResumeAnalysisRepository _repository;
  final LocalStore _store;
  final Duration stageDelay;
  bool _cancelRequested = false;
  int _runToken = 0;

  static const _storageKey = 'active_cv_record_json';

  void _restore() {
    final raw =
        _store.readString(_storageKey) ??
        _store.readString('last_resume_analysis_json');
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final analysisMap = map.containsKey('analysis')
          ? map['analysis'] as Map<String, dynamic>
          : map;
      final analysis = _analysisFromJson(analysisMap);
      CvEvidence? evidence;
      if (map['evidence'] is Map<String, dynamic>) {
        evidence = CvEvidence.fromJson(map['evidence'] as Map<String, dynamic>);
      }
      state = state.copyWith(
        phase: AnalysisPhase.completed,
        analysis: analysis,
        evidence: evidence,
        parsed: evidence == null
            ? null
            : ParsedResume(
                resumeId: analysis.resumeId,
                sections: evidence.sections
                    .map(
                      (section) => ResumeSection(
                        id: section.id,
                        key: section.key,
                        title: section.title,
                        status: section.status,
                        preview: section.body.isEmpty ? null : section.body,
                      ),
                    )
                    .toList(),
                confidence: analysis.confidence,
                engineVersion: analysis.engineVersion,
                evidence: evidence,
              ),
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
      final parsed = await _repository.parseResume(
        file,
        onStage: (stage) {
          if (_cancelRequested || token != _runToken) return;
          state = state.copyWith(processingStage: stage);
        },
      );
      if (_cancelRequested || token != _runToken) return;

      state = state.copyWith(
        phase: AnalysisPhase.reviewRequired,
        parsed: parsed,
        evidence: parsed.evidence,
        clearProcessingStage: true,
        isBusy: false,
      );
    } on CvValidationException catch (e) {
      if (_cancelRequested || token != _runToken) return;
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        validationError: e.error,
        failure: AnalysisFailure(
          code: e.error.name,
          messageKey: _messageKeyFor(e.error),
        ),
        clearProcessingStage: true,
        isBusy: false,
      );
    } on AppException catch (error) {
      if (_cancelRequested || token != _runToken) return;
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        failure: AnalysisFailure(
          code: error.code ?? 'parse_failed',
          messageKey: messageKeyForBackendCode(error.code),
        ),
        clearProcessingStage: true,
        isBusy: false,
      );
    } catch (_) {
      if (_cancelRequested || token != _runToken) return;
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

  String _messageKeyFor(CvValidationError error) {
    return switch (error) {
      CvValidationError.tooLarge => 'analyzeErrorTooLarge',
      CvValidationError.invalidExtension => 'analyzeErrorExtension',
      CvValidationError.emptyFile => 'analyzeErrorEmpty',
      CvValidationError.unreadable => 'analyzeErrorUnreadable',
      CvValidationError.scanned => 'analyzeErrorScanned',
      CvValidationError.unavailable => 'analyzeErrorUnavailable',
      CvValidationError.cancelled => 'analyzeErrorCancelled',
      CvValidationError.unknown => 'analyzeErrorGeneric',
    };
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
    if (parsed.evidence != null) {
      final next = LocalCvAnalysisEngine.withSectionStatus(
        parsed: parsed,
        sectionId: sectionId,
        status: status,
      );
      state = state.copyWith(parsed: next, evidence: next.evidence);
      return;
    }
    final sections = parsed.sections
        .map((s) => s.id == sectionId ? s.copyWith(status: status) : s)
        .toList();
    state = state.copyWith(parsed: parsed.copyWith(sections: sections));
  }

  void reclassifySection(String sectionId, String newKey, String newTitle) {
    final parsed = state.parsed;
    if (parsed == null) return;
    final next = LocalCvAnalysisEngine.reclassify(
      parsed: parsed,
      sectionId: sectionId,
      newKey: newKey,
      newTitle: newTitle,
    );
    state = state.copyWith(parsed: next, evidence: next.evidence);
  }

  Future<bool> confirmReviewAndScore() async {
    final token = _runToken;
    final file = state.selectedFile;
    final parsed = state.parsed;
    if (file == null || parsed == null) return false;

    state = state.copyWith(
      isBusy: true,
      clearFailure: true,
      phase: AnalysisPhase.processing,
      processingStage: AnalysisProcessingStage.checkingAts,
    );
    try {
      state = state.copyWith(
        processingStage: AnalysisProcessingStage.reviewingContent,
      );
      final analysis = await _repository.analyzeResume(
        file: file,
        parsed: parsed,
      );
      if (!mounted || token != _runToken) return false;
      await _persist(analysis, parsed.evidence);
      if (!mounted || token != _runToken) return false;
      state = state.copyWith(
        phase: AnalysisPhase.completed,
        analysis: analysis,
        evidence: parsed.evidence,
        clearProcessingStage: true,
        isBusy: false,
      );
      return true;
    } on AppException catch (error) {
      if (!mounted || token != _runToken) return false;
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        failure: AnalysisFailure(
          code: error.code ?? 'analyze_failed',
          messageKey: messageKeyForBackendCode(error.code),
        ),
        isBusy: false,
      );
      return false;
    } catch (_) {
      if (!mounted || token != _runToken) return false;
      state = state.copyWith(
        phase: AnalysisPhase.failure,
        failure: const AnalysisFailure(
          code: 'analyze_failed',
          messageKey: 'analyzeErrorGeneric',
        ),
        isBusy: false,
      );
      return false;
    }
  }

  /// Scores edited CV text with the active engine. The previous analysis stays
  /// in place if scoring fails; scores only change when the engine returns.
  Future<ResumeAnalysis?> rescoreEdited(CvEvidence edited) async {
    final token = _runToken;
    final current = state.analysis;
    if (current == null) return null;
    final base = state.parsed;
    final parsed = ParsedResume(
      resumeId: current.resumeId,
      confidence: base?.confidence ?? current.confidence,
      engineVersion: base?.engineVersion ?? current.engineVersion,
      evidence: edited,
      sections: edited.sections
          .map(
            (section) => ResumeSection(
              id: section.id,
              key: section.key,
              title: section.title,
              status: section.status,
              preview: section.body.isEmpty ? null : section.body,
            ),
          )
          .toList(),
    );
    final file =
        state.selectedFile ??
        SelectedCvFile(
          name: edited.originalFileName,
          extension: edited.originalFileName.split('.').last.toLowerCase(),
          sizeBytes: 0,
          path: null,
        );
    final analysis = await _repository.analyzeResume(
      file: file,
      parsed: parsed,
    );
    if (!mounted || token != _runToken) return null;
    await _persist(analysis, edited);
    if (!mounted || token != _runToken) return null;
    state = state.copyWith(
      phase: AnalysisPhase.completed,
      analysis: analysis,
      evidence: edited,
      parsed: parsed,
      clearFailure: true,
    );
    return analysis;
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
    await _store.remove('cv_versions_json');
    state = const AnalysisUiState();
  }

  /// Clears in-memory analysis state after the signed-in user changes.
  void clearUserData() {
    _cancelRequested = true;
    _runToken++;
    state = const AnalysisUiState();
  }

  @override
  void dispose() {
    _cancelRequested = true;
    _runToken++;
    super.dispose();
  }

  Future<void> applyExternalAnalysis(ResumeAnalysis analysis) async {
    final token = _runToken;
    await _persist(analysis, state.evidence);
    if (!mounted || token != _runToken) return;
    state = state.copyWith(
      phase: AnalysisPhase.completed,
      analysis: analysis,
      clearFailure: true,
      clearProcessingStage: true,
      isBusy: false,
    );
  }

  Future<void> _persist(ResumeAnalysis analysis, CvEvidence? evidence) async {
    await _store.writeString(
      _storageKey,
      jsonEncode({
        'analysis': _analysisToJson(analysis),
        if (evidence != null) 'evidence': evidence.toJson(),
      }),
    );
    await _store.remove('last_resume_analysis_json');
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
      final controller = AnalysisController(
        repository: ref.watch(resumeAnalysisRepositoryProvider),
        store: ref.watch(localStoreProvider),
      );
      final store = ref.watch(localStoreProvider);
      store.addUserDataResetListener(controller.clearUserData);
      ref.onDispose(
        () => store.removeUserDataResetListener(controller.clearUserData),
      );
      return controller;
    });
