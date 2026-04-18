import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/models/agentic_models.dart';
import '../network/api_config.dart';

/// WebSocket service for real-time agentic backend communication.
///
/// Manages two WebSocket connections:
///
/// 1. **Behavior channel** (`/ws/v1/behavior/{sessionId}`)
///    - Sends behavioral signals (typing speed, idle time, correction rate)
///    - Receives `intervention_proposed` events when Particle Filter
///      detects high uncertainty.
///
/// 2. **Dashboard channel** (`/ws/v1/dashboard/stream/{sessionId}`)
///    - Read-only stream of full dashboard payloads after each
///      orchestrator step (academic, empathy, strategy, orchestrator states).
class AgenticWsService {
  AgenticWsService({
    String? wsBaseUrl,
    Future<String?> Function()? getAccessToken,
  }) : _wsBaseUrl = wsBaseUrl ?? _defaultWsBaseUrl,
       _getAccessToken = getAccessToken;

  final String _wsBaseUrl;
  final Future<String?> Function()? _getAccessToken;

  WebSocketChannel? _behaviorChannel;
  WebSocketChannel? _dashboardChannel;

  final _behaviorEventController =
      StreamController<BehaviorWsEvent>.broadcast();
  final _dashboardController = StreamController<DashboardUpdate>.broadcast();

  StreamSubscription? _behaviorSub;
  StreamSubscription? _dashboardSub;

  /// Stream of behavior events (intervention_proposed, hitl_triggered, etc.)
  Stream<BehaviorWsEvent> get behaviorEvents => _behaviorEventController.stream;

  /// Stream of dashboard updates after each orchestrator step.
  Stream<DashboardUpdate> get dashboardUpdates => _dashboardController.stream;

  bool get isBehaviorConnected => _behaviorChannel != null;
  bool get isDashboardConnected => _dashboardChannel != null;

  // ─── Connect ───────────────────────────────────────────────────────────

  /// Opens the behavior telemetry WebSocket for a session.
  Future<void> connectBehavior(String sessionId) async {
    disconnectBehavior();

    final uri = await _buildSessionUri('behavior/$sessionId');
    _log('Connecting behavior WS: $uri');

    _behaviorChannel = WebSocketChannel.connect(uri);

    _behaviorSub = _behaviorChannel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data.toString()) as Map<String, dynamic>;
          final event = BehaviorWsEvent.fromJson(json);
          _behaviorEventController.add(event);
        } catch (e) {
          _log('Behavior WS parse error: $e');
        }
      },
      onError: (Object error) {
        _log('Behavior WS error: $error');
      },
      onDone: () {
        _log('Behavior WS closed');
        _behaviorChannel = null;
      },
    );
  }

  /// Opens the dashboard stream WebSocket for a session.
  Future<void> connectDashboard(String sessionId) async {
    disconnectDashboard();

    final uri = await _buildSessionUri('dashboard/stream/$sessionId');
    _log('Connecting dashboard WS: $uri');

    _dashboardChannel = WebSocketChannel.connect(uri);

    _dashboardSub = _dashboardChannel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data.toString()) as Map<String, dynamic>;
          final update = DashboardUpdate.fromJson(json);
          _dashboardController.add(update);
        } catch (e) {
          _log('Dashboard WS parse error: $e');
        }
      },
      onError: (Object error) {
        _log('Dashboard WS error: $error');
      },
      onDone: () {
        _log('Dashboard WS closed');
        _dashboardChannel = null;
      },
    );
  }

  /// Opens both channels at once for a session.
  Future<void> connectAll(String sessionId) async {
    await Future.wait([
      connectBehavior(sessionId),
      connectDashboard(sessionId),
    ]);
  }

  // ─── Send Signals ──────────────────────────────────────────────────────

  /// Sends a behavioral signal batch to the Particle Filter via WebSocket.
  ///
  /// ```dart
  /// wsService.sendBehaviorSignal({
  ///   'typing_speed': 45.0,
  ///   'idle_time': 12.0,
  ///   'correction_rate': 0.3,
  /// });
  /// ```
  void sendBehaviorSignal(Map<String, dynamic> signal) {
    if (_behaviorChannel == null) {
      _log('Behavior WS not connected, signal dropped');
      return;
    }

    _behaviorChannel!.sink.add(jsonEncode(signal));
  }

  // ─── Disconnect ────────────────────────────────────────────────────────

  void disconnectBehavior() {
    _behaviorSub?.cancel();
    _behaviorSub = null;
    _behaviorChannel?.sink.close();
    _behaviorChannel = null;
  }

  void disconnectDashboard() {
    _dashboardSub?.cancel();
    _dashboardSub = null;
    _dashboardChannel?.sink.close();
    _dashboardChannel = null;
  }

  void disconnectAll() {
    disconnectBehavior();
    disconnectDashboard();
  }

  /// Closes all connections and stream controllers.
  void dispose() {
    disconnectAll();
    _behaviorEventController.close();
    _dashboardController.close();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  static String get _defaultWsBaseUrl {
    final restUrl = ApiConfig.restApiBaseUrl;
    // Convert http(s)://host:port/api/v1 → ws(s)://host:port/ws/v1
    final wsScheme = restUrl.startsWith('https') ? 'wss' : 'ws';
    final uri = Uri.parse(restUrl);
    return '$wsScheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/ws/v1';
  }

  Future<Uri> _buildSessionUri(String path) async {
    final uri = Uri.parse('$_wsBaseUrl/$path');
    final accessToken = await _getAccessToken?.call();
    if (accessToken == null || accessToken.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        'access_token': accessToken,
      },
    );
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('🔌 [WS] $message');
  }
}
