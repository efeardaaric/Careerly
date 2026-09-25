import 'package:flutter/foundation.dart';

/// Environment-aware configuration. No API keys belong in the client.
enum AppEnvironment { dev, staging, production }

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
    required this.useMockAnalysis,
    required this.allowsMockAuth,
    required this.allowsMockBilling,
  });

  static late final AppConfig instance;

  final AppEnvironment environment;
  final String apiBaseUrl;

  /// When true, Flutter uses mock analysis / Job Match / Builder AI.
  /// Production always forces false.
  final bool useMockAnalysis;

  /// Mock email/password auth is allowed only outside production.
  final bool allowsMockAuth;

  /// Mock IAP / force-Pro overrides only outside production+release.
  final bool allowsMockBilling;

  bool get isDev => environment == AppEnvironment.dev;
  bool get isProduction => environment == AppEnvironment.production;

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
    bool useMockAnalysis;
    if (environment == AppEnvironment.production) {
      useMockAnalysis = false;
      if (useMockDefine.toLowerCase() == 'true') {
        throw ProductionConfigException(
          'USE_MOCK_ANALYSIS=true is forbidden when ENV=production.',
        );
      }
    } else if (useMockDefine.isEmpty) {
      useMockAnalysis = true;
    } else {
      useMockAnalysis = useMockDefine.toLowerCase() != 'false';
    }

    validateProductionConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      useMockAnalysis: useMockAnalysis,
    );

    final allowsMockAuth = environment != AppEnvironment.production;
    final allowsMockBilling =
        environment != AppEnvironment.production && !kReleaseMode;

    instance = AppConfig._(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      useMockAnalysis: useMockAnalysis,
      allowsMockAuth: allowsMockAuth,
      allowsMockBilling: allowsMockBilling,
    );

    if (kDebugMode) {
      debugPrint(
        'Careerly config: env=${environment.name} api=$apiBaseUrl '
        'mockAnalysis=$useMockAnalysis mockAuth=$allowsMockAuth '
        'mockBilling=$allowsMockBilling',
      );
    }
  }

  /// Runtime guard for release+production binaries.
  void assertReleaseSafe() {
    if (!isProduction) return;
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
