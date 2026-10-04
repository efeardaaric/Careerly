/// Turns raw picker names into a human title without dropping the original.
abstract final class CvDisplayName {
  static String normalize(String fileName) {
    var name = fileName.trim();
    if (name.isEmpty) return 'CV';
    var previous = '';
    while (name != previous) {
      previous = name;
      name = name.replaceFirst(
        RegExp(r'\.(pdf|docx|doc)$', caseSensitive: false),
        '',
      );
      name = name.replaceFirst(RegExp(r'\s*\(\d+\)\s*$'), '');
      name = name.trim();
    }
    name = name.replaceAll(RegExp(r'[_]+'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name.isEmpty ? 'CV' : name;
  }

  static String sizeLabel(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    final kb = (bytes / 1024).round();
    return '$kb KB';
  }
}
