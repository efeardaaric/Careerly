import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/billing_analytics.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/local_store.dart';
import '../../../app/session/session_controller.dart';
import '../data/api_subscription_repository.dart';
import '../data/mock_purchase_provider.dart';
import '../data/mock_subscription_repository.dart';
import '../data/unavailable_purchase_provider.dart';
import '../domain/billing_models.dart';
import '../domain/billing_repositories.dart';
import '../domain/plan_limits_config.dart';

class BillingUiState extends Equatable {
  const BillingUiState({
    this.entitlement,
    this.products = const [],
    this.purchasePhase = PurchasePhase.idle,
    this.lastError,
    this.isBusy = false,
  });

  final EntitlementSnapshot? entitlement;
  final List<StoreProduct> products;
  final PurchasePhase purchasePhase;
  final String? lastError;
  final bool isBusy;

  AccessDecision decision(FeatureId id) {
    final snap = entitlement;
    if (snap != null) return snap.decisionFor(id);
    // Fail closed for metered features when entitlement unknown.
    // Own CV data remains readable (never paywall the user's content).
    if (id == FeatureId.readOwnCv) {
      return const AccessDecision(
        featureId: FeatureId.readOwnCv,
        allowed: true,
      );
    }
    return AccessDecision(
      featureId: id,
      allowed: false,
      reason: AccessDeniedReason.offlineStale,
    );
  }

  BillingUiState copyWith({
    EntitlementSnapshot? entitlement,
    List<StoreProduct>? products,
    PurchasePhase? purchasePhase,
    String? lastError,
    bool clearError = false,
    bool? isBusy,
  }) {
    return BillingUiState(
      entitlement: entitlement ?? this.entitlement,
      products: products ?? this.products,
      purchasePhase: purchasePhase ?? this.purchasePhase,
      lastError: clearError ? null : (lastError ?? this.lastError),
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [
    entitlement,
    products,
    purchasePhase,
    lastError,
    isBusy,
  ];
}

class BillingController extends StateNotifier<BillingUiState> {
  BillingController({
    required SubscriptionRepository subscriptionRepository,
    required PurchaseProvider purchaseProvider,
    required this.userId,
  }) : _subscriptions = subscriptionRepository,
       _purchases = purchaseProvider,
       super(const BillingUiState()) {
    refresh();
  }

  final SubscriptionRepository _subscriptions;
  final PurchaseProvider _purchases;
  final String userId;
  int _generation = 0;

  bool _isCurrent(int generation) => mounted && generation == _generation;

  Future<void> refresh() async {
    final generation = _generation;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final snap = await _subscriptions.fetchEntitlements(userId: userId);
      if (!_isCurrent(generation)) return;
      state = state.copyWith(entitlement: snap, isBusy: false);
    } catch (e) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(isBusy: false, lastError: e.toString());
    }
  }

  Future<AccessDecision> precheck(FeatureId feature) async {
    final generation = _generation;
    final requestId =
        'chk_${feature.name}_${DateTime.now().microsecondsSinceEpoch}';
    final decision = await _subscriptions.checkAccess(
      userId: userId,
      featureId: feature,
      requestId: requestId,
    );
    if (!_isCurrent(generation)) {
      return AccessDecision(
        featureId: feature,
        allowed: false,
        reason: AccessDeniedReason.offlineStale,
      );
    }
    if (!decision.allowed) {
      BillingAnalytics.limitReached(featureId: feature.name);
    } else if (decision.isNearLimit) {
      BillingAnalytics.softUpgradeShown(featureId: feature.name);
    }
    // Keep local snapshot in sync for UI banners.
    await refresh();
    return decision;
  }

  /// Call only when the expensive action succeeds / is accepted.
  Future<AccessDecision> recordSuccessfulUsage(
    FeatureId feature, {
    required String requestId,
  }) {
    return _subscriptions.recordUsage(
      userId: userId,
      featureId: feature,
      requestId: requestId,
    );
  }

