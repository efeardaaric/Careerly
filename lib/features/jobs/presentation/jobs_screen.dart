import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../analyze/application/analysis_controller.dart';
import '../../home/presentation/home_shell.dart';
import '../application/job_match_controller.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(jobMatchControllerProvider);
    final hasAnalysis = ref.watch(analysisControllerProvider).analysis != null;

    return CareerlyScaffold(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CareerlyEditorialHeader(
            label: 'JOB MATCH',
            headline: 'See what the\nrole is asking for.',
            supporting: l10n.jobsHowItWorksTitle,
            background: AppColors.iceBlue,
            trailing: const CareerlyDocumentPreview(
              width: 52,
              height: 70,
              accent: AppColors.cobalt,
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
                if (hasAnalysis)
                  AppButton(
                    label: l10n.jobsNewMatch,
                    onPressed: () {
                      ref
                          .read(jobMatchControllerProvider.notifier)
                          .startNewMatch();
                      context.push(AppRoutes.jobsNew);
                    },
                  )
                else
                  AppButton(
                    label: l10n.jobsNoCvCta,
                    onPressed: () => context.go(AppRoutes.analyze),
                  ),
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.jobsSavedTitle),
                const SizedBox(height: AppSpacing.md),
                if (state.savedMatches.isEmpty)
                  CareerlyEmptyState(
                    number: '00',
                    label: 'NO MATCHES YET',
                    headline: hasAnalysis
                        ? 'Your next application\nstarts here.'
                        : l10n.jobsNoCvTitle,
                    body: hasAnalysis ? l10n.jobsEmptyBody : l10n.jobsNoCvBody,
                    actionLabel:
                        hasAnalysis ? l10n.jobsNewMatch : l10n.jobsNoCvCta,
                    onAction: () {
                      if (!hasAnalysis) {
                        context.go(AppRoutes.analyze);
                        return;
                      }
                      ref
                          .read(jobMatchControllerProvider.notifier)
                          .startNewMatch();
                      context.push(AppRoutes.jobsNew);
                    },
                  )
                else
                  ...state.savedMatches.map((match) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Material(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          onTap: () {
                            ref
                                .read(jobMatchControllerProvider.notifier)
                                .openSaved(match);
                            context.push(AppRoutes.jobsResults);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                CareerlyMetric(
                                  score: match.overallMatchScore,
                                  compact: true,
                                  semanticLabel: l10n.jobsRecentMatchScore(
                                    match.overallMatchScore,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        match.jobTitle,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        match.company ?? '—',
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: AppColors.cobalt,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                if (state.savedMatches.isEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  CareerlySectionLabel(l10n.jobsHowItWorksTitle),
                  const SizedBox(height: AppSpacing.md),
                  _Step(number: '01', text: l10n.jobsHowItWorks1),
                  _Step(number: '02', text: l10n.jobsHowItWorks2),
                  _Step(number: '03', text: l10n.jobsHowItWorks3),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.cobalt,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
