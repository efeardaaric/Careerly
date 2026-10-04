import 'package:uuid/uuid.dart';

import '../../personalization/domain/personalization_models.dart';
import '../domain/analysis_models.dart';
import '../domain/cv_display_name.dart';
import 'phrasing_rules.dart';
import 'score_math.dart';
import 'section_detector.dart';

class AnalysisProfileContext {
  const AnalysisProfileContext({
    this.careerStage,
    this.fields = const [],
    this.cvLanguage,
    this.locale = 'en',
  });

  final CareerStage? careerStage;
  final List<String> fields;
  final CvLanguagePreference? cvLanguage;
  final String locale;

  bool get earlyCareer =>
      careerStage == CareerStage.student ||
      careerStage == CareerStage.intern ||
      careerStage == CareerStage.newGraduate ||
      careerStage == null;

  bool get softwareLike => fields.any(
    (f) => const {
      'software',
      'data',
      'ai',
      'cybersecurity',
      'engineering',
      'game',
    }.contains(f),
  );
}

/// Rule-based CV score. Numbers come only from measurable checks.
abstract final class LocalCvAnalysisEngine {
  static ParsedResume parseText({
    required String text,
    required String originalFileName,
    required String resumeId,
    bool preferTurkish = false,
  }) {
    final evidence = SectionDetector.detect(
      text: text,
      originalFileName: originalFileName,
      displayName: CvDisplayName.normalize(originalFileName),
      preferTurkish: preferTurkish,
    );
    return _parsedFromEvidence(resumeId, evidence);
  }

  static ParsedResume reclassify({
    required ParsedResume parsed,
    required String sectionId,
    required String newKey,
    required String newTitle,
  }) {
    final evidence = parsed.evidence;
    if (evidence == null) return parsed;
    final sections = evidence.sections.map((section) {
      if (section.id != sectionId) return section;
      return section.copyWith(
        key: newKey,
        title: newTitle,
        status: SectionStatus.userCorrected,
        confidence: 1,
      );
    }).toList();
    final next = evidence.copyWith(sections: sections);
    return _parsedFromEvidence(parsed.resumeId, next);
  }

  static ParsedResume withSectionStatus({
    required ParsedResume parsed,
    required String sectionId,
    required SectionStatus status,
  }) {
    final evidence = parsed.evidence;
    if (evidence == null) {
      return parsed.copyWith(
        sections: parsed.sections
            .map((s) => s.id == sectionId ? s.copyWith(status: status) : s)
            .toList(),
      );
    }
    final sections = evidence.sections
        .map(
          (section) => section.id == sectionId
              ? section.copyWith(status: status)
              : section,
        )
        .toList();
    return _parsedFromEvidence(
      parsed.resumeId,
      evidence.copyWith(sections: sections),
    );
  }

