import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/local_store.dart';
import '../../analyze/application/analysis_controller.dart';
import '../../analyze/domain/analysis_models.dart';
import '../../analyze/domain/cv_display_name.dart';
import '../data/local_resume_document_repository.dart';
import '../domain/resume_document.dart';

enum SaveStatus { idle, saving, saved, error }

class BuilderUiState extends Equatable {
  const BuilderUiState({
    this.documents = const [],
    this.active,
    this.saveStatus = SaveStatus.idle,
    this.isBusy = false,
    this.errorMessage,
    this.previewZoom = 1.0,
  });

  final List<ResumeDocument> documents;
  final ResumeDocument? active;
  final SaveStatus saveStatus;
  final bool isBusy;
  final String? errorMessage;
  final double previewZoom;

  BuilderUiState copyWith({
    List<ResumeDocument>? documents,
    ResumeDocument? active,
    bool clearActive = false,
    SaveStatus? saveStatus,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    double? previewZoom,
  }) {
    return BuilderUiState(
      documents: documents ?? this.documents,
      active: clearActive ? null : (active ?? this.active),
      saveStatus: saveStatus ?? this.saveStatus,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      previewZoom: previewZoom ?? this.previewZoom,
    );
  }

  @override
  List<Object?> get props => [
    documents,
    active,
    saveStatus,
    isBusy,
    errorMessage,
    previewZoom,
  ];
}

class BuilderController extends StateNotifier<BuilderUiState> {
  BuilderController({
    required ResumeDocumentRepository repository,
    required this._ai,
    required this.readHasAnalysis,
    required this.readAnalysisMeta,
    this.autosaveDelay = const Duration(milliseconds: 700),
  }) : _repo = repository,
       super(const BuilderUiState()) {
    refreshList();
  }

  final ResumeDocumentRepository _repo;
  final BuilderAiRepository _ai;
  final bool Function() readHasAnalysis;
  final ({String analysisId, String fileName, CvEvidence? evidence})? Function()
  readAnalysisMeta;
  final Duration autosaveDelay;
  Timer? _debounce;
  int _generation = 0;

  bool _isCurrent(int generation) => mounted && generation == _generation;

  Future<void> refreshList() async {
    final generation = _generation;
    final docs = await _repo.listDocuments();
    if (!_isCurrent(generation)) return;
    state = state.copyWith(documents: docs);
  }

  bool get hasAnalyzedCv => readHasAnalysis();

  Future<void> createBlank({
    required CvDocumentLanguage language,
    required CvTemplateId templateId,
  }) async {
    final generation = _generation;
    final doc = ResumeDocument.blank(
      language: language,
      templateId: templateId,
    );
    await _repo.save(doc);
    if (!_isCurrent(generation)) return;
    await refreshList();
    if (!_isCurrent(generation)) return;
    state = state.copyWith(active: doc, saveStatus: SaveStatus.saved);
  }

  Future<void> createFromAnalyzed({
    required CvDocumentLanguage language,
    required CvTemplateId templateId,
  }) async {
    final generation = _generation;
    final meta = readAnalysisMeta();
    if (meta == null) {
      state = state.copyWith(errorMessage: 'no_analysis');
      return;
    }
    final doc = meta.evidence == null
        ? ResumeDocument.blank(
            language: language,
            templateId: templateId,
            title: CvDisplayName.normalize(meta.fileName),
          )
        : ResumeDocument.fromEvidence(
            evidence: meta.evidence!,
            analysisId: meta.analysisId,
            language: language,
            templateId: templateId,
          );
    await _repo.save(doc);
    if (!_isCurrent(generation)) return;
    await refreshList();
    if (!_isCurrent(generation)) return;
    state = state.copyWith(active: doc, saveStatus: SaveStatus.saved);
  }

  /// Opens a saved CV version as a new Builder document (Careerly template).
  Future<void> createFromVersion({
    required CvEvidence evidence,
    required String versionId,
  }) async {
    final generation = _generation;
    final doc = ResumeDocument.fromEvidence(
      evidence: evidence,
      analysisId: versionId,
      language: evidence.detectedLanguage == 'tr'
          ? CvDocumentLanguage.tr
          : CvDocumentLanguage.en,
    );
    await _repo.save(doc);
    if (!_isCurrent(generation)) return;
    await refreshList();
    if (!_isCurrent(generation)) return;
    state = state.copyWith(active: doc, saveStatus: SaveStatus.saved);
  }

