import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netmon2_gui/models/device.dart';
import 'package:provider/provider.dart';

import '../models/network.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../services/alert_service.dart';
import '../services/device_service.dart';
import '../services/network_service.dart';
import '../utils/constants.dart';
import '../utils/errors.dart';
import '../widgets/error_display.dart';
import '../widgets/network_card.dart';
import '../widgets/network_config_form.dart';
import '../widgets/shell_menu_leading.dart';

class _NetworkStats {
  final int online;
  final int offline;
  final int alerts;
  const _NetworkStats({
    required this.online,
    required this.offline,
    required this.alerts,
  });
}

/// Main dashboard: list of network cards showing per-network statistics.
/// Auto-refreshes every [kDashboardRefreshInterval].
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _deviceService = DeviceService();
  final _alertService = AlertService();
  final _networkService = NetworkService();
  Map<int, _NetworkStats> _stats = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
    _refreshTimer = Timer.periodic(kDashboardRefreshInterval, (_) {
      _refreshAll();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Refreshes the current user profile, network list, and per-network stats.
  /// Used by the periodic timer and pull-to-refresh.
  Future<void> _refreshAll() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.refreshCurrentUser();
    if (!mounted) return;
    await context.read<NetworkProvider>().loadNetworks(
      isAdmin: auth.isAdmin,
      accountId: auth.currentUser!.id,
    );
    await _loadStats();
  }

  Future<void> _loadStats() async {
    final networks = context.read<NetworkProvider>().networks;
    if (networks.isEmpty) return;

    try {
      final entries = await Future.wait(
        networks.map((n) async {
          final results = await Future.wait([
            _deviceService.getDeviceStats(n.id),
            _alertService.getAlertsByNetwork(n.id, activeOnly: true),
          ]);
          final ds = results[0] as DeviceStats;
          final alerts = results[1] as List;
          return MapEntry(
            n.id,
            _NetworkStats(
              online: ds.online,
              offline: ds.offline,
              alerts: alerts.length,
            ),
          );
        }),
      );
      if (mounted) {
        setState(() => _stats = Map.fromEntries(entries));
      }
    } catch (_) {
      // Stats are best-effort; silently ignore errors.
    }
  }

  Future<void> _addNetwork() async {
    final nameCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add network'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Network name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                NetworkConfigForm(
                  initial: const NetworkConfiguration(),
                  onCancel: () => Navigator.of(ctx).pop(),
                  onSave: (cfg) async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Network name is required.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    try {
                      await _networkService.createNetwork(
                        SaveNetworkRequest(name: name, configuration: cfg),
                      );
                      if (mounted) {
                        final auth = context.read<AuthProvider>();
                        await context.read<NetworkProvider>().loadNetworks(
                          isAdmin: auth.isAdmin,
                          accountId: auth.currentUser!.id,
                        );
                        _loadStats();
                      }
                    } catch (e) {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Failed to create network'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final networkProvider = context.watch<NetworkProvider>();
    final networks = networkProvider.networks;

    final Widget body;
    if (networkProvider.loading && networks.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (networkProvider.error != null && networks.isEmpty) {
      body = ErrorDisplay(message: networkProvider.error!);
    } else {
      body = RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: networks.length,
          itemBuilder: (ctx, i) {
            final n = networks[i];
            final stats = _stats[n.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NetworkCard(
                network: n,
                onlineCount: stats?.online,
                offlineCount: stats?.offline,
                alertCount: stats?.alerts,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed('/network', arguments: n.id),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [ShellMenuAction()],
      ),
      body: body,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _addNetwork,
              icon: const Icon(Icons.add),
              label: const Text('Add network'),
            )
          : null,
    );
  }
}
