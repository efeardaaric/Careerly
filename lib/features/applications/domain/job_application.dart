import 'package:equatable/equatable.dart';

enum ApplicationStatus { saved, preparing, applied, interview, offer, rejected }

/// One tracked application. Match score is copied from a real job match only.
class JobApplication extends Equatable {
  const JobApplication({
    required this.id,
    required this.jobTitle,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.company,
    this.jobUrl,
    this.jobMatchId,
    this.matchScore,
    this.cvVersionId,
    this.appliedAt,
    this.notes = '',
    this.nextAction = '',
  });

  final String id;
  final String jobTitle;
  final String? company;
  final String? jobUrl;
  final String? jobMatchId;
  final int? matchScore;
  final String? cvVersionId;
  final ApplicationStatus status;
  final DateTime? appliedAt;
  final String notes;
  final String nextAction;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobApplication copyWith({
    String? jobTitle,
    String? company,
    ApplicationStatus? status,
    String? cvVersionId,
    bool clearCvVersion = false,
    DateTime? appliedAt,
    String? notes,
    String? nextAction,
    DateTime? updatedAt,
  }) {
    return JobApplication(
      id: id,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      jobUrl: jobUrl,
      jobMatchId: jobMatchId,
      matchScore: matchScore,
      cvVersionId: clearCvVersion ? null : (cvVersionId ?? this.cvVersionId),
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      notes: notes ?? this.notes,
      nextAction: nextAction ?? this.nextAction,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobTitle': jobTitle,
    'company': company,
    'jobUrl': jobUrl,
    'jobMatchId': jobMatchId,
    'matchScore': matchScore,
    'cvVersionId': cvVersionId,
    'status': status.name,
    'appliedAt': appliedAt?.toIso8601String(),
    'notes': notes,
    'nextAction': nextAction,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] as String,
      jobTitle: json['jobTitle'] as String? ?? '',
      company: json['company'] as String?,
      jobUrl: json['jobUrl'] as String?,
      jobMatchId: json['jobMatchId'] as String?,
      matchScore: json['matchScore'] as int?,
      cvVersionId: json['cvVersionId'] as String?,
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.saved,
      ),
      appliedAt: json['appliedAt'] == null
          ? null
          : DateTime.parse(json['appliedAt'] as String),
      notes: json['notes'] as String? ?? '',
      nextAction: json['nextAction'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    jobTitle,
    company,
    jobUrl,
    jobMatchId,
    matchScore,
    cvVersionId,
    status,
    appliedAt,
    notes,
    nextAction,
    createdAt,
    updatedAt,
  ];
}
