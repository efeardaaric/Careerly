import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final billing = ref.read(billingControllerProvider.notifier);
  final decision = await billing.precheck(feature);
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
    if (again.allowed) {
      ref.read(pendingUsageRequestIdProvider.notifier).state =
          newUsageRequestId(feature);
      return true;
    }
  }
  return false;
}

Future<void> consumePendingUsage(WidgetRef ref, FeatureId feature) async {
  final requestId = ref.read(pendingUsageRequestIdProvider);
  if (requestId == null || !requestId.startsWith(feature.name)) return;
  await ref
      .read(billingControllerProvider.notifier)
      .recordSuccessfulUsage(feature, requestId: requestId);
  ref.read(pendingUsageRequestIdProvider.notifier).state = null;
  await ref.read(billingControllerProvider.notifier).refresh();
}

final pendingUsageRequestIdProvider = StateProvider<String?>((ref) => null);
