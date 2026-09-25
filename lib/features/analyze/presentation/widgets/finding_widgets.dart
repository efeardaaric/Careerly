import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/careerly_identity.dart';
import '../../domain/analysis_models.dart';

class FindingCard extends StatelessWidget {
  const FindingCard({super.key, required this.finding, required this.onOpen});

  final AnalysisFinding finding;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (color, icon, label) = switch (finding.severity) {
      FindingSeverity.critical => (
        AppColors.critical,
        Icons.error_outline,
        l10n.findingSeverityCritical,
      ),
      FindingSeverity.improve => (
        AppColors.warning,
        Icons.tips_and_updates_outlined,
        l10n.findingSeverityImprove,
      ),
      FindingSeverity.good => (
        AppColors.success,
        Icons.check_circle_outline,
        l10n.findingSeverityGood,
      ),
    };

    return AppCard(
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(finding.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  finding.recommendedAction,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

Future<void> showFindingDetailSheet({
  required BuildContext context,
  required AnalysisFinding finding,
  required VoidCallback onImproveInfo,
}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(finding.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                _DetailBlock(
                  title: l10n.findingWhyMatters,
                  body: finding.whyItMatters,
                ),
                _DetailBlock(
                  title: l10n.findingEvidence,
                  body: finding.evidence,
                ),
                _DetailBlock(
                  title: l10n.findingAction,
                  body: finding.recommendedAction,
                ),
                if (finding.beforeText != null &&
                    finding.afterText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.suggestionDemoTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BeforeAfterSuggestion(
                    beforeText: finding.beforeText!,
                    afterText: finding.afterText!,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (finding.supportsAiImprove)
                  AppButton(
                    label: l10n.findingImproveWithAi,
                    onPressed: () {
                      Navigator.pop(context);
                      onImproveInfo();
                    },
                  ),
                AppButton(
                  label: l10n.close,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class BeforeAfterSuggestion extends StatefulWidget {
  const BeforeAfterSuggestion({
    super.key,
    required this.beforeText,
    required this.afterText,
    this.onAccept,
    this.onEdit,
    this.onReject,
  });

  final String beforeText;
  final String afterText;
  final VoidCallback? onAccept;
  final VoidCallback? onEdit;
  final VoidCallback? onReject;

  @override
  State<BeforeAfterSuggestion> createState() => _BeforeAfterSuggestionState();
}

class _BeforeAfterSuggestionState extends State<BeforeAfterSuggestion> {
  String? _decision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(AppRadii.block),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CareerlySectionLabel(l10n.suggestionBefore),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.beforeText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const CareerlyHairline(),
          const SizedBox(height: AppSpacing.md),
          CareerlySectionLabel(l10n.suggestionAfter, color: AppColors.inkNavy),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.afterText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.inkNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.suggestionDemoNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
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
                  setState(() => _decision = 'accepted');
                  widget.onAccept?.call();
                },
              ),
              AppButton(
                label: l10n.suggestionEdit,
                size: AppButtonSize.compact,
                expanded: false,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  setState(() => _decision = 'edit');
                  widget.onEdit?.call();
                },
              ),
              AppButton(
                label: l10n.suggestionReject,
                size: AppButtonSize.compact,
                expanded: false,
                variant: AppButtonVariant.ghost,
                onPressed: () {
                  setState(() => _decision = 'rejected');
                  widget.onReject?.call();
                },
              ),
            ],
          ),
          if (_decision != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.suggestionDecisionSaved,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CategoryScoreRow extends StatelessWidget {
  const CategoryScoreRow({
    super.key,
    required this.label,
    required this.score,
    required this.summary,
  });

  final String label;
  final int score;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = score >= 80
        ? AppColors.mint
        : score >= 65
            ? AppColors.cobalt
            : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelMedium,
                ),
              ),
              Text(
                '$score',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  letterSpacing: -0.5,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          CareerlyProgressRow(value: score / 100, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(summary, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
