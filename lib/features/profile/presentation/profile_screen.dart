import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../billing/application/billing_controller.dart';
import '../../billing/data/mock_subscription_repository.dart';
import '../../billing/domain/billing_models.dart';
import '../../billing/presentation/paywall_screen.dart';
import '../../home/presentation/home_shell.dart';
import '../../personalization/domain/personalization_models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _stageLabel(AppLocalizations l10n, CareerStage? stage) {
    if (stage == null) return l10n.profileNotSet;
    return switch (stage) {
      CareerStage.student => l10n.careerStageStudent,
      CareerStage.intern => l10n.careerStageIntern,
      CareerStage.newGraduate => l10n.careerStageNewGraduate,
      CareerStage.professional => l10n.careerStageProfessional,
      CareerStage.careerChanger => l10n.careerStageCareerChanger,
    };
  }

  String _goalLabel(AppLocalizations l10n, CareerGoal? goal) {
    if (goal == null) return l10n.profileNotSet;
    return switch (goal) {
      CareerGoal.internship => l10n.goalInternship,
      CareerGoal.partTime => l10n.goalPartTime,
      CareerGoal.fullTime => l10n.goalFullTime,
      CareerGoal.graduateProgram => l10n.goalGraduateProgram,
      CareerGoal.notSure => l10n.goalNotSure,
    };
  }

  String _cvLangLabel(AppLocalizations l10n, CvLanguagePreference? value) {
    if (value == null) return l10n.profileNotSet;
    return switch (value) {
      CvLanguagePreference.turkish => l10n.cvLanguageTr,
      CvLanguagePreference.english => l10n.cvLanguageEn,
      CvLanguagePreference.both => l10n.cvLanguageBoth,
    };
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

  Future<void> _editFirstName(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: ref.read(sessionProvider).firstName ?? '',
    );
    final saved = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profileFirstName),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.done),
            ),
          ],
        );
      },
    );
    if (saved != null) {
      await ref.read(sessionProvider.notifier).setFirstName(saved);
    }
  }

  Future<void> _changeLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(sessionProvider).localeCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.languageEnglish),
                trailing: current == 'en'
                    ? const Icon(Icons.check, color: AppColors.actionBlue)
                    : null,
                onTap: () => Navigator.pop(context, 'en'),
              ),
              ListTile(
                title: Text(l10n.languageTurkish),
                trailing: current == 'tr'
                    ? const Icon(Icons.check, color: AppColors.actionBlue)
                    : null,
                onTap: () => Navigator.pop(context, 'tr'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await ref.read(sessionProvider.notifier).setLocale(selected);
    }
  }

  Future<void> _resetDemo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profileResetDemo),
          content: Text(l10n.profileResetDemoConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.profileResetDemoAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(sessionProvider.notifier).resetDemo();
    if (context.mounted) context.go(AppRoutes.language);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profileDeleteAccount),
          content: Text(l10n.profileDeleteAccountConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.profileDeleteAccountAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(sessionProvider.notifier).deleteLocalAccount();
    if (context.mounted) context.go(AppRoutes.language);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final fields = session.fields.map((f) => _fieldLabel(l10n, f)).join(', ');

    return CareerlyScaffold(
      backgroundColor: AppColors.cream.withValues(alpha: 0.35),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CareerlyEditorialHeader(
            label: l10n.profileHeaderLabel,
            headline:
                session.greetingName ??
                session.firstName ??
                l10n.profileMockUser,
            supporting: session.email ?? l10n.authMockBanner,
            background: AppColors.cream,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.pageInsets(context).left,
              top: AppSpacing.xl,
              right: AppSpacing.pageInsets(context).right,
              bottom: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CareerlySectionLabel(l10n.profilePreferences),
                const SizedBox(height: AppSpacing.md),
                _QuietRow(
                  label: l10n.profileFirstName,
                  value: session.firstName?.trim().isNotEmpty == true
                      ? session.firstName!
                      : l10n.profileNotSet,
                  onTap: () => _editFirstName(context, ref),
                ),
                const CareerlyHairline(),
                _QuietRow(
                  label: l10n.profileLanguage,
                  value: session.localeCode == 'tr'
                      ? l10n.languageTurkish
                      : l10n.languageEnglish,
                  onTap: () => _changeLanguage(context, ref),
                ),
                const CareerlyHairline(),
                _QuietRow(
                  label: l10n.profileCareerStage,
                  value: _stageLabel(l10n, session.careerStage),
                ),
                const CareerlyHairline(),
                _QuietRow(
                  label: l10n.profileGoal,
                  value: _goalLabel(l10n, session.goal),
                ),
                const CareerlyHairline(),
                _QuietRow(
                  label: l10n.profileFields,
                  value: fields.isEmpty ? l10n.profileNotSet : fields,
                ),
                const CareerlyHairline(),
                _QuietRow(
                  label: l10n.profileCvLanguage,
                  value: _cvLangLabel(l10n, session.cvLanguage),
                ),
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.profileSubscription),
                const SizedBox(height: AppSpacing.md),
                _PlanCard(),
                const SizedBox(height: AppSpacing.xl),
                CareerlySectionLabel(l10n.profilePrivacy),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.profilePrivacyBody,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.signOut,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    await ref.read(sessionProvider.notifier).signOutMock();
                    if (context.mounted) context.go(AppRoutes.auth);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.profileResetDemo,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => _resetDemo(context, ref),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.profileDeleteAccount,
                  variant: AppButtonVariant.destructive,
                  onPressed: () => _deleteAccount(context, ref),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.profileVersion('1.0.0'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietRow extends StatelessWidget {
  const _QuietRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.secondaryText,
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _PlanCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final billing = ref.watch(billingControllerProvider);
    final ent = billing.entitlement;
    final isPro = ent?.isProActive ?? false;
    final statusLabel = switch (ent?.status) {
      SubscriptionStatus.active => l10n.billingStatusActive,
      SubscriptionStatus.expired => l10n.billingStatusExpired,
      SubscriptionStatus.billingIssue => l10n.billingStatusBillingIssue,
      _ => l10n.billingStatusFree,
    };
    final planLabel = isPro ? l10n.billingPlanPro : l10n.billingPlanFree;
    final headline = isPro
        ? '$planLabel · $statusLabel'
        : l10n.billingStatusFree;

    return CareerlyColorSection(
      tone: CareerlySurfaceTone.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.billingPlanBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final counter in ent?.usage ?? const <UsageCounter>[])
            if (counter.featureId == FeatureId.cvAnalysis ||
                counter.featureId == FeatureId.jobMatch)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Text(
                  '${counter.featureId == FeatureId.cvAnalysis ? l10n.profileUsageAnalyses : l10n.profileUsageMatches} · ${counter.limit == null ? '${counter.used}' : l10n.profileUsageMeter(counter.used, counter.limit!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          if (!isPro)
            AppButton(
              label: l10n.billingUpgradeCta,
              onPressed: () => showPaywall(context, contextKey: 'profile'),
            )
          else
            AppButton(
              label: l10n.billingManageSubscription,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(l10n.billingManageSubscription),
                      content: Text(l10n.billingManageBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.close),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          if (!kReleaseMode) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.billingDevOverride, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final o in DevSubscriptionOverride.values)
                  OutlinedButton(
                    onPressed: () => ref
                        .read(billingControllerProvider.notifier)
                        .setDevOverride(o),
                    child: Text(o.name),
                  ),
                OutlinedButton(
                  onPressed: () => ref
                      .read(billingControllerProvider.notifier)
                      .setDevOverride(null),
                  child: Text(l10n.billingDevClear),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