  static ResumeAnalysis score({
    required ParsedResume parsed,
    required String fileName,
    AnalysisProfileContext profile = const AnalysisProfileContext(),
  }) {
    final evidence = parsed.evidence;
    final tr = profile.locale.startsWith('tr');
    if (evidence == null) {
      throw StateError('Local analysis requires extracted CV evidence.');
    }

    final active = evidence.sections
        .where((s) => s.status != SectionStatus.missing)
        .toList();
    final experienceBullets = PhrasingRules.achievementLines(
      _bodies(evidence, const {'experience', 'volunteer'}),
    );
    final projectBullets = PhrasingRules.achievementLines(
      _bodies(evidence, const {'projects'}),
    );
    final impactBullets = [...experienceBullets, ...projectBullets];
    final quantified = impactBullets.where(_hasMeasure).length;
    final unquantified = impactBullets.length - quantified;
    final skills = _skillTokens(evidence.joinedBody('skills'));
    final summary = evidence.summary ?? evidence.joinedBody('summary');

    final basics = _basicsScore(evidence, profile);
    final ats = _atsScore(evidence, active, tr);
    final experience = _experienceScore(
      evidence,
      experienceBullets,
      projectBullets,
      profile,
    );
    final content = _contentScore(impactBullets, summary, quantified, tr);
    final skillsScore = _skillsScore(skills, evidence, profile);
    final structure = _structureScore(evidence, active);
    final language = _languageScore(impactBullets, evidence, profile);

    final scores = {
      ScoreCategoryId.atsCompatibility: ats.score,
      ScoreCategoryId.contentImpact: content.score,
      ScoreCategoryId.experiencePresentation: experience.score,
      ScoreCategoryId.skillsRelevance: skillsScore.score,
      ScoreCategoryId.structureReadability: structure.score,
      ScoreCategoryId.languageGrammar: language.score,
      ScoreCategoryId.basicsContact: basics.score,
    };
    final overall = ScoreMath.overall(scores);

    final findings = <AnalysisFinding>[
      ...basics.findings,
      ...ats.findings,
      ...content.findings,
      ...experience.findings,
      ...skillsScore.findings,
      ...structure.findings,
      ...language.findings,
    ];

    if (unquantified > 0 && impactBullets.isNotEmpty) {
      findings.add(
        AnalysisFinding(
          id: 'impact_unquantified',
          severity: unquantified >= 3
              ? FindingSeverity.critical
              : FindingSeverity.improve,
          title: tr
              ? 'Ölçülebilir sonuçlar seyrek'
              : 'Measurable outcomes are thin',
          whyItMatters: tr
              ? 'Sonuç belirten maddeler, yalnızca görev anlatan maddelerden daha kolay okunur.'
              : 'Bullets that show a result are easier to judge than activity-only bullets.',
          evidence: tr
              ? '$unquantified / ${impactBullets.length} deneyim veya proje maddesinde ölçülebilir bir sonuç yok.'
              : '$unquantified of ${impactBullets.length} experience or project bullets describe activity without a measurable result.',
          recommendedAction: tr
              ? 'Doğrulayabildiğin bir sonuç varsa ekle. Rakam uydurulmaz.'
              : 'Add a measurable result if you can verify one. Do not invent a number.',
          categoryId: ScoreCategoryId.contentImpact,
        ),
      );
    }

    final working = <String>[];
    if (evidence.email != null) {
      working.add(tr ? 'E-posta okunabilir.' : 'An email address is readable.');
    }
    if (active.any((s) => s.key == 'experience' && s.body.trim().isNotEmpty)) {
      working.add(
        tr
            ? 'Deneyim bölümü standart bir başlıkla ayrılmış.'
            : 'Experience is under a recognizable heading.',
      );
    }
    if (skills.length >= 4) {
      working.add(
        tr
            ? '${skills.length} yetenek ayrı bir bölümde listelenmiş.'
            : '${skills.length} skills are listed in their own section.',
      );
    }
    if (evidence.joinedBody('education').isNotEmpty) {
      working.add(
        tr ? 'Eğitim bölümü tespit edildi.' : 'An education section was detected.',
      );
    }

    final ranked = _rank(findings);
    final topIds = ranked
        .where((f) => f.severity != FindingSeverity.good)
        .take(3)
        .map((f) => f.id)
        .toList();

    return ResumeAnalysis(
      id: const Uuid().v4(),
      resumeId: parsed.resumeId,
      overallScore: overall,
      confidence: ScoreMath.confidenceBand(evidence.parserConfidenceScore),
      categories: scores.entries
          .map(
            (e) => ScoreCategory(
              id: e.key,
              score: e.value,
              weight: ScoreMath.weights[e.key] ?? 0,
              summary: _categorySummary(e.key, profile, tr),
            ),
          )
          .toList(),
      findings: ranked,
      workingWell: working.take(4).toList(),
      topImprovementIds: topIds,
      engineVersion: ScoreMath.engineVersion,
      analyzedAt: DateTime.now().toUtc(),
      fileName: fileName,
    );
  }

  static ParsedResume _parsedFromEvidence(String resumeId, CvEvidence evidence) {
    return ParsedResume(
      resumeId: resumeId,
      confidence: ScoreMath.confidenceBand(evidence.parserConfidenceScore),
      engineVersion: ScoreMath.engineVersion,
      evidence: evidence,
      sections: evidence.sections
          .map(
            (section) => ResumeSection(
              id: section.id,
              key: section.key,
              title: section.title,
              status: section.status,
              preview: _preview(section.body),
              note: section.status == SectionStatus.lowConfidence
                  ? (evidence.detectedLanguage == 'tr'
                        ? 'Başlık tam tanınamadı. Bu bölümü onayla.'
                        : 'Heading confidence is low. Confirm this section.')
                  : null,
            ),
          )
          .toList(),
    );
  }
}

