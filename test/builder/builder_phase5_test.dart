import 'dart:convert';

import 'package:careerly/features/cv_builder/application/builder_controller.dart';
import 'package:careerly/features/cv_builder/data/local_resume_document_repository.dart';
import 'package:careerly/features/cv_builder/data/resume_snapshot_from_document.dart';
import 'package:careerly/features/cv_builder/domain/resume_document.dart';
import 'package:careerly/core/storage/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResumeDocument', () {
    test('json round-trip preserves structured fields', () {
      final doc = ResumeDocument.fromAnalyzedFixture(
        analysisId: 'a1',
        fileName: 'aylin.pdf',
      );
      final again = ResumeDocument.fromJson(doc.toJson());
      expect(again.personal.fullName, 'Aylin Demir');
      expect(again.projects.first.name, 'Campus Event App');
      expect(again.templateId, CvTemplateId.student);
      expect(again.exportFileName(), 'Aylin_Demir_CV_EN.pdf');
    });

    test('template switch does not alter content fields', () {
      final doc = ResumeDocument.fromAnalyzedFixture(
        analysisId: 'a1',
        fileName: 'aylin.pdf',
      );
      final switched = doc.copyWith(templateId: CvTemplateId.tech);
      expect(switched.summary, doc.summary);
      expect(switched.experience, doc.experience);
      expect(switched.projects, doc.projects);
      expect(switched.templateId, CvTemplateId.tech);
    });

    test('TR export filename suffix', () {
      final doc = ResumeDocument.blank(
        language: CvDocumentLanguage.tr,
        templateId: CvTemplateId.classicAts,
      ).copyWith(personal: const PersonalDetails(fullName: 'Aylin Demir'));
      expect(doc.exportFileName(), 'Aylin_Demir_CV_TR.pdf');
    });
  });

  group('LocalResumeDocumentRepository', () {
    test('save list duplicate delete', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalResumeDocumentRepository(LocalStore(prefs));
      final doc = ResumeDocument.blank(
        language: CvDocumentLanguage.en,
        templateId: CvTemplateId.classicAts,
      );
      await repo.save(doc);
      expect((await repo.listDocuments()).length, 1);
      final copy = await repo.duplicate(doc.id);
      expect(copy.id, isNot(doc.id));
      expect((await repo.listDocuments()).length, 2);
      await repo.delete(doc.id);
      expect(await repo.getById(doc.id), isNull);
      expect((await repo.listDocuments()).length, 1);
    });
  });

  group('BuilderAiRepository mock', () {
    test('improve without metrics asks for fact', () async {
      final ai = BuilderAiRepository(useMock: true);
      final s = await ai.rewrite(
        mode: 'improve',
        text: 'Built a campus event app using Flutter and Firebase',
        locale: 'en',
      );
      expect(s.needsUserFact, isTrue);
      expect(
        s.suggested,
        'Built a campus event app using Flutter and Firebase',
      );
    });

    test('translate preserves proper nouns', () async {
      final ai = BuilderAiRepository(useMock: true);
      final source = ResumeDocument.fromAnalyzedFixture(
        analysisId: 'a1',
        fileName: 'aylin.pdf',
      );
      final tr = await ai.translateDocument(
        source: source,
        target: CvDocumentLanguage.tr,
      );
      expect(tr.personal.fullName, 'Aylin Demir');
      expect(tr.language, CvDocumentLanguage.tr);
      expect(tr.summary.contains('staj'), isTrue);
    });
  });

  group('ResumeSnapshotFromDocument', () {
    test('maps skills and bullets without inventing', () {
      final doc = ResumeDocument.fromAnalyzedFixture(
        analysisId: 'a1',
        fileName: 'aylin.pdf',
      );
      final snap = ResumeSnapshotFromDocument.fromDocument(doc);
      expect(snap.skills, contains('Flutter'));
      expect(snap.projectBullets.first, contains('Flutter'));
      expect(snap.resumeId, doc.id);
    });
  });

  group('persistence index encoding', () {
    test('index stored as json list string', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      final repo = LocalResumeDocumentRepository(store);
      final doc = ResumeDocument.blank(
        language: CvDocumentLanguage.en,
        templateId: CvTemplateId.modernAts,
      );
      await repo.save(doc);
      final raw = store.readString('builder_resume_ids');
      expect(raw, isNotNull);
      expect(jsonDecode(raw!) as List, contains(doc.id));
    });
  });
}
