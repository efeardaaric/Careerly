import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/motion/careerly_motion.dart';
import '../../home/presentation/home_shell.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  Future<void> _select(WidgetRef ref, BuildContext context, String code) async {
    await ref.read(sessionProvider.notifier).setLocale(code);
    if (context.mounted) context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return CareerlyScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CareerlySignalMark(),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.appName, style: theme.textTheme.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.tagline, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.languageTitle, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.languageSubtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                _LanguageOption(
                  mark: 'EN',
                  label: l10n.languageEnglish,
                  onTap: () => _select(ref, context, 'en'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LanguageOption(
                  mark: 'TR',
                  label: l10n.languageTurkish,
                  onTap: () => _select(ref, context, 'tr'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.mark,
    required this.label,
    required this.onTap,
  });

  final String mark;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CareerlyPressable(
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _LangMark(label: mark),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(label, style: theme.textTheme.titleMedium),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangMark extends StatelessWidget {
  const _LangMark({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.minTouch,
      height: AppSizes.minTouch,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.actionBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.actionBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
