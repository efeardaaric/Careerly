import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/storage/local_store.dart';
import '../../analyze/application/analysis_controller.dart';
import '../data/mock_job_match_repository.dart';
import '../data/resume_snapshot_builder.dart';
import '../domain/job_match_models.dart';
import '../domain/job_match_repository.dart';

class JobMatchUiState extends Equatable {
  const JobMatchUiState({
    this.phase = JobMatchPhase.list,
    this.selectedResume,
    this.jobTitle = '',
    this.company = '',
    this.jobUrl = '',
    this.jobDescription = '',
    this.processingStage,
    this.result,
    this.savedMatches = const [],
    this.failureMessage,
    this.isBusy = false,
  });

  final JobMatchPhase phase;
  final ResumeSnapshot? selectedResume;
  final String jobTitle;
  final String company;
  final String jobUrl;
  final String jobDescription;
  final JobMatchProcessingStage? processingStage;
  final JobMatchResult? result;
  final List<JobMatchResult> savedMatches;
  final String? failureMessage;
  final bool isBusy;

  JobMatchResult? get mostRecentSaved =>
      savedMatches.isEmpty ? null : savedMatches.first;

  JobMatchUiState copyWith({
    JobMatchPhase? phase,
    ResumeSnapshot? selectedResume,
    bool clearResume = false,
    String? jobTitle,
    String? company,
    String? jobUrl,
    String? jobDescription,
    JobMatchProcessingStage? processingStage,
    bool clearProcessingStage = false,
    JobMatchResult? result,
    bool clearResult = false,
    List<JobMatchResult>? savedMatches,
    String? failureMessage,
    bool clearFailure = false,
    bool? isBusy,
  }) {
    return JobMatchUiState(
      phase: phase ?? this.phase,
      selectedResume: clearResume
          ? null
          : (selectedResume ?? this.selectedResume),
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      jobUrl: jobUrl ?? this.jobUrl,
      jobDescription: jobDescription ?? this.jobDescription,
      processingStage: clearProcessingStage
          ? null
          : (processingStage ?? this.processingStage),
      result: clearResult ? null : (result ?? this.result),
      savedMatches: savedMatches ?? this.savedMatches,
      failureMessage: clearFailure
          ? null
          : (failureMessage ?? this.failureMessage),
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    selectedResume,
    jobTitle,
    company,
    jobUrl,
    jobDescription,
    processingStage,
    result,
    savedMatches,
    failureMessage,
    isBusy,
  ];
}

class JobMatchController extends StateNotifier<JobMatchUiState> {
  JobMatchController({
    required this._repository,
    required this._store,
    required this.readAnalysis,
    required this.readLocale,
    required this.readCareerStage,
    this.stageDelay = const Duration(milliseconds: 450),
  }) : super(const JobMatchUiState()) {
    _restoreSaved();
  }

  final JobMatchRepository _repository;
  final LocalStore _store;
  final ResumeSnapshot? Function() readAnalysis;
  final String Function() readLocale;
  final String? Function() readCareerStage;
  final Duration stageDelay;

  static const storageKey = 'saved_job_matches_json';
  bool _cancelRequested = false;
  int _runToken = 0;

  void _restoreSaved() {
    final raw = _store.readString(storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(JobMatchResult.fromJson)
          .toList();
      state = state.copyWith(savedMatches: list);
    } catch (_) {
      // Ignore corrupt cache.
    }
  }

  Future<void> _persistSaved(List<JobMatchResult> matches) async {
    await _store.writeString(
      storageKey,
      jsonEncode(matches.map((m) => m.toJson()).toList()),
    );
  }

  void startNewMatch() {
    final snapshot = readAnalysis();
    state = state.copyWith(
      phase: snapshot == null ? JobMatchPhase.selectCv : JobMatchPhase.selectCv,
      clearResult: true,
      clearFailure: true,
      clearProcessingStage: true,
      selectedResume: snapshot,
      jobTitle: '',
      company: '',
      jobUrl: '',
      jobDescription: '',
      isBusy: false,
    );
  }

  void selectResume(ResumeSnapshot? snapshot) {
    state = state.copyWith(
      selectedResume: snapshot,
      clearResume: snapshot == null,
    );
  }

  void continueToJobForm() {
    if (state.selectedResume == null) return;
    state = state.copyWith(phase: JobMatchPhase.enterJob, clearFailure: true);
  }

  void updateJobTitle(String value) => state = state.copyWith(jobTitle: value);

  void updateCompany(String value) => state = state.copyWith(company: value);

  void updateJobUrl(String value) => state = state.copyWith(jobUrl: value);

  void updateJobDescription(String value) =>
      state = state.copyWith(jobDescription: value);

