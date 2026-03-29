import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device_status_history.dart';
import '../widgets/shell_menu_leading.dart';

final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

class HistoryDetailScreen extends StatelessWidget {
  final DeviceStatusHistory entry;

  const HistoryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = entry.online ? Colors.green : colorScheme.error;
    return Scaffold(
      appBar: AppBar(
        title: Text("Status Event #${entry.id}"),
        actions: const [ShellMenuAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(
            children: [
              _Row(
                label: 'Status',
                child: Row(
                  children: [
                    Icon(
                      entry.online ? Icons.circle : Icons.circle_outlined,
                      color: color,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.online
                          ? 'Device came online'
                          : 'Device went offline',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _Row(label: 'Network', value: entry.networkName),
              if (entry.deviceNameOrVendor != null)
                _Row(label: 'Device', value: entry.deviceNameOrVendor),
              _Row(
                label: 'Timestamp',
                value: _fmt.format(entry.timestamp.toLocal()),
              ),
              if (entry.ipAddress != null)
                _Row(label: 'IP Address', value: entry.ipAddress!),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.lan_outlined, size: 16),
                  label: const Text('Show network'),
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed('/network', arguments: entry.networkId),
                ),
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
      ),
    );
  }
}

// ─── Shared layout helpers ───────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _Row({required this.label, this.value, this.child})
    : assert(value != null || child != null);

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: labelStyle)),
          Expanded(child: child ?? Text(value!)),
        ],
      ),
    );
  }
}
