import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Environment-aware configuration. No API keys belong in the client.
enum AppEnvironment { dev, staging, production }

/// Where CV analysis and job match run.
///
/// [api] calls the Careerly backend (default).
/// [local] is the on-device rules engine, only when USE_LOCAL_ANALYSIS=true.
/// [mock] is an explicit dev fixture and is forbidden in production.
enum AnalysisEngine { local, mock, api }

class ProductionConfigException implements Exception {
  ProductionConfigException(this.message);
  final String message;
  @override
  String toString() => 'ProductionConfigException: $message';
}

class AppConfig {
  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.analysisEngine,
    required this.allowsMockAuth,
    required this.allowsMockBilling,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  static late final AppConfig instance;

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabasePublishableKey;
  bool get usesSupabase => supabaseUrl.isNotEmpty;

  /// Analysis backend. Production is always [AnalysisEngine.api].
  final AnalysisEngine analysisEngine;

  /// Fixture analysis is active only when [analysisEngine] is [AnalysisEngine.mock].
  bool get useMockAnalysis => analysisEngine == AnalysisEngine.mock;

  bool get useLocalAnalysis => analysisEngine == AnalysisEngine.local;

  /// Mock email/password auth is allowed only outside production.
  final bool allowsMockAuth;

  /// Mock IAP / force-Pro overrides only outside production+release.
  final bool allowsMockBilling;

  bool get isDev => environment == AppEnvironment.dev;
  bool get isProduction => environment == AppEnvironment.production;

  static bool isPublicSupabaseKey(String key) {
    if (key.startsWith('sb_publishable_')) return true;
    try {
      final payload = key.split('.')[1];
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      );
      return decoded is Map && decoded['role'] == 'anon';
    } catch (_) {
      return false;
    }
  }

  static bool _isLoopback(String url) {
    final lower = url.toLowerCase();
    return lower.contains('127.0.0.1') ||
        lower.contains('localhost') ||
        lower.contains('0.0.0.0') ||
        lower.contains('[::1]');
  }

  /// Pure validation used by tests and [bootstrap].
  static void validateProductionConfig({
    required AppEnvironment environment,
    required String apiBaseUrl,
    required bool useMockAnalysis,
  }) {
    if (environment != AppEnvironment.production) return;
    if (useMockAnalysis) {
      throw ProductionConfigException(
        'USE_MOCK_ANALYSIS=true is forbidden when ENV=production.',
      );
    }
    if (_isLoopback(apiBaseUrl)) {
      throw ProductionConfigException(
        'API_BASE_URL must not be localhost in production '
        '(got $apiBaseUrl). EXTERNAL ACTION: set real API host.',
      );
    }
  }

  /// Call once from [main] before [runApp].
  /// Throws [ProductionConfigException] if production is misconfigured.
  static void bootstrap() {
    const envName = String.fromEnvironment('ENV', defaultValue: 'dev');
    final environment = switch (envName.toLowerCase()) {
      'staging' || 'stage' => AppEnvironment.staging,
      'production' || 'prod' => AppEnvironment.production,
      _ => AppEnvironment.dev,
    };

    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    final apiBaseUrl = overrideUrl.isNotEmpty
        ? overrideUrl
        : switch (environment) {
            AppEnvironment.dev => 'http://127.0.0.1:8787',
            AppEnvironment.staging => 'https://api.staging.careerly.ai',
            AppEnvironment.production => 'https://api.careerly.ai',
          };

    const useMockDefine = String.fromEnvironment('USE_MOCK_ANALYSIS');
    const useLocalDefine = String.fromEnvironment('USE_LOCAL_ANALYSIS');
    final AnalysisEngine analysisEngine;
    if (environment == AppEnvironment.production) {
      if (useMockDefine.toLowerCase() == 'true') {
        throw ProductionConfigException(
          'USE_MOCK_ANALYSIS=true is forbidden when ENV=production.',
        );
      }
      analysisEngine = AnalysisEngine.api;
    } else if (useMockDefine.toLowerCase() == 'true') {
      analysisEngine = AnalysisEngine.mock;
    } else if (useLocalDefine.toLowerCase() == 'true') {
      analysisEngine = AnalysisEngine.local;
    } else {
      analysisEngine = AnalysisEngine.api;
    }

    validateProductionConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      useMockAnalysis: analysisEngine == AnalysisEngine.mock,
    );

    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    if (supabaseUrl.isNotEmpty != supabasePublishableKey.isNotEmpty) {
      throw ProductionConfigException(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set together.',
      );
    }
    if (supabaseUrl.isNotEmpty &&
        Uri.tryParse(supabaseUrl)?.scheme != 'https') {
      throw ProductionConfigException('SUPABASE_URL must use HTTPS.');
    }
    if (supabaseUrl.isNotEmpty &&
        !isPublicSupabaseKey(supabasePublishableKey)) {
      throw ProductionConfigException(
        'Only a publishable or legacy anon key may be shipped in Flutter.',
      );
    }
    final allowsMockAuth =
        environment != AppEnvironment.production && supabaseUrl.isEmpty;
    final allowsMockBilling =
        environment != AppEnvironment.production && !kReleaseMode;

    instance = AppConfig._(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      analysisEngine: analysisEngine,
      allowsMockAuth: allowsMockAuth,
      allowsMockBilling: allowsMockBilling,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
    );

    if (kDebugMode) {
      debugPrint(
        'Careerly config: env=${environment.name} api=$apiBaseUrl '
        'engine=${analysisEngine.name} mockAuth=$allowsMockAuth '
        'mockBilling=$allowsMockBilling',
      );
    }
  }

  /// Runtime guard for release+production binaries.
  void assertReleaseSafe() {
    if (!isProduction) return;
    if (!usesSupabase) {
      throw ProductionConfigException(
        'Supabase Auth must be configured in production.',
      );
    }
    if (useMockAnalysis) {
      throw ProductionConfigException('mock analysis active in production');
    }
    if (_isLoopback(apiBaseUrl)) {
      throw ProductionConfigException('localhost API in production');
    }
    if (allowsMockBilling) {
      throw ProductionConfigException('mock billing active in production');
    }
  }
}
