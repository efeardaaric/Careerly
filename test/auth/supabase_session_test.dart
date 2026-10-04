import 'package:careerly/app/session/session_controller.dart';
import 'package:careerly/core/storage/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session sessionFor(String userId, String token) => Session.fromJson({
  'access_token': token,
  'refresh_token': 'refresh-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': userId,
    'email': '$userId@example.com',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'aud': 'authenticated',
    'created_at': '2026-10-04T00:00:00Z',
  },
})!;

void main() {
  test(
    'real session uses UUID and never stores bearer in preferences',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_mock_signed_in': true,
        'auth_access_token': 'dev:old-user',
        'active_cv_record_json': 'old-cv',
      });
      final store = await LocalStore.create();
      final controller = SessionController(store);
      addTearDown(controller.dispose);

      await controller.syncSupabaseSession(sessionFor('user-a', 'token-a'));

      expect(controller.state.userId, 'user-a');
      expect(controller.state.accessToken, 'token-a');
      expect(store.readString('auth_access_token'), isNull);
      expect(store.readString('active_cv_record_json'), isNull);
      expect(store.isMockSignedIn, isFalse);
    },
  );

  test(
    'refresh preserves data; account switch and sign-out clear it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.create();
      final controller = SessionController(store);
      addTearDown(controller.dispose);
      await controller.syncSupabaseSession(sessionFor('user-a', 'token-a'));
      await store.writeString('active_cv_record_json', 'cv-a');
      final generation = store.userGeneration;

      await controller.syncSupabaseSession(
        sessionFor('user-a', 'token-refreshed'),
      );
      expect(store.readString('active_cv_record_json'), 'cv-a');
      expect(store.userGeneration, generation);
      expect(controller.state.accessToken, 'token-refreshed');

      await controller.syncSupabaseSession(sessionFor('user-b', 'token-b'));
      expect(store.readString('active_cv_record_json'), isNull);
      expect(controller.state.userId, 'user-b');

      await controller.syncSupabaseSession(null);
      expect(controller.state.isAuthenticated, isFalse);
      expect(controller.state.userId, isNull);
      expect(controller.state.accessToken, isNull);
      expect(store.readString('supabase_user_id'), isNull);
    },
  );
}
