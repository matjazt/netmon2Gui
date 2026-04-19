import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import 'constants.dart';

/// Shared date/time formatter used throughout the app.
final kDateTimeFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

/// Formats [dt] in local time as 'yyyy-MM-dd HH:mm:ss'.
/// Returns '-' if [dt] is null.
String formatDateTime(DateTime? dt) =>
    dt != null ? kDateTimeFmt.format(dt.toLocal()) : '-';

/// Returns a human-readable label for an [AlertType].
String alertTypeLabel(AlertType t) => switch (t) {
  AlertType.networkDown => 'Network down',
  AlertType.deviceDown => 'Device down',
  AlertType.deviceUnauthorized => 'Unauthorized device',
  AlertType.unknown => 'Unknown',
};

/// Returns the display colour for a log level integer.
Color logLevelColor(int level) => switch (level) {
  kLogLevelTrace => Colors.grey,
  kLogLevelDebug => Colors.blueGrey,
  kLogLevelInfo => Colors.blue,
  kLogLevelWarn => Colors.orange,
  kLogLevelError => Colors.red,
  _ => Colors.grey,
};
