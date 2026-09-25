import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../analyze/application/analysis_controller.dart';
import '../../analyze/domain/analysis_models.dart';
import '../../home/presentation/home_shell.dart';
import '../../jobs/application/job_match_controller.dart';
import '../application/builder_controller.dart';
import '../data/resume_snapshot_from_document.dart';
import '../domain/resume_document.dart';
import '../pdf/resume_pdf_renderer.dart';
import 'widgets/ai_rewrite_sheet.dart';
import 'widgets/builder_preview.dart';
import 'widgets/section_editors.dart';

class BuilderScreen extends ConsumerWidget {
  const BuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(builderControllerProvider.select((s) => s.active));
    if (active != null) {
      return const _BuilderEditor();
    }
    return const _BuilderHome();
  }
}

class _BuilderHome extends ConsumerWidget {
  const _BuilderHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(builderControllerProvider);
    final ctrl = ref.read(builderControllerProvider.notifier);
    final hasAnalysis = ctrl.hasAnalyzedCv;

    final theme = Theme.of(context);
    return CareerlyScaffold(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CareerlyEditorialHeader(
            label: 'MY CVS',
            headline: 'Build the version\nthat fits the role.',
            supporting: l10n.builderHomeBody,
            background: AppColors.cream,
            trailing: const CareerlyDocumentPreview(
              width: 56,
              height: 76,
              accent: AppColors.mint,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton(
                  label: l10n.builderCreateNew,
                  onPressed: () =>
                      _openSetup(context, ref, BuilderStartPoint.blank),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l10n.builderUseExisting,
                        variant: AppButtonVariant.secondary,
                        onPressed: state.documents.isEmpty
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.builderPickExistingHint),
                                  ),
                                );
                              },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: l10n.builderFromAnalyzed,
                        variant: AppButtonVariant.secondary,
                        onPressed: hasAnalysis
                            ? () => _openSetup(
                                  context,
                                  ref,
                                  BuilderStartPoint.fromAnalyzed,
                                )
                            : null,
                      ),
                    ),
                  ],
                ),
                if (!hasAnalysis) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.builderFromAnalyzedHint,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.builderYourCvs),
                const SizedBox(height: AppSpacing.md),
                if (state.documents.isEmpty)
                  CareerlyEmptyState(
                    number: '00',
                    label: 'NO DOCUMENTS',
                    headline: l10n.builderEmptyTitle,
                    body: l10n.builderEmptyBody,
                    actionLabel: l10n.builderCreateNew,
                    onAction: () =>
                        _openSetup(context, ref, BuilderStartPoint.blank),
                  )
                else
                  ...state.documents.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Material(
                        color: AppColors.cream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          side: BorderSide(
                            color: AppColors.inkNavy.withValues(alpha: 0.1),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          onTap: () => ctrl.openDocument(doc.id),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                const CareerlyDocumentPreview(
                                  width: 48,
                                  height: 64,
                                  accent: AppColors.cobalt,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.title,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        '${doc.language.name.toUpperCase()} · ${_templateLabel(l10n, doc.templateId)}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    switch (v) {
                                      case 'rename':
                                        final title = await _promptText(
                                          context,
                                          title: l10n.builderRename,
                                          initial: doc.title,
                                        );
                                        if (title != null &&
                                            title.trim().isNotEmpty) {
                                          await ctrl.rename(
                                            doc.id,
                                            title.trim(),
                                          );
                                        }
                                      case 'duplicate':
                                        await ctrl.duplicate(doc.id);
                                      case 'delete':
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(
                                              l10n.builderDeleteConfirmTitle,
                                            ),
                                            content: Text(
                                              l10n.builderDeleteConfirmBody,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: Text(l10n.builderCancel),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: Text(l10n.builderDelete),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          await ctrl.delete(doc.id);
                                        }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Text(l10n.builderRename),
                                    ),
                                    PopupMenuItem(
                                      value: 'duplicate',
                                      child: Text(l10n.builderDuplicate),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l10n.builderDelete),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSetup(
    BuildContext context,
    WidgetRef ref,
    BuilderStartPoint start,
  ) async {
    final result = await showModalBottomSheet<_SetupResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _QuickSetupSheet(startPoint: start),
    );
    if (result == null) return;
    final ctrl = ref.read(builderControllerProvider.notifier);
    if (start == BuilderStartPoint.fromAnalyzed) {
      await ctrl.createFromAnalyzed(
        language: result.language,
        templateId: result.templateId,
      );
    } else {
      await ctrl.createBlank(
        language: result.language,
        templateId: result.templateId,
      );
    }
  }
}