class _Check {
  const _Check({required this.score, this.findings = const []});
  final int score;
  final List<AnalysisFinding> findings;
}

bool _hasMeasure(String text) => RegExp(r'\d').hasMatch(text);

String? _preview(String body) {
  final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.isEmpty) return null;
  if (flat.length <= 140) return flat;
  return '${flat.substring(0, 137)}…';
}

_Check _basicsScore(CvEvidence evidence, AnalysisProfileContext profile) {
  var score = 35;
  final findings = <AnalysisFinding>[];
  final tr = profile.locale.startsWith('tr');
  if (evidence.email != null) {
    score += 25;
  } else {
    findings.add(
      _finding(
        id: 'contact_email',
        title: tr ? 'E-posta bulunamadı' : 'No email detected',
        evidence: tr
            ? 'Çıkarılan metinde e-posta deseni yok.'
            : 'No email pattern was found in the extracted text.',
        action: tr
            ? 'Üst kısma okunabilir bir e-posta ekle.'
            : 'Add a readable email near the top of the CV.',
        category: ScoreCategoryId.basicsContact,
        severity: FindingSeverity.critical,
      ),
    );
  }
  if (evidence.phone != null) score += 15;
  if (evidence.fullName != null) score += 10;
  if (evidence.location != null) score += 8;
  if (evidence.linkedIn != null) {
    score += 7;
  } else {
    findings.add(
      _finding(
        id: 'contact_linkedin',
        title: tr ? 'LinkedIn bağlantısı yok' : 'No LinkedIn link',
        evidence: tr
            ? 'İletişim bilgilerinde LinkedIn profili bulunamadı.'
            : 'No LinkedIn profile was found in the contact details.',
        action: tr
            ? 'Güncel bir LinkedIn profilin varsa bağlantısını ekle.'
            : 'If you keep an up-to-date LinkedIn profile, add the link.',
        category: ScoreCategoryId.basicsContact,
      ),
    );
  }
  if (profile.softwareLike && evidence.github != null) score += 5;
  if (profile.softwareLike && evidence.github == null) {
    findings.add(
      _finding(
        id: 'contact_github',
        title: tr ? 'GitHub bağlantısı yok' : 'GitHub link not detected',
        evidence: tr
            ? 'Yazılım veya veri profili için GitHub isteğe bağlı bir artıdır, zorunluluk değildir.'
            : 'For a software or data profile, GitHub is a bonus, not a requirement.',
        action: tr
            ? 'GitHub kullanıyorsan profil bağlantısını ekle.'
            : 'If you use GitHub, add the profile link.',
        category: ScoreCategoryId.basicsContact,
        severity: FindingSeverity.improve,
      ),
    );
  }
  return _Check(score: ScoreMath.clamp(score), findings: findings);
}

