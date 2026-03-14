import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_status_history.dart';
import '../models/page_result.dart';
import '../providers/network_provider.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/error_display.dart';

/// Shows paginated device-status-history.
/// Scoped to the selected network (or all for admins).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = HistoryService();
  final List<DeviceStatusHistory> _entries = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _entries.clear();
      _page = 0;
      _hasMore = true;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final network = context.read<NetworkProvider>().selectedNetwork;

      PageResult<DeviceStatusHistory> result;
      if (network != null) {
        result = await _service.getByNetwork(
          network.id,
          page: _page,
          size: kLogPageSize,
        );
      } else {
        setState(() {
          _loading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _entries.addAll(result.content);
          _hasMore = !result.last;
          _page = result.number + 1;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load history.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: () => _load(reset: true));
    }
    if (_entries.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('No history'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        itemCount: _entries.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i == _entries.length) {
            if (!_loading) _load();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return HistoryListTile(entry: _entries[i]);
        },
      ),
    );
  }
}