  Future<void> openDocument(String id) async {
    final generation = _generation;
    final doc = await _repo.getById(id);
    if (!_isCurrent(generation)) return;
    state = state.copyWith(active: doc, clearActive: doc == null);
  }

  void closeEditor() {
    _debounce?.cancel();
    state = state.copyWith(clearActive: true, saveStatus: SaveStatus.idle);
  }

  /// Clears in-memory Builder state after the signed-in user changes.
  void clearUserData() {
    _generation++;
    _debounce?.cancel();
    state = const BuilderUiState();
  }

  void setZoom(double zoom) {
    state = state.copyWith(previewZoom: zoom.clamp(0.6, 1.6));
  }

  void updateActive(ResumeDocument Function(ResumeDocument current) transform) {
    final current = state.active;
    if (current == null) return;
    final next = transform(current).copyWith(updatedAt: DateTime.now().toUtc());
    state = state.copyWith(active: next, saveStatus: SaveStatus.saving);
    _scheduleAutosave(next);
  }

  void _scheduleAutosave(ResumeDocument doc) {
    final generation = _generation;
    _debounce?.cancel();
    _debounce = Timer(autosaveDelay, () async {
      try {
        await _repo.save(doc);
        if (!_isCurrent(generation)) return;
        if (state.active?.id == doc.id) {
          final documents = await _repo.listDocuments();
          if (!_isCurrent(generation)) return;
          state = state.copyWith(
            saveStatus: SaveStatus.saved,
            documents: documents,
          );
        }
      } catch (_) {
        if (!_isCurrent(generation)) return;
        state = state.copyWith(saveStatus: SaveStatus.error);
      }
    });
  }

  Future<void> rename(String id, String title) async {
    final generation = _generation;
    final doc = await _repo.getById(id);
    if (!_isCurrent(generation)) return;
    if (doc == null) return;
    final next = doc.copyWith(title: title, updatedAt: DateTime.now().toUtc());
    await _repo.save(next);
    if (!_isCurrent(generation)) return;
    await refreshList();
    if (!_isCurrent(generation)) return;
    if (state.active?.id == id) {
      state = state.copyWith(active: next);
    }
  }

  Future<void> duplicate(String id) async {
    final generation = _generation;
    final copy = await _repo.duplicate(id);
    if (!_isCurrent(generation)) return;
    await refreshList();
    if (!_isCurrent(generation)) return;
    state = state.copyWith(active: copy);
  }

  Future<void> delete(String id) async {
    final generation = _generation;
    await _repo.delete(id);
    if (!_isCurrent(generation)) return;
    await refreshList();
    if (!_isCurrent(generation)) return;
    if (state.active?.id == id) {
      state = state.copyWith(clearActive: true);
    }
  }

  Future<void> switchTemplate(CvTemplateId templateId) async {
    updateActive((d) => d.copyWith(templateId: templateId));
  }

