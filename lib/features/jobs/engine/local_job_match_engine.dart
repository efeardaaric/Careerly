import 'package:uuid/uuid.dart';

import '../domain/job_match_models.dart';

/// Deterministic comparison of a job description against CV evidence.
///
/// A missing skill means the CV does not show it. It does not mean the
/// person lacks the skill.
abstract final class LocalJobMatchEngine {
  static const engineVersion = 'local-job-match-1.1.0';

  static const _lexicon = [
    'python',
    'sql',
    'excel',
    'power bi',
    'tableau',
    'aws',
    'azure',
    'gcp',
    'flutter',
    'dart',
    'java',
    'javascript',
    'typescript',
    'react',
    'node',
    'git',
    'docker',
    'kubernetes',
    'figma',
    'salesforce',
    'sap',
    'r',
    'spark',
    'hadoop',
    'tensorflow',
    'pytorch',
    'pandas',
    'numpy',
    'looker',
    'jira',
    'agile',
    'scrum',
    'c++',
    'c#',
    'kotlin',
    'swift',
    'html',
    'css',
    'linux',
    'rest',
    'graphql',
    'postgresql',
    'mysql',
    'mongodb',
    'snowflake',
    'dbt',
    'airflow',
    'nlp',
    'machine learning',
    'data visualization',
    'statistics',
    'communication',
    'leadership',
  ];

  static JobMatchResult match(JobMatchInput input) {
    final tr = input.locale.toLowerCase().startsWith('tr');
    final resumeBlob = _resumeBlob(input.resume);
    final requirements = _requirements(input.jobDescription, input.jobTitle);
    final skills = <SkillMatchItem>[];
    for (final skill in requirements) {
      final status = _statusFor(skill, input.resume, resumeBlob);
      skills.add(
        SkillMatchItem(
          skill: skill,
          status: status,
          required: true,
          evidence: status == SkillEvidenceStatus.matched
              ? (tr ? "CV metninde geçiyor." : 'Shown in the CV text.')
              : null,
          note: switch (status) {
            SkillEvidenceStatus.matched => tr
                ? "CV'nizde bu beceri için kanıt var."
                : 'Your CV currently shows evidence of this.',
            SkillEvidenceStatus.partial => tr
                ? 'Yakın bir ifade var; aynı beceri net değil.'
                : 'A related phrase appears, but the skill is not explicit.',
            SkillEvidenceStatus.notDemonstrated => tr
                ? 'Bu ilan $skill diyor; CV\'niz şu an $skill deneyimi göstermiyor.'
                : 'This role mentions $skill, but your CV does not currently show $skill experience.',
            SkillEvidenceStatus.unclear => tr
                ? 'Eşleşme net değil.'
                : 'The overlap is unclear.',
          },
        ),
      );
    }

    final matched = skills
        .where((s) => s.status == SkillEvidenceStatus.matched)
        .length;
    final partial = skills
        .where((s) => s.status == SkillEvidenceStatus.partial)
        .length;
    final total = skills.isEmpty ? 1 : skills.length;
    final skillScore = (((matched + partial * 0.5) / total) * 100).round();

    final jdTokens = _keywords(input.jobDescription);
    final covered = jdTokens.where((t) => resumeBlob.contains(t)).toList();
    final missingKeywords = jdTokens
        .where((t) => !resumeBlob.contains(t))
        .take(12)
        .toList();
    final keywordScore = jdTokens.isEmpty
        ? 50
        : ((covered.length / jdTokens.length) * 100).round();

    final educationHit = _educationOverlap(input);
    final experienceScore = _experienceAlignment(input, resumeBlob);

    final categories = [
      MatchCategory(
        id: JobMatchCategoryId.coreSkills,
        score: skillScore.clamp(0, 100),
        weight: 0.40,
        summary: tr
            ? 'İlandan çıkarılan beceriler CV metniyle karşılaştırıldı.'
            : 'Skills extracted from the posting were compared with CV text.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.experienceProjects,
        score: experienceScore,
        weight: 0.25,
        summary: tr
            ? 'Deneyim ve proje maddelerindeki örtüşme.'
            : 'Overlap with experience and project bullets.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.education,
        score: educationHit,
        weight: 0.15,
        summary: tr
            ? 'Eğitim ifadeleri ilandaki eğitim ipuçlarıyla karşılaştırıldı.'
            : 'Education lines were compared with education cues in the posting.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.tools,
        score: skillScore.clamp(0, 100),
        weight: 0.10,
        summary: tr
            ? 'Araçlar beceri listesinin içinde sayıldı.'
            : 'Tools were counted inside the skill comparison.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.languageOther,
        score: keywordScore.clamp(0, 100),
        weight: 0.10,
        summary: tr
            ? 'Anahtar kelime kapsamı.'
            : 'Keyword coverage against the posting.',
      ),
    ];
    final weightSum = categories.fold<double>(0, (sum, c) => sum + c.weight);
    final overall = (categories.fold<double>(
              0,
              (sum, c) => sum + c.score * c.weight,
            ) /
            weightSum)
        .round()
        .clamp(0, 100);

    final recommendations = <MatchRecommendation>[];
    for (final missing in skills.where(
      (s) => s.status == SkillEvidenceStatus.notDemonstrated,
    ).take(3)) {
      recommendations.add(
        MatchRecommendation(
          id: 'gap_${missing.skill.toLowerCase().replaceAll(' ', '_')}',
          title: tr
              ? '${missing.skill} CV\'de görünmüyor'
              : '${missing.skill} is not shown on your CV',
          body: tr
              ? 'Bu rol ${missing.skill} diyor, ancak CV\'niz şu an ${missing.skill} deneyimi göstermiyor. Kullandıysan nerede ve nasıl kullandığını ekle. Kullanmadıysan deneyim uydurma.'
              : 'This role mentions ${missing.skill}, but your CV does not currently show ${missing.skill} experience. If you have used it, add where and how. If you have not, do not invent it.',
          kind: 'gap',
        ),
      );
    }

    return JobMatchResult(
      id: const Uuid().v4(),
      resumeId: input.resume.resumeId,
      jobTitle: input.jobTitle,
      company: input.company,
      jobUrl: null,
      overallMatchScore: overall,
      scoreDisclaimer: tr
          ? 'Bu eşleşme skoru ilanla hizalanmayı gösterir. İşe alınma olasılığı değildir.'
          : 'This match score shows alignment with the posting. It is not a hiring probability.',
      categories: categories,
      skillMatches: skills,
      keywordsCovered: covered.take(24).toList(),
      keywordsMissing: missingKeywords,
      recommendations: recommendations,
      verificationQuestions: recommendations
          .map(
            (r) => tr
                ? 'Bu deneyim sende varsa hangi projede?'
                : 'If you have this experience, which project shows it?',
          )
          .toList(),
      learningOpportunities: const [],
      workingWell: skills
          .where((s) => s.status == SkillEvidenceStatus.matched)
          .map((s) => s.skill)
          .take(4)
          .toList(),
      engineVersion: engineVersion,
      matchedAt: DateTime.now().toUtc(),
    );
  }

