import '../domain/billing_models.dart';

abstract class PurchaseProvider {
  Future<List<StoreProduct>> loadProducts();
  Future<PurchaseResult> purchase(String productId);
  Future<List<PurchaseResult>> restore();
}

abstract class SubscriptionRepository {
  Future<EntitlementSnapshot> fetchEntitlements({required String userId});
  Future<EntitlementSnapshot> verifyPurchase({
    required String userId,
    required String platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
  });
  Future<AccessDecision> checkAccess({
    required String userId,
    required FeatureId featureId,
    required String requestId,
  });
  Future<AccessDecision> recordUsage({
    required String userId,
    required FeatureId featureId,
    required String requestId,
  });
}
