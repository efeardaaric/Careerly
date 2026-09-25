import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/job_match_models.dart';
import '../domain/job_match_repository.dart';

/// Real backend Job Match client.
/// Path: lib/features/jobs/data/api_job_match_repository.dart
class ApiJobMatchRepository implements JobMatchRepository {
  ApiJobMatchRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<JobMatchResult> matchJob(JobMatchInput input) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/jobs/match',
        data: {
          'resume': input.resume.toJson(),
          'jobTitle': input.jobTitle,
          'jobDescription': input.jobDescription,
          if (input.company != null && input.company!.isNotEmpty)
            'company': input.company,
          if (input.jobUrl != null && input.jobUrl!.isNotEmpty)
            'jobUrl': input.jobUrl,
          'locale': input.locale,
          if (input.careerStage != null) 'careerStage': input.careerStage,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(
          code: 'empty_response',
          message: 'Empty Job Match response',
        );
      }
      final matchJson = data['match'] as Map<String, dynamic>;
      return JobMatchResult.fromJson(matchJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(code: 'job_match_failed', message: e.toString());
    }
  }
}
