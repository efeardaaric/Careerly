import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_states.dart';
import '../../billing/domain/billing_models.dart';
import '../../billing/presentation/billing_gate.dart';
import '../application/analysis_controller.dart';
import '../domain/analysis_models.dart';

class SectionsReviewScreen extends ConsumerWidget {
  const SectionsReviewScreen({super.key});

  static const _sectionKeys = [
    'contact',
    'summary',
    'experience',
    'education',
    'projects',
    'skills',
    'certifications',
    'languages',
  ];

  String _sectionTitle(AppLocalizations l10n, String key) {
    final tr = l10n.localeName.startsWith('tr');
    return switch (key) {
      'contact' => tr ? 'İletişim' : 'Contact',
      'summary' => tr ? 'Özet' : 'Summary',
      'experience' => tr ? 'Deneyim' : 'Experience',
      'education' => tr ? 'Eğitim' : 'Education',
      'projects' => tr ? 'Projeler' : 'Projects',
      'skills' => tr ? 'Yetenekler' : 'Skills',
      'certifications' => tr ? 'Sertifikalar' : 'Certifications',
      'languages' => tr ? 'Diller' : 'Languages',
      _ => key,
    };
  }

  String _statusLabel(AppLocalizations l10n, SectionStatus status) {
    return switch (status) {
      SectionStatus.detected => l10n.sectionStatusDetected,
      SectionStatus.missing => l10n.sectionStatusMissing,
      SectionStatus.needsReview => l10n.sectionStatusNeedsReview,
      SectionStatus.lowConfidence => l10n.sectionStatusLowConfidence,
      SectionStatus.userCorrected => l10n.sectionStatusUserCorrected,
    };
  }

  Color _statusColor(SectionStatus status) {
    return switch (status) {
      SectionStatus.detected => AppColors.success,
      SectionStatus.userCorrected => AppColors.success,
      SectionStatus.missing => AppColors.secondaryText,
      SectionStatus.needsReview => AppColors.warning,
      SectionStatus.lowConfidence => AppColors.warning,
    };
  }

  String _confidenceLabel(AppLocalizations l10n, ParserConfidence c) {
    return switch (c) {
      ParserConfidence.high => l10n.parserConfidenceHigh,
      ParserConfidence.medium => l10n.parserConfidenceMedium,
      ParserConfidence.low => l10n.parserConfidenceLow,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(analysisControllerProvider);
    final parsed = state.parsed;

    if (parsed == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.analyzeReviewTitle)),
        body: Center(
          child: AppButton(
            label: l10n.back,
            onPressed: () => context.go(AppRoutes.analyze),
            expanded: false,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyzeReviewTitle),
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.go(AppRoutes.analyze),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  l10n.analyzeReviewHeadline,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.analyzeReviewBody, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.actionBlue,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.analyzeReviewConfidence(
                            _confidenceLabel(l10n, parsed.confidence),
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < parsed.sections.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      parsed.sections[i].title,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  AppStatusBadge(
                                    label: _statusLabel(
                                      l10n,
                                      parsed.sections[i].status,
                                    ),
                                    color: _statusColor(
                                      parsed.sections[i].status,
                                    ),
                                  ),
                                ],
                              ),
                              if (parsed.sections[i].preview != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  parsed.sections[i].preview!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                              if (parsed.sections[i].note != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  parsed.sections[i].note!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                              if (parsed.sections[i].status !=
                                  SectionStatus.missing) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(
                                              analysisControllerProvider
                                                  .notifier,
                                            )
                                            .updateSectionStatus(
                                              parsed.sections[i].id,
                                              SectionStatus.userCorrected,
                                            );
                                      },
                                      child: Text(l10n.sectionMarkDetected),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(
                                              analysisControllerProvider
                                                  .notifier,
                                            )
                                            .updateSectionStatus(
                                              parsed.sections[i].id,
                                              SectionStatus.missing,
                                            );
                                      },
                                      child: Text(l10n.sectionMarkMissing),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: l10n.sectionChangeType,
                                      onSelected: (key) {
                                        ref
                                            .read(
                                              analysisControllerProvider
                                                  .notifier,
                                            )
                                            .reclassifySection(
                                              parsed.sections[i].id,
                                              key,
                                              _sectionTitle(l10n, key),
                                            );
                                      },
                                      itemBuilder: (context) => [
                                        for (final key in _sectionKeys)
                                          PopupMenuItem(
                                            value: key,
                                            child: Text(
                                              _sectionTitle(l10n, key),
                                            ),
                                          ),
                                      ],
                                      child: Text(l10n.sectionChangeType),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (i < parsed.sections.length - 1)
                          const Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: l10n.analyzeContinueToScore,
                isLoading: state.isBusy,
                onPressed: () async {
                  final ok = await ref
                      .read(analysisControllerProvider.notifier)
                      .confirmReviewAndScore();
                  if (!ok || !context.mounted) return;
                  if (ref.read(analysisControllerProvider).phase !=
                      AnalysisPhase.completed) {
                    return;
                  }
                  await consumePendingUsage(ref, FeatureId.cvAnalysis);
                  if (context.mounted) {
                    context.go(AppRoutes.analyzeResults);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
