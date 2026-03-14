import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/alert.dart';
import '../models/device_status_history.dart';
import '../providers/auth_provider.dart';
import '../services/device_service.dart';
import '../services/alert_service.dart';
import '../widgets/alert_list_tile.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/error_display.dart';

class DeviceDetailScreen extends StatefulWidget {
  final int deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  final _deviceService = DeviceService();
  final _alertService = AlertService();

  Device? _device;
  List<Alert> _alerts = [];
  List<DeviceStatusHistory> _history = [];
  bool _loading = true;
  String? _error;

  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _deviceService.getDeviceById(widget.deviceId),
        _alertService.getAlertsByDevice(widget.deviceId),
        _deviceService.getDeviceHistory(widget.deviceId),
      ]);
      if (mounted) {
        setState(() {
          _device = results[0] as Device;
          _alerts = results[1] as List<Alert>;
          _history = results[2] as List<DeviceStatusHistory>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load device.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeName() async {
    if (_device == null) return;
    final ctrl = TextEditingController(text: _device!.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename device'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        final updated = await _deviceService.updateDevice(
          _device!.id,
          SaveDeviceRequest(
            name: newName,
            deviceOperationMode: _device!.deviceOperationMode,
          ),
        );
        if (mounted) setState(() => _device = updated);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Rename failed.')));
        }
      }
    }
  }

  Future<void> _changeMode(String mode) async {
    try {
      final updated = await _deviceService.updateDeviceMode(_device!.id, mode);
      if (mounted) setState(() => _device = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mode change failed.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(_device?.name ?? 'Device'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline),
              tooltip: 'Rename',
              onPressed: _changeName,
            ),
            if (_device != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.security),
                tooltip: 'Set operation mode',
                onSelected: _changeMode,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'AUTHORIZED', child: Text('Authorized')),
                  PopupMenuItem(
                    value: 'UNAUTHORIZED',
                    child: Text('Unauthorized'),
                  ),
                  PopupMenuItem(value: 'ALWAYS_ON', child: Text('Always On')),
                ],
              ),
          ],
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Alerts'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorDisplay(message: _error!, onRetry: _load)
          : TabBarView(
              controller: _tabs,
              children: [_buildInfo(), _buildAlerts(), _buildHistory()],
            ),
    );
  }

  Widget _buildInfo() {
    final d = _device!;
    final onlineColor = d.online ? Colors.green : Colors.red;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(
              d.online ? Icons.circle : Icons.circle_outlined,
              color: onlineColor,
            ),
            const SizedBox(width: 8),
            Text(
              d.online ? 'Online' : 'Offline',
              style: TextStyle(color: onlineColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _infoRow('Name', d.name),
        _infoRow('MAC address', d.macAddress),
        if (d.ipAddress != null) _infoRow('IP address', d.ipAddress!),
        if (d.vendor != null) _infoRow('Vendor', d.vendor!),
        _infoRow('Operation mode', d.deviceOperationMode ?? '-'),
        _infoRow('Last seen', d.lastSeen?.toLocal().toString() ?? '-'),
      ],
    );
  }

  Widget _buildAlerts() {
    if (_alerts.isEmpty) return const Center(child: Text('No alerts'));
    return ListView.separated(
      itemCount: _alerts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) => AlertListTile(alert: _alerts[i]),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const Center(child: Text('No history'));
    return ListView.separated(
      itemCount: _history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) => HistoryListTile(entry: _history[i]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
