/// Wrapper cho API response (không dùng freezed vì generic type).
///
/// Format chuẩn từ backend:
/// ```json
/// {
///   "status": "success" | "error",
///   "data": { ... },
///   "message": "string",
///   "meta": { ... }
/// }
/// ```
class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.metadata,
  });

  final String status;
  final T? data;
  final String? message;
  final Map<String, dynamic>? metadata;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(Map<String, dynamic>)? fromJsonT,
  ]) {
    return ApiResponse<T>(
      status: json['status']?.toString() ?? 'unknown',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : json['data'] as T?,
      message: json['message']?.toString(),
      metadata: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson([Object? Function(T)? toJsonT]) {
    return <String, dynamic>{
      'status': status,
      if (data != null) 'data': toJsonT != null ? toJsonT(data as T) : data,
      if (message != null) 'message': message,
      if (metadata != null) 'meta': metadata,
    };
  }

  /// Check nếu response là success
  bool get isSuccess => status == 'success';

  /// Check nếu response là error
  bool get isError => status == 'error';

  @override
  String toString() {
    return 'ApiResponse(status: $status, message: $message)';
  }
}
