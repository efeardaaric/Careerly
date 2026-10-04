import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../motion/careerly_motion.dart';
import 'app_button.dart';

/// Uppercase editorial metadata label.
class CareerlySectionLabel extends StatelessWidget {
  const CareerlySectionLabel(
    this.text, {
    super.key,
    this.color,
    this.light = false,
  });

  final String text;
  final Color? color;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color:
            color ??
            (light
                ? Colors.white.withValues(alpha: 0.72)
                : AppColors.secondaryText),
      ),
    );
  }
}

/// Small geometric status marker (square / diamond / circle).
enum CareerlyMarkerShape { square, diamond, circle }

class CareerlyStatusMarker extends StatelessWidget {
  const CareerlyStatusMarker({
    super.key,
    this.color = AppColors.cobalt,
    this.size = 8,
    this.shape = CareerlyMarkerShape.square,
  });

  final Color color;
  final double size;
  final CareerlyMarkerShape shape;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: shape == CareerlyMarkerShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == CareerlyMarkerShape.square
            ? BorderRadius.circular(1.5)
            : null,
      ),
    );
    if (shape == CareerlyMarkerShape.diamond) {
      return Transform.rotate(angle: 0.785398, child: child);
    }
    return child;
  }
}

/// Editorial page header — label + large left-aligned headline.
class CareerlyEditorialHeader extends StatelessWidget {
  const CareerlyEditorialHeader({
    super.key,
    required this.label,
    required this.headline,
    this.supporting,
    this.trailing,
    this.showBrand = true,
    this.background,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.page,
      AppSpacing.lg,
      AppSpacing.page,
      AppSpacing.lg,
    ),
    this.light = false,
  });

  final String label;
  final String headline;
  final String? supporting;
  final Widget? trailing;
  final bool showBrand;
  final Color? background;
  final EdgeInsets padding;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = light ? Colors.white : AppColors.primaryText;
    final muted = light
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.secondaryText;
    final horizontal = AppSpacing.pageInsets(context).left;
    final resolvedPadding = EdgeInsets.fromLTRB(
      horizontal,
      padding.top,
      horizontal,
      padding.bottom,
    );

    return ColoredBox(
      color: light ? AppColors.inkNavy : AppColors.background,
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBrand)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryText,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Careerly',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: fg,
                          ),
                        ),
                        Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (showBrand) const SizedBox(height: AppSpacing.lg),
            Text(
              headline.replaceAll('\n', ' '),
              style: theme.textTheme.displayMedium?.copyWith(color: fg),
            ),
            if (supporting != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                supporting!,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Colored editorial surface (cream / mint / coral / lavender / ice / navy).
enum CareerlySurfaceTone {
  neutral,
  cream,
  mint,
  coral,
  lavender,
  ice,
  navy,
  cobalt,
}

class CareerlyColorSection extends StatelessWidget {
  const CareerlyColorSection({
    super.key,
    required this.child,
    this.tone = CareerlySurfaceTone.cream,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  final Widget child;
  final CareerlySurfaceTone tone;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;

  Color get _bg => switch (tone) {
    CareerlySurfaceTone.neutral => AppColors.surface,
    CareerlySurfaceTone.cream => AppColors.cream,
    CareerlySurfaceTone.mint => AppColors.iceBlue,
    CareerlySurfaceTone.coral => AppColors.softCoral,
    CareerlySurfaceTone.lavender => AppColors.lavender,
    CareerlySurfaceTone.ice => AppColors.iceBlue,
    CareerlySurfaceTone.navy => AppColors.inkNavy,
    CareerlySurfaceTone.cobalt => AppColors.cobalt,
  };

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppRadii.block),
        border: tone == CareerlySurfaceTone.neutral
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.block),
        child: box,
      ),
    );
  }
}

/// Oversized editorial score — NOT a donut.
class CareerlyScoreHero extends StatelessWidget {
  const CareerlyScoreHero({
    super.key,
    required this.score,
    this.max = 100,
    this.label = 'CV SCORE',
    this.status,
    this.caption,
    this.dark = true,
    this.animate = true,
    this.semanticLabel,
    this.revealId,
  });

  final int? score;
  final int max;
  final String label;
  final String? status;
  final String? caption;
  final bool dark;
  final bool animate;
  final String? semanticLabel;

  /// When set, the count-up plays once for this id, not on later rebuilds.
  final String? revealId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = dark ? Colors.white : AppColors.primaryText;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.secondaryText;
    final accent = dark ? AppColors.coral : AppColors.cobalt;

