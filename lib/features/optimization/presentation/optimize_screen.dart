import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/analytics/billing_analytics.dart';
import '../../../core/motion/careerly_motion.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../billing/domain/billing_models.dart';
import '../../billing/presentation/billing_gate.dart';
import '../../cv_builder/application/builder_controller.dart';
import '../../jobs/application/job_match_controller.dart';
import '../application/optimization_controller.dart';
import '../domain/cv_suggestion.dart';
import '../domain/cv_version.dart';

class OptimizeScreen extends ConsumerStatefulWidget {
  const OptimizeScreen({super.key});

  @override
  ConsumerState<OptimizeScreen> createState() => _OptimizeScreenState();
}

class _OptimizeScreenState extends ConsumerState<OptimizeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(optimizationControllerProvider.notifier).load(),
    );
  }

  String _message(AppLocalizations l10n, String key) {
    return switch (key) {
      'optimizeNoCv' => l10n.optimizeNoCv,
      'optimizeAiUnavailable' => l10n.optimizeAiUnavailable,
      'optimizeAiKeptOriginal' => l10n.optimizeAiKeptOriginal,
      'optimizeRescoreFailed' => l10n.optimizeRescoreFailed,
      _ => l10n.optimizeAiFailed,
    };
  }

  Future<void> _apply() async {
    final ok = await ensureFeatureAccess(
      context,
      ref,
      FeatureId.aiRewrite,
      paywallContext: 'optimize_cv',
    );
    if (!ok || !mounted) return;
    final applied = await ref
        .read(optimizationControllerProvider.notifier)
        .applyAndRescore();
    if (applied) await consumePendingUsage(ref, FeatureId.aiRewrite);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(optimizationControllerProvider);
    final controller = ref.read(optimizationControllerProvider.notifier);
    final hasJob = ref.watch(jobMatchControllerProvider).savedMatches.isNotEmpty;

    ref.listen(optimizationControllerProvider.select((s) => s.errorKey), (
      _,
      key,
    ) {
      if (key == null || key == 'optimizeNoCv') return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_message(l10n, key))));
      controller.clearMessage();
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.optimizeTitle)),
      bottomNavigationBar: state.decidedCount == 0
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: AppButton(
                label: l10n.optimizeApply(state.decidedCount),
                isLoading: state.applying,
                onPressed: state.applying ? null : _apply,
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Text(l10n.optimizeIntro, style: theme.textTheme.bodyMedium),
          if (state.lastChange != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ScoreChangeCard(change: state.lastChange!, hasJob: hasJob),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (state.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.errorKey == 'optimizeNoCv')
            Text(l10n.optimizeNoCv, style: theme.textTheme.bodyLarge)
          else if (state.suggestions.isEmpty)
            Text(l10n.optimizeEmpty, style: theme.textTheme.bodyLarge)
          else
            for (final item in state.suggestions) ...[
              _SuggestionCard(
                suggestion: item,
                aiAvailable: state.aiAvailable,
                rewriting: state.rewritingId == item.id,
                onAccept: () => controller.accept(item.id),
                onReject: () => controller.reject(item.id),
                onUndo: () => controller.undo(item.id),
                onEdit: () => _edit(item),
                onRewrite: (mode) => controller.rewrite(item.id, mode),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (state.versions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            CareerlySectionLabel(l10n.optimizeVersions),
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.optimizeBuilderNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            for (final version in state.versions.reversed)
              _VersionTile(
                version: version,
                busy: state.applying,
                onRestore: () => controller.restore(version),
                onOpenInBuilder: () async {
                  await ref
                      .read(builderControllerProvider.notifier)
                      .createFromVersion(
                        evidence: version.evidence,
                        versionId: version.id,
                      );
                  BillingAnalytics.track('cv_version_opened_in_builder');
                  if (context.mounted) context.go(AppRoutes.builder);
                },
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(CvSuggestion item) async {
    final l10n = AppLocalizations.of(context);
    final text = TextEditingController(
      text: item.editedText ?? item.suggestedText ?? item.originalText,
    );
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.optimizeYourVersion,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (item.needsUserFact) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.kind == SuggestionKind.noMetric
                      ? l10n.optimizeQuestionMetric
                      : l10n.optimizeQuestionOutcome,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: text,
                autofocus: true,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(hintText: l10n.optimizeEditHint),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.optimizeSave,
                onPressed: () => Navigator.pop(context, text.text),
              ),
            ],
          ),
        );
      },
    );
    text.dispose();
    if (result == null || result.trim().isEmpty) return;
    if (result.trim() == item.originalText) return;
    ref.read(optimizationControllerProvider.notifier).edit(item.id, result);
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.aiAvailable,
    required this.rewriting,
    required this.onAccept,
    required this.onReject,
    required this.onUndo,
    required this.onEdit,
    required this.onRewrite,
  });

  final CvSuggestion suggestion;
  final bool aiAvailable;
  final bool rewriting;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onUndo;
  final VoidCallback onEdit;
  final ValueChanged<RewriteMode> onRewrite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = suggestion;
    final decided = s.status != SuggestionStatus.pending;
    final duration = careerlyReduceMotion(context)
        ? Duration.zero
        : AppMotion.normal;

    final (title, why) = switch (s.kind) {
      SuggestionKind.weakOpening => (
        l10n.optimizeKindWeakOpening,
        l10n.optimizeWhyWeakOpening,
      ),
      SuggestionKind.firstPerson => (
        l10n.optimizeKindFirstPerson,
        l10n.optimizeWhyFirstPerson,
      ),
      SuggestionKind.tooLong => (
        l10n.optimizeKindTooLong,
        l10n.optimizeWhyTooLong,
      ),
      SuggestionKind.noMetric => (
        l10n.optimizeKindNoMetric,
        l10n.optimizeWhyNoMetric,
      ),
      SuggestionKind.formatting => (
        l10n.optimizeKindFormatting,
        l10n.optimizeWhyFormatting,
      ),
    };
    final impact = switch (s.impact) {
      SuggestionImpact.high => l10n.optimizeImpactHigh,
      SuggestionImpact.medium => l10n.optimizeImpactMedium,
      SuggestionImpact.low => l10n.optimizeImpactLow,
    };
    final statusLabel = switch (s.status) {
      SuggestionStatus.accepted => l10n.optimizeStatusAccepted,
      SuggestionStatus.edited => l10n.optimizeStatusEdited,
      SuggestionStatus.rejected => l10n.optimizeStatusSkipped,
      SuggestionStatus.pending => null,
    };
    final shownSuggestion = s.status == SuggestionStatus.edited
        ? s.editedText
        : s.suggestedText;

    return AnimatedOpacity(
      duration: duration,
      curve: AppMotion.enter,
      opacity: s.status == SuggestionStatus.rejected ? 0.55 : 1,
      child: CareerlyColorSection(
        tone: s.impact == SuggestionImpact.high
            ? CareerlySurfaceTone.coral
            : CareerlySurfaceTone.neutral,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: CareerlySectionLabel(impact)),
                AnimatedSwitcher(
                  duration: duration,
                  child: statusLabel == null
                      ? const SizedBox.shrink()
                      : Row(
                          key: ValueKey(statusLabel),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (s.status != SuggestionStatus.rejected)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.inkNavy,
                              ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(statusLabel, style: theme.textTheme.labelMedium),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.optimizeOriginal, style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text('“${s.originalText}”', style: theme.textTheme.bodyMedium),
            if (shownSuggestion != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.status == SuggestionStatus.edited
                    ? l10n.optimizeYourVersion
                    : l10n.optimizeSuggested,
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '“$shownSuggestion”',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(why, style: theme.textTheme.bodySmall),
            if (s.needsUserFact && !decided) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.kind == SuggestionKind.noMetric
                    ? l10n.optimizeQuestionMetric
                    : l10n.optimizeQuestionOutcome,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkNavy,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (decided)
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: l10n.optimizeUndo,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.compact,
                  expanded: false,
                  onPressed: onUndo,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (s.suggestedText != null)
                    AppButton(
                      label: l10n.optimizeAccept,
                      size: AppButtonSize.compact,
                      expanded: false,
                      onPressed: onAccept,
                    ),
                  AppButton(
                    label: l10n.optimizeEdit,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                    expanded: false,
                    onPressed: onEdit,
                  ),
                  AppButton(
                    label: l10n.optimizeSkip,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.compact,
                    expanded: false,
                    onPressed: onReject,
                  ),
                  if (aiAvailable)
                    PopupMenuButton<RewriteMode>(
                      enabled: !rewriting,
                      onSelected: onRewrite,
                      itemBuilder: (context) => [
                        for (final mode in RewriteMode.values)
                          PopupMenuItem(
                            value: mode,
                            child: Text(_modeLabel(l10n, mode)),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: rewriting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                l10n.optimizeRewrite,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.cobalt,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _modeLabel(AppLocalizations l10n, RewriteMode mode) {
    return switch (mode) {
      RewriteMode.impact => l10n.optimizeModeImpact,
      RewriteMode.concise => l10n.optimizeModeConcise,
      RewriteMode.professional => l10n.optimizeModeProfessional,
      RewriteMode.jobTargeted => l10n.optimizeModeJobTargeted,
      RewriteMode.grammar => l10n.optimizeModeGrammar,
    };
  }
}

class _ScoreChangeCard extends StatelessWidget {
  const _ScoreChangeCard({required this.change, required this.hasJob});

  final ScoreChange change;
  final bool hasJob;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final before = change.before;
    final after = change.after;
    final unchanged =
        before.cvQuality == after.cvQuality &&
        before.atsReadability == after.atsReadability;
    return CareerlyColorSection(
      tone: CareerlySurfaceTone.mint,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CareerlySectionLabel(l10n.optimizeResultTitle),
          const SizedBox(height: AppSpacing.sm),
          _DeltaRow(
            label: l10n.productCvQuality,
            from: before.cvQuality,
            to: after.cvQuality,
          ),
          if (before.atsReadability != null && after.atsReadability != null)
            _DeltaRow(
              label: l10n.productAtsReadability,
              from: before.atsReadability!,
              to: after.atsReadability!,
            ),
          if (unchanged) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.optimizeResultUnchanged, style: theme.textTheme.bodySmall),
          ],
          if (hasJob) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.optimizeJobMatchRerun, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({required this.label, required this.from, required this.to});

  final String label;
  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = careerlyReduceMotion(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text('$from  →  ', style: theme.textTheme.titleMedium),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: from.toDouble(), end: to.toDouble()),
            duration: reduce ? Duration.zero : AppMotion.slow,
            curve: AppMotion.enter,
            builder: (context, value, _) => Text(
              '${value.round()}',
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.version,
    required this.busy,
    required this.onRestore,
    required this.onOpenInBuilder,
  });

  final CvVersion version;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onOpenInBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final type = version.type == CvVersionType.original
        ? l10n.optimizeVersionOriginal
        : l10n.optimizeVersionOptimized;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).add_Hm().format(version.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$type · ${version.label}', style: theme.textTheme.titleSmall),
                Text(
                  [
                    date,
                    if (version.cvQuality != null)
                      '${l10n.productCvQuality} ${version.cvQuality}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<VoidCallback>(
            enabled: !busy,
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(value: onRestore, child: Text(l10n.optimizeRestore)),
              PopupMenuItem(
                value: onOpenInBuilder,
                child: Text(l10n.optimizeOpenInBuilder),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