_Check _atsScore(CvEvidence evidence, List<CvTextSection> active, bool tr) {
  final raw = evidence.rawText;
  final standardHeadings = active
      .where((s) => s.key != 'contact' && s.body.trim().isNotEmpty)
      .length;
  final dates = _dateStyles(
    _bodies(evidence, const {'experience', 'volunteer', 'projects'}).join('\n'),
  );
  final datesConsistent = !(dates.monthYear && dates.yearOnly);
  final longestLine = raw
      .split(RegExp(r'\r?\n'))
      .fold<int>(0, (max, l) => l.length > max ? l.length : max);
  final emailIndex = evidence.email == null ? -1 : raw.indexOf(evidence.email!);
  final checks = <bool>[
    raw.trim().length >= 80,
    active.any((s) => s.key == 'experience' || s.key == 'education'),
    evidence.email != null,
    evidence.phone != null,
    RegExp(r'(19|20)\d{2}').hasMatch(raw),
    active.any((s) => s.key == 'skills'),
    _decorativeRatio(raw) < 0.04,
    standardHeadings >= 4,
    datesConsistent,
    longestLine <= 300,
    emailIndex >= 0 && emailIndex <= 400,
  ];
  final passed = checks.where((c) => c).length;
  final score = ScoreMath.clamp((passed / checks.length) * 100);
  final findings = <AnalysisFinding>[];
  if (!checks[1]) {
    findings.add(
      _finding(
        id: 'ats_headings',
        title: tr
            ? 'Standart bölüm başlığı kullan'
            : 'Use a standard section heading',
        evidence: tr
            ? 'Deneyim ve Eğitim başlıklarının ikisi birden tanınmadı.'
            : 'Experience and education headings were not both recognized.',
        action: tr
            ? 'Yaratıcı başlıkları "Deneyim" veya "Eğitim" olarak değiştir.'
            : 'Rename informal headings to Experience or Education.',
        category: ScoreCategoryId.atsCompatibility,
        severity: FindingSeverity.critical,
        before: active.isEmpty ? null : active.first.title,
        after: tr ? 'Deneyim' : 'Experience',
      ),
    );
  }
  if (!checks[6]) {
    findings.add(
      _finding(
        id: 'ats_decorative',
        title: tr
            ? 'Süs karakterleri ayrıştırmayı zorlaştırabilir'
            : 'Decorative characters may confuse parsers',
        evidence: tr
            ? 'Metnin önemli bir kısmı kelime yerine sembol.'
            : 'A high share of the text is symbols rather than words.',
        action: tr
            ? 'Sade başlıklar ve basit madde işaretleri kullan.'
            : 'Prefer plain headings and simple bullets.',
        category: ScoreCategoryId.atsCompatibility,
      ),
    );
  }
  if (!checks[7]) {
    findings.add(
      _finding(
        id: 'ats_few_sections',
        title: tr ? 'Az sayıda bölüm tanındı' : 'Few sections were recognized',
        evidence: tr
            ? 'Yalnızca $standardHeadings dolu bölüm tanındı. ATS sistemleri bilgiyi başlıklara göre ayırır.'
            : 'Only $standardHeadings filled sections were recognized. ATS tools sort information by heading.',
        action: tr
            ? 'Özet, Deneyim, Eğitim ve Yetenekler için ayrı başlıklar kullan.'
            : 'Use separate Summary, Experience, Education and Skills headings.',
        category: ScoreCategoryId.atsCompatibility,
      ),
    );
  }
  if (!checks[8]) {
    findings.add(
      _finding(
        id: 'ats_date_format',
        title: tr ? 'Tarih biçimi tutarsız' : 'Inconsistent date format',
        evidence: tr
            ? 'Bazı tarihler ay ve yılla (${dates.monthExample}), bazıları yalnızca yılla (${dates.yearExample}) yazılmış.'
            : 'Some dates use month and year (${dates.monthExample}), others year only (${dates.yearExample}).',
        action: tr
            ? 'Tüm deneyimlerde aynı biçimi kullan, örneğin "Haz 2025 – Eyl 2025".'
            : 'Use one format for every role, for example "Jun 2025 – Sep 2025".',
        category: ScoreCategoryId.atsCompatibility,
      ),
    );
  }
  if (!checks[9]) {
    findings.add(
      _finding(
        id: 'ats_long_lines',
        title: tr
            ? 'Sütunlar birleşmiş olabilir'
            : 'Columns may have merged',
        evidence: tr
            ? 'Bir satır $longestLine karakter. Bu genelde iki sütunlu veya tablolu düzende görülür.'
            : 'One line is $longestLine characters long, which often comes from two-column or table layouts.',
        action: tr
            ? 'Tek sütunlu, tablosuz bir düzen kullan.'
            : 'Use a single-column layout without tables.',
        category: ScoreCategoryId.atsCompatibility,
        severity: FindingSeverity.critical,
      ),
    );
  }
  return _Check(score: score, findings: findings);
}

final _monthYear = RegExp(
  r'(?<![A-Za-zçğıöşüÇĞİÖŞÜ])(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec|january|february|march|april|june|july|august|september|october|november|december|ocak|şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|ekim|kasım|aralık|oca|şub|nis|haz|tem|ağu|eyl|eki|kas|ara|\d{1,2}[./])\.?\s*(?:19|20)\d{2}\b',
  caseSensitive: false,
);
final _yearRange = RegExp(
  r'(?:^|[\s|(])((?:19|20)\d{2})\s*[-–—]\s*(?:(?:19|20)\d{2}|halen|günümüz|devam|present|current|now)\b',
  caseSensitive: false,
);