class _SetupResult {
  const _SetupResult({required this.language, required this.templateId});
  final CvDocumentLanguage language;
  final CvTemplateId templateId;
}

class _QuickSetupSheet extends StatefulWidget {
  const _QuickSetupSheet({required this.startPoint});
  final BuilderStartPoint startPoint;

  @override
  State<_QuickSetupSheet> createState() => _QuickSetupSheetState();
}

class _QuickSetupSheetState extends State<_QuickSetupSheet> {
  CvDocumentLanguage _lang = CvDocumentLanguage.en;
  CvTemplateId _template = CvTemplateId.classicAts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.builderQuickSetup,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.builderCvLanguage,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          ChoiceChipCard(
            label: l10n.builderLangEn,
            selected: _lang == CvDocumentLanguage.en,
            onTap: () => setState(() => _lang = CvDocumentLanguage.en),
          ),
          const SizedBox(height: AppSpacing.sm),
          ChoiceChipCard(
            label: l10n.builderLangTr,
            selected: _lang == CvDocumentLanguage.tr,
            onTap: () => setState(() => _lang = CvDocumentLanguage.tr),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.builderTemplate,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...CvTemplateId.values.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ChoiceChipCard(
                label: _templateLabel(l10n, t),
                selected: _template == t,
                onTap: () => setState(() => _template = t),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.builderStartEditing,
            onPressed: () => Navigator.pop(
              context,
              _SetupResult(language: _lang, templateId: _template),
            ),
          ),
        ],
      ),
    );
  }
}

String _templateLabel(AppLocalizations l10n, CvTemplateId id) => switch (id) {
  CvTemplateId.classicAts => l10n.builderTemplateClassic,
  CvTemplateId.modernAts => l10n.builderTemplateModern,
  CvTemplateId.student => l10n.builderTemplateStudent,
  CvTemplateId.tech => l10n.builderTemplateTech,
};

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String initial,
}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(ctx).builderCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(AppLocalizations.of(ctx).builderSave),
        ),
      ],
    ),
  );
}

class _BuilderEditor extends ConsumerStatefulWidget {
  const _BuilderEditor();

  @override
  ConsumerState<_BuilderEditor> createState() => _BuilderEditorState();
}

