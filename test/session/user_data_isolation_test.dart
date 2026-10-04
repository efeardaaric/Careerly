import 'dart:async';

import 'package:careerly/app/session/session_controller.dart';
import 'package:careerly/core/config/app_config.dart';
import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/applications/application/applications_controller.dart';
import 'package:careerly/features/billing/data/mock_subscription_repository.dart';
import 'package:careerly/features/billing/presentation/billing_gate.dart';
import 'package:careerly/features/cv_builder/application/builder_controller.dart';
import 'package:careerly/features/cv_builder/domain/resume_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedTranslation extends BuilderAiRepository {
  final pending = Completer<ResumeDocument>();

  @override
  Future<ResumeDocument> translateDocument({
    required ResumeDocument source,
    required CvDocumentLanguage target,
  }) => pending.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppConfig.bootstrap);

  for (final action in ['signOut', 'reset', 'delete', 'switchUser']) {
    test(
      '$action clears active Builder, applications and pending usage',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_mock_signed_in': true,
          'auth_mock_email': 'alice@example.com',
          'locale_code': 'tr',
          'onboarding_completed': true,
        });
        final store = await LocalStore.create();
        final container = ProviderContainer(
          overrides: [
            localStoreProvider.overrideWithValue(store),
            builderAiRepositoryProvider.overrideWithValue(
              BuilderAiRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);
        final builder = container.read(builderControllerProvider.notifier);
        await builder.createBlank(
          language: CvDocumentLanguage.tr,
          templateId: CvTemplateId.classicAts,
        );
        await container
            .read(applicationsControllerProvider.notifier)
            .create(jobTitle: 'Private role');
        container.read(pendingUsageRequestIdProvider.notifier).state =
            'cvAnalysis_pending';
        final session = container.read(sessionProvider.notifier);
        switch (action) {
          case 'signOut':
            await session.signOutMock();
          case 'reset':
            await session.resetDemo();
          case 'delete':
            await session.deleteLocalAccount();
          case 'switchUser':
            await session.signInMock(email: 'bob@example.com');
        }
        expect(container.read(builderControllerProvider).active, isNull);
        expect(container.read(builderControllerProvider).documents, isEmpty);
        expect(container.read(applicationsControllerProvider), isEmpty);
        expect(container.read(pendingUsageRequestIdProvider), isNull);
        expect(store.readString('builder_resume_ids'), isNull);
        expect(store.readString('job_applications_json'), isNull);
      },
    );
  }

  test(
    'translation completing after sign out cannot save a previous CV',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.create();
      final ai = _DelayedTranslation();
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          builderAiRepositoryProvider.overrideWithValue(ai),
        ],
      );
      addTearDown(container.dispose);
      final builder = container.read(builderControllerProvider.notifier);
      await builder.createBlank(
        language: CvDocumentLanguage.en,
        templateId: CvTemplateId.classicAts,
      );
      final source = container.read(builderControllerProvider).active!;
      final translation = builder.translateActive(CvDocumentLanguage.tr);
      await container.read(sessionProvider.notifier).signOutMock();
      ai.pending.complete(source.copyWith(language: CvDocumentLanguage.tr));
      expect(await translation, isNull);
      expect(container.read(builderControllerProvider).documents, isEmpty);
      expect(store.readString('builder_resume_ids'), isNull);
    },
  );

  test('mock paid override is removed from the next user session', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();
    final container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final repository = MockSubscriptionRepository(
      store: store,
      initialOverride: DevSubscriptionOverride.pro,
    );
    store.addUserDataResetListener(repository.clearUserData);
    await container.read(sessionProvider.notifier).signOutMock();
    expect(repository.devOverride, isNull);
    store.removeUserDataResetListener(repository.clearUserData);
  });
}
