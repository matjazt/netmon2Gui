import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../screens/log_detail_screen.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Colour-codes the log level label, then shows origin and message.
class LogListTile extends StatelessWidget {
  final LogEntry entry;

  const LogListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final levelColor = logLevelColor(entry.level);
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
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LogDetailScreen(entry: entry))),
      title: Text(entry.message, overflow: TextOverflow.fade),
      subtitle: Text(
        [
          formatDateTime(entry.timestamp),
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
}