  Future<void> loadProducts() async {
    final generation = _generation;
    state = state.copyWith(purchasePhase: PurchasePhase.loadingProducts);
    try {
      final products = await _purchases.loadProducts();
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        products: products,
        purchasePhase: PurchasePhase.idle,
      );
    } catch (e) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        purchasePhase: PurchasePhase.error,
        lastError: e.toString(),
      );
    }
  }

  Future<bool> purchase(String productId) async {
    final generation = _generation;
    BillingAnalytics.purchaseStarted(productId: productId);
    state = state.copyWith(
      purchasePhase: PurchasePhase.purchasing,
      clearError: true,
    );
    try {
      final result = await _purchases.purchase(productId);
      if (!_isCurrent(generation)) return false;
      if (result.cancelled) {
        state = state.copyWith(purchasePhase: PurchasePhase.cancelled);
        return false;
      }
      if (!result.success) {
        BillingAnalytics.purchaseFailed(
          productId: productId,
          code: result.errorMessage,
        );
        state = state.copyWith(
          purchasePhase: PurchasePhase.error,
          lastError: result.errorMessage,
        );
        return false;
      }
      state = state.copyWith(purchasePhase: PurchasePhase.verifying);
      final snap = await _subscriptions.verifyPurchase(
        userId: userId,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        productId: productId,
        purchaseToken: result.purchaseToken,
        transactionId: result.transactionId,
      );
      if (!_isCurrent(generation)) return false;
      BillingAnalytics.purchaseSucceeded(productId: productId);
      state = state.copyWith(
        entitlement: snap,
        purchasePhase: PurchasePhase.success,
      );
      return true;
    } catch (e) {
      if (!_isCurrent(generation)) return false;
      BillingAnalytics.purchaseFailed(productId: productId, code: 'exception');
      state = state.copyWith(
        purchasePhase: PurchasePhase.error,
        lastError: e.toString(),
      );
      return false;
    }
  }

  Future<bool> restore() async {
    final generation = _generation;
    state = state.copyWith(purchasePhase: PurchasePhase.purchasing);
    try {
      final results = await _purchases.restore();
      if (!_isCurrent(generation)) return false;
      if (results.isEmpty) {
        state = state.copyWith(
          purchasePhase: PurchasePhase.error,
          lastError: 'nothing_to_restore',
        );
        return false;
      }
      final first = results.first;
      final snap = await _subscriptions.verifyPurchase(
        userId: userId,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        productId: first.productId,
        purchaseToken: first.purchaseToken,
        transactionId: first.transactionId,
      );
      BillingAnalytics.purchaseRestored();
      if (!_isCurrent(generation)) return false;
      state = state.copyWith(
        entitlement: snap,
        purchasePhase: PurchasePhase.restored,
      );
      return true;
    } catch (e) {
      if (!_isCurrent(generation)) return false;
      state = state.copyWith(
        purchasePhase: PurchasePhase.error,
        lastError: e.toString(),
      );
      return false;
    }
  }

  Future<void> setDevOverride(DevSubscriptionOverride? value) async {
    assert(!kReleaseMode);
    if (!AppConfig.instance.allowsMockBilling) {
      throw StateError('Dev subscription override is disabled in production.');
    }
    final repo = _subscriptions;
    if (repo is MockSubscriptionRepository) {
      await repo.setDevOverride(value);
      await refresh();
    }
  }

  /// Prevents the previous user's entitlement from remaining visible after sign-out.
  void clearUserData() {
    _generation++;
    state = const BillingUiState();
  }
}

final purchaseProviderProvider = Provider<PurchaseProvider>((ref) {
  if (!AppConfig.instance.allowsMockBilling) {
    return UnavailablePurchaseProvider();
  }
  return MockPurchaseProvider();
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final store = ref.watch(localStoreProvider);
  if (AppConfig.instance.analysisEngine == AnalysisEngine.api) {
    return ApiSubscriptionRepository(
      apiClient: ref.watch(apiClientProvider),
      store: store,
    );
  }
  final repository = MockSubscriptionRepository(store: store);
  store.addUserDataResetListener(repository.clearUserData);
  ref.onDispose(
    () => store.removeUserDataResetListener(repository.clearUserData),
  );
  return repository;
});

final billingControllerProvider =
    StateNotifierProvider<BillingController, BillingUiState>((ref) {
      final session = ref.watch(sessionProvider);
      final userId = session.email ?? 'anonymous';
      final controller = BillingController(
        subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
        purchaseProvider: ref.watch(purchaseProviderProvider),
        userId: userId,
      );
      final store = ref.watch(localStoreProvider);
      store.addUserDataResetListener(controller.clearUserData);
      ref.onDispose(
        () => store.removeUserDataResetListener(controller.clearUserData),
      );
      return controller;
    });

String newUsageRequestId(FeatureId feature) =>
    '${feature.name}_${DateTime.now().microsecondsSinceEpoch}_${PlanLimitsConfig.monthlyProductId.hashCode}';
