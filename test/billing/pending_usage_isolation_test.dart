import 'dart:async';

import 'package:careerly/app/session/session_controller.dart';
import 'package:careerly/core/config/app_config.dart';
import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/billing/application/billing_controller.dart';
import 'package:careerly/features/billing/data/mock_purchase_provider.dart';
import 'package:careerly/features/billing/data/mock_subscription_repository.dart';
import 'package:careerly/features/billing/domain/billing_models.dart';
import 'package:careerly/features/billing/presentation/billing_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedUsage extends MockSubscriptionRepository {
  _DelayedUsage(LocalStore store) : super(store: store);

  final pending = Completer<AccessDecision>();
  int calls = 0;

  @override
  Future<AccessDecision> recordUsage({
    required String userId,
    required FeatureId featureId,
    required String requestId,
  }) {
    calls++;
    return pending.future;
  }
}

void main() {
  setUpAll(AppConfig.bootstrap);

  for (final feature in [FeatureId.builderCv, FeatureId.cvAnalysis]) {
    testWidgets('$feature usage belongs only to its initiating session', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.create();
      final repository = _DelayedUsage(store);
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          subscriptionRepositoryProvider.overrideWithValue(repository),
          purchaseProviderProvider.overrideWithValue(MockPurchaseProvider()),
        ],
      );
      addTearDown(container.dispose);
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              widgetRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      container.read(pendingUsageRequestIdProvider.notifier).state =
          '${feature.name}_alice';
      final consuming = consumePendingUsage(widgetRef, feature);
      if (feature == FeatureId.cvAnalysis) {
        await consuming;
        expect(repository.calls, 0);
      } else {
        expect(repository.calls, 1);
        await container.read(sessionProvider.notifier).signOutMock();
        container.read(pendingUsageRequestIdProvider.notifier).state =
            'builderCv_bob';
        repository.pending.complete(
          AccessDecision(featureId: feature, allowed: true),
        );
        await consuming;
        expect(container.read(pendingUsageRequestIdProvider), 'builderCv_bob');
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
