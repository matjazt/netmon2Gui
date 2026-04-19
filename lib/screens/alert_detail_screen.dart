import 'package:flutter/material.dart';

import '../models/alert.dart';
import '../utils/formatters.dart';
import '../widgets/shell_menu_leading.dart';

class AlertDetailScreen extends StatelessWidget {
  final Alert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final isOpen = alert.isOpen;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = isOpen ? colorScheme.error : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text("Alert #${alert.id}: ${alertTypeLabel(alert.alertType)}"),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOpen
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _Row(label: 'Type', value: alertTypeLabel(alert.alertType)),
              if (alert.networkName != null)
                _Row(
                  label: 'Network',
                  value: alert.networkName,
                  softWrap: true,
                ),
              if (alert.deviceNameOrVendor != null)
                _Row(
                  label: 'Device',
                  value: alert.deviceNameOrVendor,
                  softWrap: true,
                ),
              _Row(label: 'ID', value: '${alert.id}'),
              _Row(label: 'Opened', value: formatDateTime(alert.timestamp)),
              if (alert.closureTimestamp != null)
                _Row(
                  label: 'Closed',
                  value: formatDateTime(alert.closureTimestamp),
                ),
            ],
          ),
          if (alert.message != null) ...[
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                _Row(label: 'Message', value: alert.message, softWrap: true),
              ],
            ),
          ],
          if (alert.networkId != null || alert.deviceId != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (alert.networkId != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.lan_outlined, size: 16),
                      label: const Text('Show network'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed('/network', arguments: alert.networkId),
                    ),
                  if (alert.deviceId != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.devices_outlined, size: 16),
                      label: const Text('Show device'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed('/device', arguments: alert.deviceId),
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

// ─── Shared layout helpers ────────────────────────────────────────────────────

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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child:
                child ??
                Text(
                  value ?? '-',
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
