import 'billing_models.dart';

/// Central Free/Pro limits — change here, never scatter in widgets.
/// Not permanent business law; values are product-configurable.
class FeatureLimit {
  const FeatureLimit({
    required this.freeLimit,
    required this.proLimit,
    this.period = 'month',
    this.metered = true,
  });

  /// null = unlimited
  final int? freeLimit;
  final int? proLimit;
  final String period;
  final bool metered;
}

abstract final class PlanLimitsConfig {
  static const Map<FeatureId, FeatureLimit> limits = {
    FeatureId.cvAnalysis: FeatureLimit(freeLimit: 2, proLimit: null),
    FeatureId.jobMatch: FeatureLimit(freeLimit: 1, proLimit: null),
    FeatureId.aiRewrite: FeatureLimit(freeLimit: 3, proLimit: null),
    FeatureId.builderCv: FeatureLimit(
      freeLimit: 1,
      proLimit: null,
      period: 'lifetime',
    ),
    FeatureId.premiumTemplate: FeatureLimit(
      freeLimit: 0,
      proLimit: null,
      period: 'none',
      metered: false,
    ),
    FeatureId.translation: FeatureLimit(
      freeLimit: 0,
      proLimit: null,
      period: 'none',
      metered: false,
    ),
    FeatureId.jobTailor: FeatureLimit(
      freeLimit: 0,
      proLimit: null,
      period: 'none',
      metered: false,
    ),
    FeatureId.readOwnCv: FeatureLimit(
      freeLimit: null,
      proLimit: null,
      period: 'none',
      metered: false,
    ),
  };

  /// Config-driven product IDs — prices come from the store, not hard-coded.
  static const monthlyProductId = 'careerly_pro_monthly';
  static const yearlyProductId = 'careerly_pro_yearly';

  static FeatureLimit forFeature(FeatureId id) =>
      limits[id] ?? const FeatureLimit(freeLimit: 0, proLimit: null);
}
