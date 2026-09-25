import 'package:careerly/features/analyze/data/api_resume_analysis_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AnalyzeApiEnvelope.fromJson maps backend payload', () {
    final envelope = AnalyzeApiEnvelope.fromJson({
      'resumeId': 'resume_abc',
      'fileName': 'cv.docx',
      'warnings': ['SCANNED_DOCUMENT_REQUIRES_OCR'],
      'analysisVersion': 'analysis-engine-3.0.0',
      'parsed': {
        'resumeId': 'resume_abc',
        'confidence': 'medium',
        'engineVersion': 'analysis-engine-3.0.0',
        'sections': [
          {
            'id': 'sec_contact',
            'key': 'contact',
            'title': 'Contact',
            'status': 'detected',
            'preview': 'a@b.com',
            'note': null,
          },
        ],
      },
      'analysis': {
        'id': 'analysis_resume_abc',
        'resumeId': 'resume_abc',
        'overallScore': 77,
        'confidence': 'medium',
        'engineVersion': 'analysis-engine-3.0.0',
        'analyzedAt': '2026-09-22T12:00:00.000Z',
        'fileName': 'cv.docx',
        'topImprovementIds': ['ats_missing_email'],
        'workingWell': ['Projects present'],
        'categories': [
          {
            'id': 'atsCompatibility',
            'score': 80,
            'weight': 0.25,
            'summary': 'ok',
          },
          {'id': 'contentImpact', 'score': 70, 'weight': 0.20, 'summary': 'ok'},
          {
            'id': 'experiencePresentation',
            'score': 68,
            'weight': 0.15,
            'summary': 'ok',
          },
          {
            'id': 'skillsRelevance',
            'score': 76,
            'weight': 0.15,
            'summary': 'ok',
          },
          {
            'id': 'structureReadability',
            'score': 80,
            'weight': 0.10,
            'summary': 'ok',
          },
          {
            'id': 'languageGrammar',
            'score': 82,
            'weight': 0.10,
            'summary': 'ok',
          },
          {'id': 'basicsContact', 'score': 90, 'weight': 0.05, 'summary': 'ok'},
        ],
        'findings': [
          {
            'id': 'ats_missing_email',
            'severity': 'critical',
            'title': 'Email',
            'whyItMatters': 'why',
            'evidence': 'ev',
            'recommendedAction': 'act',
            'categoryId': 'atsCompatibility',
            'supportsAiImprove': false,
          },
        ],
      },
    });

    expect(envelope.warnings, contains('SCANNED_DOCUMENT_REQUIRES_OCR'));
    expect(envelope.parsed.resumeId, 'resume_abc');
    expect(envelope.analysis.overallScore, 77);
    expect(envelope.analysis.categories.length, 7);
    expect(envelope.analysis.findings.first.severity.name, 'critical');
  });
}
