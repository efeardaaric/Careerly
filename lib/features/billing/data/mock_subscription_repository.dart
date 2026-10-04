import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/storage/local_store.dart';
import '../domain/billing_models.dart';
import '../domain/billing_repositories.dart';
import '../domain/entitlement_policy.dart';
import '../domain/plan_limits_config.dart';

/// Dev-only subscription override. Release builds must not expose bypass.
enum DevSubscriptionOverride { free, pro, expired, billingIssue }

class MockSubscriptionRepository implements SubscriptionRepository {
  MockSubscriptionRepository({
    required this._store,
    DevSubscriptionOverride? initialOverride,
  }) : _override = initialOverride;

  void clearUserData() {
    _override = null;
    _seenRequestIds.clear();
  }

  final LocalStore _store;
  DevSubscriptionOverride? _override;

  static const _usageKey = 'billing_usage_json';
  static const _overrideKey = 'billing_dev_override';
  static const _cacheKey = 'billing_entitlement_cache_json';

  DevSubscriptionOverride? get devOverride {
    if (kReleaseMode) return null;
    if (_override != null) return _override;
    final raw = _store.readString(_overrideKey);
    if (raw == null) return null;
    return DevSubscriptionOverride.values
        .where((e) => e.name == raw)
        .firstOrNull;
  }

  Future<void> setDevOverride(DevSubscriptionOverride? value) async {
    assert(!kReleaseMode, 'Dev subscription override forbidden in release');
    if (kReleaseMode) return;
    _override = value;
    if (value == null) {
      await _store.remove(_overrideKey);
    } else {
      await _store.writeString(_overrideKey, value.name);
    }
  }

  (SubscriptionTier, SubscriptionStatus, String?) _tierFromOverride() {
    return switch (devOverride) {
      DevSubscriptionOverride.pro => (
        SubscriptionTier.pro,
        SubscriptionStatus.active,
        PlanLimitsConfig.monthlyProductId,
      ),
      DevSubscriptionOverride.expired => (
        SubscriptionTier.free,
        SubscriptionStatus.expired,
        PlanLimitsConfig.monthlyProductId,
      ),
      DevSubscriptionOverride.billingIssue => (
        SubscriptionTier.pro,
        SubscriptionStatus.billingIssue,
        PlanLimitsConfig.monthlyProductId,
      ),
      DevSubscriptionOverride.free ||
      null => (SubscriptionTier.free, SubscriptionStatus.none, null),
    };
  }

  Map<FeatureId, int> _loadUsage() {
    final raw = _store.readString(_usageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries)
          FeatureId.values.firstWhere(
            (f) => f.name == e.key,
            orElse: () => FeatureId.cvAnalysis,
          ): (e.value as num)
              .toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUsage(Map<FeatureId, int> usage) async {
    await _store.writeString(
      _usageKey,
      jsonEncode({for (final e in usage.entries) e.key.name: e.value}),
    );
  }

  final Set<String> _seenRequestIds = {};

  @override
  Future<EntitlementSnapshot> fetchEntitlements({
    required String userId,
  }) async {
    final (tier, status, productId) = _tierFromOverride();
    final snap = EntitlementPolicy.buildLocalSnapshot(
      userId: userId,
      tier: tier,
      status: status,
      usageByFeature: _loadUsage(),
      productId: productId,
      source: 'mock',
    );
    await _store.writeString(_cacheKey, jsonEncode(snap.toJson()));
    return snap;
  }

  /// Offline: return last cached snapshot if present.
  Future<EntitlementSnapshot?> readCachedEntitlements() async {
    final raw = _store.readString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return EntitlementSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EntitlementSnapshot> verifyPurchase({
    required String userId,
    required String platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
  }) async {
    final token = (purchaseToken ?? '').toLowerCase();
    if (token.contains('expired')) {
      await setDevOverride(DevSubscriptionOverride.expired);
    } else if (token.contains('billing')) {
      await setDevOverride(DevSubscriptionOverride.billingIssue);
    } else {
      await setDevOverride(DevSubscriptionOverride.pro);
    }
    return fetchEntitlements(userId: userId);
  }

  @override
  Future<AccessDecision> checkAccess({
    required String userId,
    required FeatureId featureId,
    required String requestId,
  }) async {
    final snap = await fetchEntitlements(userId: userId);
    return snap.decisionFor(featureId);
  }

  @override
  Future<AccessDecision> recordUsage({
    required String userId,
    required FeatureId featureId,
    required String requestId,
  }) async {
    final (tier, status, _) = _tierFromOverride();
    final usage = _loadUsage();
    final used = usage[featureId] ?? 0;

    if (_seenRequestIds.contains(requestId)) {
      return EntitlementPolicy.decide(
        featureId: featureId,
        tier: tier,
        status: status,
        used: used,
      );
    }

    final pre = EntitlementPolicy.decide(
      featureId: featureId,
      tier: tier,
      status: status,
      used: used,
    );
    if (!pre.allowed) return pre;

    final limit = PlanLimitsConfig.forFeature(featureId);
    if (limit.metered) {
      usage[featureId] = used + 1;
      await _saveUsage(usage);
      _seenRequestIds.add(requestId);
    }

    return EntitlementPolicy.decide(
      featureId: featureId,
      tier: tier,
      status: status,
      used: usage[featureId] ?? used,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
