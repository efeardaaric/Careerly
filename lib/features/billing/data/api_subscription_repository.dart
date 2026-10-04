import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/local_store.dart';
import '../domain/billing_models.dart';
import '../domain/billing_repositories.dart';

/// Server-authoritative subscription client.
class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository({
    required ApiClient apiClient,
    required this._store,
  }) : _api = apiClient;

  final ApiClient _api;
  final LocalStore _store;
  static const _cacheKey = 'billing_entitlement_cache_json';

  Options _headers(String userId, {String? requestId}) {
    return Options(headers: {'X-User-Id': userId, 'X-Request-Id': ?requestId});
  }

  @override
  Future<EntitlementSnapshot> fetchEntitlements({
    required String userId,
  }) async {
    final generation = _store.userGeneration;
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/v1/billing/entitlements',
        options: _headers(userId),
      );
      final data = response.data?['entitlement'] as Map<String, dynamic>?;
      if (data == null) {
        throw const AppException(
          message: 'Empty entitlements',
          code: 'empty_entitlements',
        );
      }
      final snap = EntitlementSnapshot.fromJson(data);
      if (generation != _store.userGeneration || snap.userId != userId) {
        throw const AppException(
          message: 'Session changed',
          code: 'session_changed',
        );
      }
      await _store.writeString(_cacheKey, jsonEncode(snap.toJson()));
      return snap;
    } on AppException {
      if (generation != _store.userGeneration) rethrow;
      final cached = await _readCache();
      if (cached != null && cached.userId == userId) {
        return EntitlementSnapshot(
          userId: cached.userId,
          tier: cached.tier,
          status: cached.status,
          productId: cached.productId,
          expiresAt: cached.expiresAt,
          decisions: cached.decisions
              .map(
                (d) => AccessDecision(
                  featureId: d.featureId,
                  allowed: d.featureId == FeatureId.readOwnCv,
                  reason: d.featureId == FeatureId.readOwnCv
                      ? null
                      : AccessDeniedReason.offlineStale,
                  remaining: d.remaining,
                  limit: d.limit,
                  used: d.used,
                  resetAt: d.resetAt,
                  requiredTier: d.requiredTier,
                  upgradeContext: d.upgradeContext,
                ),
              )
              .toList(),
          usage: cached.usage,
          cachedAt: cached.cachedAt,
          source: 'cache',
        );
      }
      rethrow;
    }
  }

  Future<EntitlementSnapshot?> _readCache() async {
    final raw = _store.readString(_cacheKey);
    if (raw == null) return null;
    try {
      return EntitlementSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EntitlementSnapshot> verifyPurchase({
    required String userId,
    required String platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/api/v1/billing/subscriptions/verify',
      data: {
        'userId': userId,
        'platform': platform,
        'productId': productId,
        'purchaseToken': ?purchaseToken,
        'transactionId': ?transactionId,
      },
      options: _headers(userId),
    );
    return fetchEntitlements(userId: userId);
  }

  @override
  Future<AccessDecision> checkAccess({
    required String userId,
    required FeatureId featureId,
    required String requestId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/v1/billing/access/check',
      data: {
        'userId': userId,
        'featureId': featureId.name,
        'requestId': requestId,
      },
      options: _headers(userId, requestId: requestId),
    );
    final decision = response.data?['decision'] as Map<String, dynamic>?;
    if (decision == null) {
      throw const AppException(message: 'No decision', code: 'no_decision');
    }
    return AccessDecision.fromJson(decision);
  }

  @override
  Future<AccessDecision> recordUsage({
    required String userId,
    required FeatureId featureId,
    required String requestId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/v1/billing/usage/record',
      data: {
        'userId': userId,
        'featureId': featureId.name,
        'requestId': requestId,
      },
      options: _headers(userId, requestId: requestId),
    );
    final decision = response.data?['decision'] as Map<String, dynamic>?;
    if (decision == null) {
      throw const AppException(message: 'No decision', code: 'no_decision');
    }
    return AccessDecision.fromJson(decision);
  }
}