({bool monthYear, bool yearOnly, String monthExample, String yearExample})
    _dateStyles(String raw) {
  final month = _monthYear.firstMatch(raw);
  final year = _yearRange.firstMatch(raw);
  return (
    monthYear: month != null,
    yearOnly: year != null,
    monthExample: month?.group(0)?.trim() ?? '',
    yearExample: year?.group(0)?.replaceFirst(RegExp(r'^[\s|(]'), '').trim() ?? '',
  );
}

Iterable<String> _bodies(CvEvidence evidence, Set<String> keys) => evidence
    .sections
    .where((s) => keys.contains(s.key) && s.status != SectionStatus.missing)
    .map((s) => s.body);

_Check _experienceScore(
  CvEvidence evidence,
  List<String> experienceBullets,
  List<String> projectBullets,
  AnalysisProfileContext profile,
) {
  final tr = profile.locale.startsWith('tr');
  final pool = profile.earlyCareer
      ? [...experienceBullets, ...projectBullets]
      : experienceBullets;
  if (pool.isEmpty) {
    final score = profile.earlyCareer ? 48 : 30;
    return _Check(
      score: score,
      findings: [
        _finding(
          id: 'experience_missing_bullets',
          title: profile.earlyCareer
              ? (tr
                    ? 'Proje veya deneyim maddeleri az'
                    : 'Projects or experience bullets are thin')
              : (tr
                    ? 'Deneyim maddeleri bulunamadı'
                    : 'Experience bullets were not detected'),
          evidence: profile.earlyCareer
              ? (tr
                    ? 'Öğrenci ve yeni mezun profillerinde staj ve projeler birlikte değerlendirilir.'
                    : 'Student and early-career scoring looks at projects and internships together.')
              : (tr
                    ? 'Tanınan bir başlık altında deneyim maddesi bulunamadı.'
                    : 'No experience bullets were found under a recognized heading.'),
          action: profile.earlyCareer
              ? (tr
                    ? 'Ne yaptığını anlatan proje veya staj maddeleri ekle.'
                    : 'Add project or internship bullets that describe what you did.')
              : (tr
                    ? 'Deneyim başlığı altına rol maddeleri ekle. İşveren uydurma.'
                    : 'Add role bullets under Experience. Do not invent employers.'),
          category: ScoreCategoryId.experiencePresentation,
          severity: profile.earlyCareer
              ? FindingSeverity.improve
              : FindingSeverity.critical,
        ),
      ],
    );
  }
  final verbHits = pool.where((b) => _startsWithAction(b)).length;
  final measured = pool.where(_hasMeasure).length;
  final longOnes = pool.where((b) => b.length > 220).length;
  final weak = pool.where(PhrasingRules.isWeakOpening).toList();
  var score = 45;
  score += ((verbHits / pool.length) * 25).round();
  score += ((measured / pool.length) * 20).round();
  score -= longOnes * 4;
  score -= (weak.length * 5).clamp(0, 20);
  if (profile.earlyCareer && projectBullets.isNotEmpty) score += 6;
  final findings = <AnalysisFinding>[];
  if (weak.isNotEmpty) {
    findings.add(
      AnalysisFinding(
        id: 'weak_openings',
        severity: weak.length >= 2
            ? FindingSeverity.critical
            : FindingSeverity.improve,
        title: tr
            ? 'Satırlar görevi anlatıyor, katkını değil'
            : 'Lines describe duties, not contributions',
        whyItMatters: tr
            ? '"Sorumluydum" veya "yardımcı oldum" gibi ifadeler ne yaptığını göstermez. İşe alımcı somut eylemi arar.'
            : 'Phrases like "responsible for" or "helped with" hide what you actually did. Recruiters look for the action.',
        evidence: tr
            ? '${weak.length} satır görev ifadesiyle yazılmış. Örnek: "${weak.first}"'
            : '${weak.length} lines use duty phrasing. Example: "${weak.first}"',
        recommendedAction: tr
            ? 'Satırı yaptığın işle başlat. "CV\'mi iyileştir" ekranında her satır için öneri var.'
            : 'Start the line with what you did. "Improve my CV" has a suggestion for each line.',
        categoryId: ScoreCategoryId.experiencePresentation,
        beforeText: weak.first,
      ),
    );
  }
  return _Check(score: ScoreMath.clamp(score), findings: findings);
}

