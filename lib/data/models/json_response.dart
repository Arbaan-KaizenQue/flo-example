import 'package:equatable/equatable.dart';

/// [JsonResponse] — universal wrapper returned by every service / repository.
/// Mirrors the CLAUDE.md `JsonResponse` contract: a success/failure flag,
/// human-readable message, optional HTTP-style status code, and optional
/// parsed [data] payload (caller casts to the expected type).
class JsonResponse extends Equatable {
  const JsonResponse._({
    required this.success,
    required this.message,
    this.statusCode,
    this.data,
  });

  factory JsonResponse.success({String message = '', Object? data}) =>
      JsonResponse._(success: true, message: message, data: data);

  factory JsonResponse.failure({
    required String message,
    int statusCode = 500,
  }) =>
      JsonResponse._(
        success: false,
        message: message,
        statusCode: statusCode,
      );

  final bool success;
  final String message;
  final int? statusCode;
  final Object? data;

  @override
  List<Object?> get props => [success, message, statusCode, data];
}
