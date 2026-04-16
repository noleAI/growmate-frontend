import 'package:flutter/material.dart';

import '../error/app_exceptions.dart';
import '../widgets/api_error_displayer.dart';

/// Mixin tiện lợi cho Cubit/Bloc để xử lý lỗi API tự động.
///
/// Sử dụng:
/// ```dart
/// class MyCubit extends Cubit<MyState> with ApiErrorHandlerMixin {
///   Future<void> loadData(BuildContext context) async {
///     try {
///       // ...
///     } on AppException catch (e) {
///       handleApiError(context, e);
///     }
///   }
/// }
/// ```
mixin ApiErrorHandlerMixin {
  /// Xử lý lỗi API và hiển thị UI phù hợp.
  ///
  /// Lỗi nghiêm trọng (auth, server 5xx) → dialog.
  /// Lỗi thông thường → snackbar.
  void handleApiError(
    BuildContext context,
    AppException error, {
    VoidCallback? onRetry,
  }) {
    if (_isSevereError(error)) {
      ApiErrorDisplayer.showAlertDialog(
        context: context,
        error: error,
        actionLabel: onRetry != null ? 'Thử lại' : null,
        onAction: onRetry,
      );
    } else {
      ApiErrorDisplayer.showSnackBar(context: context, error: error);
    }
  }

  bool _isSevereError(AppException error) =>
      error is TokenExpiredException ||
      error is UnauthorizedException ||
      error is ServerException ||
      error is ServiceUnavailableException;
}

/// Map error codes → Vietnamese messages thân thiện.
extension AppExceptionViMessage on AppException {
  String get vietnameseMessage {
    return switch (runtimeType) {
      const (ValidationException) =>
        'Dữ liệu không hợp lệ, vui lòng kiểm tra lại',
      const (TokenExpiredException) =>
        'Phiên đăng nhập hết hạn, đăng nhập lại nhé',
      const (UnauthorizedException) =>
        'Phiên đăng nhập hết hạn, đăng nhập lại nhé',
      const (RateLimitException) => 'Bạn thao tác quá nhanh, chờ chút nhé 😊',
      const (ServerException) => 'Hệ thống đang bận, thử lại sau nhé',
      const (ServiceUnavailableException) =>
        'Server đang bảo trì, quay lại sau nhé',
      const (NetworkException) => 'Mất kết nối mạng, kiểm tra internet nhé',
      const (TimeoutException) => 'Kết nối quá chậm, thử lại sau nhé',
      const (NotFoundException) => 'Không tìm thấy dữ liệu yêu cầu',
      _ => message,
    };
  }
}
