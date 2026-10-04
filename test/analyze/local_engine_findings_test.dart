import 'package:careerly/features/analyze/domain/analysis_models.dart';
import 'package:careerly/features/analyze/engine/local_cv_analysis_engine.dart';
import 'package:careerly/features/analyze/engine/phrasing_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _cv = '''
Deniz Kaya
deniz.kaya@example.com | +90 555 000 1122
linkedin.com/in/denizkaya-example

Özet
Bilgisayar mühendisliği öğrencisi.

Deneyim
Yazılım Stajyeri | Örnek Yazılım A.Ş. | Haziran 2025 - Eylül 2025
- Test süreçlerinin yürütülmesinden sorumluydum
- Worked on internal tools with the team
- Haftalık hata raporlarını hazırladım

Eğitim
Bilgisayar Mühendisliği, Örnek Üniversitesi | 2022 - 2026

Yetenekler
Python, SQL, Git, Docker, Flutter
''';

ResumeAnalysis _score(String text) {
  final parsed = LocalCvAnalysisEngine.parseText(
    text: text,
    originalFileName: 'Deniz_Kaya_CV.pdf',
    resumeId: 'r1',
    preferTurkish: true,
  );
  return LocalCvAnalysisEngine.score(
    parsed: parsed,
    fileName: 'Deniz_Kaya_CV.pdf',
    profile: const AnalysisProfileContext(locale: 'tr'),
  );
}

int _cat(ResumeAnalysis a, ScoreCategoryId id) => a.category(id)!.score;

void main() {
  test('role header rows are not achievement lines', () {
    final lines = PhrasingRules.achievementLines([
      'Yazılım Stajyeri | Örnek Yazılım A.Ş. | Haziran 2025 - Eylül 2025\n'
          '- Haftalık hata raporlarını hazırladım',
    ]);
    expect(lines, ['Haftalık hata raporlarını hazırladım']);
  });

  test('evidence-based findings are produced in Turkish', () {
    final ids = _score(_cv).findings.map((f) => f.id).toSet();
    expect(ids, containsAll(['weak_openings', 'language_mixed', 'summary_short']));
  });

  test('rewriting a weak line raises experience only through the engine', () {
    final before = _score(_cv);
    final after = _score(
      _cv.replaceFirst(
        'Test süreçlerinin yürütülmesinden sorumluydum',
        'Test süreçlerini yürüttüm',
      ),
    );
    expect(
      _cat(after, ScoreCategoryId.experiencePresentation),
      greaterThan(_cat(before, ScoreCategoryId.experiencePresentation)),
    );
  });

  test('mixed date styles lower ATS readability below 100', () {
    final analysis = _score(
      '$_cv\nGönüllülük\nKulüp Üyesi | Örnek Kulübü | 2023 - Halen\n- Etkinlik planladım\n',
    );
    expect(_cat(analysis, ScoreCategoryId.atsCompatibility), lessThan(100));
  });
}
