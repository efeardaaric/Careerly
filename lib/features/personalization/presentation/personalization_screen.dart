import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_states.dart';
import '../domain/personalization_models.dart';

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  final _pageController = PageController();
  int _step = 0;
  CareerStage? _stage;
  CareerGoal? _goal;
  final Set<String> _fields = {};
  CvLanguagePreference? _cvLanguage;
  bool _saving = false;
  bool _ready = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _go(int step) async {
    setState(() => _step = step);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref
        .read(sessionProvider.notifier)
        .savePersonalization(
          stage: _stage,
          goal: _goal,
          fields: _fields.toList(),
          cvLanguage: _cvLanguage,
          markCompleted: false,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _ready = true;
    });
  }

  Future<void> _goHome() async {
    await ref.read(sessionProvider.notifier).completePersonalization();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  String _fieldLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'software' => l10n.fieldSoftware,
      'data' => l10n.fieldData,
      'finance' => l10n.fieldFinance,
      'marketing' => l10n.fieldMarketing,
      'product' => l10n.fieldProduct,
      'design' => l10n.fieldDesign,
      'engineering' => l10n.fieldEngineering,
      'healthcare' => l10n.fieldHealthcare,
      'education' => l10n.fieldEducation,
      _ => l10n.fieldOther,
    };
  }

  String _stageLabel(AppLocalizations l10n, CareerStage stage) {
    return switch (stage) {
      CareerStage.student => l10n.careerStageStudent,
      CareerStage.intern => l10n.careerStageIntern,
      CareerStage.newGraduate => l10n.careerStageNewGraduate,
      CareerStage.professional => l10n.careerStageProfessional,
      CareerStage.careerChanger => l10n.careerStageCareerChanger,
    };
  }

  String _goalLabel(AppLocalizations l10n, CareerGoal goal) {
    return switch (goal) {
      CareerGoal.internship => l10n.goalInternship,
      CareerGoal.partTime => l10n.goalPartTime,
      CareerGoal.fullTime => l10n.goalFullTime,
      CareerGoal.graduateProgram => l10n.goalGraduateProgram,
      CareerGoal.notSure => l10n.goalNotSure,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_ready) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: AppSizes.iconWellLg,
                  height: AppSizes.iconWellLg,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sheet),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.personalizationReadyTitle,
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.personalizationReadyBody,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                AppButton(
                  label: l10n.personalizationGoHome,
                  onPressed: _goHome,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canContinue = switch (_step) {
      0 => _stage != null,
      1 => _goal != null,
      2 => _cvLanguage != null,
      _ => false,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      tooltip: l10n.back,
                      onPressed: () => _go(_step - 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: AppSizes.minTouch),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.personalizationProgress(_step + 1, 3),
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          child: LinearProgressIndicator(
                            value: (_step + 1) / 3,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () {
                            if (_step < 2) {
                              _go(_step + 1);
                            } else {
                              _finish();
                            }
                          },
                    child: Text(l10n.skip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepScaffold(
                    title: l10n.personalizationStep1Title,
                    subtitle: l10n.personalizationStep1Subtitle,
                    child: Column(
                      children: [
                        for (final stage in CareerStage.values) ...[
                          ChoiceChipCard(
                            label: _stageLabel(l10n, stage),
                            selected: _stage == stage,
                            onTap: () => setState(() => _stage = stage),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                  _StepScaffold(
                    title: l10n.personalizationStep2Title,
                    subtitle: l10n.personalizationStep2Subtitle,
                    child: Column(
                      children: [
                        for (final goal in CareerGoal.values) ...[
                          ChoiceChipCard(
                            label: _goalLabel(l10n, goal),
                            selected: _goal == goal,
                            onTap: () => setState(() => _goal = goal),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                  _StepScaffold(
                    title: l10n.personalizationStep3Title,
                    subtitle: l10n.personalizationStep3Subtitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final field in InterestFields.all) ...[
                          ChoiceChipCard(
                            label: _fieldLabel(l10n, field),
                            selected: _fields.contains(field),
                            multi: true,
                            onTap: () {
                              setState(() {
                                if (_fields.contains(field)) {
                                  _fields.remove(field);
                                } else {
                                  _fields.add(field);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.cvLanguagePreference,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final pref in CvLanguagePreference.values) ...[
                          ChoiceChipCard(
                            label: switch (pref) {
                              CvLanguagePreference.turkish => l10n.cvLanguageTr,
                              CvLanguagePreference.english => l10n.cvLanguageEn,
                              CvLanguagePreference.both => l10n.cvLanguageBoth,
                            },
                            selected: _cvLanguage == pref,
                            onTap: () => setState(() => _cvLanguage = pref),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: _step == 2 ? l10n.done : l10n.continueLabel,
                isLoading: _saving,
                onPressed: !canContinue && _step < 2
                    ? null
                    : () {
                        if (_step < 2) {
                          _go(_step + 1);
                        } else {
                          _finish();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(title, style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        child,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
