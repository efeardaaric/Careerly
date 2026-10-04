import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../motion/careerly_motion.dart';
import 'app_button.dart';
import 'careerly_identity.dart';

/// Shared processing layout — editorial timeline (Analyze + Job Match).
class ProcessingStageView extends StatelessWidget {
  const ProcessingStageView({
    super.key,
    required this.headline,
    required this.stageLabel,
    required this.progress,
    required this.cancelLabel,
    required this.onCancel,
    this.body,
    this.hint,
    this.stages,
    this.currentIndex = 0,
  });

  final String headline;
  final String stageLabel;
  final double progress;
  final String cancelLabel;
  final VoidCallback onCancel;
  final String? body;
  final String? hint;
  final List<String>? stages;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = stages ?? [stageLabel];

    final steps = <CareerlyTimelineStep>[
      for (var i = 0; i < labels.length; i++)
        CareerlyTimelineStep(
          title: labels[i],
          state: i < currentIndex
              ? CareerlyTimelineState.completed
              : i == currentIndex
              ? CareerlyTimelineState.current
              : CareerlyTimelineState.upcoming,
        ),
    ];

    // If only one stage label was provided, still show progress row.
    final showTimeline = stages != null && stages!.length > 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Text(headline, style: theme.textTheme.displayMedium),
                    if (body != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(body!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const CareerlyColorSection(
                      tone: CareerlySurfaceTone.mint,
                      child: Center(child: CareerlyScanDocument()),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (showTimeline)
                      CareerlyTimeline(steps: steps)
                    else ...[
                      Text(
                        stageLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.cobalt,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CareerlyProgressRow(value: progress),
                    ],
                    if (hint != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(hint!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: cancelLabel,
              variant: AppButtonVariant.secondary,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
