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
import '../widgets/alert_list_tile.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/error_display.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/network_config_form.dart';

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
        setState(() {
          _network = results[0] as Network;
          _alerts = results[1] as List<Alert>;
          _devices = results[2] as List<Device>;
          _logs = (results[3] as PageResult<LogEntry>).content;
          _history = (results[4] as PageResult<DeviceStatusHistory>).content;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load network.';
          _loading = false;
        });
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
            onSave: (cfg) async {
              Navigator.of(ctx).pop();
              try {
                final updated = await _networkService.updateNetwork(
                  _network!.id,
                  SaveNetworkRequest(name: _network!.name, configuration: cfg),
                );
                if (mounted) setState(() => _network = updated);
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Save failed.')));
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
        title: Text(_network?.name ?? 'Network'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Edit configuration',
              onPressed: _editConfig,
            ),
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
          ? ErrorDisplay(message: _error!, onRetry: _load)
          : TabBarView(
              controller: _tabs,
              children: [
                _buildInfo(),
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
        onTap: () => Navigator.of(
          context,
        ).pushNamed('/device', arguments: _devices[i].id),
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
    if (_logs.isEmpty) return const Center(child: Text('No logs'));
    return ListView.separated(
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) => LogListTile(entry: _logs[i]),
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

  Widget _buildInfo() {
    final n = _network!;
    final cfg = n.config;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Name', n.name),
        _infoRow('First seen', n.firstSeen?.toLocal().toString() ?? '-'),
        _infoRow('Last seen', n.lastSeen?.toLocal().toString() ?? '-'),
        _infoRow('Timezone', cfg.timezone),
        _infoRow(
          'Reporting interval',
          cfg.reportingInterval != null ? '${cfg.reportingInterval} s' : '-',
        ),
        _infoRow(
          'Alerting delay',
          cfg.alertingDelay != null ? '${cfg.alertingDelay} s' : '-',
        ),
        _infoRow('Notification email', cfg.notificationEmailAddress ?? '-'),
        _infoRow('Reminder time', cfg.reminderTimeOfDay ?? '-'),
        _infoRow(
          'Reminder interval',
          cfg.reminderIntervalDays != null
              ? '${cfg.reminderIntervalDays} days'
              : '-',
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
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
