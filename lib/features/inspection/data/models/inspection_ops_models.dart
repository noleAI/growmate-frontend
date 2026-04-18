import 'package:equatable/equatable.dart';

class InspectionRuntimeAlertItem extends Equatable {
  const InspectionRuntimeAlertItem({
    required this.name,
    required this.metric,
    required this.value,
    required this.threshold,
    required this.severity,
    required this.message,
    required this.observedAt,
  });

  final String name;
  final String metric;
  final int value;
  final int threshold;
  final String severity;
  final String message;
  final DateTime observedAt;

  factory InspectionRuntimeAlertItem.fromJson(
    Map<String, dynamic> json, {
    DateTime? observedAt,
  }) {
    return InspectionRuntimeAlertItem(
      name: (json['name'] ?? '').toString(),
      metric: (json['metric'] ?? '').toString(),
      value: _toInt(json['value']) ?? 0,
      threshold: _toInt(json['threshold']) ?? 0,
      severity: (json['severity'] ?? 'info').toString(),
      message: (json['message'] ?? '').toString(),
      observedAt: observedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    name,
    metric,
    value,
    threshold,
    severity,
    message,
    observedAt,
  ];
}

class InspectionRuntimeMetricsSnapshot extends Equatable {
  const InspectionRuntimeMetricsSnapshot({
    required this.metrics,
    required this.observedAt,
  });

  final Map<String, int> metrics;
  final DateTime observedAt;

  factory InspectionRuntimeMetricsSnapshot.fromJson(
    Map<String, dynamic> json, {
    DateTime? observedAt,
  }) {
    return InspectionRuntimeMetricsSnapshot(
      metrics: parseInspectionMetricMap(json['metrics']),
      observedAt: observedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => <Object?>[metrics, observedAt];
}

class InspectionRuntimeAlertsSnapshot extends Equatable {
  const InspectionRuntimeAlertsSnapshot({
    required this.metrics,
    required this.alerts,
    required this.count,
    required this.dispatch,
    required this.dispatchStats,
    required this.observedAt,
  });

  final Map<String, int> metrics;
  final List<InspectionRuntimeAlertItem> alerts;
  final int count;
  final bool dispatch;
  final Map<String, int> dispatchStats;
  final DateTime observedAt;

  factory InspectionRuntimeAlertsSnapshot.fromJson(
    Map<String, dynamic> json, {
    DateTime? observedAt,
  }) {
    final now = observedAt ?? DateTime.now();
    final rawAlerts = json['alerts'];

    final alerts = <InspectionRuntimeAlertItem>[];
    if (rawAlerts is List) {
      for (final item in rawAlerts) {
        if (item is! Map) {
          continue;
        }
        alerts.add(
          InspectionRuntimeAlertItem.fromJson(
            Map<String, dynamic>.from(item),
            observedAt: now,
          ),
        );
      }
    }

    return InspectionRuntimeAlertsSnapshot(
      metrics: parseInspectionMetricMap(json['metrics']),
      alerts: alerts,
      count: _toInt(json['count']) ?? alerts.length,
      dispatch: json['dispatch'] == true,
      dispatchStats: _extractDispatchStats(json),
      observedAt: now,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    metrics,
    alerts,
    count,
    dispatch,
    dispatchStats,
    observedAt,
  ];
}

Map<String, int> parseInspectionMetricMap(dynamic raw) {
  if (raw is! Map) {
    return const <String, int>{};
  }

  final parsed = <String, int>{};
  for (final entry in raw.entries) {
    final metricName = entry.key.toString().trim();
    if (metricName.isEmpty) {
      continue;
    }

    final metricValue = _toInt(entry.value);
    if (metricValue == null) {
      continue;
    }

    parsed[metricName] = metricValue;
  }

  return parsed;
}

Map<String, int> _extractDispatchStats(Map<String, dynamic> json) {
  const keys = <String>[
    'attempted',
    'sent',
    'failed',
    'skipped_rate_limited',
    'skipped_no_webhook',
  ];

  final stats = <String, int>{};
  for (final key in keys) {
    final value = _toInt(json[key]);
    if (value != null) {
      stats[key] = value;
    }
  }

  return stats;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
