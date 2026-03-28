import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../services/log_service.dart';
import '../utils/constants.dart';
import '../utils/errors.dart';
import '../widgets/error_display.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/shell_menu_leading.dart';

/// Shows paginated logs.
/// - Admins see all logs via /api/logs/paginated.
/// - Users see logs scoped to the selected network via /api/logs/network/{id}.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _service = LogService();
  final List<LogEntry> _log = [];
  int _logPage = 0;
  bool _logHasMore = true;
  bool _logLoading = false;
  String? _logError;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

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
      final result = await _service.getAllLogsPaginated(
        page: _logPage,
        size: kLogPageSize,
      );

      if (mounted) {
        setState(() {
          _log.addAll(result.content);
          _logHasMore = !result.last;
          _logPage = result.number + 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadLogs(reset: true),
          ),
          const ShellMenuAction(),
        ],
      ),
      body: _logLoading && _log.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _logError != null
          ? ErrorDisplay(message: _logError!, onRetry: () => _loadLogs(reset: true))
          : RefreshIndicator(
              onRefresh: () => _loadLogs(reset: true),
              child: _log.isEmpty
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
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        if (i == _log.length) {
                          if (!_logLoading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_logLoading) _loadMoreLogs();
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
            ),
    );
  }
}
