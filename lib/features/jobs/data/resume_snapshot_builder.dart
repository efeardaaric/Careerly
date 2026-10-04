import '../domain/job_match_models.dart';
import '../../analyze/domain/analysis_models.dart';

/// Builds a Job Match resume snapshot from the last analysis + known fixture
/// evidence. Never invents skills beyond what analysis/fixture already showed.
abstract final class ResumeSnapshotBuilder {
  static ResumeSnapshot fromStored({
    required String resumeId,
    required String fileName,
    int? overallScore,
    CvEvidence? evidence,
  }) {
    if (evidence == null) {
      return ResumeSnapshot(
        resumeId: resumeId,
        fileName: fileName,
        overallScore: overallScore,
        skills: const [],
        experienceBullets: const [],
        projectBullets: const [],
        education: const [],
        tools: const [],
        languages: const [],
      );
    }
    final skills = evidence
        .linesFor('skills')
        .expand((line) => line.split(RegExp(r'[,;•]')))
        .map((s) => s.trim())
        .where((s) => s.length > 1 && s.length < 40)
        .toList();
    return ResumeSnapshot(
      resumeId: resumeId,
      fileName: evidence.displayName,
      overallScore: overallScore,
      skills: skills,
      tools: const [],
      experienceBullets: evidence.bulletsFor(const ['experience', 'volunteer']),
      projectBullets: evidence.bulletsFor(const ['projects']),
      education: evidence.linesFor('education'),
      languages: evidence.linesFor('languages'),
      summary: evidence.summary,
      sectionKeys: evidence.sections
          .where((s) => s.status != SectionStatus.missing)
          .map((s) => s.key)
          .toList(),
    );
  }

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
