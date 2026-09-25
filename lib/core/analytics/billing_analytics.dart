/// Product analytics — never log CV/JD/prompt content.
abstract final class BillingAnalytics {
  static final List<Map<String, Object?>> _events = [];

  static List<Map<String, Object?>> get debugEvents =>
      List.unmodifiable(_events);

  static void clear() => _events.clear();

  static void track(String name, [Map<String, Object?> props = const {}]) {
    // Strip any accidental content keys.
    final safe = Map<String, Object?>.from(props)
      ..removeWhere(
        (k, _) =>
            k.contains('cv') ||
            k.contains('jd') ||
            k.contains('prompt') ||
            k.contains('resumeText') ||
            k.contains('jobDescription'),
      );
    _events.add({
      'name': name,
      ...safe,
      'at': DateTime.now().toIso8601String(),
    });
    // ignore: avoid_print
    assert(() {
      // ignore: avoid_print
      print('analytics:$name $safe');
      return true;
    }());
  }

  static void paywallViewed({required String context}) =>
      track('paywall_viewed', {'context': context});

  static void paywallClosed({required String context}) =>
      track('paywall_closed', {'context': context});

  static void purchaseStarted({required String productId}) =>
      track('purchase_started', {'productId': productId});

  static void purchaseSucceeded({required String productId}) =>
      track('purchase_succeeded', {'productId': productId});

  static void purchaseFailed({required String productId, String? code}) =>
      track('purchase_failed', {'productId': productId, 'code': code});

  static void purchaseRestored() => track('purchase_restored');

  static void limitReached({required String featureId}) =>
      track('limit_reached', {'featureId': featureId});

  static void softUpgradeShown({required String featureId}) =>
      track('soft_upgrade_shown', {'featureId': featureId});
}
