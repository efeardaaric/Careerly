import 'package:careerly/core/errors/app_exception.dart';
import 'package:careerly/features/analyze/data/api_resume_analysis_repository.dart';
import 'package:careerly/features/analyze/domain/analysis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend error codes map to existing Analyze copy', () {
    expect(messageKeyForBackendCode('CV_TOO_LARGE'), 'analyzeErrorTooLarge');
    expect(
      messageKeyForBackendCode('UNSUPPORTED_CV_TYPE'),
      'analyzeErrorExtension',
    );
    expect(
      messageKeyForBackendCode('SCANNED_DOCUMENT_DETECTED'),
      'analyzeErrorScanned',
    );
    expect(
      messageKeyForBackendCode('CV_EXTRACTION_FAILED'),
      'analyzeErrorUnreadable',
    );
    expect(messageKeyForBackendCode('NETWORK_ERROR'), 'analyzeErrorUnavailable');
    expect(messageKeyForBackendCode('ANALYSIS_FAILED'), 'analyzeErrorGeneric');
  });

  test('parse payload becomes the shared CV record', () {
    final parsed = parsedResumeFromApi({
      'resumeId': 'cv-1',
      'confidence': 'high',
      'engineVersion': '1.0.0',
      'sections': [
        {
          'id': 'section_0',
          'key': 'experience',
          'title': 'Experience',
          'status': 'detected',
          'preview': 'Software Intern',
        },
      ],
      'evidence': {
        'originalFileName': 'Ada Yilmaz CV.pdf',
        'displayName': 'Ada Yilmaz CV',
        'rawText': '',
        'parserConfidenceScore': 80,
        'detectedLanguage': 'en',
        'email': 'ada.yilmaz@example.com',
        'sections': [
          {
            'id': 'section_0',
            'key': 'experience',
            'title': 'Experience',
            'body': 'Software Intern | Example Labs',
            'status': 'detected',
            'confidence': 0.9,
          },
        ],
      },
    });

    expect(parsed.resumeId, 'cv-1');
    expect(parsed.confidence, ParserConfidence.high);
    expect(parsed.evidence?.email, 'ada.yilmaz@example.com');
    expect(parsed.evidence?.rawText, isEmpty);
    expect(parsed.evidence?.sections.single.key, 'experience');
  });

  test('analysis payload keeps category ids and findings', () {
    final analysis = resumeAnalysisFromApi({
      'id': 'analysis-1',
      'resumeId': 'cv-1',
      'overallScore': 61,
      'confidence': 'medium',
      'engineVersion': '1.0.0',
      'analyzedAt': '2026-10-02T00:00:00Z',
      'fileName': 'Ada Yilmaz CV',
      'topImprovementIds': ['finding-1'],
      'workingWell': ['An email address was read from the CV.'],
      'categories': [
        {
          'id': 'atsCompatibility',
          'score': 70,
          'weight': 0.2,
          'summary': 'Parser checks only.',
        },
      ],
      'findings': [
        {
          'id': 'finding-1',
          'severity': 'improve',
          'title': 'Limited measurable impact',
          'whyItMatters': 'Only written results count.',
          'evidence': '1 of 4 experience/project bullets includes a measurable result.',
          'recommendedAction': 'Add a verified result if you have one.',
          'categoryId': 'contentImpact',
        },
      ],
    });

    expect(analysis.overallScore, 61);
    expect(analysis.categories.single.id, ScoreCategoryId.atsCompatibility);
    expect(analysis.findings.single.evidence, contains('1 of 4'));
    expect(analysis.topImprovements.single.title, 'Limited measurable impact');
  });
}
