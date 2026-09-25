import 'package:equatable/equatable.dart';

enum SkillEvidenceStatus { matched, partial, notDemonstrated, unclear }

enum JobMatchCategoryId {
  coreSkills,
  experienceProjects,
  responsibilities,
  education,
  tools,
  languageOther,
}

enum JobMatchPhase { list, selectCv, enterJob, processing, results, failure }

enum JobMatchProcessingStage {
  readingJob,
  matchingSkills,
  scoringAlignment,
  draftingSuggestions,
}

enum SuggestionDecision { pending, accepted, edited, rejected }

/// Structured resume evidence sent to Job Match (never invents skills).
class ResumeSnapshot extends Equatable {
  const ResumeSnapshot({
    required this.resumeId,
    required this.fileName,
    required this.skills,
    required this.experienceBullets,
    required this.projectBullets,
    required this.education,
    required this.tools,
    required this.languages,
    this.summary,
    this.sectionKeys = const [],
    this.overallScore,
  });

  final String resumeId;
  final String fileName;
  final List<String> skills;
  final List<String> experienceBullets;
  final List<String> projectBullets;
  final List<String> education;
  final List<String> tools;
  final List<String> languages;
  final String? summary;
  final List<String> sectionKeys;
  final int? overallScore;

  Map<String, dynamic> toJson() => {
    'resumeId': resumeId,
    'fileName': fileName,
    'skills': skills,
    'experienceBullets': experienceBullets,
    'projectBullets': projectBullets,
    'education': education,
    'tools': tools,
    'languages': languages,
    'summary': summary,
    'sectionKeys': sectionKeys,
  };

