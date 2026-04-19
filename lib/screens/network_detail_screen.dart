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
import '../utils/dialogs.dart';
import '../utils/errors.dart';
import '../utils/formatters.dart';
import '../widgets/alert_list_tile.dart';
import '../widgets/async_list_view.dart';
import '../widgets/detail_card.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/error_display.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/network_config_form.dart';
import '../widgets/paginated_list_view.dart';
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
    final newName = await showTextInputDialog(
      context,
      title: 'Rename network',
      labelText: 'Name',
      initialValue: _network!.name,
    );
    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        final updated = await _networkService.updateNetwork(
          _network!.id,
          SaveNetworkRequest(name: newName, configuration: _network!.config),
        );
        if (mounted) setState(() => _network = updated);
      } catch (e) {
        if (mounted) showErrorDialog(context, title: 'Rename failed', error: e);
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
                if (mounted)
                  showErrorDialog(context, title: 'Save failed', error: e);
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

  Widget _buildDeviceList() => AsyncListView<Device>(
    items: _devices,
    isLoading: _devicesLoading,
    error: _devicesError,
    onRefresh: () async {
      _devicesLoaded = false;
      await _loadDevices();
    },
    emptyMessage: 'No devices',
    itemBuilder: (ctx, d) => DeviceListTile(
      device: d,
      onTap: () async {
        await Navigator.of(ctx).pushNamed('/device', arguments: d.id);
        if (mounted) {
          _devicesLoaded = false;
          _loadDevices();
        }
      },
    ),
  );

  Widget _buildAlertList() => AsyncListView<Alert>(
    items: _alerts,
    isLoading: _alertsLoading,
    error: _alertsError,
    onRefresh: () async {
      _alertsLoaded = false;
      await _loadAlerts();
    },
    emptyMessage: 'No alerts',
    itemBuilder: (_, a) => AlertListTile(alert: a),
  );

  Widget _buildLogs() => PaginatedListView<LogEntry>(
    items: _log,
    isLoading: _logLoading,
    hasMore: _logHasMore,
    error: _logError,
    onRefresh: () => _loadLogs(reset: true),
    onLoadMore: _loadMoreLogs,
    emptyMessage: 'No logs',
    itemBuilder: (_, entry) => LogListTile(entry: entry),
  );

  Widget _buildHistory() => PaginatedListView<DeviceStatusHistory>(
    items: _history,
    isLoading: _historyLoading,
    hasMore: _historyHasMore,
    error: _historyError,
    onRefresh: () => _loadHistory(reset: true),
    onLoadMore: _loadMoreHistory,
    emptyMessage: 'No history',
    itemBuilder: (_, entry) => HistoryListTile(entry: entry),
  );

  Widget _buildInfo(bool isAdmin) {
    final n = _network!;
    final cfg = n.config;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DetailCard(
          children: [
            DetailRow(label: 'Name', value: n.name, labelWidth: 180),
            DetailRow(label: 'ID', value: '${n.id}', labelWidth: 180),
            DetailRow(
              label: 'First seen',
              value: formatDateTime(n.firstSeen),
              labelWidth: 180,
            ),
            DetailRow(
              label: 'Last seen',
              value: formatDateTime(n.lastSeen),
              labelWidth: 180,
            ),
            DetailRow(label: 'Timezone', value: cfg.timezone, labelWidth: 180),
            DetailRow(
              label: 'Reporting interval',
              value: cfg.reportingInterval != null
                  ? '${cfg.reportingInterval} s'
                  : '-',
              labelWidth: 180,
            ),
            DetailRow(
              label: 'Alerting delay',
              value: cfg.alertingDelay != null ? '${cfg.alertingDelay} s' : '-',
              labelWidth: 180,
            ),
            DetailRow(
              label: 'Notification email',
              value: cfg.notificationEmailAddress ?? '-',
              labelWidth: 180,
            ),
            DetailRow(
              label: 'Reminder time',
              value: cfg.reminderTimeOfDay ?? '-',
              labelWidth: 180,
            ),
            DetailRow(
              label: 'Reminder interval',
              value: cfg.reminderIntervalDays != null
                  ? '${cfg.reminderIntervalDays} days'
                  : '-',
              labelWidth: 180,
            ),
          ],
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
}
