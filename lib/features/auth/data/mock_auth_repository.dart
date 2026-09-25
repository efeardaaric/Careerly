import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Isolated mock auth. Swap for a real AuthRepository + secure tokens later.
class MockAuthUser extends Equatable {
  const MockAuthUser({
    required this.email,
    required this.displayName,
    required this.provider,
  });

  final String email;
  final String displayName;
  final String provider;

  @override
  List<Object?> get props => [email, displayName, provider];
}

class MockAuthRepository {
  Future<MockAuthUser> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (password.length < 8) {
      throw StateError('invalid_password');
    }
    return MockAuthUser(
      email: email,
      displayName: email.split('@').first,
      provider: createAccount ? 'email_signup' : 'email_signin',
    );
  }

  Future<MockAuthUser> signInWithProvider(String provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final label = provider == 'apple' ? 'Apple User' : 'Google User';
    return MockAuthUser(
      email: '$provider.user@careerly.demo',
      displayName: label,
      provider: provider,
    );
  }
}

final mockAuthRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});
