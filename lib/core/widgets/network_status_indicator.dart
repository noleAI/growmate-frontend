import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Widget hiển thị trạng thái kết nối mạng.
///
/// Tự động hiển thị banner khi mất internet
/// và ẩn khi có lại.
class NetworkStatusIndicator extends StatefulWidget {
  const NetworkStatusIndicator({super.key});

  @override
  State<NetworkStatusIndicator> createState() =>
      _NetworkStatusIndicatorState();

  /// Static method để check nhanh có mạng không
  static Future<bool> get isConnected async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any(
        (result) => result != ConnectivityResult.none,
      );
    } catch (_) {
      return false;
    }
  }
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _subscribeToConnectivityChanges();
  }

  Future<void> _checkInitialStatus() async {
    final connected = await NetworkStatusIndicator.isConnected;
    if (mounted) {
      setState(() => _isOffline = !connected);
    }
  }

  void _subscribeToConnectivityChanges() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;

      final isNowOffline = results.every(
        (result) => result == ConnectivityResult.none,
      );

      setState(() => _isOffline = isNowOffline);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) {
      return const SizedBox.shrink();
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _isOffline ? Offset.zero : const Offset(0, -1),
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Không có kết nối internet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
