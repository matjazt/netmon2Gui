/// Log severity levels as returned by the backend (numeric).
/// Matches standard levels: 0=TRACE, 1=DEBUG, 2=INFO, 3=WARN, 4=ERROR.
/// Display names come from constants.dart logLevelName().
///
/// Mirrors LogDto from /api/logs/*.
class LogEntry {
  final int id;
  final DateTime timestamp;
  final int level;
  final String origin;
  final String message;
  final int? networkId;
  final int? deviceId;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.origin,
    required this.message,
    this.networkId,
    this.deviceId,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    id: json['id'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    level: json['level'] as int,
    origin: json['origin'] as String,
    message: json['message'] as String,
    networkId: json['networkId'] as int?,
    deviceId: json['deviceId'] as int?,
  );
}
