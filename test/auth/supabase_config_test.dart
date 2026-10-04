import 'dart:convert';

import 'package:careerly/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client allows publishable and legacy anon keys only', () {
    String legacyKey(String role) =>
        'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role})))}.signature';
    expect(AppConfig.isPublicSupabaseKey('sb_publishable_test'), isTrue);
    expect(AppConfig.isPublicSupabaseKey(legacyKey('anon')), isTrue);
    expect(AppConfig.isPublicSupabaseKey(legacyKey('service_role')), isFalse);
    expect(AppConfig.isPublicSupabaseKey('sb_secret_test'), isFalse);
    expect(AppConfig.isPublicSupabaseKey('invalid'), isFalse);
  });
}
