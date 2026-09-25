import 'billing_models.dart';
import 'plan_limits_config.dart';

/// Pure policy — widgets ask [EntitlementPolicy.decide], never `if (isPro)`.
abstract final class EntitlementPolicy {
  static AccessDecision decide({
    required FeatureId featureId,
    required SubscriptionTier tier,
    required SubscriptionStatus status,
    required int used,
  }) {
    // Never lock the user's own CV data.
    if (featureId == FeatureId.readOwnCv) {
      return AccessDecision(
        featureId: featureId,
        allowed: true,
        requiredTier: SubscriptionTier.free,
      );
    }

    var effectiveTier = tier;
    if (status == SubscriptionStatus.expired) {
      effectiveTier = SubscriptionTier.free;
    }
    if (status == SubscriptionStatus.billingIssue &&
        tier == SubscriptionTier.pro) {
      effectiveTier = SubscriptionTier.free;
    }

    final limitDef = PlanLimitsConfig.forFeature(featureId);
    final cap = effectiveTier == SubscriptionTier.pro
        ? limitDef.proLimit
        : limitDef.freeLimit;

    if (!limitDef.metered && cap == 0) {
      return AccessDecision(
        featureId: featureId,
        allowed: false,
        reason: AccessDeniedReason.requiresPro,
        remaining: 0,
        limit: 0,
        used: used,
        requiredTier: SubscriptionTier.pro,
        upgradeContext: 'upgrade_for_${featureId.name}',
      );
    }

    if (cap != null && used >= cap) {
      final reason = switch (status) {
        SubscriptionStatus.expired => AccessDeniedReason.subscriptionExpired,
        SubscriptionStatus.billingIssue => AccessDeniedReason.billingIssue,
        _ => AccessDeniedReason.limitReached,
      };
      return AccessDecision(
        featureId: featureId,
        allowed: false,
        reason: reason,
        remaining: 0,
        limit: cap,
        used: used,
        requiredTier: SubscriptionTier.pro,
        upgradeContext: 'limit_${featureId.name}',
      );
    }

    final remaining = cap == null ? null : (cap - used).clamp(0, cap);
    return AccessDecision(
      featureId: featureId,
      allowed: true,
      remaining: remaining,
      limit: cap,
      used: used,
      requiredTier: effectiveTier == SubscriptionTier.pro
          ? SubscriptionTier.pro
          : SubscriptionTier.free,
    );
  }

  static EntitlementSnapshot buildLocalSnapshot({
    required String userId,
    required SubscriptionTier tier,
    required SubscriptionStatus status,
    required Map<FeatureId, int> usageByFeature,
    String? productId,
    DateTime? expiresAt,
    String source = 'local',
  }) {
    final decisions = FeatureId.values
        .map(
          (f) => decide(
            featureId: f,
            tier: tier,
            status: status,
            used: usageByFeature[f] ?? 0,
          ),
        )
        .toList();
    final usage = FeatureId.values
        .where((f) => PlanLimitsConfig.forFeature(f).metered)
        .map((f) {
          final limit = PlanLimitsConfig.forFeature(f);
          final used = usageByFeature[f] ?? 0;
          final cap = tier == SubscriptionTier.pro
              ? limit.proLimit
              : limit.freeLimit;
          return UsageCounter(
            featureId: f,
            used: used,
            limit: cap,
            remaining: cap == null ? null : (cap - used).clamp(0, cap),
            period: limit.period,
          );
        })
        .toList();

    return EntitlementSnapshot(
      userId: userId,
      tier: tier,
      status: status,
      productId: productId,
      expiresAt: expiresAt,
      decisions: decisions,
      usage: usage,
      cachedAt: DateTime.now().toUtc(),
      source: source,
    );
  }
}
