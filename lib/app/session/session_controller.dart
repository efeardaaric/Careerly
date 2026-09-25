import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import '../../features/personalization/domain/personalization_models.dart';

/// Aggregated session flags driving GoRouter redirects.
class SessionState extends Equatable {
  const SessionState({
    required this.localeCode,
    required this.onboardingCompleted,
    required this.isAuthenticated,
    required this.personalizationCompleted,
    this.email,
    this.displayName,
    this.accessToken,
    this.careerStage,
    this.goal,
    this.fields = const [],
    this.cvLanguage,
    this.hydrated = true,
  });

  final String? localeCode;
  final bool onboardingCompleted;
  final bool isAuthenticated;
  final bool personalizationCompleted;
  final String? email;
  final String? displayName;
  final String? accessToken;
  final CareerStage? careerStage;
  final CareerGoal? goal;
  final List<String> fields;
  final CvLanguagePreference? cvLanguage;
  final bool hydrated;

  bool get hasLocale => localeCode != null && localeCode!.isNotEmpty;

  Locale? get locale => hasLocale ? Locale(localeCode!) : null;

  SessionState copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? onboardingCompleted,
    bool? isAuthenticated,
    bool? personalizationCompleted,
    String? email,
    String? displayName,
    String? accessToken,
    bool clearAuthProfile = false,
    CareerStage? careerStage,
    CareerGoal? goal,
    List<String>? fields,
    CvLanguagePreference? cvLanguage,
    bool? hydrated,
  }) {
    return SessionState(
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      personalizationCompleted:
          personalizationCompleted ?? this.personalizationCompleted,
      email: clearAuthProfile ? null : (email ?? this.email),
      displayName: clearAuthProfile ? null : (displayName ?? this.displayName),
      accessToken: clearAuthProfile ? null : (accessToken ?? this.accessToken),
      careerStage: careerStage ?? this.careerStage,
      goal: goal ?? this.goal,
      fields: fields ?? this.fields,
      cvLanguage: cvLanguage ?? this.cvLanguage,
      hydrated: hydrated ?? this.hydrated,
    );
  }

  @override
  List<Object?> get props => [
    localeCode,
    onboardingCompleted,
    isAuthenticated,
    personalizationCompleted,
    email,
    displayName,
    accessToken,
    careerStage,
    goal,
    fields,
    cvLanguage,
    hydrated,
  ];
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._store)
    : super(
        SessionState(
          localeCode: _store.localeCode,
          onboardingCompleted: _store.onboardingCompleted,
          isAuthenticated: _store.isMockSignedIn,
          personalizationCompleted: _store.personalizationCompleted,
          email: _store.mockEmail,
          displayName: _store.mockDisplayName,
          accessToken: _store.readString('auth_access_token'),
          careerStage: CareerStage.fromStorage(_store.careerStage),
          goal: CareerGoal.fromStorage(_store.goal),
          fields: _store.fields,
          cvLanguage: CvLanguagePreference.fromStorage(_store.cvLanguage),
        ),
      );

  final LocalStore _store;

  Future<void> setLocale(String code) async {
    await _store.setLocaleCode(code);
    state = state.copyWith(localeCode: code);
  }

  Future<void> completeOnboarding() async {
    await _store.setOnboardingCompleted(true);
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<void> signInMock({
    required String email,
    String? displayName,
    String? accessToken,
  }) async {
    final name = displayName ?? email.split('@').first;
    final token = accessToken ?? 'dev:$email';
    await _store.setMockSignedIn(
      signedIn: true,
      email: email,
      displayName: name,
    );
    await _store.writeString('auth_access_token', token);
    state = state.copyWith(
      isAuthenticated: true,
      email: email,
      displayName: name,
      accessToken: token,
    );
  }

  Future<void> signOutMock() async {
    await _store.setMockSignedIn(signedIn: false);
    await _store.remove('auth_access_token');
    state = state.copyWith(isAuthenticated: false, clearAuthProfile: true);
  }

  Future<void> savePersonalization({
    CareerStage? stage,
    CareerGoal? goal,
    List<String> fields = const [],
    CvLanguagePreference? cvLanguage,
    bool markCompleted = true,
  }) async {
    await _store.setCareerStage(stage?.storageKey);
    await _store.setGoal(goal?.storageKey);
    await _store.setFields(fields);
    await _store.setCvLanguage(cvLanguage?.storageKey);
    if (markCompleted) {
      await _store.setPersonalizationCompleted(true);
    }
    state = state.copyWith(
      careerStage: stage,
      goal: goal,
      fields: fields,
      cvLanguage: cvLanguage,
      personalizationCompleted: markCompleted
          ? true
          : state.personalizationCompleted,
    );
  }

  Future<void> completePersonalization() async {
    await _store.setPersonalizationCompleted(true);
    state = state.copyWith(personalizationCompleted: true);
  }

  Future<void> resetDemo() async {
    await _store.resetDemoProgress();
    state = const SessionState(
      localeCode: null,
      onboardingCompleted: false,
      isAuthenticated: false,
      personalizationCompleted: false,
    );
  }

  /// Local account deletion — wipes all persisted user data on device.
  Future<void> deleteLocalAccount() async {
    await _store.deleteAllLocalUserData();
    state = const SessionState(
      localeCode: null,
      onboardingCompleted: false,
      isAuthenticated: false,
      personalizationCompleted: false,
    );
  }
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((
  ref,
) {
  return SessionController(ref.watch(localStoreProvider));
});
