import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../billing/domain/billing_models.dart';
import '../../billing/presentation/billing_gate.dart';
import '../../billing/presentation/soft_upgrade_banner.dart';
import '../../billing/application/billing_controller.dart';
import '../../billing/presentation/paywall_screen.dart';
import '../../home/presentation/home_shell.dart';
import '../application/analysis_controller.dart';
import '../data/cv_file_validator.dart';
import '../domain/analysis_models.dart';
import 'widgets/cv_score_indicator.dart';
import 'widgets/selected_cv_card.dart';

class AnalyzeScreen extends ConsumerWidget {
  const AnalyzeScreen({super.key});

  Future<void> _pickFile(WidgetRef ref, BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: CvFileRules.allowedExtensions.toList(),
      );
      if (files.isEmpty) {
        return; // cancelled
      }
      final file = files.single;
      final ext = (file.extension ?? '').toLowerCase();
      final sizeBytes = file.lengthSync() ?? await file.length() ?? 0;
      final bytes = await file.readAsBytes();
      final selected = SelectedCvFile(
        name: file.name,
        extension: ext,
        sizeBytes: sizeBytes,
        path: file.path,
        bytes: bytes,
      );
      await ref.read(analysisControllerProvider.notifier).selectFile(selected);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.analyzePickFailed)));
      }
    }
  }

  String _validationMessage(AppLocalizations l10n, CvValidationError? error) {
    return switch (error) {
      CvValidationError.invalidExtension => l10n.analyzeErrorExtension,
      CvValidationError.tooLarge => l10n.analyzeErrorTooLarge,
      CvValidationError.emptyFile => l10n.analyzeErrorEmpty,
      CvValidationError.unavailable => l10n.analyzeErrorUnavailable,
      CvValidationError.cancelled => l10n.analyzeErrorCancelled,
      CvValidationError.unknown || null => l10n.analyzeErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(analysisControllerProvider);
    final controller = ref.read(analysisControllerProvider.notifier);

    if (state.phase == AnalysisPhase.completed && state.analysis != null) {
      return _ReturningAnalyzeView(analysis: state.analysis!);
    }

    final canAnalyze =
        state.phase == AnalysisPhase.ready &&
        state.selectedFile != null &&
        !state.isBusy;

    return CareerlyScaffold(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CareerlyEditorialHeader(
            label: 'CV ANALYSIS',
            headline: "Let's see what\nyour CV says.",
            supporting: l10n.analyzeUploadBody,
            background: AppColors.iceBlue,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          CareerlyColorSection(
            tone: CareerlySurfaceTone.cream,
            onTap: state.isBusy ? null : () => _pickFile(ref, context),
            child: Column(
              children: [
                const CareerlyDocumentPreview(
                  width: 64,
                  height: 86,
                  accent: AppColors.cobalt,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.analyzeSelectCv,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.analyzeSupportedFormats,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (state.selectedFile != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SelectedCvCard(
              file: state.selectedFile!,
              onChange: () => _pickFile(ref, context),
              onRemove: controller.clearSelection,
            ),
          ],
          if (state.validationError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _validationMessage(l10n, state.validationError),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.critical,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SoftUpgradeBanner(
            decision: ref
                .watch(billingControllerProvider)
                .decision(FeatureId.cvAnalysis),
            onUpgrade: () => showPaywall(context, contextKey: 'analyze_soft'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.analyzeStartCta,
            isLoading: state.isBusy && state.phase == AnalysisPhase.validating,
            onPressed: canAnalyze
                ? () async {
                    final ok = await ensureFeatureAccess(
                      context,
                      ref,
                      FeatureId.cvAnalysis,
                      paywallContext: 'analyze_start',
                    );
                    if (ok && context.mounted) {
                      context.push(AppRoutes.analyzeProcessing);
                    }
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.analyzePrivacyNote,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          CareerlySectionLabel(l10n.analyzeWhatWeCheck),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(text: l10n.analyzeCheckAts),
          _CheckRow(text: l10n.analyzeCheckContent),
          _CheckRow(text: l10n.analyzeCheckSkills, isLast: true),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.analyzeScoreDisclaimer, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturningAnalyzeView extends ConsumerWidget {
  const _ReturningAnalyzeView({required this.analysis});

  final ResumeAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return CareerlyScaffold(
      title: l10n.analyzeTitle,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.analyzeReturningTitle,
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.analyzeReturningBody(analysis.fileName),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Row(
              children: [
                CvScoreIndicator(
                  score: analysis.overallScore,
                  label: l10n.scoreOutOf100,
                  size: 84,
                  semanticLabel: l10n.scoreSemantic(analysis.overallScore),
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
                        l10n.analyzeLastScan(
                          MaterialLocalizations.of(context)
                              .formatShortDate(analysis.analyzedAt.toLocal()),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.analyzeViewResults,
            onPressed: () => context.push(AppRoutes.analyzeResults),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.analyzeAgain,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              await ref
                  .read(analysisControllerProvider.notifier)
                  .reanalyzeNewFile();
            },
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.text, this.isLast = false});

  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 20,
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
