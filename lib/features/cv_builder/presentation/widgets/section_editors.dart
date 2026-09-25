import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'builder_bound_field.dart';
import '../../domain/resume_document.dart';

typedef DocUpdater = void Function(ResumeDocument next);

class SectionEditorCard extends StatelessWidget {
  const SectionEditorCard({
    super.key,
    required this.sectionKey,
    required this.document,
    required this.onChanged,
    required this.onAiImprove,
  });

  final String sectionKey;
  final ResumeDocument document;
  final DocUpdater onChanged;
  final Future<void> Function(String text, void Function(String accepted) apply)
  onAiImprove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completion = document.completionFor(sectionKey);
    final visible = document.sectionVisibility[sectionKey] ?? true;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_iconFor(sectionKey), color: AppColors.actionBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _label(l10n, sectionKey),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _CompletionBadge(completion: completion),
                IconButton(
                  tooltip: visible
                      ? l10n.builderHideSection
                      : l10n.builderShowSection,
                  onPressed: () {
                    final map = Map<String, bool>.from(
                      document.sectionVisibility,
                    );
                    map[sectionKey] = !visible;
                    onChanged(document.copyWith(sectionVisibility: map));
                  },
                  icon: Icon(
                    visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                if (sectionKey != 'personal')
                  IconButton(
                    tooltip: l10n.builderMoveUp,
                    onPressed: () => _move(-1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                if (sectionKey != 'personal')
                  IconButton(
                    tooltip: l10n.builderMoveDown,
                    onPressed: () => _move(1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
              ],
            ),
            if (!visible)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.builderSectionHidden,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else ...[
              const SizedBox(height: AppSpacing.md),
              _body(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  void _move(int delta) {
    final order = List<String>.from(document.sectionOrder);
    final i = order.indexOf(sectionKey);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= order.length) return;
    order[i] = order[j];
    order[j] = sectionKey;
    onChanged(document.copyWith(sectionOrder: order));
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    switch (sectionKey) {
      case 'personal':
        final p = document.personal;
        return Column(
          children: [
            _field(l10n.builderFieldFullName, p.fullName, (v) {
              onChanged(document.copyWith(personal: p.copyWith(fullName: v)));
            }),
            _field(l10n.builderFieldEmail, p.email, (v) {
              onChanged(document.copyWith(personal: p.copyWith(email: v)));
            }),
            _field(l10n.builderFieldPhone, p.phone, (v) {
              onChanged(document.copyWith(personal: p.copyWith(phone: v)));
            }),
            _field(l10n.builderFieldLocation, p.location, (v) {
              onChanged(document.copyWith(personal: p.copyWith(location: v)));
            }),
            _field(l10n.builderFieldLinkedin, p.linkedin, (v) {
              onChanged(document.copyWith(personal: p.copyWith(linkedin: v)));
            }),
            _field(l10n.builderFieldWebsite, p.website, (v) {
              onChanged(document.copyWith(personal: p.copyWith(website: v)));
            }),
          ],
        );
      case 'summary':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              l10n.builderSectionSummary,
              document.summary,
              (v) => onChanged(document.copyWith(summary: v)),
              maxLines: 4,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: document.summary.trim().isEmpty
                    ? null
                    : () => onAiImprove(
                        document.summary,
                        (accepted) =>
                            onChanged(document.copyWith(summary: accepted)),
                      ),
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(l10n.builderAiImprove),
              ),
            ),
          ],
        );
      case 'education':
        return _listBlock(
          l10n: l10n,
          emptyLabel: l10n.builderAddEducation,
          onAdd: () {
            onChanged(
              document.copyWith(
                education: [
                  ...document.education,
                  EducationEntry(id: const Uuid().v4()),
                ],
              ),
            );
          },
          children: [
            for (final e in document.education)
              _EducationEditor(
                entry: e,
                onChanged: (next) {
                  onChanged(
                    document.copyWith(
                      education: document.education
                          .map((x) => x.id == next.id ? next : x)
                          .toList(),
                    ),
                  );
                },
                onDelete: () {
                  onChanged(
                    document.copyWith(
                      education: document.education
                          .where((x) => x.id != e.id)
                          .toList(),
                    ),
                  );
                },
              ),
          ],
        );
      case 'experience':
        return _listBlock(
          l10n: l10n,
          emptyLabel: l10n.builderAddExperience,
          onAdd: () {
            onChanged(
              document.copyWith(
                experience: [
                  ...document.experience,
                  ExperienceEntry(id: const Uuid().v4()),
                ],
              ),
            );
          },
          children: [
            for (final e in document.experience)
              _ExperienceEditor(
                entry: e,
                onChanged: (next) {
                  onChanged(
                    document.copyWith(
                      experience: document.experience
                          .map((x) => x.id == next.id ? next : x)
                          .toList(),
                    ),
                  );
                },
                onDelete: () {
                  onChanged(
                    document.copyWith(
                      experience: document.experience
                          .where((x) => x.id != e.id)
                          .toList(),
                    ),
                  );
                },
                onAiBullet: (bullet, index) {
                  onAiImprove(bullet, (accepted) {
                    final bullets = List<String>.from(e.bullets);
                    bullets[index] = accepted;
                    onChanged(
                      document.copyWith(
                        experience: document.experience
                            .map(
                              (x) => x.id == e.id
                                  ? x.copyWith(bullets: bullets)
                                  : x,
                            )
                            .toList(),
                      ),
                    );
                  });
                },
              ),
          ],
        );
      case 'projects':
        return _listBlock(
          l10n: l10n,
          emptyLabel: l10n.builderAddProject,
          onAdd: () {
            onChanged(
              document.copyWith(
                projects: [
                  ...document.projects,
                  ProjectEntry(id: const Uuid().v4()),
                ],
              ),
            );
          },
          children: [
            for (final p in document.projects)
              _ProjectEditor(
                entry: p,
                onChanged: (next) {
                  onChanged(
                    document.copyWith(
                      projects: document.projects
                          .map((x) => x.id == next.id ? next : x)
                          .toList(),
                    ),
                  );
                },
                onDelete: () {
                  onChanged(
                    document.copyWith(
                      projects: document.projects
                          .where((x) => x.id != p.id)
                          .toList(),
                    ),
                  );
                },
                onAiBullet: (bullet, index) {
                  onAiImprove(bullet, (accepted) {
                    final bullets = List<String>.from(p.bullets);
                    bullets[index] = accepted;
                    onChanged(
                      document.copyWith(
                        projects: document.projects
                            .map(
                              (x) => x.id == p.id
                                  ? x.copyWith(bullets: bullets)
                                  : x,
                            )
                            .toList(),
                      ),
                    );
                  });
                },
              ),
          ],
        );
      case 'skills':
        return _listBlock(
          l10n: l10n,
          emptyLabel: l10n.builderAddSkillGroup,
          onAdd: () {
            onChanged(
              document.copyWith(
                skillGroups: [
                  ...document.skillGroups,
                  SkillGroup(id: const Uuid().v4()),
                ],
              ),
            );
          },
          children: [
            for (final g in document.skillGroups)
              _SkillGroupEditor(
                group: g,
                onChanged: (next) {
                  onChanged(
                    document.copyWith(
                      skillGroups: document.skillGroups
                          .map((x) => x.id == next.id ? next : x)
                          .toList(),
                    ),
                  );
                },
                onDelete: () {
                  onChanged(
                    document.copyWith(
                      skillGroups: document.skillGroups
                          .where((x) => x.id != g.id)
                          .toList(),
                    ),
                  );
                },
              ),
          ],
        );
      case 'languages':
        return _listBlock(
          l10n: l10n,
          emptyLabel: l10n.builderAddLanguage,
          onAdd: () {
            onChanged(
              document.copyWith(
                languages: [
                  ...document.languages,
                  LanguageEntry(id: const Uuid().v4()),
                ],
              ),
            );
          },
          children: [
            for (final lang in document.languages)
              Row(
                children: [
                  Expanded(
                    child: _field(l10n.builderFieldLanguage, lang.name, (v) {
                      onChanged(
                        document.copyWith(
                          languages: document.languages
                              .map(
                                (x) =>
                                    x.id == lang.id ? x.copyWith(name: v) : x,
                              )
                              .toList(),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(l10n.builderFieldLevel, lang.level, (v) {
                      onChanged(
                        document.copyWith(
                          languages: document.languages
                              .map(
                                (x) =>
                                    x.id == lang.id ? x.copyWith(level: v) : x,
                              )
                              .toList(),
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    onPressed: () {
                      onChanged(
                        document.copyWith(
                          languages: document.languages
                              .where((x) => x.id != lang.id)
                              .toList(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
          ],
        );
      case 'certifications':
        return _listBlock(
          l10n: l10n,
          emptyLabel: l10n.builderAddCert,
          onAdd: () {
            onChanged(
              document.copyWith(
                certifications: [
                  ...document.certifications,
                  CertificationEntry(id: const Uuid().v4()),
                ],
              ),
            );
          },
          children: [
            for (final c in document.certifications)
              Column(
                children: [
                  _field(l10n.builderFieldCertName, c.name, (v) {
                    onChanged(
                      document.copyWith(
                        certifications: document.certifications
                            .map((x) => x.id == c.id ? x.copyWith(name: v) : x)
                            .toList(),
                      ),
                    );
                  }),
                  _field(l10n.builderFieldIssuer, c.issuer, (v) {
                    onChanged(
                      document.copyWith(
                        certifications: document.certifications
                            .map(
                              (x) => x.id == c.id ? x.copyWith(issuer: v) : x,
                            )
                            .toList(),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        onChanged(
                          document.copyWith(
                            certifications: document.certifications
                                .where((x) => x.id != c.id)
                                .toList(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
          ],
        );
      case 'awards':
        return _listBlock(
          l10n: l10n,
          emptyLabel: l10n.builderAddAward,
          onAdd: () {
            onChanged(
              document.copyWith(
                awards: [
                  ...document.awards,
                  AwardEntry(id: const Uuid().v4()),
                ],
              ),
            );
          },
          children: [
            for (final a in document.awards)
              Row(
                children: [
                  Expanded(
                    child: _field(l10n.builderFieldAward, a.title, (v) {
                      onChanged(
                        document.copyWith(
                          awards: document.awards
                              .map(
                                (x) => x.id == a.id ? x.copyWith(title: v) : x,
                              )
                              .toList(),
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    onPressed: () {
                      onChanged(
                        document.copyWith(
                          awards: document.awards
                              .where((x) => x.id != a.id)
                              .toList(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _listBlock({
    required AppLocalizations l10n,
    required String emptyLabel,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(emptyLabel),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BuilderBoundField(
        label: label,
        value: value,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }

  IconData _iconFor(String key) => switch (key) {
    'personal' => Icons.badge_outlined,
    'summary' => Icons.short_text_rounded,
    'education' => Icons.school_outlined,
    'experience' => Icons.business_center_outlined,
    'projects' => Icons.folder_open_outlined,
    'skills' => Icons.bolt_outlined,
    'languages' => Icons.translate_rounded,
    'certifications' => Icons.verified_outlined,
    'awards' => Icons.emoji_events_outlined,
    _ => Icons.notes_outlined,
  };

  String _label(AppLocalizations l10n, String key) => switch (key) {
    'personal' => l10n.builderSectionPersonal,
    'summary' => l10n.builderSectionSummary,
    'education' => l10n.builderSectionEducation,
    'experience' => l10n.builderSectionExperience,
    'projects' => l10n.builderSectionProjects,
    'skills' => l10n.builderSectionSkills,
    'languages' => l10n.builderSectionLanguages,
    'certifications' => l10n.builderSectionCerts,
    'awards' => l10n.builderSectionAwards,
    _ => key,
  };
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.completion});
  final SectionCompletion completion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, label, color) = switch (completion) {
      SectionCompletion.empty => (
        Icons.radio_button_unchecked,
        l10n.builderCompletionEmpty,
        AppColors.secondaryText,
      ),
      SectionCompletion.partial => (
        Icons.timelapse,
        l10n.builderCompletionPartial,
        AppColors.warning,
      ),
      SectionCompletion.complete => (
        Icons.check_circle_outline,
        l10n.builderCompletionComplete,
        AppColors.success,
      ),
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class CustomSectionEditor extends StatelessWidget {
  const CustomSectionEditor({
    super.key,
    required this.section,
    required this.onChanged,
    required this.onDelete,
  });

  final CustomSection section;
  final ValueChanged<CustomSection> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: BuilderBoundField(
                    label: l10n.builderCustomTitle,
                    value: section.title,
                    onChanged: (v) => onChanged(section.copyWith(title: v)),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            BuilderBoundField(
              label: l10n.builderBulletsHint,
              value: section.bullets.join('\n'),
              maxLines: 4,
              onChanged: (v) => onChanged(
                section.copyWith(
                  bullets: v
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationEditor extends StatelessWidget {
  const _EducationEditor({
    required this.entry,
    required this.onChanged,
    required this.onDelete,
  });

  final EducationEntry entry;
  final ValueChanged<EducationEntry> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        BuilderBoundField(
          label: l10n.builderFieldSchool,
          value: entry.school,
          onChanged: (v) => onChanged(entry.copyWith(school: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        BuilderBoundField(
          label: l10n.builderFieldDegree,
          value: entry.degree,
          onChanged: (v) => onChanged(entry.copyWith(degree: v)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _ExperienceEditor extends StatelessWidget {
  const _ExperienceEditor({
    required this.entry,
    required this.onChanged,
    required this.onDelete,
    required this.onAiBullet,
  });

  final ExperienceEntry entry;
  final ValueChanged<ExperienceEntry> onChanged;
  final VoidCallback onDelete;
  final void Function(String bullet, int index) onAiBullet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BuilderBoundField(
          label: l10n.builderFieldTitle,
          value: entry.title,
          onChanged: (v) => onChanged(entry.copyWith(title: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        BuilderBoundField(
          label: l10n.builderFieldOrganization,
          value: entry.organization,
          onChanged: (v) => onChanged(entry.copyWith(organization: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        BuilderBoundField(
          label: l10n.builderBulletsHint,
          value: entry.bullets.join('\n'),
          maxLines: 4,
          onChanged: (v) => onChanged(
            entry.copyWith(
              bullets: v
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
          ),
        ),
        if (entry.bullets.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onAiBullet(entry.bullets.first, 0),
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(l10n.builderAiImprove),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _ProjectEditor extends StatelessWidget {
  const _ProjectEditor({
    required this.entry,
    required this.onChanged,
    required this.onDelete,
    required this.onAiBullet,
  });

  final ProjectEntry entry;
  final ValueChanged<ProjectEntry> onChanged;
  final VoidCallback onDelete;
  final void Function(String bullet, int index) onAiBullet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BuilderBoundField(
          label: l10n.builderFieldProjectName,
          value: entry.name,
          onChanged: (v) => onChanged(entry.copyWith(name: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        BuilderBoundField(
          label: l10n.builderFieldTech,
          value: entry.tech.join(', '),
          onChanged: (v) => onChanged(
            entry.copyWith(
              tech: v
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BuilderBoundField(
          label: l10n.builderBulletsHint,
          value: entry.bullets.join('\n'),
          maxLines: 4,
          onChanged: (v) => onChanged(
            entry.copyWith(
              bullets: v
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
          ),
        ),
        if (entry.bullets.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onAiBullet(entry.bullets.first, 0),
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(l10n.builderAiImprove),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _SkillGroupEditor extends StatelessWidget {
  const _SkillGroupEditor({
    required this.group,
    required this.onChanged,
    required this.onDelete,
  });

  final SkillGroup group;
  final ValueChanged<SkillGroup> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        BuilderBoundField(
          label: l10n.builderFieldSkillGroup,
          value: group.label,
          onChanged: (v) => onChanged(group.copyWith(label: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        BuilderBoundField(
          label: l10n.builderFieldSkillsCsv,
          value: group.skills.join(', '),
          onChanged: (v) => onChanged(
            group.copyWith(
              skills: v
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
