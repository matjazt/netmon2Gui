import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../providers/network_provider.dart';
import '../services/device_service.dart';
import '../utils/constants.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/error_display.dart';
import '../widgets/network_card.dart';

/// Main dashboard: network selector on the left, device list on the right.
/// Auto-refreshes every [kDashboardRefreshInterval].
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _deviceService = DeviceService();
  List<Device> _devices = [];
  DeviceStats? _stats;
  bool _loadingDevices = false;
  String? _devicesError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load devices after the first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDevices());
    _refreshTimer = Timer.periodic(kDashboardRefreshInterval, (_) {
      _loadDevices();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final network = context.read<NetworkProvider>().selectedNetwork;
    if (network == null) return;

    setState(() {
      _loadingDevices = true;
      _devicesError = null;
    });

    try {
      final results = await Future.wait([
        _deviceService.getDevicesByNetwork(network.id),
        _deviceService.getDeviceStats(network.id),
      ]);
      if (mounted) {
        setState(() {
          _devices = results[0] as List<Device>;
          _stats = results[1] as DeviceStats;
          _loadingDevices = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _devicesError = 'Failed to load devices.';
          _loadingDevices = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final selected = networkProvider.selectedNetwork;
    final networks = networkProvider.networks;

    return Row(
      children: [
        // Network side panel
        Container(
          width: 220,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Networks',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: networkProvider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : networkProvider.error != null
                    ? ErrorDisplay(message: networkProvider.error!)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        itemCount: networks.length,
                        itemBuilder: (ctx, i) {
                          final n = networks[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NetworkCard(
                              network: n,
                              onTap: () {
                                context
                                    .read<NetworkProvider>()
                                    .selectNetwork(n)
                                    .then((_) => _loadDevices());
                                Navigator.of(
                                  context,
                                ).pushNamed('/network', arguments: n.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Device list
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, selected?.name, _stats),
              const Divider(height: 1),
              Expanded(
                child: selected == null
                    ? const Center(child: Text('Select a network'))
                    : _loadingDevices
                    ? const Center(child: CircularProgressIndicator())
                    : _devicesError != null
                    ? ErrorDisplay(
                        message: _devicesError!,
                        onRetry: _loadDevices,
                      )
                    : _devices.isEmpty
                    ? const Center(child: Text('No devices in this network'))
                    : ListView.separated(
                        itemCount: _devices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) => DeviceListTile(
                          device: _devices[i],
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/device', arguments: _devices[i].id),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String? networkName,
    DeviceStats? stats,
  ) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                networkName ?? 'Dashboard',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (stats != null) ...[
              _statChip(
                context,
                label: '${stats.online} online',
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _statChip(
                context,
                label: '${stats.offline} offline',
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
