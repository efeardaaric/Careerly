import '../domain/job_match_models.dart';

/// Deterministic early-career Job Match fixture (mock AI path).
abstract final class MockJobMatchFixture {
  static const engineVersion = 'mock-job-match-1.0.0';

  static JobMatchResult result({
    required ResumeSnapshot resume,
    required String jobTitle,
    String? company,
    String? jobUrl,
    String locale = 'en',
  }) {
    final tr = locale.toLowerCase().startsWith('tr');
    final resumeSkills = resume.skills.map((s) => s.toLowerCase()).toSet();
    final jdLower = jobTitle.toLowerCase();

    SkillMatchItem item(String skill, {bool required = true}) {
      final hit =
          resumeSkills.contains(skill.toLowerCase()) ||
          resume.projectBullets.any(
            (b) => b.toLowerCase().contains(skill.toLowerCase()),
          ) ||
          resume.tools.any((t) => t.toLowerCase() == skill.toLowerCase());
      if (hit) {
        return SkillMatchItem(
          skill: skill,
          status: SkillEvidenceStatus.matched,
          required: required,
          note: tr ? "CV'nizde gösterilmiş." : 'Demonstrated in your CV.',
        );
      }
      return SkillMatchItem(
        skill: skill,
        status: SkillEvidenceStatus.notDemonstrated,
        required: required,
        note: tr ? "CV'nizde gösterilmemiş." : 'Not demonstrated in your CV.',
      );
    }

    final skills = [
      item('Flutter'),
      item('Dart'),
      item('Git'),
      item('SQL'),
      item('Docker', required: false),
    ];

    final covered = skills
        .where(
          (s) =>
              s.status == SkillEvidenceStatus.matched ||
              s.status == SkillEvidenceStatus.partial,
        )
        .map((s) => s.skill)
        .toList();
    final missing = skills
        .where((s) => s.status == SkillEvidenceStatus.notDemonstrated)
        .map((s) => s.skill)
        .toList();

    // Deterministic score from weights — not invented hiring odds.
    const categories = [
      MatchCategory(
        id: JobMatchCategoryId.coreSkills,
        score: 72,
        weight: 0.30,
        summary: 'Core skills partially align with the posting.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.experienceProjects,
        score: 68,
        weight: 0.25,
        summary: 'Projects overlap some role responsibilities; outcome language can be stronger.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.responsibilities,
        score: 62,
        weight: 0.20,
        summary: 'Some responsibility themes appear partially; evidence should be clearer.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.education,
        score: 80,
        weight: 0.10,
        summary: 'Education keywords checked against your CV.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.tools,
        score: 70,
        weight: 0.10,
        summary: 'Tools/tech overlap computed from the posting.',
      ),
      MatchCategory(
        id: JobMatchCategoryId.languageOther,
        score: 85,
        weight: 0.05,
        summary: 'Language and other requirements evaluated.',
      ),
    ];

    final overall =
        (categories.fold<double>(0, (sum, c) => sum + c.score * c.weight) /
                categories.fold<double>(0, (sum, c) => sum + c.weight))
            .round()
            .clamp(0, 100);

    return JobMatchResult(
      id: 'jm_mock_${DateTime.now().millisecondsSinceEpoch}',
      resumeId: resume.resumeId,
      jobTitle: jobTitle.isEmpty ? 'Untitled role' : jobTitle,
      company: company,
      jobUrl: jobUrl,
      overallMatchScore: overall,
      scoreDisclaimer: tr
          ? 'Bu eşleşme skoru hizalanmayı gösterir; işe alınma olasılığı değildir.'
          : 'This match score shows alignment with the posting — not hiring probability.',
      categories: categories,
      skillMatches: skills,
      keywordsCovered: covered,
      keywordsMissing: missing,
      recommendations: [
        MatchRecommendation(
          id: 'jm_rec_impact',
          title: tr
              ? 'Proje maddesini role yaklaştırın'
              : 'Align a project bullet to the role',
          body: tr
              ? 'İlanda geçen bir sorumluluğu, yalnızca doğruysa ölçülebilir bir sonuçla bağlayın.'
              : 'Tie one real project outcome to a responsibility in the posting — only if true.',
          kind: 'cv_improvement',
          beforeText: tr
              ? 'Flutter ile kampüs uygulaması geliştirdim.'
              : 'Built a campus app with Flutter.',
          afterText: tr
              ? 'Flutter ile kampüs etkinlik uygulaması geliştirdim.'
              : 'Built a campus events app with Flutter.',
        ),
        MatchRecommendation(
          id: 'jm_rec_learn',
          title: tr ? 'Öğrenme fırsatı: SQL' : 'Learning opportunity: SQL',
          body: tr
              ? "CV'de gösterilmeyen bir gereksinim için kısa, dürüst bir öğrenme adımı ekleyin — uydurma deneyim yazmayın."
              : 'For a requirement not demonstrated in your CV, add an honest learning step — never invent experience.',
          kind: 'learning',
        ),
      ],
      verificationQuestions: [
        tr
            ? 'SQL deneyiminiz var mı? Varsa hangi projede?'
            : 'Do you have experience with SQL? If yes, in which project?',
      ],
      learningOpportunities: [
        tr
            ? 'SQL için küçük bir demo veya kurs notu eklemeyi düşünün.'
            : 'Consider a small demo or course note for SQL.',
      ],
      workingWell: [
        tr
            ? "CV'de projeler bölümü mevcut — staj/öğrenci başvuruları için güçlü."
            : 'Projects section is present — strong for internship/student applications.',
        if (jdLower.contains('intern') || jdLower.contains('staj'))
          tr
              ? 'Rol staj odaklı; erken kariyer profilinizle uyumlu.'
              : 'Internship-focused role aligns with an early-career profile.',
      ],
      engineVersion: engineVersion,
      matchedAt: DateTime.now().toUtc(),
    );
  }
}
