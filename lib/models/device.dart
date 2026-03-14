/// Mirrors DeviceDto returned by the REST API.
class Device {
  final int id;
  final int networkId;
  final String name;
  final String macAddress;
  final String? ipAddress;
  final bool online;
  final DateTime? lastSeen;
  final String? deviceOperationMode;
  final int? activeAlertId;
  final String? vendor;

  const Device({
    required this.id,
    required this.networkId,
    required this.name,
    required this.macAddress,
    this.ipAddress,
    this.online = false,
    this.lastSeen,
    this.deviceOperationMode,
    this.activeAlertId,
    this.vendor,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] as int,
    networkId: json['networkId'] as int,
    name: json['name'] as String,
    macAddress: json['macAddress'] as String,
    ipAddress: json['ipAddress'] as String?,
    online: json['online'] as bool? ?? false,
    lastSeen: json['lastSeen'] != null
        ? DateTime.parse(json['lastSeen'] as String)
        : null,
    deviceOperationMode: json['deviceOperationMode'] as String?,
    activeAlertId: json['activeAlertId'] as int?,
    vendor: json['vendor'] as String?,
  );

  bool get hasActiveAlert => activeAlertId != null;
}

/// Sent to POST or PUT /api/devices. Only name and mode are editable via UI.
class SaveDeviceRequest {
  final String name;
  final String? deviceOperationMode;

  const SaveDeviceRequest({required this.name, this.deviceOperationMode});

  Map<String, dynamic> toJson() => {
    'name': name,
    if (deviceOperationMode != null) 'deviceOperationMode': deviceOperationMode,
  };
}

/// Aggregated counts returned by GET /api/devices/stats/{networkId}.
class DeviceStats {
  final int total;
  final int online;
  final int offline;

  const DeviceStats({
    required this.total,
    required this.online,
    required this.offline,
  });

  factory DeviceStats.fromJson(Map<String, dynamic> json) => DeviceStats(
    total: json['total'] as int? ?? 0,
    online: json['online'] as int? ?? 0,
    offline: json['offline'] as int? ?? 0,
  );
}
