import 'dart:convert';

import '../../analyze/domain/analysis_models.dart';
import '../../analyze/engine/phrasing_rules.dart';
import 'cv_suggestion.dart';

/// On-device mirror of backend `app/optimization/suggestions.py` for local and
/// mock engines. Keep both in sync; the API engine uses the backend.
abstract final class SuggestionRules {
  static const targetSections = {'experience', 'projects', 'volunteer'};
  static const maxSuggestions = 12;
  static const maxMetricQuestions = 4;
  static const longLineWords = 32;

  static final _bullet = PhrasingRules.bullet;
  static final _year = PhrasingRules.year;
  static final _digit = RegExp(r'\d');
  static final _firstPerson = PhrasingRules.firstPerson;
  static final _fillers = <RegExp, String>{
    RegExp(r'\bin order to\b', caseSensitive: false): 'to',
    RegExp(r'\butilized\b', caseSensitive: false): 'used',
    RegExp(r'\butilize\b', caseSensitive: false): 'use',
    RegExp(r'\bdue to the fact that\b', caseSensitive: false): 'because',
  };

  static String cleanLine(String text) {
    var value = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    value = value.replaceFirst(_firstPerson, '');
    _fillers.forEach((pattern, replacement) {
      value = value.replaceAll(pattern, replacement);
    });
    value = value.replaceAllMapped(RegExp(r'\s+([,.;:])'), (m) => m[1]!);
    if (value.isNotEmpty && value[0] != value[0].toUpperCase()) {
      value = value[0].toUpperCase() + value.substring(1);
    }
    return value;
  }

  static List<CvSuggestion> build(List<CvTextSection> sections) {
    final out = <CvSuggestion>[];
    final seen = <String>{};
    var metricBudget = maxMetricQuestions;
    for (final section in sections) {
      if (!targetSections.contains(section.key) ||
          section.status == SectionStatus.missing) {
        continue;
      }
      for (final raw in const LineSplitter().convert(section.body)) {
        final line = raw.replaceFirst(_bullet, '').trim();
        if (!_candidate(line) || seen.contains(line)) continue;
        final classified = _classify(line, metricBudget);
        if (classified == null) continue;
        final (kind, impact) = classified;
        if (kind == SuggestionKind.noMetric) metricBudget--;
        seen.add(line);
        final cleaned = cleanLine(line);
        out.add(
          CvSuggestion(
            id: '${section.id}:${line.hashCode.toUnsigned(32).toRadixString(16)}',
            sectionId: section.id,
            sectionKey: section.key,
            originalText: line,
            suggestedText: cleaned == line ? null : cleaned,
            kind: kind,
            impact: impact,
            needsUserFact:
                kind == SuggestionKind.weakOpening ||
                kind == SuggestionKind.noMetric,
          ),
        );
      }
    }
    out.sort((a, b) => a.impact.index.compareTo(b.impact.index));
    return out.take(maxSuggestions).toList();
  }

  static bool _candidate(String line) {
    final words = line.split(RegExp(r'\s+'));
    if (line.length < 20 || words.length < 4) return false;
    return !(_year.hasMatch(line) || line.endsWith(':'));
  }

  static (SuggestionKind, SuggestionImpact)? _classify(String line, int budget) {
    if (PhrasingRules.isWeakOpening(line)) {
      return (SuggestionKind.weakOpening, SuggestionImpact.high);
    }
    if (_firstPerson.hasMatch(line)) {
      return (SuggestionKind.firstPerson, SuggestionImpact.medium);
    }
    if (line.split(RegExp(r'\s+')).length > longLineWords) {
      return (SuggestionKind.tooLong, SuggestionImpact.medium);
    }
    if (!_digit.hasMatch(line) && budget > 0) {
      return (SuggestionKind.noMetric, SuggestionImpact.medium);
    }
    if (cleanLine(line) != line) {
      return (SuggestionKind.formatting, SuggestionImpact.low);
    }
    return null;
  }

  /// Replaces each decided line in its own section. Returns a new evidence copy.
  static CvEvidence apply(CvEvidence evidence, List<CvSuggestion> decided) {
    final bySection = <String, List<CvSuggestion>>{};
    for (final item in decided) {
      if (item.replacement == null || item.replacement!.trim().isEmpty) continue;
      bySection.putIfAbsent(item.sectionId, () => []).add(item);
    }
    if (bySection.isEmpty) return evidence;
    final sections = evidence.sections.map((section) {
      final items = bySection[section.id];
      if (items == null) return section;
      var body = section.body;
      for (final item in items) {
        body = body.replaceFirst(item.originalText, item.replacement!.trim());
      }
      return section.copyWith(body: body);
    }).toList();
    return evidence.copyWith(sections: sections);
  }
}
