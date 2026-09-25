import 'job_match_models.dart';

abstract class JobMatchRepository {
  Future<JobMatchResult> matchJob(JobMatchInput input);
}
