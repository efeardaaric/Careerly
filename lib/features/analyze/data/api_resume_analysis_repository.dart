import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/analysis_models.dart';
import '../domain/resume_analysis_repository.dart';
import '../engine/local_cv_analysis_engine.dart';
import 'cv_file_validator.dart';
import 'local_resume_analysis_repository.dart';
import 'mock_resume_analysis_repository.dart';

/// Real backend analysis client. Swap in via [resumeAnalysisRepositoryProvider].
///
/// Path: lib/features/analyze/data/api_resume_analysis_repository.dart
class ApiResumeAnalysisRepository implements ResumeAnalysisRepository {
  ApiResumeAnalysisRepository({
    required ApiClient apiClient,
    this.localeCode = 'en',
    this.careerStage,
    this.targetRole,
    this._validator = const CvFileValidator(),
  }) : _api = apiClient;

  final ApiClient _api;
  final CvFileValidator _validator;
  final String localeCode;
  final String? careerStage;
  final String? targetRole;

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
    onStage?.call(AnalysisProcessingStage.readingStructure);
    final bytes = await _resolveBytes(file);
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
      'locale': localeCode,
      if (careerStage != null) 'career_stage': _careerStage(careerStage!),
      if (targetRole != null) 'target_fields': targetRole,
    });
    final data = await _postMap(
      '/api/v1/cvs/parse',
      form,
      contentType: 'multipart/form-data',
    );
    onStage?.call(AnalysisProcessingStage.detectingSections);
    return parsedResumeFromApi(data);
  }

  @override
  Future<ResumeAnalysis> analyzeResume({
    required SelectedCvFile file,
    required ParsedResume parsed,
  }) async {
    final evidence = parsed.evidence;
    await _patchMap('/api/v1/cvs/${parsed.resumeId}/parsed', {
      'sections': evidence == null
          ? parsed.sections
                .map(
                  (section) => {
                    'id': section.id,
                    'key': section.key,
                    'title': section.title,
                    'body': section.preview ?? '',
                    'status': section.status.name,
                  },
                )
                .toList()
          : evidence.sections.map((section) => section.toJson()).toList(),
      if (evidence != null)
        'contact': {
          'fullName': evidence.fullName,
          'email': evidence.email,
          'phone': evidence.phone,
          'location': evidence.location,
          'linkedIn': evidence.linkedIn,
          'github': evidence.github,
          'portfolio': evidence.portfolio,
        },
      if (evidence?.summary != null) 'summary': evidence!.summary,
    });
    final data = await _postMap('/api/v1/cvs/${parsed.resumeId}/analyze', null);
    return resumeAnalysisFromApi(data);
  }

  Future<Map<String, dynamic>> _postMap(
    String path,
    Object? body, {
    String? contentType,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(
          contentType: contentType,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(
          message: 'Empty analysis response',
          code: 'empty_response',
        );
      }
      return data;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> _patchMap(String path, Map<String, dynamic> body) async {
    try {
      await _api.patch<Map<String, dynamic>>(path, data: body);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  String _careerStage(String value) {
    return switch (value) {
      'newGraduate' => 'new_graduate',
      'careerChanger' => 'career_changer',
      _ => value,
    };
  }

  Future<Uint8List> _resolveBytes(SelectedCvFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return Uint8List.fromList(file.bytes!);
    }
    throw const AppException(
      message: 'CV bytes unavailable for upload. Please re-select the file.',
      code: 'missing_bytes',
    );
  }
}

class AnalyzeApiEnvelope {
  const AnalyzeApiEnvelope({
    required this.parsed,
    required this.analysis,
    required this.warnings,
  });

  final ParsedResume parsed;
  final ResumeAnalysis analysis;
  final List<String> warnings;

  factory AnalyzeApiEnvelope.fromJson(Map<String, dynamic> json) {
    final parsedJson = json['parsed'] as Map<String, dynamic>;
    final analysisJson = json['analysis'] as Map<String, dynamic>;
    return AnalyzeApiEnvelope(
      parsed: parsedResumeFromApi(parsedJson),
      analysis: resumeAnalysisFromApi(analysisJson),
      warnings: (json['warnings'] as List?)?.cast<String>() ?? const [],
    );
  }
}

ParsedResume parsedResumeFromApi(Map<String, dynamic> json) {
  final evidenceJson = json['evidence'];
  return ParsedResume(
    resumeId: json['resumeId'] as String,
    confidence: ParserConfidence.values.firstWhere(
      (e) => e.name == json['confidence'],
      orElse: () => ParserConfidence.medium,
    ),
    engineVersion: json['engineVersion'] as String? ?? '1.0.0',
    evidence: evidenceJson is Map<String, dynamic>
        ? CvEvidence.fromJson(evidenceJson)
        : evidenceJson is Map
        ? CvEvidence.fromJson(Map<String, dynamic>.from(evidenceJson))
        : null,
    sections: (json['sections'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (s) => ResumeSection(
            id: s['id'] as String,
            key: s['key'] as String,
            title: s['title'] as String,
            status: SectionStatus.values.firstWhere(
              (e) => e.name == s['status'],
              orElse: () => SectionStatus.detected,
            ),
            preview: s['preview'] as String?,
            note: s['note'] as String?,
          ),
        )
        .toList(),
  );
}

ResumeAnalysis resumeAnalysisFromApi(Map<String, dynamic> json) {
  return ResumeAnalysis(
    id: json['id'] as String,
    resumeId: json['resumeId'] as String,
    overallScore: json['overallScore'] as int,
    confidence: ParserConfidence.values.firstWhere(
      (e) => e.name == json['confidence'],
      orElse: () => ParserConfidence.medium,
    ),
    engineVersion: json['engineVersion'] as String? ?? 'api',
    analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    fileName: json['fileName'] as String,
    topImprovementIds:
        (json['topImprovementIds'] as List?)?.cast<String>() ?? const [],
    workingWell: (json['workingWell'] as List?)?.cast<String>() ?? const [],
    categories: (json['categories'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (c) => ScoreCategory(
            id: ScoreCategoryId.values.firstWhere((e) => e.name == c['id']),
            score: c['score'] as int,
            weight: (c['weight'] as num).toDouble(),
            summary: c['summary'] as String? ?? '',
          ),
        )
        .toList(),
    findings: (json['findings'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (f) => AnalysisFinding(
            id: f['id'] as String,
            severity: FindingSeverity.values.firstWhere(
              (e) => e.name == f['severity'],
              orElse: () => FindingSeverity.improve,
            ),
            title: f['title'] as String,
            whyItMatters: f['whyItMatters'] as String? ?? '',
            evidence: f['evidence'] as String? ?? '',
            recommendedAction: f['recommendedAction'] as String? ?? '',
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

final resumeAnalysisRepositoryProvider = Provider<ResumeAnalysisRepository>((
  ref,
) {
  final config = AppConfig.instance;
  if (config.analysisEngine == AnalysisEngine.mock) {
    return MockResumeAnalysisRepository();
  }
  if (config.analysisEngine == AnalysisEngine.local) {
    return LocalResumeAnalysisRepository(
      readProfile: () {
        final session = ref.read(sessionProvider);
        return AnalysisProfileContext(
          careerStage: session.careerStage,
          fields: session.fields,
          cvLanguage: session.cvLanguage,
          locale: session.localeCode ?? 'en',
        );
      },
    );
  }
  return ApiResumeAnalysisRepository(
    apiClient: ref.watch(apiClientProvider),
    localeCode: ref.watch(sessionProvider).localeCode ?? 'en',
    careerStage: ref.watch(sessionProvider).careerStage?.storageKey,
    targetRole: ref.watch(sessionProvider).fields.join(','),
  );
});
