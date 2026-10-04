import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../domain/cv_version.dart';

/// Device-local CV versions. The backend keeps only the current text per CV.
class CvVersionStore {
  const CvVersionStore(this._store);

  final LocalStore _store;

  static const key = 'cv_versions_json';

  List<CvVersion> read() {
    final raw = _store.readString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(CvVersion.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  CvVersion? byId(String? id) {
    if (id == null) return null;
    for (final version in read()) {
      if (version.id == id) return version;
    }
    return null;
  }

  Future<void> add(CvVersion version) async {
    final all = [...read(), version];
    await _store.writeString(key, jsonEncode(all.map((v) => v.toJson()).toList()));
  }
}

final cvVersionStoreProvider = Provider<CvVersionStore>(
  (ref) => CvVersionStore(ref.watch(localStoreProvider)),
);
