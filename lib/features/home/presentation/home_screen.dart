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
import '../../../core/widgets/resume_template_gallery.dart';
import '../../analyze/application/analysis_controller.dart';
import '../../analyze/domain/product_scores.dart';
import '../../cv_builder/application/builder_controller.dart';
import '../../cv_builder/domain/resume_document.dart';
import '../../applications/application/applications_controller.dart';
import '../../applications/domain/job_application.dart';
import '../../jobs/application/job_match_controller.dart';
import '../../optimization/data/cv_version_store.dart';
import '../../optimization/domain/cv_version.dart';
import '../../optimization/domain/suggestion_rules.dart';
import 'home_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _chooseTemplate(
    BuildContext context,
    WidgetRef ref,
    CvTemplateId template,
  ) async {
    final l10n = AppLocalizations.of(context);
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.builderCreateNew,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: ResumeLayoutThumbnail(template: template),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: l10n.builderStartEditing,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted != true || !context.mounted) return;
    await ref
        .read(builderControllerProvider.notifier)
        .createBlank(
          language: ref.read(sessionProvider).localeCode == 'tr'
              ? CvDocumentLanguage.tr
              : CvDocumentLanguage.en,
          templateId: template,
        );
    if (context.mounted) context.go(AppRoutes.builder);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final session = ref.watch(sessionProvider);
    final analysisState = ref.watch(analysisControllerProvider);
    final analysis = analysisState.analysis;
    final evidence = analysisState.evidence;
    final jobs = ref.watch(jobMatchControllerProvider);
    final applications = ref.watch(applicationsControllerProvider);
    final name = session.greetingName;

    final scores = analysis == null
        ? null
        : ProductScores.fromAnalysis(analysis);
    final match = analysis == null
        ? null
        : jobs.savedMatches
              .where((m) => m.resumeId == analysis.resumeId)
              .firstOrNull;
    final pendingFixes = evidence == null
        ? 0
        : SuggestionRules.build(evidence.sections).length;
    final optimized =
        analysis != null &&
        ref
            .read(cvVersionStoreProvider)
            .read()
            .any(
              (v) =>
                  v.resumeId == analysis.resumeId &&
                  v.type == CvVersionType.optimized,
            );

    final day = DateFormat.EEEE(locale).format(DateTime.now());

    return CareerlyScaffold(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: AppColors.primaryText,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileHeaderLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        name ?? l10n.appName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.navProfile,
                  onPressed: () => context.go(AppRoutes.profile),
                  icon: const Icon(Icons.settings_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          CareerlyEditorialHeader(
            showBrand: false,
            label: l10n.homeOverviewLabel(day),
            headline: name == null
                ? l10n.homeReadyPlain
                : l10n.homeReadyNamed(name),
            background: AppColors.cream,
            trailing: const CareerlyDocumentPreview(
              width: 56,
              height: 76,
              accent: AppColors.coral,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.pageInsets(context).left,
              top: AppSpacing.lg,
              right: AppSpacing.pageInsets(context).right,
              bottom: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.builderTemplate,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.builder),
                      child: Text(l10n.navBuilder),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ResumeTemplateGallery(
                  onSelected: (template) =>
                      _chooseTemplate(context, ref, template),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _HomeToolTile(
                        icon: Icons.note_add_outlined,
                        color: AppColors.purple,
                        label: l10n.builderCreateNew,
                        onTap: () => context.go(AppRoutes.builder),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HomeToolTile(
                        icon: Icons.upload_file_outlined,
                        color: AppColors.cyan,
                        label: l10n.homeActionAnalyze,
                        onTap: () => context.go(AppRoutes.analyze),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HomeToolTile(
                        icon: Icons.work_outline_rounded,
                        color: AppColors.olive,
                        label: l10n.homeActionMatch,
                        onTap: () => context.go(AppRoutes.jobs),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (analysis == null || scores == null)
                  _EmptyCvCard(onStart: () => context.go(AppRoutes.analyze))
                else ...[
                  _CvHero(
                    title: evidence?.displayName ?? analysis.fileName,
                    subtitle: l10n.homeCvCardScoredBody(
                      MaterialLocalizations.of(context)
                          .formatShortDate(analysis.analyzedAt.toLocal()),
                    ),
                    quality: scores.cvQuality,
                    ats: scores.atsReadability,
                    jobMatch: match?.overallMatchScore,
                    onTap: () => context.push(AppRoutes.analyzeResults),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: pendingFixes > 0
                        ? l10n.homeImproveCta(pendingFixes)
                        : l10n.homeImproveCtaNone,
                    icon: Icons.auto_fix_high_rounded,
                    onPressed: () => context.push(AppRoutes.optimize),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: l10n.homeViewAnalysis,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(AppRoutes.analyzeResults),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.homeStepsTitle),
                const SizedBox(height: AppSpacing.md),
                _StepList(
                  steps: [
                    _Step(
                      title: l10n.homeStepAnalyze,
                      subtitle: scores == null
                          ? l10n.homeStepAnalyzeHint
                          : l10n.homeStepAnalyzeDone(scores.cvQuality),
                      done: analysis != null,
                      onTap: () => analysis == null
                          ? context.go(AppRoutes.analyze)
                          : context.push(AppRoutes.analyzeResults),
                    ),
                    _Step(
                      title: l10n.homeStepImprove,
                      subtitle: analysis == null
                          ? l10n.homeStepImproveHint
                          : pendingFixes > 0
                          ? l10n.homeStepImprovePending(pendingFixes)
                          : optimized
                          ? l10n.homeStepImproveDone
                          : l10n.homeStepImproveNone,
                      done:
                          analysis != null && (optimized || pendingFixes == 0),
                      onTap: () => analysis == null
                          ? context.go(AppRoutes.analyze)
                          : context.push(AppRoutes.optimize),
                    ),
                    _Step(
                      title: l10n.homeStepMatch,
                      subtitle: match == null
                          ? l10n.homeStepMatchHint
                          : l10n.homeStepMatchDone(
                              match.overallMatchScore,
                              match.jobTitle,
                            ),
                      done: match != null,
                      onTap: () => context.go(AppRoutes.jobs),
                    ),
                    _Step(
                      title: l10n.homeStepTrack,
                      subtitle: applications.isEmpty
                          ? l10n.homeStepTrackHint
                          : l10n.homeStepTrackDone(applications.length),
                      done: applications.isNotEmpty,
                      onTap: () => context.push(AppRoutes.applications),
                    ),
                  ],
                ),
                if (applications.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  CareerlySectionLabel(l10n.appsTitle),
                  const SizedBox(height: AppSpacing.md),
                  _ApplicationsStrip(applications: applications),
                ],
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.homeRecentMatches),
                const SizedBox(height: AppSpacing.md),
                if (jobs.mostRecentSaved == null)
                  CareerlyColorSection(
                    tone: CareerlySurfaceTone.ice,
                    onTap: () => context.go(AppRoutes.jobs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeNoMatchesHeadline,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.homeRecentMatchesEmpty,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${l10n.homeActionMatch} →',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.cobalt),
                        ),
                      ],
                    ),
                  )
                else
                  _RecentMatchCard(
                    score: jobs.mostRecentSaved!.overallMatchScore,
                    title: jobs.mostRecentSaved!.jobTitle,
                    company: jobs.mostRecentSaved!.company,
                    semanticLabel: l10n.jobsRecentMatchScore(
                      jobs.mostRecentSaved!.overallMatchScore,
                    ),
                    onTap: () => context.go(AppRoutes.jobs),
                  ),
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.homeToolsTitle),
                const SizedBox(height: AppSpacing.xs),
                _TextAction(
                  label: l10n.homeActionAnalyze,
                  onTap: () => context.go(AppRoutes.analyze),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeToolTile extends StatelessWidget {
  const _HomeToolTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 82,
            width: double.infinity,
            child: Icon(icon, color: color, size: 32),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _EmptyCvCard extends StatelessWidget {
  const _EmptyCvCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CareerlyColorSection(
      tone: CareerlySurfaceTone.mint,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CareerlySectionLabel(l10n.homeCvCardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.homeCvCardEmptyTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeCvCardEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.homeAnalyzeMyCv,
            icon: Icons.upload_file_rounded,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _CvHero extends StatelessWidget {
  const _CvHero({
    required this.title,
    required this.subtitle,
    required this.quality,
    required this.ats,
    required this.jobMatch,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int quality;
  final int? ats;
  final int? jobMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CareerlyColorSection(
      tone: CareerlySurfaceTone.navy,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CareerlySectionLabel(l10n.homeCvCardTitle, light: true),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ScoreTile(label: l10n.productCvQuality, score: quality),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScoreTile(
                  label: l10n.productAtsReadability,
                  score: ats,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScoreTile(
                  label: l10n.productJobMatch,
                  score: jobMatch,
                  lockedText: l10n.homeJobMatchAdd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.label, required this.score, this.lockedText});

  final String label;
  final int? score;
  final String? lockedText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final value = score;
    final band = value == null ? null : scoreBand(value);
    final color = switch (band) {
      ScoreBand.excellent || ScoreBand.strong => AppColors.mint,
      ScoreBand.developing => AppColors.warning,
      ScoreBand.needsWork => AppColors.coral,
      null => Colors.white.withValues(alpha: 0.4),
    };
    final bandText = switch (band) {
      ScoreBand.excellent => l10n.productBandExcellent,
      ScoreBand.strong => l10n.productBandStrong,
      ScoreBand.developing => l10n.productBandDeveloping,
      ScoreBand.needsWork => l10n.productBandNeedsWork,
      null => lockedText ?? '—',
    };
    return Semantics(
      label: value == null ? '$label: $bandText' : '$label: $value / 100',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
            child: Text(
              label,
              maxLines: 2,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 0.2,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value?.toString() ?? '—',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 34,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          CareerlyProgressRow(
            value: value == null ? 0 : value / 100,
            color: color,
            trackColor: Colors.white.withValues(alpha: 0.14),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            bandText,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 0.2,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps});

  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = steps.indexWhere((s) => !s.done);
    return CareerlyColorSection(
      tone: CareerlySurfaceTone.neutral,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            InkWell(
              onTap: steps[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _StepDot(
                      index: i + 1,
                      done: steps[i].done,
                      current: i == current,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: steps[i].done
                                  ? AppColors.secondaryText
                                  : AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            steps[i].subtitle,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: i == current
                          ? AppColors.cobalt
                          : AppColors.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 60),
                child: CareerlyHairline(),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.done,
    required this.current,
  });

  final int index;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? AppColors.mint
        : current
        ? AppColors.cobalt
        : AppColors.border;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 18, color: AppColors.inkNavy)
          : Text(
              index.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: current ? Colors.white : AppColors.secondaryText,
                letterSpacing: 0,
                fontSize: 10,
              ),
            ),
    );
  }
}

class _ApplicationsStrip extends StatelessWidget {
  const _ApplicationsStrip({required this.applications});

  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    int count(Set<ApplicationStatus> statuses) =>
        applications.where((a) => statuses.contains(a.status)).length;
    final active = count({
      ApplicationStatus.saved,
      ApplicationStatus.preparing,
      ApplicationStatus.applied,
    });
    final interview = count({ApplicationStatus.interview});
    final offer = count({ApplicationStatus.offer});

    Widget cell(String label, int value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.cobalt,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );

    return CareerlyColorSection(
      tone: CareerlySurfaceTone.ice,
      onTap: () => context.push(AppRoutes.applications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              cell(l10n.homeAppsActive, active),
              cell(l10n.appsStatusInterview, interview),
              cell(l10n.appsStatusOffer, offer),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${l10n.appsOpen} →',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.cobalt,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMatchCard extends StatelessWidget {
  const _RecentMatchCard({
    required this.score,
    required this.title,
    required this.company,
    required this.semanticLabel,
    required this.onTap,
  });

  final int score;
  final String title;
  final String? company;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CareerlyColorSection(
      tone: CareerlySurfaceTone.ice,
      onTap: onTap,
      child: Row(
        children: [
          CareerlyMetric(
            score: score,
            compact: true,
            semanticLabel: semanticLabel,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(company ?? '—', style: theme.textTheme.bodySmall),
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
