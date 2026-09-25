import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

enum AppButtonSize { regular, compact }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.expanded = true,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expanded;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isCompact = size == AppButtonSize.compact;
    final minHeight = isCompact ? 36.0 : AppSizes.minTouch;
    final horizontal = isCompact ? AppSpacing.md : AppSpacing.lg;
    final vertical = isCompact ? AppSpacing.xs : AppSpacing.sm;
    final iconSize = isCompact ? 16.0 : 18.0;

    final child = isLoading
        ? SizedBox(
            width: iconSize + 2,
            height: iconSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary
                  ? Colors.white
                  : AppColors.actionBlue,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(AppSizes.minTouch, minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(AppSizes.minTouch, minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
        ),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          minimumSize: Size(AppSizes.minTouch, minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
        ),
        child: child,
      ),
      AppButtonVariant.destructive => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          minimumSize: Size(AppSizes.minTouch, minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          foregroundColor: AppColors.critical,
        ),
        child: child,
      ),
    };

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
