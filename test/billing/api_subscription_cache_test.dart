import 'dart:async';
import 'dart:convert';

import 'package:careerly/core/api/api_client.dart';
import 'package:careerly/core/errors/app_exception.dart';
import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/billing/data/api_subscription_repository.dart';
import 'package:careerly/features/billing/domain/billing_models.dart';
import 'package:careerly/features/billing/domain/entitlement_policy.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

EntitlementSnapshot _snapshot(String userId) =>
    EntitlementPolicy.buildLocalSnapshot(
      userId: userId,
      tier: SubscriptionTier.pro,
      status: SubscriptionStatus.active,
      usageByFeature: {},
      source: 'server',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final cachedUser in ['alice', 'bob']) {
    test(
      'offline cache for $cachedUser cannot grant Alice paid access',
      () async {
        SharedPreferences.setMockInitialValues({
          'billing_entitlement_cache_json': jsonEncode(
            _snapshot(cachedUser).toJson(),
          ),
        });
        final store = await LocalStore.create();
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
            },
          ),
        );
        final repository = ApiSubscriptionRepository(
          apiClient: ApiClient(baseUrl: 'https://test.invalid', dio: dio),
          store: store,
        );
        if (cachedUser == 'bob') {
          await expectLater(
            repository.fetchEntitlements(userId: 'alice'),
            throwsA(isA<AppException>()),
          );
        } else {
          final snapshot = await repository.fetchEntitlements(userId: 'alice');
          expect(snapshot.decisionFor(FeatureId.cvAnalysis).allowed, isFalse);
          expect(snapshot.decisionFor(FeatureId.readOwnCv).allowed, isTrue);
        }
      },
    );
  }

  test('late entitlements cannot repopulate cache after sign out', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();
    final received = Completer<void>();
    final response = Completer<void>();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          received.complete();
          await response.future;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'entitlement': _snapshot('alice').toJson()},
            ),
          );
        },
      ),
    );
    final repository = ApiSubscriptionRepository(
      apiClient: ApiClient(baseUrl: 'https://test.invalid', dio: dio),
      store: store,
    );
    final request = repository.fetchEntitlements(userId: 'alice');
    await received.future;
    await store.clearUserData();
    final expectation = expectLater(request, throwsA(isA<AppException>()));
    response.complete();
    await expectation;
    expect(store.readString('billing_entitlement_cache_json'), isNull);
  });
}
