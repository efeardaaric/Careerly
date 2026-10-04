import 'package:careerly/app/session/session_controller.dart';
import 'package:careerly/core/storage/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sign out clears user session data and preserves app setup', () async {
    SharedPreferences.setMockInitialValues({
      'locale_code': 'tr',
      'onboarding_completed': true,
      'auth_mock_signed_in': true,
      'auth_mock_email': 'a@example.com',
      'auth_mock_display_name': 'User A',
      'personalization_completed': true,
      'active_cv_record_json': '{"analysis":{}}',
      'job_applications_json': '[]',
      'saved_job_matches_json': '[]',
    });

    final store = await LocalStore.create();
    final controller = SessionController(store);

    await controller.signOutMock();

    expect(controller.state.isAuthenticated, isFalse);
    expect(controller.state.personalizationCompleted, isFalse);
    expect(controller.state.email, isNull);
    expect(store.localeCode, 'tr');
    expect(store.onboardingCompleted, isTrue);
    expect(store.readString('active_cv_record_json'), isNull);
    expect(store.readString('job_applications_json'), isNull);
    expect(store.readString('saved_job_matches_json'), isNull);
  });

  test('repeated sign out is harmless', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = SessionController(await LocalStore.create());

    await controller.signOutMock();
    await controller.signOutMock();

    expect(controller.state.isAuthenticated, isFalse);
  });
}