class _BuilderEditorState extends ConsumerState<_BuilderEditor> {
  /// Prefer edit on narrow layouts — PDF.js preview often fails on web.
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(builderControllerProvider);
    final doc = state.active!;
    final ctrl = ref.read(builderControllerProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return CareerlyScaffold(
      title: doc.title,
      actions: [
        _SaveChip(status: state.saveStatus),
        IconButton(
          tooltip: l10n.builderExportPdf,
          onPressed: () async {
            try {
              await ResumePdfRenderer.sharePdf(doc);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.builderExportError)),
                );
              }
            }
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.builderMoreActions,
          icon: const Icon(Icons.more_vert),
          onSelected: (v) => _onMenu(context, v, doc),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'template',
              child: Text(l10n.builderChangeTemplate),
            ),
            PopupMenuItem(
              value: 'translate',
              child: Text(l10n.builderTranslate),
            ),
            PopupMenuItem(value: 'check', child: Text(l10n.builderCheckCv)),
            PopupMenuItem(value: 'tailor', child: Text(l10n.builderTailorJob)),
            PopupMenuItem(value: 'close', child: Text(l10n.builderCloseEditor)),
          ],
        ),
      ],
      child: Column(
        children: [
          if (!wide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.builderEditTab),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.builderPreviewTab),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                  ),
                ],
                selected: {_showPreview},
                onSelectionChanged: (s) =>
                    setState(() => _showPreview = s.first),
              ),
            ),
          Expanded(
            child: wide
                ? Row(
                    children: [
                      Expanded(flex: 5, child: _EditorPane(doc: doc)),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 4,
                        child: BuilderPreview(
                          document: doc,
                          zoom: state.previewZoom,
                          onZoom: ctrl.setZoom,
                        ),
                      ),
                    ],
                  )
                : _showPreview
                ? BuilderPreview(
                    document: doc,
                    zoom: state.previewZoom,
                    onZoom: ctrl.setZoom,
                  )
                : _EditorPane(doc: doc),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    String value,
    ResumeDocument doc,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ctrl = ref.read(builderControllerProvider.notifier);
    switch (value) {
      case 'close':
        ctrl.closeEditor();
      case 'template':
        final t = await showModalBottomSheet<CvTemplateId>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => ListView(
            shrinkWrap: true,
            children: CvTemplateId.values
                .map(
                  (id) => ListTile(
                    title: Text(_templateLabel(l10n, id)),
                    selected: id == doc.templateId,
                    onTap: () => Navigator.pop(ctx, id),
                  ),
                )
                .toList(),
          ),
        );
        if (t != null) await ctrl.switchTemplate(t);
      case 'translate':
        final target = doc.language == CvDocumentLanguage.en
            ? CvDocumentLanguage.tr
            : CvDocumentLanguage.en;
        final version = await ctrl.translateActive(target);
        if (context.mounted && version != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.builderTranslateDone)));
        }
      case 'check':
        await _runCheck(context);
      case 'tailor':
        final snapshot = ResumeSnapshotFromDocument.fromDocument(doc);
        ref.read(jobMatchControllerProvider.notifier).selectResume(snapshot);
        if (context.mounted) context.push(AppRoutes.jobsNew);
    }
  }

  Future<void> _runCheck(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ctrl = ref.read(builderControllerProvider.notifier);
    final raw = await ctrl.checkStructuredCv(locale: locale);
    if (!context.mounted || raw == null) return;
    final analysisJson = raw['analysis'] as Map<String, dynamic>?;
    if (analysisJson == null) return;

    // Ensure analyzedAt present for mapper.
    analysisJson.putIfAbsent(
      'analyzedAt',
      () => DateTime.now().toUtc().toIso8601String(),
    );
    analysisJson.putIfAbsent('fileName', () => raw['fileName'] ?? 'CV');
    analysisJson.putIfAbsent(
      'engineVersion',
      () => raw['analysisVersion'] ?? 'builder',
    );
    analysisJson.putIfAbsent('topImprovementIds', () => const <String>[]);
    analysisJson.putIfAbsent('workingWell', () => const <String>[]);
    analysisJson.putIfAbsent('categories', () => const []);
    analysisJson.putIfAbsent('findings', () => const []);
    analysisJson.putIfAbsent('confidence', () => 'medium');

    final analysis = _mapAnalysis(analysisJson);
    await ref
        .read(analysisControllerProvider.notifier)
        .applyExternalAnalysis(analysis);

    if (!context.mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.builderCheckResultTitle),
        content: Text(l10n.builderCheckResultBody(analysis.overallScore)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.close),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.builderOpenAnalysis),
          ),
        ],
      ),
    );
    if (open == true && context.mounted) {
      context.push(AppRoutes.analyzeResults);
    }
  }
}

