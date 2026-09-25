import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../analyze/presentation/widgets/finding_widgets.dart';
import '../application/job_match_controller.dart';
import '../domain/job_match_models.dart';

class JobMatchResultScreen extends ConsumerWidget {
  const JobMatchResultScreen({super.key});

  String _categoryLabel(AppLocalizations l10n, JobMatchCategoryId id) {
    return switch (id) {
      JobMatchCategoryId.coreSkills => l10n.jobsCategoryCoreSkills,
      JobMatchCategoryId.experienceProjects => l10n.jobsCategoryExperience,
      JobMatchCategoryId.responsibilities => l10n.jobsCategoryResponsibilities,
      JobMatchCategoryId.education => l10n.jobsCategoryEducation,
      JobMatchCategoryId.tools => l10n.jobsCategoryTools,
      JobMatchCategoryId.languageOther => l10n.jobsCategoryLanguage,
    };
  }

  String _statusLabel(AppLocalizations l10n, SkillEvidenceStatus status) {
    return switch (status) {
      SkillEvidenceStatus.matched => l10n.jobsSkillsMatched,
      SkillEvidenceStatus.partial => l10n.jobsSkillsPartial,
      SkillEvidenceStatus.notDemonstrated => l10n.jobsSkillsNotDemonstrated,
      SkillEvidenceStatus.unclear => l10n.jobsSkillsUnclear,
    };
  }

  Color _statusColor(SkillEvidenceStatus status) {
    return switch (status) {
      SkillEvidenceStatus.matched => AppColors.mint,
      SkillEvidenceStatus.partial => AppColors.cobalt,
      SkillEvidenceStatus.notDemonstrated => AppColors.coral,
      SkillEvidenceStatus.unclear => AppColors.secondaryText,
    };
  }

