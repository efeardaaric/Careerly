import '../domain/job_match_models.dart';

/// Builds a Job Match resume snapshot from the last analysis + known fixture
/// evidence. Never invents skills beyond what analysis/fixture already showed.
abstract final class ResumeSnapshotBuilder {
  static ResumeSnapshot fromAnalyzedCv({
    required String resumeId,
    required String fileName,
    int? overallScore,
    List<String>? sectionKeys,
  }) {
    // Early-career demo evidence aligned with Phase 2/3 fixture — not invented.
    return ResumeSnapshot(
      resumeId: resumeId,
      fileName: fileName,
      overallScore: overallScore,
      skills: const ['Flutter', 'Dart', 'Python', 'teamwork', 'MS Office'],
      tools: const ['Firebase', 'Git'],
      experienceBullets: const [
        'Supported event promotion for student community',
      ],
      projectBullets: const [
        'Built a campus event app using Flutter and Firebase',
      ],
      education: const ['B.Sc. Computer Science · Expected 2027'],
      languages: const ['Turkish (Native)', 'English (B2)'],
      summary: 'Computer Science student seeking internship opportunities in software.',
      sectionKeys:
          sectionKeys ??
          const [
            'contact',
            'summary',
            'education',
            'experience',
            'projects',
            'skills',
            'languages',
          ],
    );
  }
}