_Check _contentScore(
  List<String> bullets,
  String summary,
  int quantified,
  bool tr,
) {
  var score = 40;
  final findings = <AnalysisFinding>[];
  final length = summary.trim().length;
  if (length >= 120 && length <= 600) {
    score += 20;
  } else if (length >= 40) {
    score += 12;
  } else if (length == 0) {
    score -= 8;
  }
  if (length == 0) {
    findings.add(
      _finding(
        id: 'summary_missing',
        title: tr ? 'Profil özeti yok' : 'No profile summary',
        evidence: tr
            ? 'CV\'nin başında kim olduğunu anlatan bir özet bulunamadı.'
            : 'No summary introducing you was found at the top of the CV.',
        action: tr
            ? 'Hedef rolünü ve en güçlü 2–3 yetkinliğini anlatan 2–3 cümlelik bir özet ekle.'
            : 'Add a 2–3 sentence summary with your target role and strongest 2–3 skills.',
        category: ScoreCategoryId.contentImpact,
      ),
    );
  } else if (length < 120) {
    findings.add(
      _finding(
        id: 'summary_short',
        title: tr ? 'Özet çok kısa' : 'Summary is very short',
        evidence: tr
            ? 'Özet $length karakter. Hedef rol ve öne çıkan yetkinlikler net değil.'
            : 'The summary is $length characters. Target role and key strengths are unclear.',
        action: tr
            ? 'Hedeflediğin rolü ve CV\'nde zaten geçen en güçlü 2–3 yetkinliği ekle.'
            : 'Add your target role and the 2–3 strongest skills already in your CV.',
        category: ScoreCategoryId.contentImpact,
      ),
    );
  }
  if (bullets.isEmpty) {
    return _Check(score: ScoreMath.clamp(score), findings: findings);
  }
  score += ((quantified / bullets.length) * 35).round();
  final uniqueStarts = bullets.map((b) => b.split(' ').first.toLowerCase()).toSet();
  if (uniqueStarts.length >= (bullets.length * 0.6)) score += 8;
  return _Check(score: ScoreMath.clamp(score), findings: findings);
}

_Check _skillsScore(
  List<String> skills,
  CvEvidence evidence,
  AnalysisProfileContext profile,
) {
  var score = skills.isEmpty ? 35 : 55;
  if (skills.length >= 5) score += 20;
  if (skills.length >= 8) score += 8;
  if (evidence.joinedBody('skills').contains(',') ||
      evidence.joinedBody('skills').contains('\n')) {
    score += 8;
  }
  final tr = profile.locale.startsWith('tr');
  final findings = <AnalysisFinding>[];
  if (skills.isEmpty) {
    findings.add(
      _finding(
        id: 'skills_missing',
        title: tr ? 'Yetenekler bölümü zayıf' : 'Skills section is thin',
        evidence: tr
            ? 'Yetenekler başlığı altında bir liste bulunamadı.'
            : 'No skill list was detected under a skills heading.',
        action: profile.fields.isEmpty
            ? (tr
                  ? 'Bir Yetenekler bölümü ekle. Bu skor iş uyumunu değil sunumu ölçer.'
                  : 'Add a Skills section. This score is about presentation, not a job match.')
            : (tr
                  ? 'Seçtiğin alanlarla ilgili, gerçekten kullandığın yetenekleri ekle: ${profile.fields.join(', ')}.'
                  : 'Add skills that match the fields you selected: ${profile.fields.join(', ')}.'),
        category: ScoreCategoryId.skillsRelevance,
      ),
    );
  } else if (skills.length < 5) {
    findings.add(
      _finding(
        id: 'skills_few',
        title: tr ? 'Az sayıda yetenek listelenmiş' : 'Only a few skills are listed',
        evidence: tr
            ? 'Yetenekler bölümünde ${skills.length} madde var.'
            : 'The skills section lists ${skills.length} items.',
        action: tr
            ? 'Projelerinde ve deneyiminde gerçekten kullandığın araçları ekle.'
            : 'Add tools you actually used in your projects and roles.',
        category: ScoreCategoryId.skillsRelevance,
      ),
    );
  }
  return _Check(score: ScoreMath.clamp(score), findings: findings);
}

_Check _structureScore(CvEvidence evidence, List<CvTextSection> active) {
  var score = 50;
  final present = active.where((s) => s.body.trim().isNotEmpty).length;
  score += (present * 5).clamp(0, 30);
  final length = evidence.rawText.length;
  if (length < 200) score -= 15;
  if (length > 12000) score -= 8;
  return _Check(score: ScoreMath.clamp(score));
}

