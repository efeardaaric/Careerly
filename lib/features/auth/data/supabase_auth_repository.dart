import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/auth_repository.dart';

class EmailConfirmationRequired implements Exception {}

class OAuthRedirectStarted implements Exception {}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    final response = createAccount
        ? await client.auth.signUp(email: email, password: password)
        : await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
    final session = response.session;
    if (session == null) {
      if (createAccount) throw EmailConfirmationRequired();
      throw StateError('Authentication did not return a session.');
    }
    return AuthUser(
      userId: session.user.id,
      email: session.user.email ?? email,
      displayName: session.user.userMetadata?['full_name'] as String? ?? '',
      provider: 'supabase',
      accessToken: session.accessToken,
    );
  }

  @override
  Future<AuthUser> signInWithProvider(String provider) async {
    final oauthProvider = switch (provider) {
      'google' => OAuthProvider.google,
      'apple' => OAuthProvider.apple,
      _ => throw ArgumentError.value(provider, 'provider'),
    };
    final launched = await client.auth.signInWithOAuth(
      oauthProvider,
      redirectTo: 'io.careerly.app://login-callback',
    );
    if (!launched) throw StateError('Could not launch sign-in.');
    throw OAuthRedirectStarted();
  }
}
