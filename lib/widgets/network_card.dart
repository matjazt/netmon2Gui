import 'package:flutter/material.dart';

import '../models/network.dart';

/// A card summarising a single network, displayed in the dashboard grid.
class NetworkCard extends StatelessWidget {
  final Network network;
  final VoidCallback? onTap;

  const NetworkCard({super.key, required this.network, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAlert = network.hasActiveAlert;

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
                    Icon(
                      hasAlert ? Icons.warning_amber_rounded : Icons.lan,
                      color: hasAlert
                          ? colorScheme.onErrorContainer
                          : colorScheme.primary,
                    ),
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
                if (hasAlert) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Active alert',
                    style: TextStyle(color: colorScheme.onErrorContainer),
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
