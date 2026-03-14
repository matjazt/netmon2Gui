import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/log_entry.dart';
import '../models/page_result.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../services/log_service.dart';
import '../utils/constants.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/error_display.dart';

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
      final auth = context.read<AuthProvider>();
      final network = context.read<NetworkProvider>().selectedNetwork;

      PageResult<LogEntry> result;
      if (auth.isAdmin) {
        result = await _service.getAllLogsPaginated(
          page: _page,
          size: kLogPageSize,
        );
      } else if (network != null) {
        result = await _service.getLogsByNetwork(
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
          _error = 'Failed to load logs.';
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
      return const Center(child: Text('No logs'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        itemCount: _entries.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i == _entries.length) {
            // Load-more trigger
            if (!_loading) _load();
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
}
