import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/device_status_history.dart';

final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

/// A compact tile showing one device-status-history row.
class HistoryListTile extends StatelessWidget {
  final DeviceStatusHistory entry;

  const HistoryListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.online ? Colors.green : Colors.red;
    return ListTile(
      dense: true,
      leading: Icon(
        entry.online ? Icons.circle : Icons.circle_outlined,
        color: color,
        size: 16,
      ),
      title: Text(
        entry.online ? 'Came online' : 'Went offline',
        style: TextStyle(color: color),
      ),
      subtitle: Text(
        [
          _fmt.format(entry.timestamp.toLocal()),
          if (entry.ipAddress != null) entry.ipAddress!,
        ].join('  ·  '),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}
