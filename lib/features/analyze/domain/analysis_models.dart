import 'package:equatable/equatable.dart';

/// Careerly structured readiness score categories (product §8).
enum ScoreCategoryId {
  atsCompatibility,
  contentImpact,
  experiencePresentation,
  skillsRelevance,
  structureReadability,
  languageGrammar,
  basicsContact,
}

enum FindingSeverity { critical, improve, good }

enum SectionStatus { detected, missing, needsReview }

enum ParserConfidence { high, medium, low }

enum AnalysisPhase {
  initial,
  fileSelected,
  validating,
  ready,
  processing,
  reviewRequired,
  completed,
  failure,
}

enum AnalysisProcessingStage {
  readingStructure,
  detectingSections,
  checkingAts,
  reviewingContent,
}

class SelectedCvFile extends Equatable {
  const SelectedCvFile({
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.path,
    this.bytes,
  });

  final String name;
  final String extension;
  final int sizeBytes;
  final String? path;

  /// Optional in-memory bytes (needed for web / API multipart uploads).
  final List<int>? bytes;

  String get typeLabel => extension.toUpperCase();

  double get sizeMb => sizeBytes / (1024 * 1024);

  @override
  List<Object?> get props => [name, extension, sizeBytes, path, bytes];
}

class Resume extends Equatable {
  const Resume({
    required this.id,
    required this.title,
    required this.fileName,
    required this.sourceType,
    required this.languageHint,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String fileName;
  final String sourceType;
  final String languageHint;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    title,
    fileName,
    sourceType,
    languageHint,
    createdAt,
    updatedAt,
  ];
}

class ResumeSection extends Equatable {
  const ResumeSection({
    required this.id,
    required this.key,
    required this.title,
    required this.status,
    this.preview,
    this.note,
  });

  final String id;
  final String key;
  final String title;
  final SectionStatus status;
  final String? preview;
  final String? note;

  ResumeSection copyWith({
    SectionStatus? status,
    String? preview,
    String? note,
  }) {
    return ResumeSection(
      id: id,
      key: key,
      title: title,
      status: status ?? this.status,
      preview: preview ?? this.preview,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, key, title, status, preview, note];
}

class ParsedResume extends Equatable {
  const ParsedResume({
    required this.resumeId,
    required this.sections,
    required this.confidence,
    required this.engineVersion,
  });

  final String resumeId;
  final List<ResumeSection> sections;
  final ParserConfidence confidence;
  final String engineVersion;

  ParsedResume copyWith({List<ResumeSection>? sections}) {
    return ParsedResume(
      resumeId: resumeId,
      sections: sections ?? this.sections,
      confidence: confidence,
      engineVersion: engineVersion,
    );
  }

  @override
  List<Object?> get props => [resumeId, sections, confidence, engineVersion];
}

class ScoreCategory extends Equatable {
  const ScoreCategory({
    required this.id,
    required this.score,
    required this.weight,
    required this.summary,
  });

  final ScoreCategoryId id;
  final int score;
  final double weight;
  final String summary;

  @override
  List<Object?> get props => [id, score, weight, summary];
}

class AnalysisFinding extends Equatable {
  const AnalysisFinding({
    required this.id,
    required this.severity,
    required this.title,
    required this.whyItMatters,
    required this.evidence,
    required this.recommendedAction,
    required this.categoryId,
    this.beforeText,
    this.afterText,
    this.supportsAiImprove = false,
  });

  final String id;
  final FindingSeverity severity;
  final String title;
  final String whyItMatters;
  final String evidence;
  final String recommendedAction;
  final ScoreCategoryId categoryId;
  final String? beforeText;
  final String? afterText;
  final bool supportsAiImprove;

  @override
  List<Object?> get props => [
    id,
    severity,
    title,
    whyItMatters,
    evidence,
    recommendedAction,
    categoryId,
    beforeText,
    afterText,
    supportsAiImprove,
  ];
}

class ResumeAnalysis extends Equatable {
  const ResumeAnalysis({
    required this.id,
    required this.resumeId,
    required this.overallScore,
    required this.confidence,
    required this.categories,
    required this.findings,
    required this.workingWell,
    required this.topImprovementIds,
    required this.engineVersion,
    required this.analyzedAt,
    required this.fileName,
  });

  final String id;
  final String resumeId;
  final int overallScore;
  final ParserConfidence confidence;
  final List<ScoreCategory> categories;
  final List<AnalysisFinding> findings;
  final List<String> workingWell;
  final List<String> topImprovementIds;
  final String engineVersion;
  final DateTime analyzedAt;
  final String fileName;

  List<AnalysisFinding> get topImprovements => topImprovementIds
      .map((id) => findings.where((f) => f.id == id))
      .expand((e) => e)
      .take(3)
      .toList();

  ScoreCategory? category(ScoreCategoryId id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    resumeId,
    overallScore,
    confidence,
    categories,
    findings,
    workingWell,
    topImprovementIds,
    engineVersion,
    analyzedAt,
    fileName,
  ];
}

class AnalysisFailure extends Equatable {
  const AnalysisFailure({required this.code, required this.messageKey});

  final String code;
  final String messageKey;

  @override
  List<Object?> get props => [code, messageKey];
}
