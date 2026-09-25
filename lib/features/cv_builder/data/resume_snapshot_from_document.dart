import '../../jobs/domain/job_match_models.dart';
import '../domain/resume_document.dart';

/// Maps canonical [ResumeDocument] → Job Match snapshot (no invented skills).
abstract final class ResumeSnapshotFromDocument {
  static ResumeSnapshot fromDocument(ResumeDocument doc) {
    final skills = <String>[];
    final tools = <String>[];
    for (final g in doc.skillGroups) {
      final label = g.label.toLowerCase();
      if (label.contains('tool') || label.contains('araç')) {
        tools.addAll(g.skills);
      } else {
        skills.addAll(g.skills);
      }
    }
    return ResumeSnapshot(
      resumeId: doc.id,
      fileName: doc.exportFileName(),
      skills: skills,
      tools: tools,
      experienceBullets: [for (final e in doc.experience) ...e.bullets],
      projectBullets: [for (final p in doc.projects) ...p.bullets],
      education: [
        for (final e in doc.education)
          [
            e.degree,
            e.field,
            e.school,
            if (e.endDate.isNotEmpty) e.endDate,
          ].where((x) => x.trim().isNotEmpty).join(' · '),
      ],
      languages: [
        for (final l in doc.languages)
          l.level.isEmpty ? l.name : '${l.name} (${l.level})',
      ],
      summary: doc.summary.isEmpty ? null : doc.summary,
      sectionKeys: [
        for (final k in doc.sectionOrder)
          if (doc.sectionVisibility[k] ?? true) k,
      ],
    );
  }
}
