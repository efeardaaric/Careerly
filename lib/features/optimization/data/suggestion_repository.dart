import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../analyze/domain/analysis_models.dart';
import '../domain/cv_suggestion.dart';
import '../domain/suggestion_rules.dart';

abstract class SuggestionRepository {
  Future<SuggestionBatch> suggestions({
    required String resumeId,
    required CvEvidence evidence,
  });

  /// Throws [AppException] with code `AI_DISABLED` when rewriting is off.
  Future<RewriteResult> rewrite({
    required String resumeId,
    required String text,
    required RewriteMode mode,
    String? jobContext,
  });
}

class ApiSuggestionRepository implements SuggestionRepository {
  ApiSuggestionRepository(this._api);

  final ApiClient _api;

  @override
  Future<SuggestionBatch> suggestions({
    required String resumeId,
    required CvEvidence evidence,
  }) async {
    final data = await _post('/api/v1/cvs/$resumeId/suggestions', null);
    return SuggestionBatch(
      aiAvailable: data['aiAvailable'] as bool? ?? false,
      suggestions: (data['suggestions'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(CvSuggestion.fromJson)
          .toList(),
    );
  }

  @override
  Future<RewriteResult> rewrite({
    required String resumeId,
    required String text,
    required RewriteMode mode,
    String? jobContext,
  }) async {
    final data = await _post('/api/v1/cvs/$resumeId/rewrite', {
      'text': text,
      'mode': mode.apiName,
      if (jobContext != null && jobContext.isNotEmpty) 'job_context': jobContext,
    });
    return RewriteResult.fromJson(data);
  }

  Future<Map<String, dynamic>> _post(String path, Object? body) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(path, data: body);
      return response.data ?? const {};
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}

/// Local and mock engines: same deterministic rules, no AI rewriting.
class LocalSuggestionRepository implements SuggestionRepository {
  const LocalSuggestionRepository();

  @override
  Future<SuggestionBatch> suggestions({
    required String resumeId,
    required CvEvidence evidence,
  }) async {
    return SuggestionBatch(
      suggestions: SuggestionRules.build(evidence.sections),
      aiAvailable: false,
    );
  }

  @override
  Future<RewriteResult> rewrite({
    required String resumeId,
    required String text,
    required RewriteMode mode,
    String? jobContext,
  }) {
    throw const AppException(message: 'AI rewrite is off', code: 'AI_DISABLED');
  }
}

final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  if (AppConfig.instance.analysisEngine == AnalysisEngine.api) {
    return ApiSuggestionRepository(ref.watch(apiClientProvider));
  }
  return const LocalSuggestionRepository();
});
