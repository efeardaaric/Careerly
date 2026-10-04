import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/local_store.dart';

import '../application/billing_controller.dart';
import '../domain/billing_models.dart';
import 'paywall_screen.dart';

/// Pre-check feature access. Returns true if the action may proceed.
Future<bool> ensureFeatureAccess(
  BuildContext context,
  WidgetRef ref,
  FeatureId feature, {
  String paywallContext = 'feature_gate',
}) async {
  final store = ref.read(localStoreProvider);
  final generation = store.userGeneration;
  final billing = ref.read(billingControllerProvider.notifier);
  final decision = await billing.precheck(feature);
  if (!context.mounted || generation != store.userGeneration) return false;
  if (decision.allowed) {
    // Store request id for later usage recording (idempotent).
    ref.read(pendingUsageRequestIdProvider.notifier).state = newUsageRequestId(
      feature,
    );
    return true;
  }
  if (!context.mounted) return false;
  final upgraded = await showPaywall(context, contextKey: paywallContext);
  if (upgraded == true) {
    final again = await billing.precheck(feature);
    if (!context.mounted || generation != store.userGeneration) return false;
    if (again.allowed) {
      ref.read(pendingUsageRequestIdProvider.notifier).state =
          newUsageRequestId(feature);
      return true;
    }
  }
  return false;
}

Future<void> consumePendingUsage(WidgetRef ref, FeatureId feature) async {
  final store = ref.read(localStoreProvider);
  final generation = store.userGeneration;
  final requestId = ref.read(pendingUsageRequestIdProvider);
  if (requestId == null || !requestId.startsWith(feature.name)) return;
  final serverMetered =
      AppConfig.instance.analysisEngine == AnalysisEngine.api &&
      {
        FeatureId.cvAnalysis,
        FeatureId.jobMatch,
        FeatureId.aiRewrite,
        FeatureId.translation,
      }.contains(feature);
  if (!serverMetered) {
    await ref
        .read(billingControllerProvider.notifier)
        .recordSuccessfulUsage(feature, requestId: requestId);
  }
  if (generation != store.userGeneration ||
      ref.read(pendingUsageRequestIdProvider) != requestId) {
    return;
  }
  ref.read(pendingUsageRequestIdProvider.notifier).state = null;
  await ref.read(billingControllerProvider.notifier).refresh();
}

final pendingUsageRequestIdProvider = StateProvider<String?>((ref) {
  final store = ref.watch(localStoreProvider);
  void clear() => ref.controller.state = null;
  store.addUserDataResetListener(clear);
  ref.onDispose(() => store.removeUserDataResetListener(clear));
  return null;
});
