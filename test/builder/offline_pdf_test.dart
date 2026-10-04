import 'dart:io';

import 'package:careerly/features/cv_builder/domain/resume_document.dart';
import 'package:careerly/features/cv_builder/pdf/resume_pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineClient extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('PDF export must not access the network');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all templates export Turkish text without downloading fonts', () async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = _OfflineClient();
    addTearDown(() => HttpOverrides.global = previous);
    for (final template in CvTemplateId.values) {
      final document = ResumeDocument.blank(
        language: CvDocumentLanguage.tr,
        templateId: template,
      ).copyWith(personal: const PersonalDetails(fullName: 'Çağrı Şen Öztürk'));
      final bytes = await ResumePdfRenderer.buildBytes(document);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1000));
    }
  });
}
