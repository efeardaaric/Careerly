import 'package:equatable/equatable.dart';

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import '../../core/config/app_config.dart';
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
    this.firstName,
    this.accessToken,
    this.userId,
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
  final String? firstName;
  final String? accessToken;
  final String? userId;
  final CareerStage? careerStage;
  final CareerGoal? goal;
  final List<String> fields;
  final CvLanguagePreference? cvLanguage;
  final bool hydrated;

  bool get hasLocale => localeCode != null && localeCode!.isNotEmpty;

  Locale? get locale => hasLocale ? Locale(localeCode!) : null;

  /// A human first name. Email handles are not used as greetings.
  String? get greetingName {
    final explicit = firstName?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.split(RegExp(r'\s+')).first;
    }
    final display = displayName?.trim();
    final handle = email?.split('@').first.toLowerCase();
    if (display == null || display.isEmpty) return null;
    if (handle != null && display.toLowerCase() == handle) return null;
    if (!display.contains(' ')) return null;
    final token = display.split(RegExp(r'\s+')).first;
    if (token.length < 2) return null;
    if (token == token.toLowerCase()) {
      return token[0].toUpperCase() + token.substring(1);
    }
    return token;
  }

  SessionState copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? onboardingCompleted,
    bool? isAuthenticated,
    bool? personalizationCompleted,
    String? email,
    String? displayName,
    String? firstName,
    bool clearFirstName = false,
    String? accessToken,
    String? userId,
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
      firstName: clearAuthProfile || clearFirstName
          ? null
          : (firstName ?? this.firstName),
      accessToken: clearAuthProfile ? null : (accessToken ?? this.accessToken),
      userId: clearAuthProfile ? null : (userId ?? this.userId),
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
    firstName,
    accessToken,
    userId,
    careerStage,
    goal,
    fields,
    cvLanguage,
    hydrated,
  ];
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._store, {SupabaseClient? supabase})
    : _supabase = supabase,
      super(
        SessionState(
          localeCode: _store.localeCode,
          onboardingCompleted: _store.onboardingCompleted,
          isAuthenticated: supabase == null && _store.isMockSignedIn,
          personalizationCompleted: _store.personalizationCompleted,
          email: _store.mockEmail,
          displayName: _store.mockDisplayName,
          firstName: _store.firstName,
          accessToken: supabase == null
              ? _store.readString('auth_access_token')
              : null,
          careerStage: CareerStage.fromStorage(_store.careerStage),
          goal: CareerGoal.fromStorage(_store.goal),
          fields: _store.fields,
          cvLanguage: CvLanguagePreference.fromStorage(_store.cvLanguage),
        ),
      ) {
    if (supabase != null) {
      _enqueueSession(supabase.auth.currentSession);
      _authSubscription = supabase.auth.onAuthStateChange.listen(
        (event) => _enqueueSession(event.session),
        onError: (Object error, StackTrace stack) {
          if (mounted) {
            state = state.copyWith(
              isAuthenticated: false,
              clearAuthProfile: true,
            );
          }
        },
      );
    }
  }

  final LocalStore _store;
  final SupabaseClient? _supabase;
  StreamSubscription<AuthState>? _authSubscription;
  Future<void> _sessionQueue = Future<void>.value();

  void _enqueueSession(Session? session) {
    _sessionQueue = _sessionQueue
        .then((_) => syncSupabaseSession(session))
        .catchError((Object error) {
          if (mounted) {
            state = state.copyWith(
              isAuthenticated: false,
              clearAuthProfile: true,
            );
          }
        });
  }

  Future<void> syncSupabaseSession(Session? session) async {
    if (!mounted) return;
    if (session != null && session.isExpired) return;
    final previousId = _store.readString('supabase_user_id');
    if (session == null || previousId != session.user.id) {
      await _store.clearUserData();
      if (!mounted) return;
      state = SessionState(
        localeCode: state.localeCode,
        onboardingCompleted: state.onboardingCompleted,
        isAuthenticated: false,
        personalizationCompleted: false,
      );
    }
    if (session == null) return;
    await _store.writeString('supabase_user_id', session.user.id);
    if (!mounted) return;
    state = state.copyWith(
      isAuthenticated: true,
      userId: session.user.id,
      email: session.user.email,
      displayName: session.user.userMetadata?['full_name'] as String? ?? '',
      accessToken: session.accessToken,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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
    if (state.email != null && state.email != email) {
      await signOutMock();
    }
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

  Future<void> setFirstName(String name) async {
    final trimmed = name.trim();
    await _store.setFirstName(trimmed.isEmpty ? null : trimmed);
    state = state.copyWith(
      firstName: trimmed.isEmpty ? null : trimmed,
      clearFirstName: trimmed.isEmpty,
    );
  }

  Future<void> signOutMock() async {
    await _supabase?.auth.signOut(scope: SignOutScope.local);
    await _store.clearUserData();
    state = SessionState(
      localeCode: state.localeCode,
      onboardingCompleted: state.onboardingCompleted,
      isAuthenticated: false,
      personalizationCompleted: false,
      hydrated: state.hydrated,
    );
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
    await _supabase?.auth.signOut(scope: SignOutScope.local);
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
    await _supabase?.auth.signOut(scope: SignOutScope.local);
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
  return SessionController(
    ref.watch(localStoreProvider),
    supabase: AppConfig.instance.usesSupabase ? Supabase.instance.client : null,
  );
});
