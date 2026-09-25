import '../domain/billing_models.dart';
import '../domain/billing_repositories.dart';

/// Fail-closed purchase provider for production until store SDK is wired.
/// Never reports a successful purchase.
class UnavailablePurchaseProvider implements PurchaseProvider {
  @override
  Future<List<StoreProduct>> loadProducts() async {
    throw StateError(
      'EXTERNAL ACTION REQUIRED: wire App Store / Google Play Billing. '
      'MockPurchaseProvider is disabled in production/release.',
    );
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    throw StateError(
      'EXTERNAL ACTION REQUIRED: wire App Store / Google Play Billing.',
    );
  }

  @override
  Future<List<PurchaseResult>> restore() async {
    throw StateError(
      'EXTERNAL ACTION REQUIRED: wire App Store / Google Play Billing.',
    );
  }
}
