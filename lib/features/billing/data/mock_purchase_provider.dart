import 'package:flutter/foundation.dart';

import '../domain/billing_models.dart';
import '../domain/billing_repositories.dart';
import '../domain/plan_limits_config.dart';

/// Mock / debug purchase provider. Release builds must not use fake prices
/// as production store truth — [AppConfig.isProduction] gates real wiring.
class MockPurchaseProvider implements PurchaseProvider {
  MockPurchaseProvider({this.simulateFailure = false});

  final bool simulateFailure;

  @override
  Future<List<StoreProduct>> loadProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Debug placeholders only — never hard-code as production prices in UI copy
    // that claims store truth. Paywall labels these as demo when kDebugMode.
    return const [
      StoreProduct(
        productId: PlanLimitsConfig.monthlyProductId,
        title: 'Careerly Pro Monthly',
        priceLabel: kDebugMode ? 'Demo · \$7.99/mo' : '—',
        period: 'monthly',
      ),
      StoreProduct(
        productId: PlanLimitsConfig.yearlyProductId,
        title: 'Careerly Pro Yearly',
        priceLabel: kDebugMode ? 'Demo · \$59.99/yr' : '—',
        period: 'yearly',
      ),
    ];
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (simulateFailure) {
      return PurchaseResult(
        success: false,
        productId: productId,
        errorMessage: 'Mock purchase failed',
      );
    }
    if (productId == 'cancel') {
      return PurchaseResult(
        success: false,
        productId: productId,
        cancelled: true,
      );
    }
    return PurchaseResult(
      success: true,
      productId: productId,
      purchaseToken: 'mock_pro_token',
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<List<PurchaseResult>> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      PurchaseResult(
        success: true,
        productId: PlanLimitsConfig.monthlyProductId,
        purchaseToken: 'mock_pro_token',
        transactionId: 'txn_restore',
      ),
    ];
  }
}