_Check _languageScore(
  List<String> bullets,
  CvEvidence evidence,
  AnalysisProfileContext profile,
) {
  final tr = profile.locale.startsWith('tr');
  var score = 82;
  final findings = <AnalysisFinding>[];
  final firstPerson = bullets.where(PhrasingRules.isFirstPerson).toList();
  if (firstPerson.isNotEmpty) {
    score -= (firstPerson.length * 3).clamp(0, 9);
    findings.add(
      _finding(
        id: 'first_person',
        title: tr ? 'Birinci şahıs kullanılmış' : 'First-person phrasing',
        evidence: tr
            ? '${firstPerson.length} satır "I" veya "My" ile başlıyor. Örnek: "${firstPerson.first}"'
            : '${firstPerson.length} lines start with "I" or "My". Example: "${firstPerson.first}"',
        action: tr
            ? 'CV satırlarını doğrudan eylemle başlat.'
            : 'Start CV lines directly with the action.',
        category: ScoreCategoryId.languageGrammar,
        before: firstPerson.first,
      ),
    );
  }
  if (evidence.detectedLanguage != 'en') {
    final english = bullets.where(PhrasingRules.looksEnglish).toList();
    if (english.isNotEmpty && english.length * 2 < bullets.length) {
      score -= (english.length * 4).clamp(0, 12);
      findings.add(
        _finding(
          id: 'language_mixed',
          title: tr ? 'Türkçe CV\'de İngilizce satırlar var' : 'English lines in a Turkish CV',
          evidence: tr
              ? '${english.length} satır İngilizce yazılmış. Örnek: "${english.first}"'
              : '${english.length} lines are in English. Example: "${english.first}"',
          action: tr
              ? 'CV\'yi tek dilde tut. İngilizce versiyon için Oluşturucu\'daki çeviriyi kullan.'
              : 'Keep the CV in one language. Use the Builder translation for an English version.',
          category: ScoreCategoryId.languageGrammar,
          severity: FindingSeverity.critical,
          before: english.first,
        ),
      );
    }
  }
  final starts = <String, int>{};
  for (final bullet in bullets) {
    final first = bullet
        .replaceFirst(RegExp(r'^[-•*]\s*'), '')
        .split(RegExp(r'\s+'))
        .first
        .toLowerCase();
    if (first.length < 4) continue;
    starts[first] = (starts[first] ?? 0) + 1;
  }
  String? repeated;
  var repeatedCount = 0;
  for (final entry in starts.entries) {
    if (entry.value > repeatedCount) {
      repeated = entry.key;
      repeatedCount = entry.value;
    }
  }
  if (repeated != null && repeatedCount >= 3) {
    score -= 8;
    final shown = repeated[0].toUpperCase() + repeated.substring(1);
    findings.add(
      _finding(
        id: 'language_repeated_verb',
        title: tr ? 'Aynı fiil tekrarlanıyor' : 'Repeated opening verb',
        evidence: tr
            ? '"$shown" $repeatedCount satırda tekrar ediyor.'
            : '"$shown" starts $repeatedCount bullets.',
        action: tr
            ? 'Anlamı netleştirdiği yerlerde farklı fiiller kullan.'
            : 'Vary action verbs where it improves clarity.',
        category: ScoreCategoryId.languageGrammar,
      ),
    );
  }
  final longBullets = bullets.where((b) => b.length > 240).length;
  if (longBullets > 0) score -= longBullets * 3;
  if (profile.cvLanguage == CvLanguagePreference.english &&
      evidence.detectedLanguage == 'tr') {
    score -= 6;
  }
  if (profile.cvLanguage == CvLanguagePreference.turkish &&
      evidence.detectedLanguage == 'en') {
    score -= 6;
  }
  return _Check(score: ScoreMath.clamp(score), findings: findings);
}

double _decorativeRatio(String text) {
  if (text.isEmpty) return 0;
  final decorative = RegExp(r'[|*=_~•▪●]').allMatches(text).length;
  return decorative / text.length;
}

