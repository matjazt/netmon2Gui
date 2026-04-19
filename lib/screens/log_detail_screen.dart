import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/detail_card.dart';
import '../widgets/shell_menu_leading.dart';

class LogDetailScreen extends StatelessWidget {
  final LogEntry entry;

  const LogDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final levelColor = logLevelColor(entry.level);
    return Scaffold(
      appBar: AppBar(
        title: Text("Log Entry #${entry.id}"),
        actions: const [ShellMenuAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailCard(
            children: [
              DetailRow(
                label: 'Level',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    logLevelName(entry.level),
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DetailRow(
                label: 'Timestamp',
                value: formatDateTime(entry.timestamp),
              ),
              DetailRow(label: 'Origin', value: entry.origin, softWrap: true),
              DetailRow(
                label: 'Network',
                value: entry.networkName,
                softWrap: true,
              ),
              if (entry.deviceNameOrVendor != null)
                DetailRow(
                  label: 'Device',
                  value: entry.deviceNameOrVendor,
                  softWrap: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          DetailCard(
            children: [
              DetailRow(label: 'Message', value: entry.message, softWrap: true),
            ],
          ),
          if (entry.networkId != null || entry.deviceId != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (entry.networkId != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.lan_outlined, size: 16),
                      label: const Text('Show network'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed('/network', arguments: entry.networkId),
                    ),
                  if (entry.deviceId != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.devices_outlined, size: 16),
                      label: const Text('Show device'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed('/device', arguments: entry.deviceId),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
