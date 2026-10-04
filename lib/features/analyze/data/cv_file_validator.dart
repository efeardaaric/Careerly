/// Central CV file rules for Phase 2 upload.
abstract final class CvFileRules {
  static const maxBytes = 10 * 1024 * 1024; // 10 MB
  static const allowedExtensions = <String>{'pdf', 'docx'};

  static bool isAllowedExtension(String extension) {
    return allowedExtensions.contains(extension.toLowerCase());
  }

  static bool isAllowedSize(int bytes) => bytes > 0 && bytes <= maxBytes;
}

enum CvValidationError {
  cancelled,
  unavailable,
  invalidExtension,
  tooLarge,
  emptyFile,
  unreadable,
  scanned,
  unknown,
}

class CvValidationException implements Exception {
  CvValidationException(this.error, {this.detail});

  final CvValidationError error;
  final String? detail;

  @override
  String toString() => 'CvValidationException($error, $detail)';
}

class CvFileValidator {
  const CvFileValidator();

  void validate({
    required String? name,
    required String? extension,
    required int? sizeBytes,
  }) {
    if (name == null || name.trim().isEmpty) {
      throw CvValidationException(CvValidationError.unavailable);
    }
    final ext = (extension ?? '').toLowerCase().replaceAll('.', '');
    if (!CvFileRules.isAllowedExtension(ext)) {
      throw CvValidationException(CvValidationError.invalidExtension);
    }
    final size = sizeBytes ?? 0;
    if (size <= 0) {
      throw CvValidationException(CvValidationError.emptyFile);
    }
    if (!CvFileRules.isAllowedSize(size)) {
      throw CvValidationException(CvValidationError.tooLarge);
    }
  }
}