final _actionVerbs = {
  'built',
  'led',
  'developed',
  'designed',
  'created',
  'managed',
  'improved',
  'launched',
  'analyzed',
  'implemented',
  'delivered',
  'owned',
  'reduced',
  'increased',
  'supported',
  'coordinated',
  'wrote',
  'automated',
  'gelistirdim',
  'geliştirdim',
  'yonettim',
  'yönettim',
  'tasarladim',
  'tasarladım',
  'olusturdum',
  'oluşturdum',
  'analiz',
  'uyguladim',
  'hazirladim',
  'hazırladım',
  'destekledim',
};

bool _startsWithAction(String bullet) {
  final word = SectionDetector.fold(
    bullet.replaceFirst(RegExp(r'^[-•*]\s*'), '').split(RegExp(r'\s+')).first,
  );
  return _actionVerbs.contains(word) || word.endsWith('ed') || word.endsWith('dim') || word.endsWith('dum');
}

List<String> _skillTokens(String body) {
  return body
      .split(RegExp(r'[\n,;•|/]+'))
      .map((s) => s.trim())
      .where((s) => s.length >= 2 && s.length <= 40)
      .where((s) => !RegExp(r'^(skills|yetenekler)$', caseSensitive: false).hasMatch(s))
      .toList();
}

AnalysisFinding _finding({
  required String id,
  required String title,
  required String evidence,
  required String action,
  required ScoreCategoryId category,
  FindingSeverity severity = FindingSeverity.improve,
  String? before,
  String? after,
}) {
  return AnalysisFinding(
    id: id,
    severity: severity,
    title: title,
    whyItMatters: action,
    evidence: evidence,
    recommendedAction: action,
    categoryId: category,
    beforeText: before,
    afterText: after,
    supportsAiImprove: before != null && after != null,
  );
}

List<AnalysisFinding> _rank(List<AnalysisFinding> findings) {
  int weight(FindingSeverity severity) => switch (severity) {
    FindingSeverity.critical => 0,
    FindingSeverity.improve => 1,
    FindingSeverity.good => 2,
  };
  final copy = [...findings];
  copy.sort((a, b) => weight(a.severity).compareTo(weight(b.severity)));
  return copy;
}

String _categorySummary(
  ScoreCategoryId id,
  AnalysisProfileContext profile,
  bool tr,
) {
  return switch (id) {
    ScoreCategoryId.atsCompatibility => tr
        ? 'Metinden doğrulanabilen 11 kontrol: başlıklar, iletişim, tarih biçimi, satır uzunluğu, semboller. Görsel düzen ayrıca doğrulanmadı.'
        : '11 checks verifiable from text: headings, contact, date format, line length, symbols. Visual layout was not separately verified.',
    ScoreCategoryId.contentImpact => tr
        ? 'Özet ve maddelerdeki ölçülebilir sonuç oranından hesaplandı.'
        : 'Based on the share of bullets that already contain a measurable result.',
    ScoreCategoryId.experiencePresentation => profile.earlyCareer
        ? (tr
              ? 'Erken kariyer profili: staj, proje ve deneyim maddeleri birlikte değerlendirildi.'
              : 'Early-career profile: internships, projects, and experience bullets were scored together.')
        : (tr
              ? 'Rol maddelerindeki eylem fiili, uzunluk ve sonuç netliği.'
              : 'Action verbs, length, and outcome clarity in role bullets.'),
    ScoreCategoryId.skillsRelevance => profile.fields.isEmpty
        ? (tr
              ? 'İş ilanı olmadığı için bu skor yetenek sunumunu ölçer.'
              : 'Without a target job, this score measures skills presentation.')
        : (tr
              ? 'Seçtiğin alanlara göre yetenek sunumu: ${profile.fields.join(', ')}.'
              : 'Skills presentation in the context of ${profile.fields.join(', ')}.'),
    ScoreCategoryId.structureReadability => tr
        ? 'Tanınan bölüm sayısı ve metin uzunluğundan hesaplandı.'
        : 'Based on recognized sections and overall length.',
    ScoreCategoryId.languageGrammar => tr
        ? 'Tekrarlayan fiiller ve aşırı uzun maddeler kontrol edildi.'
        : 'Repeated opening verbs and overly long bullets were checked.',
    ScoreCategoryId.basicsContact => tr
        ? 'Ad, e-posta, telefon ve bağlantılar metinden okundu.'
        : 'Name, email, phone, and links were read from the text.',
  };
}
