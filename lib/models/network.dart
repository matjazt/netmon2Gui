import 'dart:convert';

/// Mirrors NetworkDto from the REST API.
class Network {
  final int id;
  final String name;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final int? activeAlertId;
  final String configuration; // raw JSON string
  final DateTime? backOnlineTime;

  const Network({
    required this.id,
    required this.name,
    this.firstSeen,
    this.lastSeen,
    this.activeAlertId,
    this.configuration = '{}',
    this.backOnlineTime,
  });

  factory Network.fromJson(Map<String, dynamic> json) => Network(
        id: json['id'] as int,
        name: json['name'] as String,
        firstSeen: json['firstSeen'] != null
            ? DateTime.parse(json['firstSeen'] as String)
            : null,
        lastSeen: json['lastSeen'] != null
            ? DateTime.parse(json['lastSeen'] as String)
            : null,
        activeAlertId: json['activeAlertId'] as int?,
        configuration: json['configuration'] as String? ?? '{}',
        backOnlineTime: json['backOnlineTime'] != null
            ? DateTime.parse(json['backOnlineTime'] as String)
            : null,
      );

  /// Convenience: parse the embedded JSON configuration string.
  NetworkConfiguration get config =>
      NetworkConfiguration.fromJson(
        jsonDecode(configuration) as Map<String, dynamic>,
      );

  bool get hasActiveAlert => activeAlertId != null;
}

/// Typed representation of the JSON stored in Network.configuration.
class NetworkConfiguration {
  final int? reportingInterval; // seconds between scanner publishes (required)
  final int? alertingDelay; // seconds before absence triggers alert (required)
  final String? notificationEmailAddress;
  final String? reminderTimeOfDay; // "HH:mm"
  final int? reminderIntervalDays;
  final String timezone; // IANA timezone id, e.g. "Europe/Ljubljana"

  const NetworkConfiguration({
    this.reportingInterval,
    this.alertingDelay,
    this.notificationEmailAddress,
    this.reminderTimeOfDay,
    this.reminderIntervalDays,
    this.timezone = 'UTC',
  });

  factory NetworkConfiguration.fromJson(Map<String, dynamic> json) =>
      NetworkConfiguration(
        reportingInterval: json['reportingInterval'] as int?,
        alertingDelay: json['alertingDelay'] as int?,
        notificationEmailAddress: json['notificationEmailAddress'] as String?,
        reminderTimeOfDay: json['reminderTimeOfDay'] as String?,
        reminderIntervalDays: json['reminderIntervalDays'] as int?,
        timezone: json['timezone'] as String? ?? 'UTC',
      );

  Map<String, dynamic> toJson() => {
        'reportingInterval': reportingInterval,
        'alertingDelay': alertingDelay,
        if (notificationEmailAddress != null)
          'notificationEmailAddress': notificationEmailAddress,
        if (reminderTimeOfDay != null) 'reminderTimeOfDay': reminderTimeOfDay,
        if (reminderIntervalDays != null)
          'reminderIntervalDays': reminderIntervalDays,
        'timezone': timezone,
      };
}
