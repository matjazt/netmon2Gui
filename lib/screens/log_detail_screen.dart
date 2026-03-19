import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/log_entry.dart';
import '../utils/constants.dart';
import '../widgets/shell_menu_leading.dart';

final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

class LogDetailScreen extends StatelessWidget {
  final LogEntry entry;

  const LogDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(entry.level);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Entry'),
        actions: const [ShellMenuAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(
            children: [
              _Row(
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
              _Row(
                label: 'Timestamp',
                value: _fmt.format(entry.timestamp.toLocal()),
              ),
              _Row(label: 'Origin', value: entry.origin, softWrap: true),
              _Row(label: 'Network', value: entry.networkName, softWrap: true),
              if (entry.deviceNameOrVendor != null)
                _Row(
                  label: 'Device',
                  value: entry.deviceNameOrVendor,
                  softWrap: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            children: [
              _Row(label: 'Message', value: entry.message, softWrap: true),
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

  Color _levelColor(int level) => switch (level) {
    kLogLevelTrace => Colors.grey,
    kLogLevelDebug => Colors.blueGrey,
    kLogLevelInfo => Colors.blue,
    kLogLevelWarn => Colors.orange,
    kLogLevelError => Colors.red,
    _ => Colors.grey,
  };
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
  final bool softWrap;

  const _Row({
    required this.label,
    this.value,
    this.child,
    this.softWrap = false,
  }) : assert(value != null || child != null);

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
          Expanded(
            child:
                child ??
                Text(
                  value!,
                  softWrap: softWrap,
                  overflow: softWrap
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
          ),
        ],
      ),
    );
  }
}
