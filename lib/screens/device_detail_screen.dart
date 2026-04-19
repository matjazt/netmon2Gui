import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/device.dart';
import '../models/device_status_history.dart';
import '../models/log_entry.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import '../services/device_service.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';
import '../utils/dialogs.dart';
import '../utils/errors.dart';
import '../utils/formatters.dart';
import '../widgets/alert_list_tile.dart';
import '../widgets/detail_card.dart';
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

  // ── Info (always loaded first) ─────────────────────────────────────────────
  Device? _device;
  bool _loading = true;
  String? _error;

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
  static const int _tabAlerts = 1;
  static const int _tabLogs = 2;
  static const int _tabHistory = 3;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
      final device = await _deviceService.getDeviceById(widget.deviceId);
      if (mounted) {
        setState(() {
          _device = device;
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

  // ── Alerts ─────────────────────────────────────────────────────────────────

  Future<void> _loadAlerts() async {
    if (_alertsLoading) return;
    setState(() {
      _alertsLoading = true;
      _alertsError = null;
    });
    try {
      final alerts = await _alertService.getAlertsByDevice(widget.deviceId);
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
      final result = await _logService.getLogsByDevice(
        widget.deviceId,
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
      case _tabAlerts:
        _alertsLoaded = false;
        await _loadAlerts();
      case _tabLogs:
        await _loadLogs(reset: true);
      case _tabHistory:
        await _loadHistory(reset: true);
    }
  }

  Future<void> _changeName() async {
    if (_device == null) return;
    final newName = await showTextInputDialog(
      context,
      title: 'Rename device',
      labelText: 'Name',
      initialValue: _device!.name,
    );
    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        final updated = await _deviceService.renameDevice(_device!.id, newName);
        if (mounted) setState(() => _device = updated);
      } catch (e) {
        if (mounted) showErrorDialog(context, title: 'Rename failed', error: e);
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
      if (mounted)
        showErrorDialog(context, title: 'Mode change failed', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text("Device #${_device?.id}: ${_device?.name ?? 'Unknown'}"),
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
                _buildAlerts(),
                _buildLogs(),
                _buildHistory(),
              ],
            ),
    );
  }

  Widget _buildInfo(bool isAdmin) {
    final d = _device!;
    final colorScheme = Theme.of(context).colorScheme;
    final onlineColor = d.online ? Colors.green : colorScheme.error;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DetailCard(
          children: [
            DetailRow(
              label: 'Status',
              labelWidth: 160,
              child: Row(
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
            DetailRow(label: 'Name', value: d.name, labelWidth: 160),
            DetailRow(label: 'ID', value: '${d.id}', labelWidth: 160),
            DetailRow(
              label: 'MAC address',
              value: d.macAddress,
              labelWidth: 160,
            ),
            if (d.ipAddress != null)
              DetailRow(
                label: 'IP address',
                value: d.ipAddress!,
                labelWidth: 160,
              ),
            if (d.vendor != null)
              DetailRow(label: 'Vendor', value: d.vendor!, labelWidth: 160),
            DetailRow(
              label: 'Operation mode',
              value: d.deviceOperationMode ?? '-',
              labelWidth: 160,
            ),
            DetailRow(
              label: 'First seen',
              value: formatDateTime(d.firstSeen),
              labelWidth: 160,
            ),
            DetailRow(
              label: 'Last seen',
              value: formatDateTime(d.lastSeen),
              labelWidth: 160,
            ),
          ],
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
        ),
      ],
    );
  }

  Widget _buildAlerts() {
    if (_alertsLoading && !_alertsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_alertsError != null) {
      return ErrorDisplay(message: _alertsError!, onRetry: _loadAlerts);
    }
    return RefreshIndicator(
      onRefresh: () => _loadAlerts(),
      child: _alerts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No alerts')),
              ],
            )
          : ListView.separated(
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
    return RefreshIndicator(
      onRefresh: () => _loadLogs(reset: true),
      child: _log.isEmpty && !_logLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No logs')),
              ],
            )
          : ListView.separated(
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
    return RefreshIndicator(
      onRefresh: () => _loadHistory(reset: true),
      child: _history.isEmpty && !_historyLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No history')),
              ],
            )
          : ListView.separated(
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
}
