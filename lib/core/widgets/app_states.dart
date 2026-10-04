import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';

import '../../app/theme/app_theme.dart';
import 'careerly_identity.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareerlySectionLabel('LOADING'),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(
              width: 120,
              child: CareerlyProgressRow(value: null, height: 3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? l10n.loadingGeneric,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CareerlyEmptyState(
      number: '00',
      label: 'EMPTY',
      headline: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.title, this.body, this.onRetry});

  final String? title;
  final String? body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CareerlyEmptyState(
      number: '!',
      label: 'ERROR',
      headline: title ?? l10n.errorGenericTitle,
      body: body ?? l10n.errorGenericBody,
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry,
    );
  }
}

/// Shared semantic badge for detected, pending and error states.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.cobalt,
    this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

/// Compact editorial score — thin bar, not a circle.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, this.score, this.label, this.size = 56});

  final int? score;
  final String? label;
  final double size;

  Color get _color {
    if (score == null) return AppColors.secondaryText;
    if (score! >= 80) return AppColors.mint;
    if (score! >= 65) return AppColors.cobalt;
    if (score! >= 40) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CareerlyMetric(
      score: score,
      compact: size < 56,
      color: _color,
      semanticLabel: label ?? l10n.semanticScoreBadge,
    );
  }
}

/// Calm keyword / tag pill using design tokens (replaces Material Chip).
class AppTagChip extends StatelessWidget {
  const AppTagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.iceBlue,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.inkNavy, letterSpacing: 0.4),
      ),
    );
  }
}

/// Non-card bordered list row for static or lightly interactive content.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    this.showDivider = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final body = onTap == null
        ? content
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            child: content,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: CareerlySectionLabel(title)),
        ?trailing,
      ],
    );
  }
}

class ChoiceChipCard extends StatelessWidget {
  const ChoiceChipCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.multi = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.cream : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        side: BorderSide(
          color: selected ? AppColors.brandYellow : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
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
                CareerlyStatusMarker(
                  color: selected ? AppColors.cobalt : AppColors.border,
                  shape: multi
                      ? CareerlyMarkerShape.square
                      : CareerlyMarkerShape.circle,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.inkNavy,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