  Future<RewriteSuggestion?> requestRewrite({
    required String mode,
    required String text,
    required String locale,
    String? sectionKey,
  }) async {
    final generation = _generation;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final ai = _ai;
      final suggestion = await ai.rewrite(
        mode: mode,
        text: text,
        locale: locale,
        sectionKey: sectionKey,
      );
      if (!_isCurrent(generation)) return null;
      state = state.copyWith(isBusy: false);
      return suggestion;
    } catch (_) {
      if (!_isCurrent(generation)) return null;
      state = state.copyWith(isBusy: false, errorMessage: 'rewrite_failed');
      return null;
    }
  }

  /// Translation creates a **new** document version (never overwrites in place).
  Future<ResumeDocument?> translateActive(CvDocumentLanguage target) async {
    final generation = _generation;
    final source = state.active;
    if (source == null) return null;
    if (source.language == target) return source;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final translated = await _ai.translateDocument(
        source: source,
        target: target,
      );
      if (!_isCurrent(generation)) return null;
      final version = ResumeDocument(
        id: const Uuid().v4(),
        title: '${translated.title} (${target.name.toUpperCase()})',
        language: target,
        templateId: translated.templateId,
        personal: translated.personal,
        summary: translated.summary,
        education: translated.education,
        experience: translated.experience,
        projects: translated.projects,
        skillGroups: translated.skillGroups,
        languages: translated.languages,
        certifications: translated.certifications,
        awards: translated.awards,
        customSections: translated.customSections,
        sectionOrder: translated.sectionOrder,
        sectionVisibility: translated.sectionVisibility,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        sourceAnalysisId: translated.sourceAnalysisId,
        parentDocumentId: source.id,
      );
      await _repo.save(version);
      if (!_isCurrent(generation)) return null;
      await refreshList();
      if (!_isCurrent(generation)) return null;
      state = state.copyWith(
        active: version,
        saveStatus: SaveStatus.saved,
        isBusy: false,
      );
      return version;
    } catch (_) {
      if (!_isCurrent(generation)) return null;
      state = state.copyWith(isBusy: false, errorMessage: 'translate_failed');
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkStructuredCv({
    required String locale,
  }) async {
    final generation = _generation;
    final doc = state.active;
    if (doc == null) return null;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _ai.checkDocument(document: doc, locale: locale);
      if (!_isCurrent(generation)) return null;
      state = state.copyWith(isBusy: false);
      return result;
    } catch (_) {
      if (!_isCurrent(generation)) return null;
      state = state.copyWith(isBusy: false, errorMessage: 'check_failed');
      return null;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final builderControllerProvider =
    StateNotifierProvider<BuilderController, BuilderUiState>((ref) {
      final controller = BuilderController(
        repository: ref.watch(resumeDocumentRepositoryProvider),
        ai: ref.watch(builderAiRepositoryProvider),
        readHasAnalysis: () =>
            ref.read(analysisControllerProvider).analysis != null,
        readAnalysisMeta: () {
          final state = ref.read(analysisControllerProvider);
          final analysis = state.analysis;
          if (analysis == null) return null;
          return (
            analysisId: analysis.id,
            fileName: state.evidence?.displayName ?? analysis.fileName,
            evidence: state.evidence,
          );
        },
      );
      final store = ref.watch(localStoreProvider);
      store.addUserDataResetListener(controller.clearUserData);
      ref.onDispose(
        () => store.removeUserDataResetListener(controller.clearUserData),
      );
      return controller;
    });

/// Builder AI rewrite client (mock locally or API).
class BuilderAiRepository {
  BuilderAiRepository({ApiClient? apiClient, this.useMock = true})
    : _api = apiClient;

  final ApiClient? _api;
  final bool useMock;

  Future<RewriteSuggestion> rewrite({
    required String mode,
    required String text,
    required String locale,
    String? sectionKey,
  }) async {
    if (useMock || _api == null) {
      return _mockRewrite(mode: mode, text: text, locale: locale);
    }
    final res = await _api.post<Map<String, dynamic>>(
      '/api/v1/builder/rewrite',
      data: {
        'mode': mode,
        'text': text,
        'locale': locale,
        'sectionKey': ?sectionKey,
      },
    );
    final data = res.data?['suggestion'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Empty rewrite response');
    }
    return RewriteSuggestion.fromJson(data);
  }

  Future<ResumeDocument> translateDocument({
    required ResumeDocument source,
    required CvDocumentLanguage target,
  }) async {
    if (useMock || _api == null) {
      return _mockTranslate(source, target);
    }
    final res = await _api.post<Map<String, dynamic>>(
      '/api/v1/builder/translate',
      data: {'targetLanguage': target.name, 'document': source.toJson()},
    );
    final data = res.data?['document'] as Map<String, dynamic>?;
    if (data == null) throw StateError('Empty translate response');
    return ResumeDocument.fromJson(data);
  }

  Future<Map<String, dynamic>> checkDocument({
    required ResumeDocument document,
    required String locale,
  }) async {
    if (useMock || _api == null) {
      return _mockCheck(document);
    }
    final res = await _api.post<Map<String, dynamic>>(
      '/api/v1/builder/check',
      data: {'document': document.toJson(), 'locale': locale},
    );
    final data = res.data;
    if (data == null) throw StateError('Empty check response');
    return data;
  }

  Map<String, dynamic> _mockCheck(ResumeDocument document) {
    final completeness = document.sectionOrder
        .where((k) => document.completionFor(k) == SectionCompletion.complete)
        .length;
    final score = (55 + completeness * 4).clamp(40, 92);
    return {
      'resumeId': document.id,
      'fileName': document.exportFileName(),
      'analysis': {
        'id': 'analysis_builder_${document.id}',
        'resumeId': document.id,
        'overallScore': score,
        'confidence': 'medium',
        'engineVersion': 'builder-mock',
        'analyzedAt': DateTime.now().toUtc().toIso8601String(),
        'fileName': document.exportFileName(),
        'topImprovementIds': const ['builder_impact'],
        'workingWell': const ['Structured sections present'],
        'categories': [
          {
            'id': 'atsCompatibility',
            'score': score,
            'weight': 0.2,
            'summary': 'Single-column structured CV is ATS-friendly.',
          },
        ],
        'findings': [
          {
            'id': 'builder_impact',
            'severity': 'improve',
            'title': 'Add measurable outcomes where true',
            'whyItMatters': 'Impact metrics help early-career CVs stand out.',
            'evidence': 'Checked structured Builder fields — no re-upload.',
            'recommendedAction':
                'Add a real number only if you have one — never invent.',
            'categoryId': 'contentImpact',
            'supportsAiImprove': true,
          },
        ],
      },
      'warnings': const ['Checked structured Builder CV — no file re-upload.'],
      'analysisVersion': 'builder-mock',
    };
  }

  RewriteSuggestion _mockRewrite({
    required String mode,
    required String text,
    required String locale,
  }) {
    final tr = locale.startsWith('tr');
    final looksMetricFree = !RegExp(r'\d').hasMatch(text);
    if (looksMetricFree && mode == 'improve') {
      return RewriteSuggestion(
        original: text,
        suggested: text,
        why: tr
            ? 'Ölçülebilir bir sonuç eklemek güçlendirir — sayıyı uydurmayız.'
            : 'A measurable outcome would strengthen this — we will not invent a number.',
        needsUserFact: true,
        missingFactPrompt: tr
            ? 'Kaç kişi kullandı veya ne değişti? (yalnızca gerçek rakam)'
            : 'How many people used it, or what changed? (real number only)',
      );
    }
    final suggested = switch (mode) {
      'concise' => text.length > 80 ? '${text.substring(0, 77)}…' : text,
      'professional' =>
        text
            .replaceAll('geliştirdim', 'geliştirdim ve teslim ettim')
            .replaceAll('Built', 'Designed and delivered'),
      _ => text.endsWith('.') ? text : '$text.',
    };
    return RewriteSuggestion(
      original: text,
      suggested: suggested,
      why: tr
          ? 'Anlam korunarak netlik artırıldı; yeni işveren/metrik eklenmedi.'
          : 'Clarity improved while preserving meaning — no new employers or metrics added.',
    );
  }

  ResumeDocument _mockTranslate(
    ResumeDocument source,
    CvDocumentLanguage target,
  ) {
    final tr = target == CvDocumentLanguage.tr;
    String map(String s) {
      if (s.trim().isEmpty) return s;
      // Preserve proper nouns; only translate common fixture phrases.
      return s
          .replaceAll(
            'Computer Science student seeking internship opportunities in software.',
            tr
                ? 'Yazılım alanında staj arayan Bilgisayar Mühendisliği öğrencisi.'
                : 'Computer Science student seeking internship opportunities in software.',
          )
          .replaceAll(
            'Supported event promotion for student community',
            tr
                ? 'Öğrenci topluluğu için etkinlik tanıtımına destek oldum.'
                : 'Supported event promotion for student community',
          )
          .replaceAll(
            'Built a campus event app using Flutter and Firebase',
            tr
                ? 'Flutter ve Firebase ile kampüs etkinlik uygulaması geliştirdim.'
                : 'Built a campus event app using Flutter and Firebase',
          );
    }

    return ResumeDocument(
      id: source.id, // caller assigns new id for version
      title: source.title,
      language: target,
      templateId: source.templateId,
      personal: source.personal, // names/emails preserved
      summary: map(source.summary),
      education: source.education,
      experience: source.experience
          .map(
            (e) => e.copyWith(
              title: map(e.title),
              bullets: e.bullets.map(map).toList(),
            ),
          )
          .toList(),
      projects: source.projects
          .map((p) => p.copyWith(bullets: p.bullets.map(map).toList()))
          .toList(),
      skillGroups: source.skillGroups,
      languages: source.languages,
      certifications: source.certifications,
      awards: source.awards
          .map((a) => a.copyWith(title: map(a.title)))
          .toList(),
      customSections: source.customSections,
      sectionOrder: source.sectionOrder,
      sectionVisibility: source.sectionVisibility,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      sourceAnalysisId: source.sourceAnalysisId,
      parentDocumentId: source.id,
    );
  }
}

final builderAiRepositoryProvider = Provider<BuilderAiRepository>((ref) {
  return BuilderAiRepository(
    apiClient: ref.watch(apiClientProvider),
    useMock: AppConfig.instance.analysisEngine != AnalysisEngine.api,
  );
});
