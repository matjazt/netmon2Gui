import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netmon2_gui/models/device.dart';
import 'package:provider/provider.dart';

import '../providers/network_provider.dart';
import '../services/alert_service.dart';
import '../services/device_service.dart';
import '../utils/constants.dart';
import '../widgets/error_display.dart';
import '../widgets/network_card.dart';
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
  Map<int, _NetworkStats> _stats = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
    _refreshTimer = Timer.periodic(kDashboardRefreshInterval, (_) {
      _loadStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final networks = networkProvider.networks;

    final Widget body;
    if (networkProvider.loading && networks.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (networkProvider.error != null && networks.isEmpty) {
      body = ErrorDisplay(message: networkProvider.error!);
    } else {
      body = RefreshIndicator(
        onRefresh: _loadStats,
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
        leading: ShellScope.maybeOf(context) != null
            ? const ShellMenuLeading()
            : null,
        title: const Text('Dashboard'),
      ),
      body: body,
    );
  }
}
