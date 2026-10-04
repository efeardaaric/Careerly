import 'package:equatable/equatable.dart';

enum SuggestionKind { weakOpening, firstPerson, tooLong, noMetric, formatting }

enum SuggestionImpact { high, medium, low }

enum SuggestionStatus { pending, accepted, edited, rejected }

enum RewriteMode { impact, concise, professional, jobTargeted, grammar }

extension RewriteModeApi on RewriteMode {
  String get apiName => this == RewriteMode.jobTargeted ? 'job_targeted' : name;
}

/// One proposed change to a single CV line. Applied only after the user decides.
class CvSuggestion extends Equatable {
  const CvSuggestion({
    required this.id,
    required this.sectionId,
    required this.sectionKey,
    required this.originalText,
    required this.kind,
    required this.impact,
    this.suggestedText,
    this.needsUserFact = false,
    this.source = 'rules',
    this.status = SuggestionStatus.pending,
    this.editedText,
  });

  final String id;
  final String sectionId;
  final String sectionKey;
  final String originalText;
  final String? suggestedText;
  final SuggestionKind kind;
  final SuggestionImpact impact;
  final bool needsUserFact;
  final String source;
  final SuggestionStatus status;
  final String? editedText;

  /// Text that replaces [originalText] when applied, or null if nothing to apply.
  String? get replacement => switch (status) {
    SuggestionStatus.accepted => suggestedText,
    SuggestionStatus.edited => editedText,
    _ => null,
  };

  CvSuggestion copyWith({
    String? suggestedText,
    String? source,
    SuggestionStatus? status,
    String? editedText,
    bool clearEdited = false,
  }) {
    return CvSuggestion(
      id: id,
      sectionId: sectionId,
      sectionKey: sectionKey,
      originalText: originalText,
      kind: kind,
      impact: impact,
      suggestedText: suggestedText ?? this.suggestedText,
      needsUserFact: needsUserFact,
      source: source ?? this.source,
      status: status ?? this.status,
      editedText: clearEdited ? null : (editedText ?? this.editedText),
    );
  }

  factory CvSuggestion.fromJson(Map<String, dynamic> json) {
    return CvSuggestion(
      id: json['id'] as String,
      sectionId: json['sectionId'] as String,
      sectionKey: json['sectionKey'] as String? ?? '',
      originalText: json['originalText'] as String,
      suggestedText: json['suggestedText'] as String?,
      kind: SuggestionKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => SuggestionKind.formatting,
      ),
      impact: SuggestionImpact.values.firstWhere(
        (e) => e.name == json['impact'],
        orElse: () => SuggestionImpact.low,
      ),
      needsUserFact: json['needsUserFact'] as bool? ?? false,
      source: json['source'] as String? ?? 'rules',
    );
  }

  @override
  List<Object?> get props => [
    id,
    sectionId,
    originalText,
    suggestedText,
    kind,
    impact,
    needsUserFact,
    source,
    status,
    editedText,
  ];
}

class SuggestionBatch {
  const SuggestionBatch({required this.suggestions, required this.aiAvailable});

  final List<CvSuggestion> suggestions;
  final bool aiAvailable;
}

/// Guarded AI rewrite. [accepted] is false when the backend kept the original.
class RewriteResult {
  const RewriteResult({
    required this.suggested,
    required this.accepted,
    this.factsAdded = const [],
  });

  final String suggested;
  final bool accepted;
  final List<String> factsAdded;

  factory RewriteResult.fromJson(Map<String, dynamic> json) {
    return RewriteResult(
      suggested: (json['suggested'] ?? json['suggestion'] ?? '') as String,
      accepted: json['accepted'] as bool? ?? false,
      factsAdded: (json['factsAdded'] as List?)?.cast<String>() ?? const [],
    );
  }
}
