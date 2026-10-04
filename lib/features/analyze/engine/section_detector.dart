import '../domain/analysis_models.dart';

class _Alias {
  const _Alias(this.key, this.phrases, this.titleEn, this.titleTr);
  final String key;
  final List<String> phrases;
  final String titleEn;
  final String titleTr;
}

/// Detects CV sections from plain text using English and Turkish headings.
abstract final class SectionDetector {
  static const _aliases = <_Alias>[
    _Alias('summary', [
      'summary',
      'professional summary',
      'profile',
      'about me',
      'about',
      'objective',
      'ozet',
      'özet',
      'profesyonel ozet',
      'profesyonel özet',
      'profil',
      'hakkimda',
      'hakkımda',
    ], 'Summary', 'Özet'),
    _Alias('experience', [
      'experience',
      'work experience',
      'professional experience',
      'employment',
      'work history',
      'deneyim',
      'is deneyimi',
      'iş deneyimi',
      'profesyonel deneyim',
      'calisma deneyimi',
      'çalışma deneyimi',
    ], 'Experience', 'Deneyim'),
    _Alias('education', [
      'education',
      'academic background',
      'academic history',
      'egitim',
      'eğitim',
      'egitim bilgileri',
      'eğitim bilgileri',
      'akademik gecmis',
      'akademik geçmiş',
    ], 'Education', 'Eğitim'),
    _Alias('projects', [
      'projects',
      'project experience',
      'projeler',
      'proje deneyimi',
    ], 'Projects', 'Projeler'),
    _Alias('skills', [
      'skills',
      'technical skills',
      'core skills',
      'yetenekler',
      'yetkinlikler',
      'teknik yetenekler',
    ], 'Skills', 'Yetenekler'),
    _Alias('certifications', [
      'certifications',
      'certificates',
      'licenses',
      'sertifikalar',
      'sertifikalar ve lisanslar',
    ], 'Certifications', 'Sertifikalar'),
    _Alias('languages', [
      'languages',
      'diller',
      'yabanci diller',
      'yabancı diller',
    ], 'Languages', 'Diller'),
    _Alias('awards', [
      'awards',
      'honors',
      'achievements',
      'oduller',
      'ödüller',
      'basarilar',
      'başarılar',
    ], 'Awards', 'Ödüller'),
    _Alias('volunteer', [
      'volunteer',
      'volunteer experience',
      'volunteering',
      'gonulluluk',
      'gönüllülük',
      'gonullu deneyim',
    ], 'Volunteer', 'Gönüllülük'),
    _Alias('publications', [
      'publications',
      'yayinlar',
      'yayınlar',
    ], 'Publications', 'Yayınlar'),
    _Alias('links', [
      'links',
      'baglantilar',
      'bağlantılar',
    ], 'Links', 'Bağlantılar'),
  ];

  static const coreKeys = [
    'contact',
    'summary',
    'experience',
    'education',
    'projects',
    'skills',
    'certifications',
    'languages',
  ];

