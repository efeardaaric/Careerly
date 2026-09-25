import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/billing_models.dart';

/// Soft upgrade surface — restrained, no neon/confetti/fake timers.
class SoftUpgradeBanner extends StatelessWidget {
  const SoftUpgradeBanner({
    super.key,
    required this.decision,
    required this.onUpgrade,
  });

  final AccessDecision decision;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (decision.allowed && !decision.isNearLimit) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nearLimit = decision.allowed && decision.isNearLimit;
    final title = !decision.allowed
        ? l10n.billingLimitTitle
        : l10n.billingNearLimitTitle;
    final body = !decision.allowed
        ? l10n.billingLimitBody
        : l10n.billingNearLimitBody(
            decision.remaining ?? 0,
            decision.limit ?? 0,
          );

    final accent = nearLimit ? AppColors.warning : AppColors.deepNavy;
    final fill = nearLimit
        ? AppColors.warning.withValues(alpha: 0.08)
        : AppColors.wash;

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  nearLimit
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  color: accent,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(body, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: l10n.billingUpgradeCta, onPressed: onUpgrade),
          ],
        ),
      ),
    );
  }
}
