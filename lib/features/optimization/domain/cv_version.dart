import 'package:equatable/equatable.dart';

import '../../analyze/domain/analysis_models.dart';

enum CvVersionType { original, optimized }

/// A saved snapshot of CV text. The original upload is never overwritten.
class CvVersion extends Equatable {
  const CvVersion({
    required this.id,
    required this.resumeId,
    required this.type,
    required this.label,
    required this.createdAt,
    required this.evidence,
    this.cvQuality,
    this.atsReadability,
  });

  final String id;
  final String resumeId;
  final CvVersionType type;
  final String label;
  final DateTime createdAt;
  final CvEvidence evidence;
  final int? cvQuality;
  final int? atsReadability;

  Map<String, dynamic> toJson() => {
    'id': id,
    'resumeId': resumeId,
    'type': type.name,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
    'evidence': evidence.toJson(),
    'cvQuality': cvQuality,
    'atsReadability': atsReadability,
  };

  factory CvVersion.fromJson(Map<String, dynamic> json) {
    return CvVersion(
      id: json['id'] as String,
      resumeId: json['resumeId'] as String,
      type: CvVersionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CvVersionType.optimized,
      ),
      label: json['label'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      evidence: CvEvidence.fromJson(json['evidence'] as Map<String, dynamic>),
      cvQuality: json['cvQuality'] as int?,
      atsReadability: json['atsReadability'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, resumeId, type, label, createdAt, cvQuality, atsReadability];
}
