import 'package:flutter/material.dart';

import '../models/network.dart';

/// A card summarising a single network, displayed in the dashboard.
class NetworkCard extends StatelessWidget {
  final Network network;
  final VoidCallback? onTap;
  final int? onlineCount;
  final int? offlineCount;
  final int? alertCount;

  const NetworkCard({
    super.key,
    required this.network,
    this.onTap,
    this.onlineCount,
    this.offlineCount,
    this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAlert =
        (alertCount != null && alertCount! > 0) || network.hasActiveAlert;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: hasAlert ? colorScheme.errorContainer : null,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: hasAlert ? colorScheme.error : colorScheme.primary,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lan, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        network.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (onlineCount != null ||
                    offlineCount != null ||
                    alertCount != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (onlineCount != null)
                        _StatItem(
                          icon: Icons.check_circle_outline,
                          label: '$onlineCount online',
                          color: colorScheme.onSurface,
                        ),
                      if (offlineCount != null)
                        _StatItem(
                          icon: Icons.cancel_outlined,
                          label: '$offlineCount offline',
                          color: colorScheme.onSurface,
                        ),
                      if (alertCount != null)
                        _StatItem(
                          icon: Icons.warning_amber_rounded,
                          label:
                              '$alertCount alert${alertCount == 1 ? '' : 's'}',
                          color: alertCount! > 0
                              ? colorScheme.error
                              : colorScheme.onSurface,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
