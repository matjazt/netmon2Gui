import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../models/page_result.dart';
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
  final List<LogEntry> _entries = [];
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
      // final auth = context.read<AuthProvider>();
      // final network = context.read<NetworkProvider>().selectedNetwork;

      PageResult<LogEntry> result = await _service.getAllLogsPaginated(
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load logs.\n${errorMessage(e)}';
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
      body = const Center(child: Text('No logs'));
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _entries.length + (_hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const Divider(height: 1),
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
            return LogListTile(entry: _entries[i]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: const [ShellMenuAction()],
      ),
      body: body,
    );
  }
}
