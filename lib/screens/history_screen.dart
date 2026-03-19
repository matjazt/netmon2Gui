import 'package:flutter/material.dart';

import '../models/device_status_history.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import '../widgets/error_display.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/shell_menu_leading.dart';

/// Shows paginated device-status-history for all networks the user can access.
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
      final result = await _service.getAllPaginated(
        page: _page,
        size: kLogPageSize,
      );

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
    final Widget body;
    if (_error != null) {
      body = ErrorDisplay(message: _error!, onRetry: () => _load(reset: true));
    } else if (_entries.isEmpty && _loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_entries.isEmpty) {
      body = const Center(child: Text('No history'));
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView.separated(
          itemCount: _entries.length + (_hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            if (i == _entries.length) {
              // Load-more trigger — deferred to avoid setState during build.
              if (!_loading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_loading) _load();
                });
              }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: const [ShellMenuAction()],
      ),
      body: body,
    );
  }
}
