import 'package:careerly/features/analyze/domain/analysis_models.dart';
import 'package:careerly/features/optimization/domain/cv_suggestion.dart';
import 'package:careerly/features/optimization/domain/suggestion_rules.dart';
import 'package:flutter_test/flutter_test.dart';

CvTextSection _section(String body, {String key = 'experience'}) {
  return CvTextSection(
    id: 's-$key',
    key: key,
    title: key,
    body: body,
    status: SectionStatus.detected,
    confidence: 1,
  );
}

CvEvidence _evidence(List<CvTextSection> sections) {
  return CvEvidence(
    originalFileName: 'Ada Yilmaz CV.pdf',
    displayName: 'Ada Yilmaz CV',
    rawText: '',
    parserConfidenceScore: 90,
    sections: sections,
    detectedLanguage: 'en',
  );
}

void main() {
  test('weak opening asks for facts and offers no invented rewrite', () {
    final out = SuggestionRules.build([
      _section('- Responsible for social media accounts of the club'),
    ]);
    expect(out.single.kind, SuggestionKind.weakOpening);
    expect(out.single.impact, SuggestionImpact.high);
    expect(out.single.needsUserFact, isTrue);
    expect(out.single.suggestedText, isNull);
  });

  test('first person cleanup keeps every fact', () {
    final out = SuggestionRules.build([
      _section('- I developed a Flutter app for 40 students'),
    ]);
    expect(out.single.suggestedText, 'Developed a Flutter app for 40 students');
  });

  test('date lines and skills sections are ignored', () {
    final out = SuggestionRules.build([
      _section('Software Intern | Example Labs | Sep 2024 - Present'),
      _section('Flutter, Dart, Python, SQL and many more tools', key: 'skills'),
    ]);
    expect(out, isEmpty);
  });

  test('apply replaces only accepted or edited lines', () {
    final evidence = _evidence([
      _section(
        '- I developed a Flutter app for 40 students\n- Worked on reports with Power BI',
      ),
    ]);
    final items = SuggestionRules.build(evidence.sections);
    final accepted = items
        .firstWhere((s) => s.kind == SuggestionKind.firstPerson)
        .copyWith(status: SuggestionStatus.accepted);
    final edited = items
        .firstWhere((s) => s.kind == SuggestionKind.weakOpening)
        .copyWith(
          status: SuggestionStatus.edited,
          editedText: 'Built Power BI reports for the sales team',
        );
    final next = SuggestionRules.apply(evidence, [accepted, edited]);
    expect(
      next.sections.single.body,
      '- Developed a Flutter app for 40 students\n- Built Power BI reports for the sales team',
    );
  });

  test('rejected and pending suggestions change nothing', () {
    final evidence = _evidence([_section('- I developed a Flutter app for 40 students')]);
    final item = SuggestionRules.build(evidence.sections).single;
    expect(SuggestionRules.apply(evidence, [item]), evidence);
    expect(
      SuggestionRules.apply(evidence, [item.copyWith(status: SuggestionStatus.rejected)]),
      evidence,
    );
  });

  test('rewrite result defaults to not accepted on malformed payload', () {
    final result = RewriteResult.fromJson(const {});
    expect(result.accepted, isFalse);
    expect(result.suggested, '');
  });
}
