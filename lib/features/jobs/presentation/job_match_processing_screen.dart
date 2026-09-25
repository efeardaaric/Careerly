import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/widgets/processing_stage_view.dart';
import '../../billing/domain/billing_models.dart';
import '../../billing/presentation/billing_gate.dart';
import '../application/job_match_controller.dart';
import '../domain/job_match_models.dart';

class JobMatchProcessingScreen extends ConsumerStatefulWidget {
  const JobMatchProcessingScreen({super.key});

  @override
  ConsumerState<JobMatchProcessingScreen> createState() =>
      _JobMatchProcessingScreenState();
}

class _JobMatchProcessingScreenState
    extends ConsumerState<JobMatchProcessingScreen> {
  String _stageLabel(AppLocalizations l10n, JobMatchProcessingStage? stage) {
    return switch (stage) {
      JobMatchProcessingStage.readingJob => l10n.jobsStageReadingJob,
      JobMatchProcessingStage.matchingSkills => l10n.jobsStageMatchingSkills,
      JobMatchProcessingStage.scoringAlignment => l10n.jobsStageScoring,
      JobMatchProcessingStage.draftingSuggestions => l10n.jobsStageSuggestions,
      null => l10n.loadingGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(jobMatchControllerProvider);

    ref.listen<JobMatchUiState>(jobMatchControllerProvider, (prev, next) {
      if (next.phase == JobMatchPhase.results) {
        consumePendingUsage(ref, FeatureId.jobMatch);
        context.go(AppRoutes.jobsResults);
      } else if (next.phase == JobMatchPhase.failure) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobsErrorGeneric)));
        context.go(AppRoutes.jobsEnter);
      } else if (next.phase == JobMatchPhase.enterJob &&
          prev?.phase == JobMatchPhase.processing) {
        context.go(AppRoutes.jobsEnter);
      }
    });

    final stageIndex = state.processingStage?.index ?? 0;
    final progress = (stageIndex + 1) / JobMatchProcessingStage.values.length;

    void cancel() {
      ref.read(jobMatchControllerProvider.notifier).cancelProcessing();
      context.go(AppRoutes.jobsEnter);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobsProcessingTitle),
        leading: IconButton(
          tooltip: l10n.cancel,
          onPressed: cancel,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: ProcessingStageView(
        headline: l10n.jobsProcessingTitle,
        body: l10n.jobsProcessingBody,
        stageLabel: _stageLabel(l10n, state.processingStage),
        progress: progress,
        cancelLabel: l10n.cancel,
        onCancel: cancel,
      ),
    );
  }
}
