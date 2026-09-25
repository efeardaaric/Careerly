import 'package:equatable/equatable.dart';

enum SubscriptionTier { free, pro }

enum SubscriptionStatus { active, expired, billingIssue, none }

enum FeatureId {
  cvAnalysis,
  jobMatch,
  aiRewrite,
  builderCv,
  premiumTemplate,
  translation,
  jobTailor,
  readOwnCv,
}

enum AccessDeniedReason {
  limitReached,
  requiresPro,
  billingIssue,
  subscriptionExpired,
  offlineStale,
}

enum PurchasePhase {
  idle,
  loadingProducts,
  purchasing,
  verifying,
  success,
  restored,
  cancelled,
  error,
}

/// Richer than a bool — widgets should branch on this, not `isPro`.
class AccessDecision extends Equatable {
  const AccessDecision({
    required this.featureId,
    required this.allowed,
    this.reason,
    this.remaining,
    this.limit,
    this.used = 0,
    this.resetAt,
    this.requiredTier = SubscriptionTier.pro,
    this.upgradeContext,
  });

  final FeatureId featureId;
  final bool allowed;
  final AccessDeniedReason? reason;
  final int? remaining;
  final int? limit;
  final int used;
  final DateTime? resetAt;
  final SubscriptionTier requiredTier;
  final String? upgradeContext;

  bool get isNearLimit =>
      remaining != null && limit != null && remaining! <= 1 && remaining! > 0;

  factory AccessDecision.fromJson(Map<String, dynamic> json) {
    return AccessDecision(
      featureId: FeatureId.values.firstWhere(
        (e) => e.name == json['featureId'],
        orElse: () => FeatureId.cvAnalysis,
      ),
      allowed: json['allowed'] as bool? ?? false,
      reason: json['reason'] == null
          ? null
          : AccessDeniedReason.values.firstWhere(
              (e) => e.name == json['reason'],
              orElse: () => AccessDeniedReason.limitReached,
            ),
      remaining: json['remaining'] as int?,
      limit: json['limit'] as int?,
      used: json['used'] as int? ?? 0,
      resetAt: json['resetAt'] != null
          ? DateTime.tryParse(json['resetAt'] as String)
          : null,
      requiredTier: SubscriptionTier.values.firstWhere(
        (e) => e.name == (json['requiredTier'] as String? ?? 'pro'),
        orElse: () => SubscriptionTier.pro,
      ),
      upgradeContext: json['upgradeContext'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'featureId': featureId.name,
    'allowed': allowed,
    'reason': reason?.name,
    'remaining': remaining,
    'limit': limit,
    'used': used,
    'resetAt': resetAt?.toIso8601String(),
    'requiredTier': requiredTier.name,
    'upgradeContext': upgradeContext,
  };

  @override
  List<Object?> get props => [
    featureId,
    allowed,
    reason,
    remaining,
    limit,
    used,
    resetAt,
    requiredTier,
    upgradeContext,
  ];
}

class UsageCounter extends Equatable {
  const UsageCounter({
    required this.featureId,
    required this.used,
    required this.period,
    this.limit,
    this.remaining,
    this.resetAt,
  });

  final FeatureId featureId;
  final int used;
  final int? limit;
  final int? remaining;
  final DateTime? resetAt;
  final String period;

  factory UsageCounter.fromJson(Map<String, dynamic> json) {
    return UsageCounter(
      featureId: FeatureId.values.firstWhere(
        (e) => e.name == json['featureId'],
        orElse: () => FeatureId.cvAnalysis,
      ),
      used: json['used'] as int? ?? 0,
      limit: json['limit'] as int?,
      remaining: json['remaining'] as int?,
      resetAt: json['resetAt'] != null
          ? DateTime.tryParse(json['resetAt'] as String)
          : null,
      period: json['period'] as String? ?? 'month',
    );
  }

  Map<String, dynamic> toJson() => {
    'featureId': featureId.name,
    'used': used,
    'limit': limit,
    'remaining': remaining,
    'resetAt': resetAt?.toIso8601String(),
    'period': period,
  };

  @override
  List<Object?> get props => [
    featureId,
    used,
    limit,
    remaining,
    resetAt,
    period,
  ];
}

class EntitlementSnapshot extends Equatable {
  const EntitlementSnapshot({
    required this.userId,
    required this.tier,
    required this.status,
    required this.decisions,
    required this.usage,
    required this.cachedAt,
    required this.source,
    this.productId,
    this.expiresAt,
  });

  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final String? productId;
  final DateTime? expiresAt;
  final List<AccessDecision> decisions;
  final List<UsageCounter> usage;
  final DateTime cachedAt;
  final String source;

  bool get isProActive =>
      tier == SubscriptionTier.pro && status == SubscriptionStatus.active;

  AccessDecision decisionFor(FeatureId id) {
    for (final d in decisions) {
      if (d.featureId == id) return d;
    }
    return AccessDecision(featureId: id, allowed: false);
  }

  factory EntitlementSnapshot.fromJson(Map<String, dynamic> json) {
    return EntitlementSnapshot(
      userId: json['userId'] as String? ?? 'anonymous',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.none,
      ),
      productId: json['productId'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      decisions: (json['decisions'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AccessDecision.fromJson)
          .toList(),
      usage: (json['usage'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(UsageCounter.fromJson)
          .toList(),
      cachedAt:
          DateTime.tryParse(json['cachedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      source: json['source'] as String? ?? 'cache',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'tier': tier.name,
    'status': status.name,
    'productId': productId,
    'expiresAt': expiresAt?.toIso8601String(),
    'decisions': decisions.map((d) => d.toJson()).toList(),
    'usage': usage.map((u) => u.toJson()).toList(),
    'cachedAt': cachedAt.toIso8601String(),
    'source': source,
  };

  @override
  List<Object?> get props => [
    userId,
    tier,
    status,
    productId,
    decisions,
    usage,
    source,
  ];
}

class StoreProduct extends Equatable {
  const StoreProduct({
    required this.productId,
    required this.title,
    required this.priceLabel,
    required this.period,
  });

  final String productId;
  final String title;

  /// Real store price string in release; debug may show placeholders.
  final String priceLabel;
  final String period; // monthly | yearly

  @override
  List<Object?> get props => [productId, title, priceLabel, period];
}

class PurchaseResult extends Equatable {
  const PurchaseResult({
    required this.success,
    required this.productId,
    this.purchaseToken,
    this.transactionId,
    this.errorMessage,
    this.cancelled = false,
  });

  final bool success;
  final String productId;
  final String? purchaseToken;
  final String? transactionId;
  final String? errorMessage;
  final bool cancelled;

  @override
  List<Object?> get props => [
    success,
    productId,
    purchaseToken,
    transactionId,
    cancelled,
  ];
}
