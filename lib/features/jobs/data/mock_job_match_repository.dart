import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../domain/job_match_models.dart';
import '../domain/job_match_repository.dart';
import 'api_job_match_repository.dart';
import 'local_job_match_repository.dart';
import 'mock_job_match_fixture.dart';

class MockJobMatchRepository implements JobMatchRepository {
  MockJobMatchRepository({this.delay = const Duration(milliseconds: 900)});

  final Duration delay;

  @override
  Future<JobMatchResult> matchJob(JobMatchInput input) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return MockJobMatchFixture.result(
      resume: input.resume,
      jobTitle: input.jobTitle,
      company: input.company,
      jobUrl: input.jobUrl,
      locale: input.locale,
    );
  }
}

final jobMatchRepositoryProvider = Provider<JobMatchRepository>((ref) {
  switch (AppConfig.instance.analysisEngine) {
    case AnalysisEngine.mock:
      return MockJobMatchRepository();
    case AnalysisEngine.local:
      return LocalJobMatchRepository();
    case AnalysisEngine.api:
      return ApiJobMatchRepository(apiClient: ref.watch(apiClientProvider));
  }
});