ResumeAnalysis _mapAnalysis(Map<String, dynamic> json) {
  return ResumeAnalysis(
    id: json['id'] as String? ?? 'analysis_builder',
    resumeId: json['resumeId'] as String? ?? 'builder',
    overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
    confidence: ParserConfidence.values.firstWhere(
      (e) => e.name == json['confidence'],
      orElse: () => ParserConfidence.medium,
    ),
    engineVersion: json['engineVersion'] as String? ?? 'builder',
    analyzedAt:
        DateTime.tryParse(json['analyzedAt'] as String? ?? '') ??
        DateTime.now().toUtc(),
    fileName: json['fileName'] as String? ?? 'CV',
    topImprovementIds:
        (json['topImprovementIds'] as List?)?.cast<String>() ?? const [],
    workingWell: (json['workingWell'] as List?)?.cast<String>() ?? const [],
    categories: (json['categories'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (c) => ScoreCategory(
            id: ScoreCategoryId.values.firstWhere(
              (e) => e.name == c['id'],
              orElse: () => ScoreCategoryId.atsCompatibility,
            ),
            score: (c['score'] as num?)?.toInt() ?? 0,
            weight: (c['weight'] as num?)?.toDouble() ?? 0,
            summary: c['summary'] as String? ?? '',
          ),
        )
        .toList(),
    findings: (json['findings'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (f) => AnalysisFinding(
            id: f['id'] as String? ?? 'f',
            severity: FindingSeverity.values.firstWhere(
              (e) => e.name == f['severity'],
              orElse: () => FindingSeverity.improve,
            ),
            title: f['title'] as String? ?? '',
            whyItMatters: f['whyItMatters'] as String? ?? '',
            evidence: f['evidence'] as String? ?? '',
            recommendedAction: f['recommendedAction'] as String? ?? '',
            categoryId: ScoreCategoryId.values.firstWhere(
              (e) => e.name == f['categoryId'],
              orElse: () => ScoreCategoryId.contentImpact,
            ),
            beforeText: f['beforeText'] as String?,
            afterText: f['afterText'] as String?,
            supportsAiImprove: f['supportsAiImprove'] as bool? ?? false,
          ),
        )
        .toList(),
  );
}

class _SaveChip extends StatelessWidget {
  const _SaveChip({required this.status});
  final SaveStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (status) {
      SaveStatus.saving => (l10n.builderSaving, AppColors.secondaryText),
      SaveStatus.saved => (l10n.builderSaved, AppColors.success),
      SaveStatus.error => (l10n.builderSaveError, AppColors.critical),
      SaveStatus.idle => (null, null),
    };
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xxs),
      child: Center(
        child: Semantics(
          liveRegion: true,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _EditorPane extends ConsumerWidget {
  const _EditorPane({required this.doc});
  final ResumeDocument doc;

  String _sectionLabel(AppLocalizations l10n, String key) => switch (key) {
        'personal' => l10n.builderSectionPersonal,
        'summary' => l10n.builderSectionSummary,
        'education' => l10n.builderSectionEducation,
        'experience' => l10n.builderSectionExperience,
        'projects' => l10n.builderSectionProjects,
        'skills' => l10n.builderSectionSkills,
        'languages' => l10n.builderSectionLanguages,
        'certs' => l10n.builderSectionCerts,
        'awards' => l10n.builderSectionAwards,
        _ => key,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ctrl = ref.read(builderControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        CareerlyColorSection(
          tone: CareerlySurfaceTone.cream,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CareerlySectionLabel('SECTIONS'),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < doc.sectionOrder.length; i++) ...[
                Builder(
                  builder: (context) {
                    final key = doc.sectionOrder[i];
                    final done =
                        doc.completionFor(key) == SectionCompletion.complete;
                    final partial =
                        doc.completionFor(key) == SectionCompletion.partial;
                    final color = done
                        ? AppColors.mint
                        : partial
                            ? AppColors.cobalt
                            : AppColors.border;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Text(
                            (i + 1).toString().padLeft(2, '0'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: done || partial
                                  ? AppColors.inkNavy
                                  : AppColors.secondaryText,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          CareerlyStatusMarker(
                            color: color,
                            shape: done
                                ? CareerlyMarkerShape.circle
                                : CareerlyMarkerShape.square,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _sectionLabel(l10n, key),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: done || partial
                                    ? AppColors.primaryText
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final key in doc.sectionOrder)
          SectionEditorCard(
            sectionKey: key,
            document: doc,
            onChanged: (next) => ctrl.updateActive((_) => next),
            onAiImprove: (text, apply) async {
              await showAiRewriteSheet(
                context: context,
                ref: ref,
                original: text,
                sectionKey: key,
                locale: Localizations.localeOf(context).languageCode,
                onAccept: apply,
              );
            },
          ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.builderAddCustomSection,
          variant: AppButtonVariant.secondary,
          onPressed: () {
            ctrl.updateActive(
              (d) => d.copyWith(
                customSections: [
                  ...d.customSections,
                  CustomSection(id: const Uuid().v4()),
                ],
              ),
            );
          },
        ),
        if (doc.customSections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...doc.customSections.map(
            (c) => CustomSectionEditor(
              section: c,
              onChanged: (next) {
                ctrl.updateActive((d) {
                  final list = d.customSections
                      .map((e) => e.id == next.id ? next : e)
                      .toList();
                  return d.copyWith(customSections: list);
                });
              },
              onDelete: () {
                ctrl.updateActive(
                  (d) => d.copyWith(
                    customSections: d.customSections
                        .where((e) => e.id != c.id)
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
