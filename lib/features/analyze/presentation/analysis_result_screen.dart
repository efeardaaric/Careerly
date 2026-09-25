import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../billing/domain/billing_models.dart';
import '../../billing/presentation/billing_gate.dart';
import '../application/analysis_controller.dart';
import '../domain/analysis_models.dart';
import 'widgets/finding_widgets.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({super.key});

  String _categoryLabel(AppLocalizations l10n, ScoreCategoryId id) {
    return switch (id) {
      ScoreCategoryId.atsCompatibility => l10n.scoreCategoryAts,
      ScoreCategoryId.contentImpact => l10n.scoreCategoryContent,
      ScoreCategoryId.experiencePresentation => l10n.scoreCategoryExperience,
      ScoreCategoryId.skillsRelevance => l10n.scoreCategorySkills,
      ScoreCategoryId.structureReadability => l10n.scoreCategoryStructure,
      ScoreCategoryId.languageGrammar => l10n.scoreCategoryLanguage,
      ScoreCategoryId.basicsContact => l10n.scoreCategoryBasics,
    };
  }

  String _confidenceLabel(AppLocalizations l10n, ParserConfidence c) {
    return switch (c) {
      ParserConfidence.high => l10n.parserConfidenceHigh,
      ParserConfidence.medium => l10n.parserConfidenceMedium,
      ParserConfidence.low => l10n.parserConfidenceLow,
    };
  }

  String _statusFor(int score) {
    if (score >= 80) return 'STRONG';
    if (score >= 65) return 'GOOD';
    if (score >= 40) return 'NEEDS WORK';
    return 'CRITICAL';
  }

  Future<void> _showAiInfo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ensureFeatureAccess(
      context,
      ref,
      FeatureId.aiRewrite,
      paywallContext: 'ai_rewrite',
    );
    if (!ok || !context.mounted) return;
    await consumePendingUsage(ref, FeatureId.aiRewrite);
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.findingImproveWithAi),
          content: Text(l10n.findingImproveWithAiBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(analysisControllerProvider);
    final analysis = state.analysis;

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.analyzeResultsTitle)),
        body: CareerlyEmptyState(
          label: 'NO RESULTS',
          headline: l10n.analyzeNoResultsYet,
          actionLabel: l10n.analyzeSelectCv,
          onAction: () => context.go(AppRoutes.analyze),
        ),
      );
    }

    final ats = analysis.category(ScoreCategoryId.atsCompatibility);
    final top = analysis.topImprovements.isNotEmpty
        ? analysis.topImprovements.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.analyzeResultsTitle),
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.go(AppRoutes.analyze),
          icon: const Icon(Icons.arrow_back_rounded),
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
          CareerlyScoreHero(
            score: analysis.overallScore,
            label: 'CV SCORE',
            status: _statusFor(analysis.overallScore),
            caption: l10n.analyzeOverallScoreBody(
              _confidenceLabel(l10n, analysis.confidence),
            ),
            semanticLabel: l10n.scoreSemantic(analysis.overallScore),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.analyzeScoreDisclaimer,
            style: theme.textTheme.bodySmall,
          ),
          if (top != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CareerlyColorSection(
              tone: CareerlySurfaceTone.coral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CareerlySectionLabel('01 — TOP PRIORITY'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(top.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(top.whyItMatters, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => showFindingDetailSheet(
                      context: context,
                      finding: top,
                      onImproveInfo: () => _showAiInfo(context, ref),
                    ),
                    child: Text(
                      'Improve this →',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.inkNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          CareerlySectionLabel(l10n.analyzeBreakdown),
          const SizedBox(height: AppSpacing.md),
          for (final category in analysis.categories) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _categoryLabel(l10n, category.id).toUpperCase(),
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Text(
                  '${category.score}',
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            CareerlyProgressRow(value: category.score / 100),
            const SizedBox(height: AppSpacing.xxs),
            Text(category.summary, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
          ],
          CareerlyColorSection(
            tone: CareerlySurfaceTone.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CareerlySectionLabel("WHAT'S WORKING"),
                const SizedBox(height: AppSpacing.md),
                for (final item in analysis.workingWell) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CareerlyStatusMarker(
                        color: AppColors.inkNavy,
                        shape: CareerlyMarkerShape.square,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.inkNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CareerlySectionLabel(l10n.analyzeAtsSection),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CareerlyMetric(
                score: ats?.score,
                semanticLabel: l10n.scoreSemantic(ats?.score ?? 0),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  ats?.summary ?? l10n.emptyGenericBody,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (analysis.findings.length > analysis.topImprovements.length) ...[
            const SizedBox(height: AppSpacing.xl),
            CareerlySectionLabel(l10n.analyzeAllFindings),
            const SizedBox(height: AppSpacing.md),
            for (final finding in analysis.findings.where(
              (f) => !analysis.topImprovements.any((t) => t.id == f.id),
            )) ...[
              FindingCard(
                finding: finding,
                onOpen: () => showFindingDetailSheet(
                  context: context,
                  finding: finding,
                  onImproveInfo: () => _showAiInfo(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.analyzeImproveMyCv,
            onPressed: () {
              if (top != null) {
                showFindingDetailSheet(
                  context: context,
                  finding: top,
                  onImproveInfo: () => _showAiInfo(context, ref),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.analyzeDoneToHome,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
