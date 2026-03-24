import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/device.dart';
import '../models/device_status_history.dart';
import '../models/log_entry.dart';
import '../models/network.dart';
import '../models/page_result.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import '../services/device_service.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';
import '../services/network_service.dart';
import '../utils/errors.dart';
import '../widgets/alert_list_tile.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/error_display.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/network_config_form.dart';
import '../widgets/shell_menu_leading.dart';

class NetworkDetailScreen extends StatefulWidget {
  final int networkId;
  const NetworkDetailScreen({super.key, required this.networkId});

  @override
  State<NetworkDetailScreen> createState() => _NetworkDetailScreenState();
}

class _NetworkDetailScreenState extends State<NetworkDetailScreen>
    with SingleTickerProviderStateMixin {
  final _networkService = NetworkService();
  final _alertService = AlertService();
  final _deviceService = DeviceService();
  final _historyService = HistoryService();
  final _logService = LogService();

  Network? _network;
  List<Alert> _alerts = [];
  List<Device> _devices = [];
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
    _tabs = TabController(length: 5, vsync: this);
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
        _networkService.getNetworkById(widget.networkId),
        _alertService.getAlertsByNetwork(widget.networkId),
        _deviceService.getDevicesByNetwork(widget.networkId),
        _logService.getLogsByNetwork(widget.networkId, size: 50),
        _historyService.getByNetwork(widget.networkId, size: 50),
      ]);
      if (mounted) {
        final logPage = results[3] as PageResult<LogEntry>;
        final historyPage = results[4] as PageResult<DeviceStatusHistory>;
        setState(() {
          _network = results[0] as Network;
          _alerts = results[1] as List<Alert>;
          _devices = results[2] as List<Device>;
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
          _error = 'Failed to load network.\n${errorMessage(e)}';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_logLoading || !_logHasMore) return;
    setState(() => _logLoading = true);
    try {
      final result = await _logService.getLogsByNetwork(
        widget.networkId,
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
      final result = await _historyService.getByNetwork(
        widget.networkId,
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

  Future<void> _rename() async {
    if (_network == null) return;
    final ctrl = TextEditingController(text: _network!.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename network'),
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
        final updated = await _networkService.updateNetwork(
          _network!.id,
          SaveNetworkRequest(name: newName, configuration: _network!.config),
        );
        if (mounted) setState(() => _network = updated);
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Rename failed'),
              content: Text(errorMessage(e)),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _editConfig() async {
    if (_network == null) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Network configuration'),
        content: SizedBox(
          width: 420,
          child: NetworkConfigForm(
            initial: _network!.config,
            onCancel: () => Navigator.of(ctx).pop(),
            onSave: (cfg) async {
              Navigator.of(ctx).pop();
              try {
                final updated = await _networkService.updateNetwork(
                  _network!.id,
                  SaveNetworkRequest(name: _network!.name, configuration: cfg),
                );
                if (mounted) setState(() => _network = updated);
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Save failed'),
                      content: Text(errorMessage(e)),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text("Network #${_network?.id}: ${_network?.name ?? 'Unknown'}"),
        actions: const [ShellMenuAction()],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Devices'),
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
                _buildDeviceList(),
                _buildAlertList(),
                _buildLogs(),
                _buildHistory(),
              ],
            ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return const Center(child: Text('No devices'));
    }
    return ListView.separated(
      itemCount: _devices.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) => DeviceListTile(
        device: _devices[i],
        onTap: () async {
          await Navigator.of(
            context,
          ).pushNamed('/device', arguments: _devices[i].id);
          if (mounted) {
            final updated = await _deviceService.getDevicesByNetwork(
              widget.networkId,
            );
            if (mounted) setState(() => _devices = updated);
          }
        },
      ),
    );
  }

  Widget _buildAlertList() {
    if (_alerts.isEmpty) {
      return const Center(child: Text('No alerts'));
    }
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

  Widget _buildInfo(bool isAdmin) {
    final n = _network!;
    final cfg = n.config;
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
                _infoRow('Name', n.name),
                _infoRow('ID', '${n.id}'),
                _infoRow(
                  'First seen',
                  n.firstSeen?.toLocal().toString() ?? '-',
                ),
                _infoRow('Last seen', n.lastSeen?.toLocal().toString() ?? '-'),
                _infoRow('Timezone', cfg.timezone),
                _infoRow(
                  'Reporting interval',
                  cfg.reportingInterval != null
                      ? '${cfg.reportingInterval} s'
                      : '-',
                ),
                _infoRow(
                  'Alerting delay',
                  cfg.alertingDelay != null ? '${cfg.alertingDelay} s' : '-',
                ),
                _infoRow(
                  'Notification email',
                  cfg.notificationEmailAddress ?? '-',
                ),
                _infoRow('Reminder time', cfg.reminderTimeOfDay ?? '-'),
                _infoRow(
                  'Reminder interval',
                  cfg.reminderIntervalDays != null
                      ? '${cfg.reminderIntervalDays} days'
                      : '-',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            if (isAdmin) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.drive_file_rename_outline, size: 16),
                label: const Text('Rename network'),
                onPressed: _rename,
              ),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Edit configuration'),
              onPressed: _editConfig,
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
