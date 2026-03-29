import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../screens/alert_detail_screen.dart';

final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

/// A list tile for a single alert entry.
class AlertListTile extends StatelessWidget {
  final Alert alert;

  const AlertListTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final isOpen = alert.isOpen;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isOpen ? colorScheme.error : Colors.green;

    final subject =
        (alert.deviceNameOrVendor != null && alert.networkName != null)
        ? '${alert.deviceNameOrVendor!} @ ${alert.networkName!}'
        : alert.deviceNameOrVendor ?? alert.networkName ?? '';
    return ListTile(
      leading: Icon(
        isOpen ? Icons.warning_amber_rounded : Icons.check_circle_outline,
        color: color,
      ),
      title: Text(
        '${_alertTypeLabel(alert.alertType)}${subject.isNotEmpty ? ': $subject' : ''}',
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _fmt.format(alert.timestamp.toLocal()),
          if (alert.closureTimestamp != null)
            'closed at ${_fmt.format(alert.closureTimestamp!.toLocal())}',
          if (alert.message != null) alert.message!,
        ].join('  ·  '),
      ),
      trailing: Chip(
        label: Text(isOpen ? 'Open' : 'Closed'),
        backgroundColor: color.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: color, fontSize: 12),
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: alert)),
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
