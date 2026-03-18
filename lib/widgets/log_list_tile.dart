import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/log_entry.dart';
import '../utils/constants.dart';

final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

/// Colour-codes the log level label, then shows origin and message.
class LogListTile extends StatelessWidget {
  final LogEntry entry;

  const LogListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(entry.level);
    return ListTile(
      dense: true,
      leading: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: levelColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          logLevelName(entry.level),
          style: TextStyle(
            color: levelColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(entry.message, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          _fmt.format(entry.timestamp.toLocal()),
          if (entry.deviceNameOrVendor != null && entry.networkName != null)
            '${entry.deviceNameOrVendor!} @ ${entry.networkName!}',
          if (entry.deviceNameOrVendor == null && entry.networkName != null)
            entry.networkName!,
          entry.origin,
        ].join('  ·  '),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Color _levelColor(int level) => switch (level) {
    0 => Colors.grey, // TRACE
    1 => Colors.blueGrey, // DEBUG
    2 => Colors.blue, // INFO
    3 => Colors.orange, // WARN
    4 => Colors.red, // ERROR
    _ => Colors.grey,
  };
}
