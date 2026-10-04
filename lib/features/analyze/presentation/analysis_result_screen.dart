import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../../core/widgets/resume_template_gallery.dart';
import '../../jobs/application/job_match_controller.dart';
import '../../jobs/domain/job_match_models.dart';
import '../application/analysis_controller.dart';
import '../domain/analysis_models.dart';
import '../domain/product_scores.dart';
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

  String _bandLabel(AppLocalizations l10n, int score) {
    return switch (scoreBand(score)) {
      ScoreBand.excellent => l10n.productBandExcellent,
      ScoreBand.strong => l10n.productBandStrong,
      ScoreBand.developing => l10n.productBandDeveloping,
      ScoreBand.needsWork => l10n.productBandNeedsWork,
    };
  }

  String _sliceTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'contentImpact' => l10n.productQualityImpact,
      'experiencePresentation' => l10n.productQualityExperience,
      'skillsRelevance' => l10n.productQualitySkills,
      'structureReadability' => l10n.productQualityStructure,
      'languageGrammar' => l10n.productQualityWriting,
      'basicsContact' => l10n.productQualityConcise,
      _ => key,
    };
  }

  void _showQuality(
    BuildContext context,
    AppLocalizations l10n,
    ProductScores scores,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.productCvQuality,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final slice in scores.quality) ...[
                  Row(
                    children: [
                      Expanded(child: Text(_sliceTitle(l10n, slice.title))),
                      Text('${slice.earned} / ${slice.possible}'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  CareerlyProgressRow(
                    value: slice.possible == 0
                        ? 0
                        : slice.earned / slice.possible,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAts(
    BuildContext context,
    AppLocalizations l10n,
    ProductScores scores,
    String? summary,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.productAtsReadability,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.productScoreDisclaimer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (summary != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(summary, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (scores.atsReadability != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${scores.atsReadability} / 100 · ${_bandLabel(l10n, scores.atsReadability!)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Suggestions are free to review; the paywall applies when changes are applied.
  void _showAiInfo(BuildContext context, WidgetRef ref) {
    context.push(AppRoutes.optimize);
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
          label: l10n.labelNoResults,
          headline: l10n.analyzeNoResultsYet,
          actionLabel: l10n.analyzeSelectCv,
          onAction: () => context.go(AppRoutes.analyze),
        ),
      );
    }

    final ats = analysis.category(ScoreCategoryId.atsCompatibility);
    final scores = ProductScores.fromAnalysis(analysis);
    final jobs = ref.watch(jobMatchControllerProvider);
    final match = jobs.result?.resumeId == analysis.resumeId
        ? jobs.result
        : jobs.savedMatches.cast<JobMatchResult?>().firstWhere(
            (item) => item?.resumeId == analysis.resumeId,
            orElse: () => null,
          );
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
        padding: EdgeInsets.only(
          left: AppSpacing.pageInsets(context).left,
          top: AppSpacing.sm,
          right: AppSpacing.pageInsets(context).right,
          bottom: AppSpacing.xxl,
        ),
        children: [
          _ScoreTrio(
            scores: scores,
            jobMatch: match?.overallMatchScore,
            onQuality: () => _showQuality(context, l10n, scores),
            onAts: () => _showAts(context, l10n, scores, ats?.summary),
            onJob: () => context.go(AppRoutes.jobs),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.productScoreDisclaimer, style: theme.textTheme.bodySmall),
          if (top != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CareerlyColorSection(
              tone: CareerlySurfaceTone.coral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CareerlySectionLabel(l10n.labelTopPriority),
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
                      l10n.improveThis,
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
          CareerlySectionLabel(l10n.productBiggestOpportunities),
          const SizedBox(height: AppSpacing.md),
          for (final finding in analysis.topImprovements) ...[
            Text(finding.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(finding.evidence, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          CareerlySectionLabel(l10n.analyzeBreakdown),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < analysis.categories.length; i++) ...[
            Builder(
              builder: (context) {
                final category = analysis.categories[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    CareerlyProgressRow(
                      value: category.score / 100,
                      animate: true,
                      revealKey: '${analysis.id}:${category.id.name}',
                      delay: Duration(milliseconds: 40 * i),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(category.summary, style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
            ),
          ],
          CareerlyColorSection(
            tone: CareerlySurfaceTone.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CareerlySectionLabel(l10n.labelWhatsWorking),
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
            onPressed: () => context.push(AppRoutes.optimize),
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

class _ScoreTrio extends StatelessWidget {
  const _ScoreTrio({
    required this.scores,
    required this.jobMatch,
    required this.onQuality,
    required this.onAts,
    required this.onJob,
  });

  final ProductScores scores;
  final int? jobMatch;
  final VoidCallback onQuality;
  final VoidCallback onAts;
  final VoidCallback onJob;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        CareerlyColorSection(
          tone: CareerlySurfaceTone.mint,
          onTap: onQuality,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.mint,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.productCvQuality,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: AppColors.mint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 180, child: ResumeLayoutThumbnail()),
              const SizedBox(height: 24),
              Text(
                '${scores.cvQuality}/100',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _band(l10n, scores.cvQuality),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ScoreCard(
          label: l10n.productAtsReadability,
          value: scores.atsReadability?.toString() ?? '—',
          detail: scores.atsReadability == null
              ? null
              : _band(l10n, scores.atsReadability!),
          onTap: onAts,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ScoreCard(
          label: l10n.productJobMatch,
          value: jobMatch?.toString() ?? '—',
          detail: jobMatch == null
              ? l10n.productJobMatchLocked
              : _band(l10n, jobMatch!),
          onTap: onJob,
        ),
      ],
    );
  }

  String _band(AppLocalizations l10n, int score) {
    return switch (scoreBand(score)) {
      ScoreBand.excellent => l10n.productBandExcellent,
      ScoreBand.strong => l10n.productBandStrong,
      ScoreBand.developing => l10n.productBandDeveloping,
      ScoreBand.needsWork => l10n.productBandNeedsWork,
    };
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.value,
    required this.onTap,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CareerlyColorSection(
      tone: CareerlySurfaceTone.neutral,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(detail!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineMedium),
        ],
      ),
    );
  }
}
