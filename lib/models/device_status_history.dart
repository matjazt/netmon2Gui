/// Mirrors DeviceStatusHistoryDto from /api/device-status-history/*.
class DeviceStatusHistory {
  final int id;
  final int networkId;
  final int deviceId;
  final String? ipAddress;
  final bool online;
  final DateTime timestamp;
  final String? networkName;
  final String? deviceNameOrVendor;

  const DeviceStatusHistory({
    required this.id,
    required this.networkId,
    required this.deviceId,
    this.ipAddress,
    required this.online,
    required this.timestamp,
    this.networkName,
    this.deviceNameOrVendor,
  });

  factory DeviceStatusHistory.fromJson(Map<String, dynamic> json) =>
      DeviceStatusHistory(
        id: json['id'] as int,
        networkId: json['networkId'] as int,
        deviceId: json['deviceId'] as int,
        ipAddress: json['ipAddress'] as String?,
        online: json['online'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
        networkName: json['networkName'] as String?,
        deviceNameOrVendor: json['deviceNameOrVendor'] as String?,
      );
}
