import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/analysis_models.dart';
import '../domain/resume_analysis_repository.dart';
import '../engine/cv_text_extractor.dart';
import '../engine/local_cv_analysis_engine.dart';
import 'cv_file_validator.dart';

/// On-device parse and score. Does not call a model and does not use fixtures.
class LocalResumeAnalysisRepository implements ResumeAnalysisRepository {
  LocalResumeAnalysisRepository({
    this.readProfile = _emptyProfile,
    this._validator = const CvFileValidator(),
  });

  final AnalysisProfileContext Function() readProfile;
  final CvFileValidator _validator;

  @override
  Future<void> validateCvFile(SelectedCvFile file) async {
    _validator.validate(
      name: file.name,
      extension: file.extension,
      sizeBytes: file.sizeBytes,
    );
    if (file.bytes == null || file.bytes!.isEmpty) {
      throw CvValidationException(CvValidationError.unavailable);
    }
  }

  @override
  Future<ParsedResume> parseResume(
    SelectedCvFile file, {
    void Function(AnalysisProcessingStage stage)? onStage,
  }) async {
    await validateCvFile(file);
    onStage?.call(AnalysisProcessingStage.readingStructure);
    final payload = await compute(extractCvTextPayload, {
      'ext': file.extension,
      'bytes': file.bytes!,
    });
    final error = payload['error'] as String?;
    if (error == 'unsupported') {
      throw CvValidationException(CvValidationError.invalidExtension);
    }
    if (error != null) {
      throw CvValidationException(CvValidationError.unreadable);
    }
    if (payload['scanned'] == true) {
      throw CvValidationException(CvValidationError.scanned);
    }
    final text = payload['text'] as String? ?? '';
    if (text.trim().length < 20) {
      throw CvValidationException(CvValidationError.unreadable);
    }
    onStage?.call(AnalysisProcessingStage.detectingSections);
    final profile = readProfile();
    final resumeId = const Uuid().v4();
    return LocalCvAnalysisEngine.parseText(
      text: text,
      originalFileName: file.name,
      resumeId: resumeId,
      preferTurkish:
          profile.locale.startsWith('tr') ||
          profile.cvLanguage?.name == 'turkish',
    );
  }

  @override
  Future<ResumeAnalysis> analyzeResume({
    required SelectedCvFile file,
    required ParsedResume parsed,
  }) async {
    final evidence = parsed.evidence;
    return LocalCvAnalysisEngine.score(
      parsed: parsed,
      fileName: evidence?.displayName ?? file.name,
      profile: readProfile(),
    );
  }
}

AnalysisProfileContext _emptyProfile() => const AnalysisProfileContext();

/// Top-level so it can run off the UI isolate. Returns only text, never logs it.
Map<String, Object?> extractCvTextPayload(Map<String, Object?> input) {
  try {
    final result = const CvTextExtractor().extract(
      extension: input['ext'] as String? ?? '',
      bytes: (input['bytes'] as List).cast<int>(),
    );
    return {
      'text': result.text,
      'scanned': result.likelyScanned,
    };
  } on CvExtractException catch (error) {
    return {'error': error.code};
  } catch (_) {
    return {'error': 'unreadable'};
  }
}
