import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this.key);

  final String key;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => storage.read(key: key);

  @override
  Future<bool> hasAccessToken() => storage.containsKey(key: key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      storage.write(key: key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => storage.delete(key: key);
}

Future<void> initializeSupabase() async {
  final config = AppConfig.instance;
  if (!config.usesSupabase) return;
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(
        'careerly_${Uri.parse(config.supabaseUrl).host}_session',
      ),
    ),
  );
}
