/// Mirrors DeviceStatusHistoryDto from /api/device-status-history/*.
class DeviceStatusHistory {
  final int id;
  final int networkId;
  final int deviceId;
  final String? ipAddress;
  final bool online;
  final DateTime timestamp;

  const DeviceStatusHistory({
    required this.id,
    required this.networkId,
    required this.deviceId,
    this.ipAddress,
    required this.online,
    required this.timestamp,
  });

  factory DeviceStatusHistory.fromJson(Map<String, dynamic> json) =>
      DeviceStatusHistory(
        id: json['id'] as int,
        networkId: json['networkId'] as int,
        deviceId: json['deviceId'] as int,
        ipAddress: json['ipAddress'] as String?,
        online: json['online'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