  static String _resumeBlob(ResumeSnapshot resume) {
    return [
      ...resume.skills,
      ...resume.tools,
      ...resume.experienceBullets,
      ...resume.projectBullets,
      ...resume.education,
      resume.summary ?? '',
    ].join('\n').toLowerCase();
  }

  static List<String> _requirements(String description, String title) {
    final haystack = '${title.toLowerCase()}\n${description.toLowerCase()}';
    final found = <String>[];
    for (final skill in _lexicon) {
      if (haystack.contains(skill) && !found.contains(_label(skill))) {
        found.add(_label(skill));
      }
    }
    return found;
  }

  static String _label(String skill) {
    if (skill == 'power bi') return 'Power BI';
    if (skill == 'machine learning') return 'Machine learning';
    if (skill == 'data visualization') return 'Data visualization';
    if (skill.length <= 3) return skill.toUpperCase();
    return skill[0].toUpperCase() + skill.substring(1);
  }

  static SkillEvidenceStatus _statusFor(
    String skill,
    ResumeSnapshot resume,
    String blob,
  ) {
    final needle = skill.toLowerCase();
    if (blob.contains(needle)) return SkillEvidenceStatus.matched;
    if (needle == 'data visualization' &&
        (blob.contains('dashboard') || blob.contains('görsel'))) {
      return SkillEvidenceStatus.partial;
    }
    if (needle == 'sql' && blob.contains('database')) {
      return SkillEvidenceStatus.partial;
    }
    return SkillEvidenceStatus.notDemonstrated;
  }

  static List<String> _keywords(String description) {
    final words = description
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9+#]+'))
        .where((w) => w.length >= 4)
        .where(
          (w) => !const {
            'with',
            'from',
            'that',
            'this',
            'your',
            'will',
            'have',
            'role',
            'team',
            'work',
            'and',
            'for',
            'the',
          }.contains(w),
        )
        .toSet()
        .toList();
    return words.take(24).toList();
  }

  static int _educationOverlap(JobMatchInput input) {
    final edu = input.resume.education.join(' ').toLowerCase();
    if (edu.isEmpty) return 40;
    final jd = input.jobDescription.toLowerCase();
    const cues = ['bachelor', 'master', 'degree', 'university', 'lisans', 'üniversite'];
    final asked = cues.where(jd.contains).toList();
    if (asked.isEmpty) return 80;
    final hit = asked.where(edu.contains).length;
    if (hit == 0 && edu.isNotEmpty) return 70;
    return (60 + (hit / asked.length) * 40).round().clamp(0, 100);
  }

  static int _experienceAlignment(JobMatchInput input, String blob) {
    final bullets = [
      ...input.resume.experienceBullets,
      ...input.resume.projectBullets,
    ];
    if (bullets.isEmpty) return 35;
    final tokens = _keywords(input.jobDescription);
    if (tokens.isEmpty) return 60;
    var hits = 0;
    for (final token in tokens) {
      if (blob.contains(token)) hits++;
    }
    return ((hits / tokens.length) * 100).round().clamp(0, 100);
  }
}
