import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device_status_history.dart';
import '../screens/history_detail_screen.dart';

final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

/// A compact tile showing one device-status-history row.
class HistoryListTile extends StatelessWidget {
  final DeviceStatusHistory entry;

  const HistoryListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = entry.online ? Colors.green : colorScheme.error;
    final parts = [
      _fmt.format(entry.timestamp.toLocal()),
      if (entry.networkName != null) entry.networkName!,
      if (entry.ipAddress != null) entry.ipAddress!,
    ];

    final device = entry.deviceNameOrVendor ?? 'Device ${entry.deviceId}';
    return ListTile(
      dense: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HistoryDetailScreen(entry: entry)),
      ),
      leading: Icon(
        entry.online ? Icons.circle : Icons.circle_outlined,
        color: color,
        size: 16,
      ),
      title: Text(
        device + (entry.online ? ' came online' : ' went offline'),
        style: TextStyle(color: color),
      ),
      subtitle: Text(parts.join('  ·  '), style: const TextStyle(fontSize: 11)),
    );
  }
}
