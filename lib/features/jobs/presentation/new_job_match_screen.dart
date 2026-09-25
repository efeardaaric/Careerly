import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../analyze/application/analysis_controller.dart';
import '../../analyze/presentation/widgets/cv_score_indicator.dart';
import '../application/job_match_controller.dart';
import '../data/resume_snapshot_builder.dart';

class NewJobMatchScreen extends ConsumerWidget {
  const NewJobMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final matchState = ref.watch(jobMatchControllerProvider);
    final analysis = ref.watch(analysisControllerProvider).analysis;

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.jobsSelectCvTitle),
          leading: IconButton(
            tooltip: l10n.back,
            onPressed: () {
              ref.read(jobMatchControllerProvider.notifier).backToList();
              context.go(AppRoutes.jobs);
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyView(
            icon: Icons.description_outlined,
            title: l10n.jobsNoCvTitle,
            body: l10n.jobsNoCvBody,
            actionLabel: l10n.jobsNoCvCta,
            onAction: () => context.go(AppRoutes.analyze),
          ),
        ),
      );
    }

    final snapshot =
        matchState.selectedResume ??
        ResumeSnapshotBuilder.fromAnalyzedCv(
          resumeId: analysis.resumeId,
          fileName: analysis.fileName,
          overallScore: analysis.overallScore,
        );
    final isSelected =
        matchState.selectedResume != null &&
        matchState.selectedResume!.resumeId == analysis.resumeId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobsSelectCvTitle),
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () {
            ref.read(jobMatchControllerProvider.notifier).backToList();
            context.go(AppRoutes.jobs);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.jobsSelectCvSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Material(
                color: isSelected
                    ? AppColors.actionBlue.withValues(alpha: 0.08)
                    : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: BorderSide(
                    color: isSelected ? AppColors.actionBlue : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ref
                        .read(jobMatchControllerProvider.notifier)
                        .selectResume(snapshot);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CvScoreIndicator(
                          score: analysis.overallScore,
                          size: 56,
                          animate: false,
                          semanticLabel: l10n.scoreSemantic(
                            analysis.overallScore,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                analysis.fileName,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                MaterialLocalizations.of(context)
                                    .formatShortDate(
                                      analysis.analyzedAt.toLocal(),
                                    ),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.actionBlue
                              : AppColors.secondaryText,
                          semanticLabel: l10n.jobsSelectCvTitle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AppButton(
                label: l10n.jobsSelectCvContinue,
                onPressed: () {
                  ref
                      .read(jobMatchControllerProvider.notifier)
                      .selectResume(snapshot);
                  ref
                      .read(jobMatchControllerProvider.notifier)
                      .continueToJobForm();
                  context.push(AppRoutes.jobsEnter);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
