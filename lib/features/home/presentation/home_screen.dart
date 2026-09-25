import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../analyze/application/analysis_controller.dart';
import '../../jobs/application/job_match_controller.dart';
import 'home_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _weekdayMeta(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final day = DateFormat.EEEE(locale).format(DateTime.now()).toUpperCase();
    return '$day · CAREER OVERVIEW';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final analysis = ref.watch(analysisControllerProvider).analysis;
    final recentMatch = ref.watch(jobMatchControllerProvider).mostRecentSaved;
    final name = session.displayName;
    final readyLine = (name == null || name.isEmpty)
        ? 'Ready for\nyour next move?'
        : 'Ready for\nyour next move,\n$name?';

    return CareerlyScaffold(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CareerlyEditorialHeader(
            label: _weekdayMeta(context),
            headline: readyLine,
            background: AppColors.cream,
            trailing: const CareerlyDocumentPreview(
              width: 56,
              height: 76,
              accent: AppColors.coral,
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
                CareerlySectionLabel(l10n.homeCvCardTitle),
                const SizedBox(height: AppSpacing.md),
                if (analysis == null)
                  CareerlyColorSection(
                    tone: CareerlySurfaceTone.ice,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeCvCardEmptyTitle,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.homeCvCardEmptyBody,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: l10n.homeAnalyzeMyCv,
                          onPressed: () => context.go(AppRoutes.analyze),
                        ),
                      ],
                    ),
                  )
                else
                  CareerlyColorSection(
                    tone: CareerlySurfaceTone.neutral,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    analysis.fileName,
                                    style: theme.textTheme.titleLarge,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    l10n.homeCvCardScoredBody(
                                      MaterialLocalizations.of(context)
                                          .formatShortDate(
                                        analysis.analyzedAt.toLocal(),
                                      ),
                                    ),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            CareerlyMetric(
                              score: analysis.overallScore,
                              semanticLabel:
                                  l10n.scoreSemantic(analysis.overallScore),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CareerlyProgressRow(
                          value: analysis.overallScore / 100,
                          color: AppColors.cobalt,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: l10n.homeViewAnalysis,
                                onPressed: () =>
                                    context.push(AppRoutes.analyzeResults),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: l10n.homeAnalyzeAgain,
                                variant: AppButtonVariant.secondary,
                                onPressed: () => context.go(AppRoutes.analyze),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (analysis != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  CareerlyNextMove(
                    title: analysis.topImprovements.isNotEmpty
                        ? analysis.topImprovements.first.title
                        : l10n.homeCareerProgressScored,
                    body: analysis.topImprovements.isNotEmpty
                        ? analysis.topImprovements.first.whyItMatters
                        : l10n.homeStatusScored(analysis.overallScore),
                    ctaLabel: l10n.homeViewAnalysis,
                    onCta: () => context.push(AppRoutes.analyzeResults),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.homeQuickActions),
                const SizedBox(height: AppSpacing.md),
                // Asymmetric: large primary + text actions
                AppButton(
                  label: l10n.homeActionAnalyze,
                  icon: Icons.analytics_outlined,
                  onPressed: () => context.go(AppRoutes.analyze),
                ),
                const SizedBox(height: AppSpacing.sm),
                _TextAction(
                  label: l10n.homeActionMatch,
                  onTap: () => context.go(AppRoutes.jobs),
                ),
                _TextAction(
                  label: l10n.homeActionBuild,
                  onTap: () => context.go(AppRoutes.builder),
                ),
                _TextAction(
                  label: l10n.homeActionTranslate,
                  onTap: () => context.go(AppRoutes.builder),
                  showDivider: false,
                ),
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.homeRecentMatches),
                const SizedBox(height: AppSpacing.md),
                if (recentMatch == null)
                  CareerlyEmptyState(
                    number: '00',
                    label: 'NO MATCHES YET',
                    headline: 'Your next application\nstarts here.',
                    actionLabel: l10n.homeActionMatch,
                    onAction: () => context.go(AppRoutes.jobs),
                  )
                else
                  CareerlyColorSection(
                    tone: CareerlySurfaceTone.ice,
                    onTap: () => context.go(AppRoutes.jobs),
                    child: Row(
                      children: [
                        CareerlyMetric(
                          score: recentMatch.overallMatchScore,
                          compact: true,
                          semanticLabel: l10n.jobsRecentMatchScore(
                            recentMatch.overallMatchScore,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recentMatch.jobTitle,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                recentMatch.company ?? '—',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.cobalt,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Text(
                  '→',
                  style: TextStyle(
                    color: AppColors.cobalt,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const CareerlyHairline(),
      ],
    );
  }
}
