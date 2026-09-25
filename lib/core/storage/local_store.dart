import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed local persistence for Phase 1 session / preference flags.
/// Tokens for real auth should later move to secure storage — not SharedPreferences.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLocale = 'locale_code';
  static const _keyOnboardingDone = 'onboarding_completed';
  static const _keyAuthMock = 'auth_mock_signed_in';
  static const _keyAuthEmail = 'auth_mock_email';
  static const _keyAuthDisplayName = 'auth_mock_display_name';
  static const _keyPersonalizationDone = 'personalization_completed';
  static const _keyCareerStage = 'personalization_career_stage';
  static const _keyGoal = 'personalization_goal';
  static const _keyFields = 'personalization_fields';
  static const _keyCvLanguage = 'personalization_cv_language';

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  String? get localeCode => _prefs.getString(_keyLocale);

  Future<void> setLocaleCode(String code) => _prefs.setString(_keyLocale, code);

  bool get onboardingCompleted => _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingCompleted(bool value) =>
      _prefs.setBool(_keyOnboardingDone, value);

  bool get isMockSignedIn => _prefs.getBool(_keyAuthMock) ?? false;

  String? get mockEmail => _prefs.getString(_keyAuthEmail);

  String? get mockDisplayName => _prefs.getString(_keyAuthDisplayName);

  Future<void> setMockSignedIn({
    required bool signedIn,
    String? email,
    String? displayName,
  }) async {
    await _prefs.setBool(_keyAuthMock, signedIn);
    if (signedIn) {
      if (email != null) await _prefs.setString(_keyAuthEmail, email);
      if (displayName != null) {
        await _prefs.setString(_keyAuthDisplayName, displayName);
      }
    } else {
      await _prefs.remove(_keyAuthEmail);
      await _prefs.remove(_keyAuthDisplayName);
    }
  }

  bool get personalizationCompleted =>
      _prefs.getBool(_keyPersonalizationDone) ?? false;

  Future<void> setPersonalizationCompleted(bool value) =>
      _prefs.setBool(_keyPersonalizationDone, value);

  String? get careerStage => _prefs.getString(_keyCareerStage);

  Future<void> setCareerStage(String? value) async {
    if (value == null) {
      await _prefs.remove(_keyCareerStage);
    } else {
      await _prefs.setString(_keyCareerStage, value);
    }
  }

  String? get goal => _prefs.getString(_keyGoal);

  Future<void> setGoal(String? value) async {
    if (value == null) {
      await _prefs.remove(_keyGoal);
    } else {
      await _prefs.setString(_keyGoal, value);
    }
  }

  List<String> get fields => _prefs.getStringList(_keyFields) ?? const [];

  Future<void> setFields(List<String> values) =>
      _prefs.setStringList(_keyFields, values);

  String? get cvLanguage => _prefs.getString(_keyCvLanguage);

  Future<void> setCvLanguage(String? value) async {
    if (value == null) {
      await _prefs.remove(_keyCvLanguage);
    } else {
      await _prefs.setString(_keyCvLanguage, value);
    }
  }

  /// Clears demo progress flags (keeps nothing). Used from Profile reset.
  Future<void> resetDemoProgress() async {
    await _prefs.remove(_keyLocale);
    await _prefs.remove(_keyOnboardingDone);
    await _prefs.remove(_keyAuthMock);
    await _prefs.remove(_keyAuthEmail);
    await _prefs.remove(_keyAuthDisplayName);
    await _prefs.remove(_keyPersonalizationDone);
    await _prefs.remove(_keyCareerStage);
    await _prefs.remove(_keyGoal);
    await _prefs.remove(_keyFields);
    await _prefs.remove(_keyCvLanguage);
    await _prefs.remove('last_resume_analysis_json');
    await _prefs.remove('saved_job_matches_json');
    await _prefs.remove('billing_usage_json');
    await _prefs.remove('billing_dev_override');
    await _prefs.remove('billing_entitlement_cache_json');
    await _prefs.remove('auth_access_token');
    // Phase 5 Builder documents.
    for (final key in _prefs.getKeys().where(
      (k) => k == 'builder_resume_ids' || k.startsWith('builder_resume_'),
    )) {
      await _prefs.remove(key);
    }
  }

  /// Account deletion (local): wipe all Careerly SharedPreferences keys.
  /// Server-side deletion requires EXTERNAL ACTION when accounts are hosted.
  Future<void> deleteAllLocalUserData() async {
    final keys = _prefs.getKeys().toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden in main()');
});
