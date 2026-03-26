/// Alert types matching the AlertType enum on the server.
enum AlertType {
  networkDown,
  deviceDown,
  deviceUnauthorized,
  unknown;

  static AlertType fromString(String? s) => switch (s) {
    'NETWORK_DOWN' => AlertType.networkDown,
    'DEVICE_DOWN' => AlertType.deviceDown,
    'DEVICE_UNAUTHORIZED' => AlertType.deviceUnauthorized,
    _ => AlertType.unknown,
  };
}

/// Mirrors AlertDto returned by /api/alerts/*.
class Alert {
  final int id;
  final int? networkId;
  final int? deviceId;
  final AlertType alertType;
  final String? message;
  final DateTime timestamp;
  final DateTime? closureTimestamp;
  final String? networkName;
  final String? deviceNameOrVendor;

  const Alert({
    required this.id,
    this.networkId,
    this.deviceId,
    required this.alertType,
    this.message,
    required this.timestamp,
    this.closureTimestamp,
    this.networkName,
    this.deviceNameOrVendor,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'] as int,
    networkId: json['networkId'] as int?,
    deviceId: json['deviceId'] as int?,
    alertType: AlertType.fromString(json['alertType'] as String?),
    message: json['message'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    closureTimestamp: json['closureTimestamp'] != null
        ? DateTime.parse(json['closureTimestamp'] as String)
        : null,
    networkName: json['networkName'] as String?,
    deviceNameOrVendor: json['deviceNameOrVendor'] as String?,
  );

  bool get isOpen => closureTimestamp == null;
}
