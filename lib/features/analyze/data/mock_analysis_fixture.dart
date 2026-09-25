import '../domain/analysis_models.dart';

/// One realistic early-career fixture. Scores live here — never hard-coded in widgets.
abstract final class MockAnalysisFixture {
  static const engineVersion = 'mock-analysis-1.0.0';

  static ParsedResume parsedResume({required String resumeId}) {
    return ParsedResume(
      resumeId: resumeId,
      confidence: ParserConfidence.medium,
      engineVersion: engineVersion,
      sections: const [
        ResumeSection(
          id: 'sec_contact',
          key: 'contact',
          title: 'Contact',
          status: SectionStatus.detected,
          preview: 'Aylin Demir · aylin.demir@email.com · Istanbul',
        ),
        ResumeSection(
          id: 'sec_summary',
          key: 'summary',
          title: 'Summary',
          status: SectionStatus.needsReview,
          preview: 'Computer Science student seeking internship opportunities…',
          note: 'Heading looks informal; confirm this is your professional summary.',
        ),
        ResumeSection(
          id: 'sec_education',
          key: 'education',
          title: 'Education',
          status: SectionStatus.detected,
          preview: 'B.Sc. Computer Science · Expected 2027',
        ),
        ResumeSection(
          id: 'sec_experience',
          key: 'experience',
          title: 'Experience',
          status: SectionStatus.detected,
          preview: 'Marketing Intern · Campus Club · 2025',
        ),
        ResumeSection(
          id: 'sec_projects',
          key: 'projects',
          title: 'Projects',
          status: SectionStatus.detected,
          preview: 'Campus Event App · Flutter + Firebase',
        ),
        ResumeSection(
          id: 'sec_skills',
          key: 'skills',
          title: 'Skills',
          status: SectionStatus.needsReview,
          preview: 'Flutter, Dart, Python, teamwork, MS Office',
          note: 'Soft skills mixed with tools — consider separating them.',
        ),
        ResumeSection(
          id: 'sec_languages',
          key: 'languages',
          title: 'Languages',
          status: SectionStatus.detected,
          preview: 'Turkish (Native), English (B2)',
        ),
        ResumeSection(
          id: 'sec_certs',
          key: 'certifications',
          title: 'Certifications',
          status: SectionStatus.missing,
          note: 'No certifications section detected.',
        ),
        ResumeSection(
          id: 'sec_awards',
          key: 'awards',
          title: 'Awards / activities',
          status: SectionStatus.detected,
          preview: 'Volunteer · Coding Club mentor',
        ),
      ],
    );
  }

  static ResumeAnalysis analysis({
    required String resumeId,
    required String fileName,
    DateTime? analyzedAt,
  }) {
    const findings = <AnalysisFinding>[
      AnalysisFinding(
        id: 'finding_impact',
        severity: FindingSeverity.improve,
        title: 'Turn project work into measurable outcomes',
        whyItMatters: 'Early-career CVs stand out when projects show what changed because of your work — not only what you built.',
        evidence: 'Campus Event App bullet lists tech stack without results.',
        recommendedAction: 'Add one concrete outcome (users reached, time saved, or feature shipped) only if you have the real number.',
        categoryId: ScoreCategoryId.experiencePresentation,
        beforeText: 'Built a campus event app using Flutter and Firebase.',
        afterText: 'Built a Flutter campus event app used by 120+ students to RSVP and receive schedule updates.',
        supportsAiImprove: true,
      ),
      AnalysisFinding(
        id: 'finding_ats_heading',
        severity: FindingSeverity.critical,
        title: 'Use a standard Summary heading',
        whyItMatters: 'Unusual section titles can confuse ATS parsers and hide content from recruiters skimming quickly.',
        evidence: 'Detected informal heading near the top of the document.',
        recommendedAction: 'Rename to “Summary” or “Professional Summary” and keep it single-column.',
        categoryId: ScoreCategoryId.atsCompatibility,
        supportsAiImprove: false,
      ),
      AnalysisFinding(
        id: 'finding_skills_mix',
        severity: FindingSeverity.improve,
        title: 'Separate tools from soft skills',
        whyItMatters: 'Mixed skill lists make it harder for both ATS keyword matching and humans to scan your stack.',
        evidence: '“teamwork” appears beside Flutter and Dart.',
        recommendedAction: 'Keep technical tools in Skills; move soft skills into experience/project bullets with proof.',
        categoryId: ScoreCategoryId.skillsRelevance,
        supportsAiImprove: true,
      ),
      AnalysisFinding(
        id: 'finding_contact_good',
        severity: FindingSeverity.good,
        title: 'Contact details are complete',
        whyItMatters: 'A clear email and location help both parsers and recruiters reach you.',
        evidence: 'Email and city detected in the contact block.',
        recommendedAction:
            'Keep one professional email and avoid images for contact info.',
        categoryId: ScoreCategoryId.basicsContact,
      ),
      AnalysisFinding(
        id: 'finding_structure_good',
        severity: FindingSeverity.good,
        title: 'Single-column layout looks parser-safe',
        whyItMatters: 'Simple structure improves ATS extractability versus multi-column designs.',
        evidence: 'No table/column layout detected in primary content.',
        recommendedAction: 'Continue avoiding text boxes and skill bars.',
        categoryId: ScoreCategoryId.structureReadability,
      ),
    ];

    return ResumeAnalysis(
      id: 'analysis_mock_early_career',
      resumeId: resumeId,
      overallScore: 78,
      confidence: ParserConfidence.medium,
      engineVersion: engineVersion,
      analyzedAt: analyzedAt ?? DateTime.now().toUtc(),
      fileName: fileName,
      topImprovementIds: const [
        'finding_ats_heading',
        'finding_impact',
        'finding_skills_mix',
      ],
      workingWell: const [
        'Contact block includes email and location.',
        'Projects section is present — strong for students and interns.',
        'Layout appears single-column and ATS-friendly.',
      ],
      categories: const [
        ScoreCategory(
          id: ScoreCategoryId.atsCompatibility,
          score: 84,
          weight: 0.25,
          summary: 'Mostly parser-safe; one heading needs a standard label.',
        ),
        ScoreCategory(
          id: ScoreCategoryId.contentImpact,
          score: 72,
          weight: 0.20,
          summary: 'Clear activities, but impact metrics are still thin.',
        ),
        ScoreCategory(
          id: ScoreCategoryId.experiencePresentation,
          score: 68,
          weight: 0.15,
          summary: 'Internship and projects need sharper outcome language.',
        ),
        ScoreCategory(
          id: ScoreCategoryId.skillsRelevance,
          score: 76,
          weight: 0.15,
          summary:
              'Solid tools listed; soft skills should move out of the stack.',
        ),
        ScoreCategory(
          id: ScoreCategoryId.structureReadability,
          score: 80,
          weight: 0.10,
          summary: 'Readable order with consistent sectioning.',
        ),
        ScoreCategory(
          id: ScoreCategoryId.languageGrammar,
          score: 82,
          weight: 0.10,
          summary:
              'Generally clear professional English with minor polish left.',
        ),
        ScoreCategory(
          id: ScoreCategoryId.basicsContact,
          score: 90,
          weight: 0.05,
          summary: 'Email and location detected successfully.',
        ),
      ],
      findings: findings,
    );
  }
}
