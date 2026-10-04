/// Application entry. Bootstraps Riverpod and Careerly root widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/storage/local_store.dart';
import 'core/auth/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve env from --dart-define=ENV=dev|staging|production (default: dev).
  AppConfig.bootstrap();
  AppConfig.instance.assertReleaseSafe();
  await initializeSupabase();

  final localStore = await LocalStore.create();

  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(localStore)],
      child: const CareerlyApp(),
    ),
  );
}
