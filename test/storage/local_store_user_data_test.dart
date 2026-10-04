import 'package:careerly/core/storage/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('clearUserData removes user data but preserves app setup', () async {
    SharedPreferences.setMockInitialValues({
      'locale_code': 'tr',
      'onboarding_completed': true,
      'auth_mock_signed_in': true,
      'auth_mock_email': 'a@example.com',
      'auth_mock_display_name': 'User A',
      'personalization_completed': true,
      'personalization_career_stage': 'earlyCareer',
      'active_cv_record_json': '{bad json',
      'cv_versions_json': '[]',
      'job_applications_json': '[]',
      'saved_job_matches_json': '[]',
      'billing_entitlement_cache_json': '{}',
      'builder_resume_ids': '["resume-a"]',
      'builder_resume_resume-a': '{}',
    });

    final store = await LocalStore.create();
    await store.clearUserData();

    expect(store.localeCode, 'tr');
    expect(store.onboardingCompleted, isTrue);
    expect(store.readString('auth_mock_email'), isNull);
    expect(store.readString('active_cv_record_json'), isNull);
    expect(store.readString('cv_versions_json'), isNull);
    expect(store.readString('job_applications_json'), isNull);
    expect(store.readString('saved_job_matches_json'), isNull);
    expect(store.readString('builder_resume_ids'), isNull);
    expect(store.readString('builder_resume_resume-a'), isNull);
  });

  test('clearUserData is safe when keys are missing', () async {
    SharedPreferences.setMockInitialValues({'locale_code': 'en'});
    final store = await LocalStore.create();

    await expectLater(store.clearUserData(), completes);
    expect(store.localeCode, 'en');
  });
}
