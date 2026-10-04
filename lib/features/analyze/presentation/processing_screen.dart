import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/processing_stage_view.dart';
import '../application/analysis_controller.dart';
import '../domain/analysis_models.dart';

class AnalysisProcessingScreen extends ConsumerStatefulWidget {
  const AnalysisProcessingScreen({super.key});

  @override
  ConsumerState<AnalysisProcessingScreen> createState() =>
      _AnalysisProcessingScreenState();
}

class _AnalysisProcessingScreenState
    extends ConsumerState<AnalysisProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // If user landed here without an active run, kick off or bounce back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(analysisControllerProvider);
      if (state.phase == AnalysisPhase.ready && state.selectedFile != null) {
        ref.read(analysisControllerProvider.notifier).startAnalysis();
      } else if (state.phase == AnalysisPhase.initial ||
          state.phase == AnalysisPhase.completed) {
        context.go(AppRoutes.analyze);
      }
    });
  }

  String _stageLabel(AppLocalizations l10n, AnalysisProcessingStage? stage) {
    return switch (stage) {
      AnalysisProcessingStage.readingStructure => l10n.analyzeStageReading,
      AnalysisProcessingStage.detectingSections => l10n.analyzeStageDetecting,
      AnalysisProcessingStage.checkingAts => l10n.analyzeStageAts,
      AnalysisProcessingStage.reviewingContent => l10n.analyzeStageReviewing,
      null => l10n.loadingGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(analysisControllerProvider);

    ref.listen<AnalysisUiState>(analysisControllerProvider, (prev, next) {
      if (next.phase == AnalysisPhase.reviewRequired) {
        context.go(AppRoutes.analyzeReview);
      } else if (next.phase == AnalysisPhase.failure) {
        final key = next.failure?.messageKey;
        final message = switch (key) {
          'analyzeErrorTooLarge' => l10n.analyzeErrorTooLarge,
          'analyzeErrorUnreadable' => l10n.analyzeErrorUnreadable,
          'analyzeErrorScanned' => l10n.analyzeErrorScanned,
          'analyzeErrorExtension' => l10n.analyzeErrorExtension,
          _ => l10n.analyzeErrorGeneric,
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        context.go(AppRoutes.analyze);
      } else if (next.phase == AnalysisPhase.ready &&
          prev?.phase == AnalysisPhase.processing) {
        // Cancelled
        context.go(AppRoutes.analyze);
      }
    });

    final stageIndex = state.processingStage?.index ?? 0;
    final progress = (stageIndex + 1) / AnalysisProcessingStage.values.length;

    void cancel() {
      ref.read(analysisControllerProvider.notifier).cancelProcessing();
      context.go(AppRoutes.analyze);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.analyzeProcessingTitle),
        leading: IconButton(
          tooltip: l10n.cancel,
          onPressed: cancel,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: ProcessingStageView(
        headline: l10n.analyzeProcessingHeadline,
        stageLabel: _stageLabel(l10n, state.processingStage),
        progress: progress,
        hint: l10n.analyzeProcessingHint,
        cancelLabel: l10n.cancel,
        onCancel: cancel,
        currentIndex: stageIndex,
        stages: [
          l10n.analyzeStageReading,
          l10n.analyzeStageDetecting,
          l10n.analyzeStageAts,
          l10n.analyzeStageReviewing,
        ],
      ),
    );
  }
}
