import 'package:dio/dio.dart';

/// Domain-facing error type. Keep UI free of Dio types.
class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.cause,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? cause;

  bool get isRateLimited => statusCode == 429;

  factory AppException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final parsed = _backendError(error.response?.data);
    if (parsed != null) {
      return AppException(
        message: parsed.$2,
        statusCode: status,
        code: parsed.$1,
        cause: error,
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return AppException(
        message: "Couldn't connect to Careerly. Check your connection.",
        statusCode: status,
        code: 'NETWORK_ERROR',
        cause: error,
      );
    }
    if (status == 429) {
      return AppException(
        message: 'Too many requests. Please wait a moment and try again.',
        statusCode: 429,
        code: 'rate_limited',
        cause: error,
      );
    }
    if (status == 401) {
      return AppException(
        message: 'Session expired or unauthorized. Please sign in again.',
        statusCode: 401,
        code: 'unauthorized',
        cause: error,
      );
    }
    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'Request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to reach the server. Check your connection.',
      DioExceptionType.badResponse =>
        'Server error${status != null ? ' ($status)' : ''}.',
      DioExceptionType.cancel => 'Request was cancelled.',
      _ => 'Something went wrong. Please try again.',
    };
    return AppException(
      message: message,
      statusCode: status,
      code: error.type.name,
      cause: error,
    );
  }

  @override
  String toString() => 'AppException($code, $statusCode): $message';
}

(String, String)? _backendError(Object? data) {
  if (data is! Map) return null;
  final error = data['error'];
  if (error is Map && error['code'] is String) {
    final message = error['message'];
    return (
      error['code'] as String,
      message is String ? message : 'Analysis failed.',
    );
  }
  final detail = data['detail'];
  if (detail is Map && detail['code'] is String) {
    final message = detail['message'];
    return (
      detail['code'] as String,
      message is String ? message : 'Analysis failed.',
    );
  }
  return null;
}

/// Maps stable backend codes onto existing Analyze localization keys.
String messageKeyForBackendCode(String? code) {
  return switch (code) {
    'CV_TOO_LARGE' => 'analyzeErrorTooLarge',
    'UNSUPPORTED_CV_TYPE' => 'analyzeErrorExtension',
    'SCANNED_DOCUMENT_DETECTED' => 'analyzeErrorScanned',
    'CV_TEXT_EXTRACTION_FAILED' ||
    'CV_EXTRACTION_FAILED' => 'analyzeErrorUnreadable',
    'NETWORK_ERROR' => 'analyzeErrorUnavailable',
    _ => 'analyzeErrorGeneric',
  };
}
