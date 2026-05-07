/// A single continuous period for which a device's online state is known.
class TimelineSegment {
  final DateTime start;
  final DateTime end;
  final bool online;

  const TimelineSegment({
    required this.start,
    required this.end,
    required this.online,
  });
}

/// All computed timeline segments for one device within a time range.
class DeviceTimeline {
  final int deviceId;
  final String deviceName;
  final List<TimelineSegment> segments;

  const DeviceTimeline({
    required this.deviceId,
    required this.deviceName,
    required this.segments,
  });

  bool get hasData => segments.isNotEmpty;
}
