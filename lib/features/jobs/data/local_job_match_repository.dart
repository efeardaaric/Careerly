import '../domain/job_match_models.dart';
import '../domain/job_match_repository.dart';
import '../engine/local_job_match_engine.dart';

class LocalJobMatchRepository implements JobMatchRepository {
  @override
  Future<JobMatchResult> matchJob(JobMatchInput input) async {
    return LocalJobMatchEngine.match(input);
  }
}
