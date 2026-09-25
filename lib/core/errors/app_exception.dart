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
