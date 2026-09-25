import 'package:careerly/core/config/app_config.dart';
import 'package:careerly/core/errors/app_exception.dart';
import 'package:careerly/features/auth/domain/auth_repository.dart';
import 'package:careerly/features/cv_builder/domain/resume_document.dart';
import 'package:careerly/features/cv_builder/pdf/resume_pdf_renderer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Production config gates', () {
    test('rejects mock analysis in production', () {
      expect(
        () => AppConfig.validateProductionConfig(
          environment: AppEnvironment.production,
          apiBaseUrl: 'https://api.careerly.ai',
          useMockAnalysis: true,
        ),
        throwsA(isA<ProductionConfigException>()),
      );
    });

    test('rejects localhost API in production', () {
      expect(
        () => AppConfig.validateProductionConfig(
          environment: AppEnvironment.production,
          apiBaseUrl: 'http://127.0.0.1:8787',
          useMockAnalysis: false,
        ),
        throwsA(isA<ProductionConfigException>()),
      );
    });

    test('allows production with https API and mock off', () {
      expect(
        () => AppConfig.validateProductionConfig(
          environment: AppEnvironment.production,
          apiBaseUrl: 'https://api.careerly.ai',
          useMockAnalysis: false,
        ),
        returnsNormally,
      );
    });
  });

  group('Production auth fail-closed', () {
    test('ProductionAuthRepository never signs in', () async {
      final repo = ProductionAuthRepository();
      await expectLater(
        repo.signInWithEmail(
          email: 'a@b.com',
          password: 'password123',
          createAccount: false,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('429 mapping', () {
    test('fromDio maps 429 to rate_limited', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 429,
        ),
        type: DioExceptionType.badResponse,
      );
      final ex = AppException.fromDio(dio);
      expect(ex.isRateLimited, isTrue);
      expect(ex.code, 'rate_limited');
    });
  });

  group('PDF release templates EN/TR × 4', () {
    for (final lang in CvDocumentLanguage.values) {
      for (final template in CvTemplateId.values) {
        test('${lang.name}/${template.name}', () async {
          final doc =
              ResumeDocument.fromAnalyzedFixture(
                analysisId: 'pdf_test',
                fileName: 'aylin.pdf',
                language: lang,
                templateId: template,
              ).copyWith(
                personal: const PersonalDetails(
                  fullName: 'Aylin Demir',
                  email: 'aylin.demir@email.com',
                  location: 'İstanbul',
                ),
              );
          final bytes = await ResumePdfRenderer.buildBytes(doc);
          expect(bytes.length, greaterThan(500));
          expect(String.fromCharCodes(bytes.take(4)), '%PDF');
          final suffix = lang == CvDocumentLanguage.tr ? '_TR.pdf' : '_EN.pdf';
          expect(doc.exportFileName().endsWith(suffix), isTrue);
        }, timeout: const Timeout(Duration(minutes: 2)));
      }
    }
  });
}
