import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/billing/data/mock_purchase_provider.dart';
import 'package:careerly/features/billing/data/mock_subscription_repository.dart';
import 'package:careerly/features/billing/domain/billing_models.dart';
import 'package:careerly/features/billing/domain/entitlement_policy.dart';
import 'package:careerly/features/billing/domain/plan_limits_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EntitlementPolicy', () {
    test('readOwnCv always allowed even when expired', () {
      final d = EntitlementPolicy.decide(
        featureId: FeatureId.readOwnCv,
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.expired,
        used: 99,
      );
      expect(d.allowed, isTrue);
    });

    test('free analysis limited to configured cap', () {
      final allowed = EntitlementPolicy.decide(
        featureId: FeatureId.cvAnalysis,
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.none,
        used: 1,
      );
      expect(allowed.allowed, isTrue);
      expect(allowed.remaining, 1);

      final blocked = EntitlementPolicy.decide(
        featureId: FeatureId.cvAnalysis,
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.none,
        used: PlanLimitsConfig.forFeature(FeatureId.cvAnalysis).freeLimit!,
      );
      expect(blocked.allowed, isFalse);
      expect(blocked.reason, AccessDeniedReason.limitReached);
    });

    test('premium template requires Pro', () {
      final d = EntitlementPolicy.decide(
        featureId: FeatureId.premiumTemplate,
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.none,
        used: 0,
      );
      expect(d.allowed, isFalse);
      expect(d.reason, AccessDeniedReason.requiresPro);
    });

    test('pro active has unlimited analysis', () {
      final d = EntitlementPolicy.decide(
        featureId: FeatureId.cvAnalysis,
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
        used: 100,
      );
      expect(d.allowed, isTrue);
      expect(d.limit, isNull);
    });
  });

  group('MockSubscriptionRepository', () {
    test('usage recording is idempotent by requestId', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.create();
      final repo = MockSubscriptionRepository(store: store);

      final first = await repo.recordUsage(
        userId: 'u1',
        featureId: FeatureId.cvAnalysis,
        requestId: 'req_same_12345678',
      );
      expect(first.allowed, isTrue);
      expect(first.used, 1);

      final dup = await repo.recordUsage(
        userId: 'u1',
        featureId: FeatureId.cvAnalysis,
        requestId: 'req_same_12345678',
      );
      expect(dup.used, 1);
    });

    test('dev override to pro unlocks premium template', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.create();
      final repo = MockSubscriptionRepository(store: store);
      await repo.setDevOverride(DevSubscriptionOverride.pro);
      final snap = await repo.fetchEntitlements(userId: 'u1');
      expect(snap.isProActive, isTrue);
      expect(snap.decisionFor(FeatureId.premiumTemplate).allowed, isTrue);
    });
  });

  group('MockPurchaseProvider', () {
    test('loads config-driven product ids', () async {
      final products = await MockPurchaseProvider().loadProducts();
      expect(
        products.map((p) => p.productId),
        containsAll([
          PlanLimitsConfig.monthlyProductId,
          PlanLimitsConfig.yearlyProductId,
        ]),
      );
    });
  });

  group('PlanLimitsConfig', () {
    test('product ids are not empty placeholders', () {
      expect(PlanLimitsConfig.monthlyProductId, startsWith('careerly_'));
      expect(PlanLimitsConfig.yearlyProductId, startsWith('careerly_'));
    });
  });
}
