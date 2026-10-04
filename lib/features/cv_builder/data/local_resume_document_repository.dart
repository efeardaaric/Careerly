import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_store.dart';
import '../domain/resume_document.dart';

abstract class ResumeDocumentRepository {
  Future<List<ResumeDocument>> listDocuments();
  Future<ResumeDocument?> getById(String id);
  Future<void> save(ResumeDocument doc);
  Future<void> delete(String id);
  Future<ResumeDocument> duplicate(String id);
}

class LocalResumeDocumentRepository implements ResumeDocumentRepository {
  LocalResumeDocumentRepository(this._store);

  final LocalStore _store;
  static const _indexKey = 'builder_resume_ids';
  static String _docKey(String id) => 'builder_resume_$id';

  @override
  Future<List<ResumeDocument>> listDocuments() async {
    final ids = _store.readStringList(_indexKey) ?? const [];
    final docs = <ResumeDocument>[];
    for (final id in ids) {
      final raw = _store.readString(_docKey(id));
      if (raw == null) continue;
      try {
        docs.add(
          ResumeDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  @override
  Future<ResumeDocument?> getById(String id) async {
    final raw = _store.readString(_docKey(id));
    if (raw == null) return null;
    try {
      return ResumeDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ResumeDocument doc) async {
    final generation = _store.userGeneration;
    final ids = List<String>.from(_store.readStringList(_indexKey) ?? const []);
    if (!ids.contains(doc.id)) {
      ids.insert(0, doc.id);
      await _store.writeStringList(_indexKey, ids);
    }
    if (generation != _store.userGeneration) return;
    await _store.writeString(_docKey(doc.id), jsonEncode(doc.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final ids = List<String>.from(_store.readStringList(_indexKey) ?? const []);
    ids.remove(id);
    await _store.writeStringList(_indexKey, ids);
    await _store.remove(_docKey(id));
  }

  @override
  Future<ResumeDocument> duplicate(String id) async {
    final generation = _store.userGeneration;
    final original = await getById(id);
    if (generation != _store.userGeneration) {
      throw StateError('Session changed');
    }
    if (original == null) {
      throw StateError('Document not found');
    }
    final copy = ResumeDocument(
      id: const Uuid().v4(),
      title: '${original.title} (copy)',
      language: original.language,
      templateId: original.templateId,
      personal: original.personal,
      summary: original.summary,
      education: original.education,
      experience: original.experience,
      projects: original.projects,
      skillGroups: original.skillGroups,
      languages: original.languages,
      certifications: original.certifications,
      awards: original.awards,
      customSections: original.customSections,
      sectionOrder: original.sectionOrder,
      sectionVisibility: original.sectionVisibility,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      sourceAnalysisId: original.sourceAnalysisId,
      parentDocumentId: original.id,
    );
    await save(copy);
    return copy;
  }
}

extension on LocalStore {
  List<String>? readStringList(String key) {
    // SharedPreferences string list via typed API if present; fallback JSON.
    final raw = readString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeStringList(String key, List<String> values) =>
      writeString(key, jsonEncode(values));
}

final resumeDocumentRepositoryProvider = Provider<ResumeDocumentRepository>((
  ref,
) {
  return LocalResumeDocumentRepository(ref.watch(localStoreProvider));
});