    Widget number = Text(
      score?.toString() ?? '—',
      style: theme.textTheme.displayLarge?.copyWith(
        fontSize: 64,
        height: 0.95,
        letterSpacing: -2,
        color: fg,
      ),
    );

    if (animate && score != null) {
      number = _OnceCount(
        value: score!.toDouble(),
        revealId: revealId,
        style: theme.textTheme.displayLarge?.copyWith(
          fontSize: 64,
          height: 0.95,
          letterSpacing: -2,
          color: fg,
        ),
      );
    }

    return Semantics(
      label:
          semanticLabel ??
          (score == null ? 'Score unavailable' : 'Score $score of $max'),
      child: CareerlyColorSection(
        tone: dark ? CareerlySurfaceTone.navy : CareerlySurfaceTone.ice,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareerlySectionLabel(label, light: dark),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                number,
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 10),
                  child: Text(
                    '/$max',
                    style: theme.textTheme.titleLarge?.copyWith(color: muted),
                  ),
                ),
                const Spacer(),
                if (MediaQuery.sizeOf(context).width >= 390) ...[
                  CareerlyScoreArc(
                    value: score == null ? 0 : score! / max,
                    size: 56,
                    color: dark ? AppColors.mint : AppColors.cobalt,
                    trackColor: dark
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.border,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                    child: Text(
                      status!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: dark ? Colors.white : AppColors.inkNavy,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CareerlyProgressRow(
              value: score == null ? 0 : score! / max,
              color: dark ? AppColors.mint : AppColors.cobalt,
              trackColor: dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.border,
            ),
            if (caption != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                caption!,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact editorial metric for lists / home.
class _OnceCount extends StatefulWidget {
  const _OnceCount({required this.value, required this.style, this.revealId});

  final double value;
  final TextStyle? style;
  final String? revealId;

  @override
  State<_OnceCount> createState() => _OnceCountState();
}

class _OnceCountState extends State<_OnceCount> {
  late final bool _play;

  @override
  void initState() {
    super.initState();
    _play = !CareerlyReveal.already(widget.revealId);
    CareerlyReveal.mark(widget.revealId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_play || careerlyReduceMotion(context)) {
      return Text(widget.value.round().toString(), style: widget.style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.value),
      duration: AppMotion.score,
      curve: AppMotion.enter,
      builder: (context, value, _) {
        return Text(value.round().toString(), style: widget.style);
      },
    );
  }
}

class _OnceBar extends StatefulWidget {
  const _OnceBar({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.height,
    this.revealKey,
    this.delay = Duration.zero,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;
  final String? revealKey;
  final Duration delay;

  @override
  State<_OnceBar> createState() => _OnceBarState();
}

class _OnceBarState extends State<_OnceBar> {
  late final bool _play;

  @override
  void initState() {
    super.initState();
    _play = !CareerlyReveal.already(widget.revealKey);
    CareerlyReveal.mark(widget.revealKey);
  }

  @override
  Widget build(BuildContext context) {
    if (!_play || careerlyReduceMotion(context)) {
      return _track(widget.value);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.value),
      duration: AppMotion.slow + widget.delay,
      curve: AppMotion.enter,
      builder: (context, value, _) => _track(value),
    );
  }

  Widget _track(double amount) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height),
      child: LinearProgressIndicator(
        value: amount,
        minHeight: widget.height,
        backgroundColor: widget.trackColor,
        color: widget.color,
      ),
    );
  }
}

class CareerlyMetric extends StatelessWidget {
  const CareerlyMetric({
    super.key,
    required this.score,
    this.max = 100,
    this.compact = false,
    this.color,
    this.semanticLabel,
  });

  final int? score;
  final int max;
  final bool compact;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppColors.cobalt;
    final size = compact ? 28.0 : 40.0;
    return Semantics(
      label:
          semanticLabel ??
          (score == null ? 'Score unavailable' : 'Score $score of $max'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score?.toString() ?? '—',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: size,
                  height: 1,
                  color: c,
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 2),
                child: Text(
                  '/$max',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryText,
                    letterSpacing: 0,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: compact ? 56 : 72,
            child: CareerlyProgressRow(
              value: score == null ? 0 : (score!.clamp(0, max) / max),
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class CareerlyProgressRow extends StatelessWidget {
  const CareerlyProgressRow({
    super.key,
    this.value,
    this.color = AppColors.cobalt,
    this.trackColor,
    this.height = 3,
    this.animate = false,
    this.revealKey,
    this.delay = Duration.zero,
  });

  /// Null = indeterminate (loading).
  final double? value;
  final Color color;
  final Color? trackColor;
  final double height;
  final bool animate;
  final String? revealKey;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final target = value?.clamp(0.0, 1.0);
    if (!animate || target == null) return _bar(target);
    return _OnceBar(
      value: target,
      revealKey: revealKey,
      delay: delay,
      color: color,
      trackColor: trackColor ?? AppColors.border,
      height: height,
    );
  }

  Widget _bar(double? amount) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: amount,
        minHeight: height,
        backgroundColor: trackColor ?? AppColors.border,
        color: color,
      ),
    );
  }
}

/// Signature "Next Move" editorial block.
class CareerlyNextMove extends StatelessWidget {
  const CareerlyNextMove({
    super.key,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
    this.label = 'NEXT MOVE',
  });

  final String label;
  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CareerlyColorSection(
      tone: CareerlySurfaceTone.coral,
      onTap: onCta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CareerlyStatusMarker(
                color: AppColors.coral,
                shape: CareerlyMarkerShape.diamond,
              ),
              const SizedBox(width: AppSpacing.xs),
              CareerlySectionLabel(label, color: AppColors.coral),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: theme.textTheme.bodyMedium),
          if (ctaLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '$ctaLabel →',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.inkNavy,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CareerlyTimelineStep {
  const CareerlyTimelineStep({
    required this.title,
    this.subtitle,
    this.state = CareerlyTimelineState.upcoming,
  });

  final String title;
  final String? subtitle;
  final CareerlyTimelineState state;
}

enum CareerlyTimelineState { completed, current, upcoming }

/// Editorial numbered processing timeline.
class CareerlyTimeline extends StatelessWidget {
  const CareerlyTimeline({super.key, required this.steps});

  final List<CareerlyTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      _TimelineDot(index: i + 1, state: steps[i].state),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color:
                                steps[i].state ==
                                    CareerlyTimelineState.completed
                                ? AppColors.mint
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < steps.length - 1 ? AppSpacing.lg : 0,
                      top: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                steps[i].state == CareerlyTimelineState.upcoming
                                ? AppColors.secondaryText
                                : AppColors.primaryText,
                          ),
                        ),
                        if (steps[i].subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            steps[i].subtitle!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.index, required this.state});

  final int index;
  final CareerlyTimelineState state;

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      CareerlyTimelineState.completed => AppColors.mint,
      CareerlyTimelineState.current => AppColors.cobalt,
      CareerlyTimelineState.upcoming => AppColors.border,
    };
    final fg = state == CareerlyTimelineState.upcoming
        ? AppColors.secondaryText
        : Colors.white;
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        index.toString().padLeft(2, '0'),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: fg, letterSpacing: 0, fontSize: 10),
      ),
    );
  }
}