  void backToList() {
    _cancelRequested = true;
    _runToken++;
    state = state.copyWith(
      phase: JobMatchPhase.list,
      clearProcessingStage: true,
      clearFailure: true,
      isBusy: false,
    );
  }

  void openSaved(JobMatchResult match) {
    state = state.copyWith(
      phase: JobMatchPhase.results,
      result: match,
      clearFailure: true,
    );
  }

  Future<void> runMatch() async {
    final resume = state.selectedResume;
    final jd = state.jobDescription.trim();
    if (resume == null || jd.length < 20) {
      state = state.copyWith(
        failureMessage: 'job_description_too_short',
        phase: JobMatchPhase.enterJob,
      );
      return;
    }

    final token = ++_runToken;
    _cancelRequested = false;
    state = state.copyWith(
      phase: JobMatchPhase.processing,
      clearFailure: true,
      clearResult: true,
      isBusy: true,
      processingStage: JobMatchProcessingStage.readingJob,
    );

    final stagesFuture = _advanceStages(token);
    try {
      final input = JobMatchInput(
        resume: resume,
        jobTitle: state.jobTitle.trim().isEmpty
            ? 'Untitled role'
            : state.jobTitle.trim(),
        jobDescription: jd,
        company: state.company.trim().isEmpty ? null : state.company.trim(),
        jobUrl: state.jobUrl.trim().isEmpty ? null : state.jobUrl.trim(),
        locale: readLocale(),
        careerStage: readCareerStage(),
      );
      final result = await _repository.matchJob(input);
      await stagesFuture;
      if (_cancelRequested || token != _runToken) return;
      state = state.copyWith(
        phase: JobMatchPhase.results,
        result: result,
        clearProcessingStage: true,
        isBusy: false,
      );
    } catch (_) {
      if (_cancelRequested || token != _runToken) return;
      state = state.copyWith(
        phase: JobMatchPhase.failure,
        failureMessage: 'job_match_failed',
        clearProcessingStage: true,
        isBusy: false,
      );
    }
  }

  Future<void> _advanceStages(int token) async {
    for (final stage in JobMatchProcessingStage.values) {
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
      phase: JobMatchPhase.enterJob,
      clearProcessingStage: true,
      isBusy: false,
    );
  }

  void setSuggestionDecision(
    String recommendationId,
    SuggestionDecision decision, {
    String? editedText,
  }) {
    final result = state.result;
    if (result == null) return;
    final updated = result.recommendations
        .map(
          (r) => r.id == recommendationId
              ? r.copyWith(decision: decision, editedText: editedText)
              : r,
        )
        .toList();
    state = state.copyWith(result: result.copyWith(recommendations: updated));
  }

  Future<void> saveCurrentMatch() async {
    final result = state.result;
    if (result == null) return;
    final without = state.savedMatches.where((m) => m.id != result.id).toList();
    final next = [result, ...without].take(20).toList();
    await _persistSaved(next);
    state = state.copyWith(savedMatches: next, phase: JobMatchPhase.list);
  }

  Future<void> deleteSaved(String id) async {
    final next = state.savedMatches.where((m) => m.id != id).toList();
    await _persistSaved(next);
    state = state.copyWith(savedMatches: next);
  }

  Future<void> clearSavedMatches() async {
    await _store.remove(storageKey);
    state = state.copyWith(savedMatches: const []);
  }

  /// Clears in-memory match state after the signed-in user changes.
  void clearUserData() {
    _cancelRequested = true;
    _runToken++;
    state = const JobMatchUiState();
  }

  @override
  void dispose() {
    _cancelRequested = true;
    _runToken++;
    super.dispose();
  }
}

final jobMatchControllerProvider =
    StateNotifierProvider<JobMatchController, JobMatchUiState>((ref) {
      final controller = JobMatchController(
        repository: ref.watch(jobMatchRepositoryProvider),
        store: ref.watch(localStoreProvider),
        readAnalysis: () {
          final analysis = ref.read(analysisControllerProvider);
          if (analysis.analysis == null) return null;
          return ResumeSnapshotBuilder.fromStored(
            resumeId: analysis.analysis!.resumeId,
            fileName:
                analysis.evidence?.displayName ?? analysis.analysis!.fileName,
            overallScore: analysis.analysis!.overallScore,
            evidence: analysis.evidence,
          );
        },
        readLocale: () {
          final code = ref.read(sessionProvider).localeCode;
          return code ?? 'en';
        },
        readCareerStage: () => ref.read(sessionProvider).careerStage?.name,
      );
      final store = ref.watch(localStoreProvider);
      store.addUserDataResetListener(controller.clearUserData);
      ref.onDispose(
        () => store.removeUserDataResetListener(controller.clearUserData),
      );
      return controller;
    });
