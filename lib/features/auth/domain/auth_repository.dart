import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/mock_auth_repository.dart';
import '../data/supabase_auth_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared auth user — mock or production IdP.
class AuthUser extends Equatable {
  const AuthUser({
    required this.email,
    required this.displayName,
    required this.provider,
    this.accessToken,
    this.userId,
  });

  final String email;
  final String displayName;
  final String provider;
  final String? userId;

  /// Opaque access token for backend Authorization header.
  /// Null for legacy mock session until a token is minted.
  final String? accessToken;

  @override
  List<Object?> get props => [
    email,
    displayName,
    provider,
    accessToken,
    userId,
  ];
}

abstract class AuthRepository {
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  });

  Future<AuthUser> signInWithProvider(String provider);
}

/// Production IdP is not configured in this repo.
/// Fail closed — never silently fall back to mock auth.
class ProductionAuthRepository implements AuthRepository {
  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    throw StateError(
      'EXTERNAL ACTION REQUIRED: configure production identity provider '
      '(Auth0 / Firebase Auth / Sign in with Apple+Google) before ENV=production. '
      'Mock email/password auth is disabled in production.',
    );
  }

  @override
  Future<AuthUser> signInWithProvider(String provider) async {
    throw StateError(
      'EXTERNAL ACTION REQUIRED: configure $provider sign-in for production. '
      'Mock social auth is disabled in production.',
    );
  }
}

class MockAuthRepositoryAdapter implements AuthRepository {
  MockAuthRepositoryAdapter(this._inner);
  final MockAuthRepository _inner;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    final u = await _inner.signInWithEmail(
      email: email,
      password: password,
      createAccount: createAccount,
    );
    return AuthUser(
      email: u.email,
      displayName: u.displayName,
      provider: u.provider,
      // Dev token format understood by backend AUTH_MODE=dev|hmac with shared secret.
      accessToken: 'dev:${u.email}',
    );
  }

  @override
  Future<AuthUser> signInWithProvider(String provider) async {
    final u = await _inner.signInWithProvider(provider);
    return AuthUser(
      email: u.email,
      displayName: u.displayName,
      provider: u.provider,
      accessToken: 'dev:${u.email}',
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.instance.usesSupabase) {
    return SupabaseAuthRepository(Supabase.instance.client);
  }
  if (!AppConfig.instance.allowsMockAuth) {
    return ProductionAuthRepository();
  }
  return MockAuthRepositoryAdapter(MockAuthRepository());
});
