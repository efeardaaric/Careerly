import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:careerly/features/analyze/domain/analysis_models.dart';
import 'package:careerly/features/analyze/domain/cv_display_name.dart';
import 'package:careerly/features/analyze/engine/cv_text_extractor.dart';
import 'package:careerly/features/analyze/engine/local_cv_analysis_engine.dart';
import 'package:careerly/features/analyze/engine/score_math.dart';
import 'package:careerly/features/analyze/engine/section_detector.dart';
import 'package:careerly/features/jobs/data/resume_snapshot_builder.dart';
import 'package:careerly/features/jobs/domain/job_match_models.dart';
import 'package:careerly/features/jobs/engine/local_job_match_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/analyze/application/analysis_controller.dart';
import 'package:careerly/features/analyze/data/local_resume_analysis_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('weighted example scores round to 78', () {
    final overall = ScoreMath.overall(const {
      ScoreCategoryId.atsCompatibility: 84,
      ScoreCategoryId.contentImpact: 72,
      ScoreCategoryId.experiencePresentation: 68,
      ScoreCategoryId.skillsRelevance: 76,
      ScoreCategoryId.structureReadability: 80,
      ScoreCategoryId.languageGrammar: 82,
      ScoreCategoryId.basicsContact: 90,
    });
    expect(overall, 78);
    expect(
      ScoreMath.overall(const {
        ScoreCategoryId.atsCompatibility: 84,
        ScoreCategoryId.contentImpact: 72,
        ScoreCategoryId.experiencePresentation: 68,
        ScoreCategoryId.skillsRelevance: 76,
        ScoreCategoryId.structureReadability: 80,
        ScoreCategoryId.languageGrammar: 82,
        ScoreCategoryId.basicsContact: 90,
      }),
      overall,
    );
  });

  test('filename normalization drops copy suffix and extensions', () {
    expect(
      CvDisplayName.normalize('Efe Arda Arıç CV.pdf (1).pdf'),
      'Efe Arda Arıç CV',
    );
    expect(CvDisplayName.sizeLabel(184 * 1024), '184 KB');
  });

  test('Turkish and English headings map to the same section keys', () {
    expect(SectionDetector.headingKey('İş Deneyimi'), 'experience');
    expect(SectionDetector.headingKey('Work Experience'), 'experience');
    expect(SectionDetector.headingKey('Eğitim Bilgileri'), 'education');
    expect(SectionDetector.headingKey('Yetenekler'), 'skills');
    expect(SectionDetector.headingKey('Profesyonel Özet'), 'summary');
  });

  test('same CV text produces the same score', () {
    const text = '''
Efe Arda Aric
efe@example.com
+90 555 111 22 33
Istanbul

Summary
Computer science student seeking an internship.

Experience
Developed an internal reporting tool for the campus team.
Supported weekly event promotion.

Education
B.Sc. Computer Science

Skills
Python, SQL, Excel

Projects
Built a small data cleanup script in Python.
''';
    final first = LocalCvAnalysisEngine.parseText(
      text: text,
      originalFileName: 'Efe Arda Aric CV.pdf',
      resumeId: 'cv-1',
    );
    final second = LocalCvAnalysisEngine.parseText(
      text: text,
      originalFileName: 'Efe Arda Aric CV.pdf',
      resumeId: 'cv-1',
    );
    final a = LocalCvAnalysisEngine.score(
      parsed: first,
      fileName: 'Efe Arda Aric CV',
    );
    final b = LocalCvAnalysisEngine.score(
      parsed: second,
      fileName: 'Efe Arda Aric CV',
    );
    expect(a.overallScore, b.overallScore);
    expect(a.engineVersion, ScoreMath.engineVersion);
    expect(a.categories, isNotEmpty);
    expect(
      a.findings.every((f) => !f.evidence.contains('30%')),
      isTrue,
    );
  });

  test('docx extraction keeps paragraph order', () {
    final xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>Efe Arda Aric</w:t></w:r></w:p>
    <w:p><w:r><w:t>efe@example.com</w:t></w:r></w:p>
    <w:p><w:r><w:t>Experience</w:t></w:r></w:p>
    <w:p><w:r><w:t>Developed a campus reporting tool.</w:t></w:r></w:p>
  </w:body>
</w:document>
''';
    final archive = Archive()
      ..addFile(ArchiveFile('word/document.xml', xml.length, utf8.encode(xml)));
    final bytes = ZipEncoder().encode(archive);
    final extracted = const CvTextExtractor().extract(
      extension: 'docx',
      bytes: bytes,
    );
    expect(extracted.text.indexOf('Efe Arda Aric'), lessThan(extracted.text.indexOf('Experience')));
    expect(extracted.text, contains('efe@example.com'));
  });

  test('job match does not claim a missing skill is possessed', () {
    final snapshot = ResumeSnapshotBuilder.fromStored(
      resumeId: 'cv-1',
      fileName: 'CV',
      evidence: CvEvidence(
        originalFileName: 'cv.pdf',
        displayName: 'CV',
        rawText: 'Python and SQL',
        parserConfidenceScore: 80,
        detectedLanguage: 'en',
        sections: const [],
        summary: 'Analyst',
      ),
    );
    final withSkills = ResumeSnapshot(
      resumeId: snapshot.resumeId,
      fileName: snapshot.fileName,
      skills: const ['Python', 'SQL'],
      experienceBullets: const ['Analyzed sales data with SQL'],
      projectBullets: const [],
      education: const ['B.Sc.'],
      tools: const [],
      languages: const [],
    );
    final result = LocalJobMatchEngine.match(
      JobMatchInput(
        resume: withSkills,
        jobTitle: 'Data Analyst',
        jobDescription:
            'The role requires Python, SQL, and AWS for cloud data pipelines.',
      ),
    );
    final aws = result.skillMatches.firstWhere((s) => s.skill == 'AWS');
    expect(aws.status, SkillEvidenceStatus.notDemonstrated);
    expect(aws.note!.toLowerCase(), contains('does not currently show'));
    expect(
      result.recommendations.any(
        (r) => r.body.toLowerCase().contains('do not invent'),
      ),
      isTrue,
    );
  });

  test('active CV analysis persists across a new controller', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();
    final repo = LocalResumeAnalysisRepository();
    final controller = AnalysisController(
      repository: repo,
      store: store,
      stageDelay: Duration.zero,
    );
    const text = '''
Ada Lovelace
ada@example.com
+44 20 7946 0958

Summary
Mathematician and writer with a focus on analytical engines.

Experience
Designed notes for an analytical engine used by the research team.

Education
Mathematics

Skills
Mathematics, Analysis
''';
    final parsed = LocalCvAnalysisEngine.parseText(
      text: text,
      originalFileName: 'Ada Lovelace CV.pdf',
      resumeId: 'ada',
    );
    final analysis = LocalCvAnalysisEngine.score(
      parsed: parsed,
      fileName: 'Ada Lovelace CV',
    );
    await controller.applyExternalAnalysis(analysis);
    // Persist evidence alongside the score.
    await store.writeString(
      'active_cv_record_json',
      jsonEncode({
        'analysis': {
          'id': analysis.id,
          'resumeId': analysis.resumeId,
          'overallScore': analysis.overallScore,
          'confidence': analysis.confidence.name,
          'engineVersion': analysis.engineVersion,
          'analyzedAt': analysis.analyzedAt.toIso8601String(),
          'fileName': analysis.fileName,
          'topImprovementIds': analysis.topImprovementIds,
          'workingWell': analysis.workingWell,
          'categories': analysis.categories
              .map(
                (c) => {
                  'id': c.id.name,
                  'score': c.score,
                  'weight': c.weight,
                  'summary': c.summary,
                },
              )
              .toList(),
          'findings': analysis.findings
              .map(
                (f) => {
                  'id': f.id,
                  'severity': f.severity.name,
                  'title': f.title,
                  'whyItMatters': f.whyItMatters,
                  'evidence': f.evidence,
                  'recommendedAction': f.recommendedAction,
                  'categoryId': f.categoryId.name,
                },
              )
              .toList(),
        },
        'evidence': parsed.evidence!.toJson(),
      }),
    );

    final restored = AnalysisController(
      repository: repo,
      store: store,
      stageDelay: Duration.zero,
    );
    expect(restored.state.analysis?.overallScore, analysis.overallScore);
    expect(restored.state.evidence?.displayName, 'Ada Lovelace CV');
    expect(restored.state.evidence?.email, 'ada@example.com');
    controller.dispose();
    restored.dispose();
  });
}
