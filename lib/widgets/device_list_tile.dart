import 'package:flutter/material.dart';
import '../models/device.dart';

/// A list tile for a single device, showing online status, name, MAC, and vendor.
class DeviceListTile extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceListTile({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onlineColor = device.online ? Colors.green : colorScheme.error;
    final hasAlert = device.hasActiveAlert;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: onlineColor.withValues(alpha: 0.15),
        child: Icon(
          device.online ? Icons.devices : Icons.devices_other,
          color: onlineColor,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(device.name, overflow: TextOverflow.ellipsis)),
          if (hasAlert)
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 18,
            ),
        ],
      ),
      subtitle: Text(
        [
          device.macAddress,
          if (device.vendor != null) device.vendor!,
          if (device.ipAddress != null) device.ipAddress!,
        ].join('  ·  '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Chip(
        label: Text(device.online ? 'Online' : 'Offline'),
        backgroundColor: onlineColor.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: onlineColor, fontSize: 12),
        visualDensity: VisualDensity.compact,
      ),
      onTap: onTap,
    );
  }
}
