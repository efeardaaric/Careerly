import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/careerly_identity.dart';

enum ScoreStatus { strong, solid, needsWork, critical, unknown }

/// Editorial score metric — oversized type + thin progress (no donut).
class CvScoreIndicator extends StatelessWidget {
  const CvScoreIndicator({
    super.key,
    this.score,
    this.label,
    this.status,
    this.size = 88,
    this.animate = true,
    this.semanticLabel,
  });

  final int? score;
  final String? label;
  final ScoreStatus? status;
  final double size;
  final bool animate;
  final String? semanticLabel;

  ScoreStatus get _resolvedStatus {
    if (status != null) return status!;
    if (score == null) return ScoreStatus.unknown;
    if (score! >= 80) return ScoreStatus.strong;
    if (score! >= 65) return ScoreStatus.solid;
    if (score! >= 40) return ScoreStatus.needsWork;
    return ScoreStatus.critical;
  }

  Color get _color {
    return switch (_resolvedStatus) {
      ScoreStatus.strong => AppColors.mint,
      ScoreStatus.solid => AppColors.cobalt,
      ScoreStatus.needsWork => AppColors.warning,
      ScoreStatus.critical => AppColors.critical,
      ScoreStatus.unknown => AppColors.secondaryText,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Large hero sizes use ScoreHero-style type; compact uses CareerlyMetric.
    if (size >= 100) {
      return CareerlyScoreHero(
        score: score,
        label: label ?? 'SCORE',
        status: switch (_resolvedStatus) {
          ScoreStatus.strong => 'STRONG',
          ScoreStatus.solid => 'GOOD',
          ScoreStatus.needsWork => 'NEEDS WORK',
          ScoreStatus.critical => 'CRITICAL',
          ScoreStatus.unknown => null,
        },
        dark: true,
        animate: animate,
        semanticLabel: semanticLabel,
      );
    }

    return CareerlyMetric(
      score: score,
      compact: size < 56,
      color: _color,
      semanticLabel: semanticLabel,
    );
  }
}