  String _alignmentStatus(int score) {
    if (score >= 80) return 'STRONG ALIGNMENT';
    if (score >= 65) return 'GOOD ALIGNMENT';
    if (score >= 40) return 'PARTIAL ALIGNMENT';
    return 'WEAK ALIGNMENT';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(jobMatchControllerProvider);
    final match = state.result;

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.jobsResultsTitle)),
        body: CareerlyEmptyState(
          label: 'NO MATCH',
          headline: l10n.emptyGenericTitle,
          body: l10n.jobsSavedEmpty,
          actionLabel: l10n.jobsNewMatch,
          onAction: () => context.go(AppRoutes.jobs),
        ),
      );
    }

    final matched = match.skillMatches
        .where((s) => s.status == SkillEvidenceStatus.matched)
        .length;
    final partial = match.skillMatches
        .where((s) => s.status == SkillEvidenceStatus.partial)
        .length;
    final missing = match.skillMatches
        .where(
          (s) =>
              s.status == SkillEvidenceStatus.notDemonstrated ||
              s.status == SkillEvidenceStatus.unclear,
        )
        .length;
    final total = (matched + partial + missing).clamp(1, 9999);
    final topGap = match.recommendations.isNotEmpty
        ? match.recommendations.first
        : null;
    final firstVerify = match.verificationQuestions.isNotEmpty
        ? match.verificationQuestions.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.jobsResultsTitle),
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () {
            ref.read(jobMatchControllerProvider.notifier).backToList();
            context.go(AppRoutes.jobs);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // —— JOB MATCH hero: ink navy + cobalt ——
          CareerlyColorSection(
            tone: CareerlySurfaceTone.navy,
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              0,
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CareerlySectionLabel('JOB MATCH', light: true),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: match.overallMatchScore.toDouble(),
                      ),
                      duration: AppMotion.score,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          '${value.round()}%',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 64,
                            height: 0.95,
                            letterSpacing: -2,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cobalt.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(
                        _alignmentStatus(match.overallMatchScore),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  match.jobTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (match.company != null && match.company!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    match.company!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                CareerlyProgressRow(
                  value: match.overallMatchScore / 100,
                  color: AppColors.cobalt,
                  trackColor: Colors.white.withValues(alpha: 0.12),
                  height: 4,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  match.scoreDisclaimer.isNotEmpty
                      ? match.scoreDisclaimer
                      : l10n.jobsScoreDisclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
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
                // Evidence distribution — not a hiring probability
                CareerlySectionLabel('EVIDENCE'),
                const SizedBox(height: AppSpacing.md),
                _EvidenceBar(
                  matched: matched / total,
                  partial: partial / total,
                  missing: missing / total,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _LegendDot(color: AppColors.mint, label: l10n.jobsSkillsMatched),
                    const SizedBox(width: AppSpacing.md),
                    _LegendDot(color: AppColors.cobalt, label: l10n.jobsSkillsPartial),
                    const SizedBox(width: AppSpacing.md),
                    _LegendDot(
                      color: AppColors.coral,
                      label: l10n.jobsSkillsNotDemonstrated,
                    ),
                  ],
                ),

                if (topGap != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  CareerlyColorSection(
                    tone: CareerlySurfaceTone.coral,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CareerlyStatusMarker(
                              color: AppColors.coral,
                              shape: CareerlyMarkerShape.diamond,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            CareerlySectionLabel(
                              '01 — BIGGEST GAP',
                              color: AppColors.coral,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          topGap.title,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(topGap.body, style: theme.textTheme.bodyMedium),
                        if (firstVerify != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            firstVerify,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.inkNavy,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.jobsBreakdownTitle),
                const SizedBox(height: AppSpacing.md),
                for (final c in match.categories) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _categoryLabel(l10n, c.id).toUpperCase(),
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      Text(
                        '${c.score}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  CareerlyProgressRow(
                    value: c.score / 100,
                    color: AppColors.cobalt,
                  ),
                  if (c.summary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(c.summary, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],

                CareerlySectionLabel(l10n.jobsSkillsTitle),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < match.skillMatches.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final item = match.skillMatches[i];
                      final color = _statusColor(item.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: CareerlyStatusMarker(
                                color: color,
                                shape: CareerlyMarkerShape.square,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.skill,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    _statusLabel(l10n, item.status),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: color,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  if (item.note != null) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      item.note!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (item.required)
                              Text(
                                '*',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.coral,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (i < match.skillMatches.length - 1) const CareerlyHairline(),
                  if (i < match.skillMatches.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],

                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.jobsKeywordsCovered,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final k in match.keywordsCovered) AppTagChip(label: k),
                    if (match.keywordsCovered.isEmpty)
                      Text('—', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.jobsKeywordsMissing,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final k in match.keywordsMissing) AppTagChip(label: k),
                    if (match.keywordsMissing.isEmpty)
                      Text('—', style: theme.textTheme.bodySmall),
                  ],
                ),

                if (match.workingWell.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  CareerlyColorSection(
                    tone: CareerlySurfaceTone.mint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CareerlySectionLabel(
                          l10n.jobsWorkingWellTitle,
                          color: AppColors.inkNavy,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final w in match.workingWell)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CareerlyStatusMarker(
                                  color: AppColors.mint,
                                  shape: CareerlyMarkerShape.circle,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    w,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.jobsRecommendationsTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.jobsRecommendationsBody,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                ...match.recommendations.map((rec) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(rec.body, style: theme.textTheme.bodyMedium),
                        if (rec.beforeText != null &&
                            rec.afterText != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          BeforeAfterSuggestion(
                            beforeText: rec.beforeText!,
                            afterText: rec.editedText ?? rec.afterText!,
                            onAccept: () {
                              ref
                                  .read(jobMatchControllerProvider.notifier)
                                  .setSuggestionDecision(
                                    rec.id,
                                    SuggestionDecision.accepted,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.suggestionDecisionSaved),
                                ),
                              );
                            },
                            onEdit: () async {
                              final controller = TextEditingController(
                                text: rec.afterText,
                              );
                              final edited = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(l10n.suggestionEdit),
                                    content: TextField(
                                      controller: controller,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        labelText: l10n.suggestionAfter,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                          context,
                                          controller.text,
                                        ),
                                        child: Text(l10n.save),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (edited != null) {
                                ref
                                    .read(jobMatchControllerProvider.notifier)
                                    .setSuggestionDecision(
                                      rec.id,
                                      SuggestionDecision.edited,
                                      editedText: edited,
                                    );
                              }
                            },
                            onReject: () {
                              ref
                                  .read(jobMatchControllerProvider.notifier)
                                  .setSuggestionDecision(
                                    rec.id,
                                    SuggestionDecision.rejected,
                                  );
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              AppButton(
                                label: l10n.suggestionAccept,
                                size: AppButtonSize.compact,
                                expanded: false,
                                variant: AppButtonVariant.secondary,
                                onPressed: () {
                                  ref
                                      .read(jobMatchControllerProvider.notifier)
                                      .setSuggestionDecision(
                                        rec.id,
                                        SuggestionDecision.accepted,
                                      );
                                },
                              ),
                              AppButton(
                                label: l10n.suggestionReject,
                                size: AppButtonSize.compact,
                                expanded: false,
                                variant: AppButtonVariant.ghost,
                                onPressed: () {
                                  ref
                                      .read(jobMatchControllerProvider.notifier)
                                      .setSuggestionDecision(
                                        rec.id,
                                        SuggestionDecision.rejected,
                                      );
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                if (match.verificationQuestions.length > 1) ...[
                  const SizedBox(height: AppSpacing.md),
                  CareerlySectionLabel(l10n.jobsVerificationTitle),
                  const SizedBox(height: AppSpacing.md),
                  for (final q in match.verificationQuestions.skip(1))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text('• $q'),
                    ),
                ],
                if (match.learningOpportunities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  CareerlySectionLabel(l10n.jobsLearningTitle),
                  const SizedBox(height: AppSpacing.md),
                  for (final q in match.learningOpportunities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text('• $q'),
                    ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.jobsSaveMatch,
                  onPressed: () async {
                    await ref
                        .read(jobMatchControllerProvider.notifier)
                        .saveCurrentMatch();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.jobsSavedSnack)),
                      );
                      context.go(AppRoutes.jobs);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceBar extends StatelessWidget {
  const _EvidenceBar({
    required this.matched,
    required this.partial,
    required this.missing,
  });

  final double matched;
  final double partial;
  final double missing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (matched > 0)
              Expanded(
                flex: (matched * 1000).round().clamp(1, 1000),
                child: const ColoredBox(color: AppColors.mint),
              ),
            if (partial > 0)
              Expanded(
                flex: (partial * 1000).round().clamp(1, 1000),
                child: const ColoredBox(color: AppColors.cobalt),
              ),
            if (missing > 0)
              Expanded(
                flex: (missing * 1000).round().clamp(1, 1000),
                child: const ColoredBox(color: AppColors.coral),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CareerlyStatusMarker(color: color, size: 7),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.4,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
