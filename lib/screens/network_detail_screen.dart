import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/device.dart';
import '../models/device_status_history.dart';
import '../models/log_entry.dart';
import '../models/network.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import '../services/device_service.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';
import '../services/network_service.dart';
import '../utils/errors.dart';
import '../utils/formatters.dart';
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

  // ── Info (always loaded first) ─────────────────────────────────────────────
  Network? _network;
  bool _loading = true;
  String? _error;

  // ── Devices tab ────────────────────────────────────────────────────────────
  List<Device> _devices = [];
  bool _devicesLoaded = false;
  bool _devicesLoading = false;
  String? _devicesError;

  // ── Alerts tab ─────────────────────────────────────────────────────────────
  List<Alert> _alerts = [];
  bool _alertsLoaded = false;
  bool _alertsLoading = false;
  String? _alertsError;

  // ── Logs tab ───────────────────────────────────────────────────────────────
  final List<LogEntry> _log = [];
  bool _logLoaded = false;
  int _logPage = 0;
  bool _logHasMore = true;
  bool _logLoading = false;
  String? _logError;

  // ── History tab ────────────────────────────────────────────────────────────
  final List<DeviceStatusHistory> _history = [];
  bool _historyLoaded = false;
  int _historyPage = 0;
  bool _historyHasMore = true;
  bool _historyLoading = false;
  String? _historyError;

  late TabController _tabs;

  // Tab indices
  static const int _tabInfo = 0;
  static const int _tabDevices = 1;
  static const int _tabAlerts = 2;
  static const int _tabLogs = 3;
  static const int _tabHistory = 4;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(_onTabChanged);
    _loadInfo();
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    switch (_tabs.index) {
      case _tabDevices:
        if (!_devicesLoaded) _loadDevices();
      case _tabAlerts:
        if (!_alertsLoaded) _loadAlerts();
      case _tabLogs:
        if (!_logLoaded) _loadLogs();
      case _tabHistory:
        if (!_historyLoaded) _loadHistory();
    }
  }

  // ── Info ───────────────────────────────────────────────────────────────────

  Future<void> _loadInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final network = await _networkService.getNetworkById(widget.networkId);
      if (mounted) {
        setState(() {
          _network = network;
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

  // ── Devices ────────────────────────────────────────────────────────────────

  Future<void> _loadDevices() async {
    if (_devicesLoading) return;
    setState(() {
      _devicesLoading = true;
      _devicesError = null;
    });
    try {
      final devices = await _deviceService.getDevicesByNetwork(
        widget.networkId,
      );
      if (mounted) {
        setState(() {
          _devices = devices;
          _devicesLoaded = true;
          _devicesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _devicesError = 'Failed to load devices.\n${errorMessage(e)}';
          _devicesLoading = false;
        });
      }
    }
  }

  // ── Alerts ─────────────────────────────────────────────────────────────────

  Future<void> _loadAlerts() async {
    if (_alertsLoading) return;
    setState(() {
      _alertsLoading = true;
      _alertsError = null;
    });
    try {
      final alerts = await _alertService.getAlertsByNetwork(widget.networkId);
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _alertsLoaded = true;
          _alertsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alertsError = 'Failed to load alerts.\n${errorMessage(e)}';
          _alertsLoading = false;
        });
      }
    }
  }

  // ── Logs ───────────────────────────────────────────────────────────────────

  Future<void> _loadLogs({bool reset = false}) async {
    if (_logLoading) return;
    if (reset) {
      _log.clear();
      _logPage = 0;
      _logHasMore = true;
    }
    setState(() {
      _logLoading = true;
      _logError = null;
    });
    try {
      final result = await _logService.getLogsByNetwork(
        widget.networkId,
        page: _logPage,
        size: 50,
      );
      if (mounted) {
        setState(() {
          _log.addAll(result.content);
          _logPage = result.number + 1;
          _logHasMore = !result.last;
          _logLoaded = true;
          _logLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logError = 'Failed to load logs.\n${errorMessage(e)}';
          _logLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_logLoading || !_logHasMore) return;
    _loadLogs();
  }

  // ── History ────────────────────────────────────────────────────────────────

  Future<void> _loadHistory({bool reset = false}) async {
    if (_historyLoading) return;
    if (reset) {
      _history.clear();
      _historyPage = 0;
      _historyHasMore = true;
    }
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
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
          _historyLoaded = true;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = 'Failed to load history.\n${errorMessage(e)}';
          _historyLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_historyLoading || !_historyHasMore) return;
    _loadHistory();
  }

  // ── Refresh current tab ────────────────────────────────────────────────────

  Future<void> _refreshCurrentTab() async {
    switch (_tabs.index) {
      case _tabInfo:
        await _loadInfo();
      case _tabDevices:
        _devicesLoaded = false;
        await _loadDevices();
      case _tabAlerts:
        _alertsLoaded = false;
        await _loadAlerts();
      case _tabLogs:
        await _loadLogs(reset: true);
      case _tabHistory:
        await _loadHistory(reset: true);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshCurrentTab,
          ),
          const ShellMenuAction(),
        ],
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
          ? ErrorDisplay(message: _error!, onRetry: _loadInfo)
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
    if (_devicesLoading && !_devicesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_devicesError != null) {
      return ErrorDisplay(
        message: _devicesError!,
        onRetry: () {
          _devicesLoaded = false;
          _loadDevices();
        },
      );
    }
    if (_devices.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _devicesLoaded = false;
          await _loadDevices();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No devices'),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        _devicesLoaded = false;
        await _loadDevices();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _devices.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) => DeviceListTile(
          device: _devices[i],
          onTap: () async {
            await Navigator.of(
              context,
            ).pushNamed('/device', arguments: _devices[i].id);
            if (mounted) {
              _devicesLoaded = false;
              _loadDevices();
            }
          },
        ),
      ),
    );
  }

  Widget _buildAlertList() {
    if (_alertsLoading && !_alertsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_alertsError != null) {
      return ErrorDisplay(
        message: _alertsError!,
        onRetry: () {
          _alertsLoaded = false;
          _loadAlerts();
        },
      );
    }
    if (_alerts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _alertsLoaded = false;
          await _loadAlerts();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No alerts'),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        _alertsLoaded = false;
        await _loadAlerts();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _alerts.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) => AlertListTile(alert: _alerts[i]),
      ),
    );
  }

  Widget _buildLogs() {
    if (_logLoading && !_logLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_logError != null) {
      return ErrorDisplay(
        message: _logError!,
        onRetry: () => _loadLogs(reset: true),
      );
    }
    if (_log.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadLogs(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No logs'),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadLogs(reset: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _log.length + (_logHasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i == _log.length) {
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
          return LogListTile(entry: _log[i]);
        },
      ),
    );
  }

  Widget _buildHistory() {
    if (_historyLoading && !_historyLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyError != null) {
      return ErrorDisplay(
        message: _historyError!,
        onRetry: () => _loadHistory(reset: true),
      );
    }
    if (_history.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadHistory(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No history'),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadHistory(reset: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _history.length + (_historyHasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
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
      ),
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
                _infoRow('First seen', formatDateTime(n.firstSeen)),
                _infoRow('Last seen', formatDateTime(n.lastSeen)),
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