  factory ResumeSnapshot.fromJson(Map<String, dynamic> json) {
    return ResumeSnapshot(
      resumeId: json['resumeId'] as String,
      fileName: json['fileName'] as String? ?? 'CV',
      skills: (json['skills'] as List?)?.cast<String>() ?? const [],
      experienceBullets:
          (json['experienceBullets'] as List?)?.cast<String>() ?? const [],
      projectBullets:
          (json['projectBullets'] as List?)?.cast<String>() ?? const [],
      education: (json['education'] as List?)?.cast<String>() ?? const [],
      tools: (json['tools'] as List?)?.cast<String>() ?? const [],
      languages: (json['languages'] as List?)?.cast<String>() ?? const [],
      summary: json['summary'] as String?,
      sectionKeys: (json['sectionKeys'] as List?)?.cast<String>() ?? const [],
      overallScore: json['overallScore'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    resumeId,
    fileName,
    skills,
    experienceBullets,
    projectBullets,
    education,
    tools,
    languages,
    summary,
    sectionKeys,
    overallScore,
  ];
}

class SkillMatchItem extends Equatable {
  const SkillMatchItem({
    required this.skill,
    required this.status,
    required this.required,
    this.evidence,
    this.note,
  });

  final String skill;
  final SkillEvidenceStatus status;
  final bool required;
  final String? evidence;
  final String? note;

  factory SkillMatchItem.fromJson(Map<String, dynamic> json) {
    return SkillMatchItem(
      skill: json['skill'] as String,
      status: SkillEvidenceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SkillEvidenceStatus.notDemonstrated,
      ),
      required: json['required'] as bool? ?? true,
      evidence: json['evidence'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'skill': skill,
    'status': status.name,
    'required': required,
    'evidence': evidence,
    'note': note,
  };

  @override
  List<Object?> get props => [skill, status, required, evidence, note];
}

class MatchCategory extends Equatable {
  const MatchCategory({
    required this.id,
    required this.score,
    required this.weight,
    required this.summary,
  });

  final JobMatchCategoryId id;
  final int score;
  final double weight;
  final String summary;

  factory MatchCategory.fromJson(Map<String, dynamic> json) {
    return MatchCategory(
      id: JobMatchCategoryId.values.firstWhere(
        (e) => e.name == json['id'],
        orElse: () => JobMatchCategoryId.coreSkills,
      ),
      score: json['score'] as int,
      weight: (json['weight'] as num).toDouble(),
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.name,
    'score': score,
    'weight': weight,
    'summary': summary,
  };

  @override
  List<Object?> get props => [id, score, weight, summary];
}

class MatchRecommendation extends Equatable {
  const MatchRecommendation({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.beforeText,
    this.afterText,
    this.decision = SuggestionDecision.pending,
    this.editedText,
  });

  final String id;
  final String title;
  final String body;
  final String kind;
  final String? beforeText;
  final String? afterText;
  final SuggestionDecision decision;
  final String? editedText;

  MatchRecommendation copyWith({
    SuggestionDecision? decision,
    String? editedText,
  }) {
    return MatchRecommendation(
      id: id,
      title: title,
      body: body,
      kind: kind,
      beforeText: beforeText,
      afterText: afterText,
      decision: decision ?? this.decision,
      editedText: editedText ?? this.editedText,
    );
  }

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      kind: json['kind'] as String? ?? 'cv_improvement',
      beforeText: json['beforeText'] as String?,
      afterText: json['afterText'] as String?,
      decision: SuggestionDecision.values.firstWhere(
        (e) => e.name == (json['decision'] as String? ?? 'pending'),
        orElse: () => SuggestionDecision.pending,
      ),
      editedText: json['editedText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'kind': kind,
    'beforeText': beforeText,
    'afterText': afterText,
    'decision': decision.name,
    'editedText': editedText,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    kind,
    beforeText,
    afterText,
    decision,
    editedText,
  ];
}

class JobMatchResult extends Equatable {
  const JobMatchResult({
    required this.id,
    required this.resumeId,
    required this.jobTitle,
    required this.overallMatchScore,
    required this.scoreDisclaimer,
    required this.categories,
    required this.skillMatches,
    required this.keywordsCovered,
    required this.keywordsMissing,
    required this.recommendations,
    required this.verificationQuestions,
    required this.learningOpportunities,
    required this.workingWell,
    required this.engineVersion,
    required this.matchedAt,
    this.company,
    this.jobUrl,
  });

  final String id;
  final String resumeId;
  final String jobTitle;
  final String? company;
  final String? jobUrl;
  final int overallMatchScore;
  final String scoreDisclaimer;
  final List<MatchCategory> categories;
  final List<SkillMatchItem> skillMatches;
  final List<String> keywordsCovered;
  final List<String> keywordsMissing;
  final List<MatchRecommendation> recommendations;
  final List<String> verificationQuestions;
  final List<String> learningOpportunities;
  final List<String> workingWell;
  final String engineVersion;
  final DateTime matchedAt;

  JobMatchResult copyWith({List<MatchRecommendation>? recommendations}) {
    return JobMatchResult(
      id: id,
      resumeId: resumeId,
      jobTitle: jobTitle,
      company: company,
      jobUrl: jobUrl,
      overallMatchScore: overallMatchScore,
      scoreDisclaimer: scoreDisclaimer,
      categories: categories,
      skillMatches: skillMatches,
      keywordsCovered: keywordsCovered,
      keywordsMissing: keywordsMissing,
      recommendations: recommendations ?? this.recommendations,
      verificationQuestions: verificationQuestions,
      learningOpportunities: learningOpportunities,
      workingWell: workingWell,
      engineVersion: engineVersion,
      matchedAt: matchedAt,
    );
  }

  factory JobMatchResult.fromJson(Map<String, dynamic> json) {
    return JobMatchResult(
      id: json['id'] as String,
      resumeId: json['resumeId'] as String,
      jobTitle: json['jobTitle'] as String,
      company: json['company'] as String?,
      jobUrl: json['jobUrl'] as String?,
      overallMatchScore: json['overallMatchScore'] as int,
      scoreDisclaimer: json['scoreDisclaimer'] as String? ?? '',
      categories: (json['categories'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(MatchCategory.fromJson)
          .toList(),
      skillMatches: (json['skillMatches'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(SkillMatchItem.fromJson)
          .toList(),
      keywordsCovered:
          (json['keywordsCovered'] as List?)?.cast<String>() ?? const [],
      keywordsMissing:
          (json['keywordsMissing'] as List?)?.cast<String>() ?? const [],
      recommendations: (json['recommendations'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(MatchRecommendation.fromJson)
          .toList(),
      verificationQuestions:
          (json['verificationQuestions'] as List?)?.cast<String>() ?? const [],
      learningOpportunities:
          (json['learningOpportunities'] as List?)?.cast<String>() ?? const [],
      workingWell: (json['workingWell'] as List?)?.cast<String>() ?? const [],
      engineVersion: json['engineVersion'] as String? ?? 'job-match',
      matchedAt:
          DateTime.tryParse(json['matchedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'resumeId': resumeId,
    'jobTitle': jobTitle,
    'company': company,
    'jobUrl': jobUrl,
    'overallMatchScore': overallMatchScore,
    'scoreDisclaimer': scoreDisclaimer,
    'categories': categories.map((c) => c.toJson()).toList(),
    'skillMatches': skillMatches.map((s) => s.toJson()).toList(),
    'keywordsCovered': keywordsCovered,
    'keywordsMissing': keywordsMissing,
    'recommendations': recommendations.map((r) => r.toJson()).toList(),
    'verificationQuestions': verificationQuestions,
    'learningOpportunities': learningOpportunities,
    'workingWell': workingWell,
    'engineVersion': engineVersion,
    'matchedAt': matchedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    resumeId,
    jobTitle,
    company,
    jobUrl,
    overallMatchScore,
    categories,
    skillMatches,
    recommendations,
    matchedAt,
  ];
}

class JobMatchInput extends Equatable {
  const JobMatchInput({
    required this.resume,
    required this.jobTitle,
    required this.jobDescription,
    this.company,
    this.jobUrl,
    this.locale = 'en',
    this.careerStage,
  });

  final ResumeSnapshot resume;
  final String jobTitle;
  final String jobDescription;
  final String? company;
  final String? jobUrl;
  final String locale;
  final String? careerStage;

  @override
  List<Object?> get props => [
    resume,
    jobTitle,
    jobDescription,
    company,
    jobUrl,
    locale,
    careerStage,
  ];
}
