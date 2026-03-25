/// ─── API Response Wrapper ───────────────────────────────────
/// Typed wrapper for standardized backend responses.
/// The backend always returns: { status, data, error }
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final ApiError? error;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) => ApiResponse._(
        isSuccess: true,
        data: data,
      );

  factory ApiResponse.failure(ApiError error) => ApiResponse._(
        isSuccess: false,
        error: error,
      );

  /// Parse a raw API response map
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> data) fromData,
  ) {
    if (json['status'] == 'success') {
      return ApiResponse.success(fromData(json['data'] as Map<String, dynamic>));
    }

    final errorMap = json['error'] as Map<String, dynamic>? ?? {};
    return ApiResponse.failure(ApiError(
      code: errorMap['code'] as String? ?? 'UNKNOWN',
      message: errorMap['message'] as String? ?? 'An error occurred',
    ));
  }
}

class ApiError {
  final String code;
  final String message;

  const ApiError({required this.code, required this.message});

  @override
  String toString() => '$code: $message';
}

/// Pagination metadata from the backend
class PaginationMeta {
  final bool hasMore;
  final String? nextCursor;
  final int count;

  const PaginationMeta({
    required this.hasMore,
    this.nextCursor,
    required this.count,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      hasMore: json['hasMore'] as bool? ?? false,
      nextCursor: json['nextCursor'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}
