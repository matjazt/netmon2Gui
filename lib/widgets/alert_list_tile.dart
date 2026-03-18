import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';

final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

/// A list tile for a single alert entry.
class AlertListTile extends StatelessWidget {
  final Alert alert;

  const AlertListTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final isOpen = alert.isOpen;
    final color = isOpen ? Colors.orange : Colors.green;

    return ListTile(
      leading: Icon(
        isOpen ? Icons.warning_amber_rounded : Icons.check_circle_outline,
        color: color,
      ),
      title: Text(
        _alertTypeLabel(alert.alertType),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _fmt.format(alert.timestamp.toLocal()) +
            (alert.message != null ? '  ·  ${alert.message}' : ''),
      ),
      trailing: Chip(
        label: Text(isOpen ? 'Open' : 'Closed'),
        backgroundColor: color.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: color, fontSize: 12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _alertTypeLabel(AlertType t) => switch (t) {
    AlertType.networkDown => 'Network down',
    AlertType.deviceDown => 'Device down',
    AlertType.deviceUnauthorized => 'Unauthorized device',
    AlertType.unknown => 'Unknown',
  };
}
