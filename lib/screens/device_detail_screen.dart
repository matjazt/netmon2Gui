import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/device.dart';
import '../models/device_status_history.dart';
import '../models/log_entry.dart';
import '../models/page_result.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import '../services/device_service.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';
import '../utils/errors.dart';
import '../widgets/alert_list_tile.dart';
import '../widgets/error_display.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/shell_menu_leading.dart';

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
  final _logService = LogService();
  final _historyService = HistoryService();

  Device? _device;
  List<Alert> _alerts = [];
  List<LogEntry> _logs = [];
  List<DeviceStatusHistory> _history = [];
  bool _loading = true;
  String? _error;

  // Pagination state for logs tab
  int _logPage = 0;
  bool _logHasMore = true;
  bool _logLoading = false;

  // Pagination state for history tab
  int _historyPage = 0;
  bool _historyHasMore = true;
  bool _historyLoading = false;

  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
        _logService.getLogsByDevice(widget.deviceId, size: 50),
        _historyService.getByDevice(widget.deviceId, size: 50),
      ]);
      if (mounted) {
        final logPage = results[2] as PageResult<LogEntry>;
        final historyPage = results[3] as PageResult<DeviceStatusHistory>;
        setState(() {
          _device = results[0] as Device;
          _alerts = results[1] as List<Alert>;
          _logs = logPage.content;
          _logPage = logPage.number + 1;
          _logHasMore = !logPage.last;
          _history = historyPage.content;
          _historyPage = historyPage.number + 1;
          _historyHasMore = !historyPage.last;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load device.\n${errorMessage(e)}';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_logLoading || !_logHasMore) return;
    setState(() => _logLoading = true);
    try {
      final result = await _logService.getLogsByDevice(
        widget.deviceId,
        page: _logPage,
        size: 50,
      );
      if (mounted) {
        setState(() {
          _logs.addAll(result.content);
          _logPage = result.number + 1;
          _logHasMore = !result.last;
          _logLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _logLoading = false);
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_historyLoading || !_historyHasMore) return;
    setState(() => _historyLoading = true);
    try {
      final result = await _historyService.getByDevice(
        widget.deviceId,
        page: _historyPage,
        size: 50,
      );
      if (mounted) {
        setState(() {
          _history.addAll(result.content);
          _historyPage = result.number + 1;
          _historyHasMore = !result.last;
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
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
        final updated = await _deviceService.renameDevice(_device!.id, newName);
        if (mounted) setState(() => _device = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Rename failed: ${errorMessage(e)}')));
        }
      }
    }
  }

  Future<void> _showModeDialog() async {
    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Set operation mode'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('AUTHORIZED'),
            child: const Text('Authorized'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('UNAUTHORIZED'),
            child: const Text('Unauthorized'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('ALWAYS_ON'),
            child: const Text('Always On'),
          ),
        ],
      ),
    );
    if (mode != null) _changeMode(mode);
  }

  Future<void> _changeMode(String mode) async {
    try {
      final updated = await _deviceService.updateDeviceMode(_device!.id, mode);
      if (mounted) setState(() => _device = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mode change failed: ${errorMessage(e)}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text("Device #${_device?.id}: ${_device?.name ?? 'Unknown'}"),
        actions: const [ShellMenuAction()],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Alerts'),
            Tab(text: 'Logs'),
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
              children: [
                _buildInfo(isAdmin),
                _buildAlerts(),
                _buildLogs(),
                _buildHistory(),
              ],
            ),
    );
  }

  Widget _buildInfo(bool isAdmin) {
    final d = _device!;
    final onlineColor = d.online ? Colors.green : Colors.red;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoChildRow(
                  'Status',
                  Row(
                    children: [
                      Icon(
                        d.online ? Icons.circle : Icons.circle_outlined,
                        color: onlineColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        d.online ? 'Online' : 'Offline',
                        style: TextStyle(color: onlineColor),
                      ),
                    ],
                  ),
                ),
                _infoRow('Name', d.name),
                _infoRow('ID', '${d.id}'),
                _infoRow('MAC address', d.macAddress),
                if (d.ipAddress != null) _infoRow('IP address', d.ipAddress!),
                if (d.vendor != null) _infoRow('Vendor', d.vendor!),
                _infoRow('Operation mode', d.deviceOperationMode ?? '-'),
                _infoRow('Last seen', d.lastSeen?.toLocal().toString() ?? '-'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.lan_outlined, size: 16),
              label: const Text('Show network'),
              onPressed: () => Navigator.of(
                context,
              ).pushNamed('/network', arguments: d.networkId),
            ),
            if (isAdmin) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.drive_file_rename_outline, size: 16),
                label: const Text('Rename device'),
                onPressed: _changeName,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.security, size: 16),
                label: const Text('Set operation mode'),
                onPressed: _showModeDialog,
              ),
            ],
          ],
        ),
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

  Widget _buildLogs() {
    if (_logs.isEmpty && !_logLoading) {
      return const Center(child: Text('No logs'));
    }
    return ListView.separated(
      itemCount: _logs.length + (_logHasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        if (i == _logs.length) {
          if (!_logLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadMoreLogs();
            });
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return LogListTile(entry: _logs[i]);
      },
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty && !_historyLoading) {
      return const Center(child: Text('No history'));
    }
    return ListView.separated(
      itemCount: _history.length + (_historyHasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        if (i == _history.length) {
          if (!_historyLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadMoreHistory();
            });
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return HistoryListTile(entry: _history[i]);
      },
    );
  }

  Widget _infoRow(String label, String value) =>
      _infoChildRow(label, Text(value));

  Widget _infoChildRow(String label, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}
