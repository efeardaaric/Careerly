/// Line-level phrasing checks shared by the local score and AutoFix rules.
/// Backend mirror: `app/optimization/suggestions.py`.
abstract final class PhrasingRules {
  static final bullet = RegExp(r'^\s*(?:[-•*▪●◦–—·]|\d+[.)])\s*');
  static final year = RegExp(r'\b(?:19|20)\d{2}\b');
  static final weakEn = RegExp(
    r'^(?:responsible for|worked on|helped(?: with)?|assisted(?: with| in)?|'
    r'involved in|duties included|tasks included|participated in|in charge of)\b',
    caseSensitive: false,
  );
  static final weakTr = RegExp(
    r'(?:sorumlu(?:ydum|yum)?|görev aldım|yardımcı oldum|destek oldum|katıldım|ilgilendim)',
    caseSensitive: false,
  );
  static final firstPerson = RegExp(r'^(?:I|My)\s+', caseSensitive: false);
  static final _englishWords = RegExp(
    r'\b(?:the|with|and|for|on|to|of|built|worked|developed|managed|created|led|i|my)\b',
    caseSensitive: false,
  );
  static final _turkishLetters = RegExp(r'[çğıöşüÇĞİÖŞÜ]');

  static bool isWeakOpening(String line) =>
      weakEn.hasMatch(line) || weakTr.hasMatch(line);

  static bool isFirstPerson(String line) => firstPerson.hasMatch(line);

  /// English-looking line inside a Turkish CV.
  static bool looksEnglish(String line) =>
      !_turkishLetters.hasMatch(line) &&
      _englishWords.allMatches(line).length >= 2;

  /// Role or project title rows ("Intern | Company | 2025") are not
  /// achievement lines and their years are not measurable results.
  static bool isHeaderLine(String line) {
    final words = line.split(RegExp(r'\s+'));
    return line.length < 20 ||
        words.length < 4 ||
        year.hasMatch(line) ||
        line.contains('|') ||
        line.endsWith(':');
  }

  /// Achievement lines from section bodies, bullet markers stripped.
  static List<String> achievementLines(Iterable<String> bodies) {
    final out = <String>[];
    for (final body in bodies) {
      for (final raw in body.split(RegExp(r'\r?\n'))) {
        final marked = bullet.hasMatch(raw);
        final line = raw.replaceFirst(bullet, '').trim();
        if (line.length < 8 || line.contains('|')) continue;
        if (!marked && isHeaderLine(line)) continue;
        out.add(line);
      }
    }
    return out;
  }
}