  static String fold(String input) {
    const map = {
      'ç': 'c',
      'Ç': 'c',
      'ğ': 'g',
      'Ğ': 'g',
      'ı': 'i',
      'İ': 'i',
      'I': 'i',
      'ö': 'o',
      'Ö': 'o',
      'ş': 's',
      'Ş': 's',
      'ü': 'u',
      'Ü': 'u',
    };
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(map[char] ?? char.toLowerCase());
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? headingKey(String line) => _matchHeading(line)?.key;

  static _Alias? _matchHeading(String line) {
    final folded = fold(line);
    if (folded.isEmpty || folded.length > 48) return null;
    if (RegExp(r'\d{3,}').hasMatch(folded)) return null;
    for (final alias in _aliases) {
      for (final phrase in alias.phrases) {
        final foldedPhrase = fold(phrase);
        if (folded == foldedPhrase) return alias;
      }
    }
    return null;
  }

  static CvEvidence detect({
    required String text,
    required String originalFileName,
    required String displayName,
    bool preferTurkish = false,
  }) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final blocks = <String, StringBuffer>{};
    final headingConfidence = <String, double>{};
    String? current;
    final preamble = StringBuffer();
    var ambiguous = 0;

    for (final line in lines) {
      final alias = _matchHeading(line);
      if (alias != null) {
        if (blocks.containsKey(alias.key)) ambiguous++;
        current = alias.key;
        blocks.putIfAbsent(alias.key, StringBuffer.new);
        headingConfidence[alias.key] = 0.92;
        continue;
      }
      if (current == null) {
        preamble.writeln(line);
      } else {
        blocks[current]!.writeln(line);
      }
    }

    final contact = _contactFrom('${preamble.toString()}\n$text');
    final turkishHints = RegExp(
      r'\b(ve|ile|için|icin|deneyim|eğitim|egitim|öğrenci|ogrenci)\b',
      caseSensitive: false,
    ).allMatches(text).length;
    final englishHints = RegExp(
      r'\b(and|with|experience|education|student|developed)\b',
      caseSensitive: false,
    ).allMatches(text).length;
    final detectedLanguage = turkishHints > englishHints + 2
        ? 'tr'
        : englishHints > turkishHints + 2
        ? 'en'
        : 'mixed';
    final titlesTr = preferTurkish || detectedLanguage == 'tr';

    final sections = <CvTextSection>[];
    sections.add(
      CvTextSection(
        id: 'sec_contact',
        key: 'contact',
        title: titlesTr ? 'İletişim' : 'Contact',
        body: [
          contact.fullName,
          contact.email,
          contact.phone,
          contact.location,
          contact.linkedIn,
          contact.github,
          contact.portfolio,
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        status: contact.email != null || contact.phone != null
            ? SectionStatus.detected
            : SectionStatus.needsReview,
        confidence: contact.email != null ? 0.9 : 0.45,
      ),
    );

    for (final alias in _aliases) {
      final body = blocks[alias.key]?.toString().trim() ?? '';
      final known = blocks.containsKey(alias.key);
      final confidence = headingConfidence[alias.key] ?? 0;
      SectionStatus status;
      if (!known || body.isEmpty) {
        status = SectionStatus.missing;
      } else if (confidence < 0.75 || body.length < 12) {
        status = SectionStatus.lowConfidence;
      } else if (alias.key == 'summary' || alias.key == 'skills') {
        status = SectionStatus.needsReview;
      } else {
        status = SectionStatus.detected;
      }
      if (!coreKeys.contains(alias.key) && status == SectionStatus.missing) {
        continue;
      }
      sections.add(
        CvTextSection(
          id: 'sec_${alias.key}',
          key: alias.key,
          title: titlesTr ? alias.titleTr : alias.titleEn,
          body: body,
          status: status,
          confidence: known ? confidence : 0,
        ),
      );
    }

    final recognized = sections
        .where((s) => s.status != SectionStatus.missing)
        .length;
    final unclassified = preamble.toString().trim().length;
    final total = text.trim().length.clamp(1, 1 << 30);
    final unclassifiedRatio = unclassified / total;
    var score = 40;
    score += ((recognized / coreKeys.length) * 40).round();
    if (contact.email != null) score += 8;
    if (contact.phone != null) score += 4;
    if (unclassifiedRatio > 0.45) score -= 12;
    if (ambiguous > 0) score -= 8 * ambiguous;
    if (RegExp(r'(.)\1{8,}').hasMatch(text)) score -= 10;
    final confidenceScore = score.clamp(0, 100);

    final summaryBody = blocks['summary']?.toString().trim();

    return CvEvidence(
      originalFileName: originalFileName,
      displayName: displayName,
      rawText: text,
      parserConfidenceScore: confidenceScore,
      detectedLanguage: detectedLanguage,
      fullName: contact.fullName,
      email: contact.email,
      phone: contact.phone,
      location: contact.location,
      linkedIn: contact.linkedIn,
      github: contact.github,
      portfolio: contact.portfolio,
      summary: (summaryBody == null || summaryBody.isEmpty) ? null : summaryBody,
      sections: sections,
    );
  }
}

class _Contact {
  const _Contact({
    this.fullName,
    this.email,
    this.phone,
    this.location,
    this.linkedIn,
    this.github,
    this.portfolio,
  });
  final String? fullName;
  final String? email;
  final String? phone;
  final String? location;
  final String? linkedIn;
  final String? github;
  final String? portfolio;
}

_Contact _contactFrom(String text) {
  final email = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  ).firstMatch(text)?.group(0);
  final phone = RegExp(
    r'(?:\+\d{1,3}[\s-]?)?(?:\(?\d{3}\)?[\s-]?)?\d{3}[\s-]?\d{2}[\s-]?\d{2}',
  ).firstMatch(text)?.group(0);
  final linkedIn = RegExp(
    r'(?:https?://)?(?:www\.)?linkedin\.com/in/[A-Za-z0-9\-_%]+',
    caseSensitive: false,
  ).firstMatch(text)?.group(0);
  final github = RegExp(
    r'(?:https?://)?(?:www\.)?github\.com/[A-Za-z0-9\-]+',
    caseSensitive: false,
  ).firstMatch(text)?.group(0);
  final url = RegExp(
    r'https?://[^\s)]+',
    caseSensitive: false,
  ).firstMatch(text)?.group(0);
  final portfolio =
      url != null &&
          !(url.toLowerCase().contains('linkedin.com')) &&
          !(url.toLowerCase().contains('github.com'))
      ? url
      : null;

  String? name;
  final head = text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .take(8);
  for (final line in head) {
    if (line.contains('@')) continue;
    if (RegExp(r'\d{3,}').hasMatch(line)) continue;
    if (SectionDetector._matchHeading(line) != null) continue;
    final words = line.split(RegExp(r'\s+'));
    if (words.length >= 2 && words.length <= 5 && line.length < 48) {
      name = line;
      break;
    }
  }

  String? location;
  for (final line in head) {
    if (line == name || line.contains('@')) continue;
    if (RegExp(
      r'\b(istanbul|ankara|izmir|izmir|london|berlin|remote|türkiye|turkey)\b',
      caseSensitive: false,
    ).hasMatch(line)) {
      location = line;
      break;
    }
  }

  return _Contact(
    fullName: name,
    email: email,
    phone: phone,
    location: location,
    linkedIn: linkedIn,
    github: github,
    portfolio: portfolio,
  );
}
