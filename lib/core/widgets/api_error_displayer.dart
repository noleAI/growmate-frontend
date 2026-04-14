import 'package:flutter/material.dart';

import '../../app/i18n/build_context_i18n.dart';
import '../error/app_exceptions.dart';

/// Helper hiển thị error messages từ AppException.
///
/// Dùng để show snackbars hoặc dialogs thân thiện khi có lỗi API.
class ApiErrorDisplayer {
  ApiErrorDisplayer._();

  /// Show snackbar cho lỗi nhẹ (network, timeout, validation)
  static void showSnackBar({
    required BuildContext context,
    required AppException error,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForException(error),
              color: theme.colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.errorContainer,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: error.details != null && error.details!.isNotEmpty
            ? SnackBarAction(
                label: context.t(vi: 'Chi tiết', en: 'Details'),
                textColor: theme.colorScheme.onErrorContainer,
                onPressed: () => _showDetailsDialog(context, error),
              )
            : null,
      ),
    );
  }

  /// Show dialog cho lỗi nghiêm trọng (server error, unauthorized)
  static Future<void> showAlertDialog({
    required BuildContext context,
    required AppException error,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(_getIconForException(error)),
        title: Text(_getTitleForException(context, error)),
        content: Text(error.message),
        actions: [
          if (error.details != null && error.details!.isNotEmpty)
            TextButton(
              onPressed: () => _showDetailsDialog(context, error),
              child: Text(context.t(vi: 'Chi tiết', en: 'Details')),
            ),
          if (onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onAction();
              },
              child: Text(actionLabel ?? context.t(vi: 'Thử lại', en: 'Retry')),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              context.t(vi: 'Đóng', en: 'Close'),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Tự động chọn cách hiển thị lỗi phù hợp
  static void display({
    required BuildContext context,
    required AppException error,
    VoidCallback? onRetry,
  }) {
    // Lỗi nghiêm trọng → dialog
    if (error is ServerException ||
        error is ServiceUnavailableException ||
        error is UnauthorizedException) {
      showAlertDialog(context: context, error: error, onAction: onRetry);
      return;
    }

    // Lỗi nhẹ → snackbar
    showSnackBar(context: context, error: error);
  }

  static void _showDetailsDialog(BuildContext context, AppException error) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t(vi: 'Chi tiết lỗi', en: 'Error details')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.t(vi: 'Mã lỗi', en: 'Error code')}: ${error.code}',
              ),
              if (error.statusCode != null)
                Text('HTTP Status: ${error.statusCode}'),
              const SizedBox(height: 8),
              if (error.details != null && error.details!.isNotEmpty)
                Text(
                  '${context.t(vi: 'Chi tiết', en: 'Details')}: ${error.details}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.t(vi: 'Đóng', en: 'Close')),
          ),
        ],
      ),
    );
  }

  static IconData _getIconForException(AppException error) {
    if (error is NetworkException || error is TimeoutException) {
      return Icons.wifi_off_rounded;
    }
    if (error is UnauthorizedException || error is TokenExpiredException) {
      return Icons.lock_outline_rounded;
    }
    if (error is ValidationException) {
      return Icons.edit_note_rounded;
    }
    if (error is ServerException || error is ServiceUnavailableException) {
      return Icons.cloud_off_rounded;
    }
    if (error is RateLimitException) {
      return Icons.hourglass_empty_rounded;
    }
    return Icons.error_outline_rounded;
  }

  static String _getTitleForException(
    BuildContext context,
    AppException error,
  ) {
    if (error is NetworkException) {
      return context.t(vi: 'Lỗi kết nối', en: 'Connection error');
    }
    if (error is TimeoutException) {
      return context.t(vi: 'Hết thời gian chờ', en: 'Request timed out');
    }
    if (error is UnauthorizedException || error is TokenExpiredException) {
      return context.t(vi: 'Phiên hết hạn', en: 'Session expired');
    }
    if (error is ValidationException) {
      return context.t(vi: 'Dữ liệu không hợp lệ', en: 'Invalid data');
    }
    if (error is ServerException || error is ServiceUnavailableException) {
      return context.t(vi: 'Lỗi hệ thống', en: 'System error');
    }
    if (error is RateLimitException) {
      return context.t(vi: 'Quá tải', en: 'Rate limit reached');
    }
    return context.t(vi: 'Có lỗi xảy ra', en: 'An error occurred');
  }
}