/// Miniature CV document silhouette.
class CareerlyDocumentPreview extends StatelessWidget {
  const CareerlyDocumentPreview({
    super.key,
    this.width = 72,
    this.height = 96,
    this.accent = AppColors.cobalt,
  });

  final double width;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inkNavy.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, width: width * 0.45, color: accent),
          const SizedBox(height: 8),
          // Keep the preview legible at the compact heights used by page
          // headers. Five rows plus fixed gaps used to overflow by a few px.
          for (var i = 0; i < 4; i++) ...[
            Container(
              height: 3,
              width: width * (i.isEven ? 0.7 : 0.55),
              color: AppColors.inkNavy.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 4),
          ],
          const Spacer(),
          Container(height: 3, width: width * 0.35, color: accent),
        ],
      ),
    );
  }
}

/// AI action chip — sparkle only here.
class CareerlyAiAction extends StatelessWidget {
  const CareerlyAiAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lavender,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✦',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.inkNavy),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.inkNavy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin directional rule with optional end marker.
class CareerlyHairline extends StatelessWidget {
  const CareerlyHairline({super.key, this.color = AppColors.border});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color);
  }
}

/// Primary CTA — brand cobalt, no Material default look.
class CareerlyPrimaryButton extends StatelessWidget {
  const CareerlyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      expanded: expanded,
      isLoading: isLoading,
    );
  }
}

/// Editorial empty state — left-aligned, oversized number.
class CareerlyEmptyState extends StatelessWidget {
  const CareerlyEmptyState({
    super.key,
    this.number = '00',
    required this.label,
    required this.headline,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final String number;
  final String label;
  final String headline;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              number == '!'
                  ? Icons.error_outline_rounded
                  : Icons.description_outlined,
              color: AppColors.primaryText,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CareerlySectionLabel(label),
          const SizedBox(height: AppSpacing.sm),
          Text(headline, style: theme.textTheme.headlineMedium),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(body!, style: theme.textTheme.bodyMedium),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              expanded: false,
            ),
          ],
        ],
      ),
    );
  }
}
