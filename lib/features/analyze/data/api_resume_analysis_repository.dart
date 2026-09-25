import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/analysis_models.dart';
import '../domain/resume_analysis_repository.dart';
import 'cv_file_validator.dart';
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

  /// Cached full response from the last successful upload.
  AnalyzeApiEnvelope? _pending;

  @override
  Future<void> validateCvFile(SelectedCvFile file) async {
    _validator.validate(
      name: file.name,
      extension: file.extension,
      sizeBytes: file.sizeBytes,
    );
  }

  @override
  Future<ParsedResume> parseResume(SelectedCvFile file) async {
    await validateCvFile(file);
    final envelope = await _uploadAndAnalyze(file);
    _pending = envelope;
    return envelope.parsed;
  }

  @override
  Future<ResumeAnalysis> analyzeResume({
    required SelectedCvFile file,
    required ParsedResume parsed,
  }) async {
    final pending = _pending;
    if (pending != null && pending.parsed.resumeId == parsed.resumeId) {
      return pending.analysis;
    }
    final envelope = await _uploadAndAnalyze(file);
    _pending = envelope;
    return envelope.analysis;
  }

  Future<AnalyzeApiEnvelope> _uploadAndAnalyze(SelectedCvFile file) async {
    final bytes = await _resolveBytes(file);
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
      'locale': localeCode,
      if (careerStage != null) 'career_stage': careerStage,
      if (targetRole != null) 'target_role': targetRole,
    });

    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/resumes/analyze',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
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
      return AnalyzeApiEnvelope.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
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
      parsed: _parsedFromJson(parsedJson),
      analysis: _analysisFromJson(analysisJson),
      warnings: (json['warnings'] as List?)?.cast<String>() ?? const [],
    );
  }
}

ParsedResume _parsedFromJson(Map<String, dynamic> json) {
  return ParsedResume(
    resumeId: json['resumeId'] as String,
    confidence: ParserConfidence.values.firstWhere(
      (e) => e.name == json['confidence'],
      orElse: () => ParserConfidence.medium,
    ),
    engineVersion: json['engineVersion'] as String? ?? 'api',
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

ResumeAnalysis _analysisFromJson(Map<String, dynamic> json) {
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
  if (config.useMockAnalysis) {
    return MockResumeAnalysisRepository();
  }
  return ApiResumeAnalysisRepository(apiClient: ref.watch(apiClientProvider));
});
