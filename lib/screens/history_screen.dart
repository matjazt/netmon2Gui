import 'package:flutter/material.dart';

import '../models/device_status_history.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import '../utils/errors.dart';
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
  final List<DeviceStatusHistory> _history = [];
  int _historyPage = 0;
  bool _historyHasMore = true;
  bool _historyLoading = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

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
      final result = await _service.getAllPaginated(
        page: _historyPage,
        size: kLogPageSize,
      );

      if (mounted) {
        setState(() {
          _history.addAll(result.content);
          _historyHasMore = !result.last;
          _historyPage = result.number + 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadHistory(reset: true),
          ),
          const ShellMenuAction(),
        ],
      ),
      body: _historyLoading && _history.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _historyError != null
          ? ErrorDisplay(
              message: _historyError!,
              onRetry: () => _loadHistory(reset: true),
            )
          : RefreshIndicator(
              onRefresh: () => _loadHistory(reset: true),
              child: _history.isEmpty
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
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        if (i == _history.length) {
                          if (!_historyLoading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_historyLoading)
                                _loadMoreHistory();
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
            ),
    );
  }
}
