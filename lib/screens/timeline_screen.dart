import 'package:flutter/material.dart';

import '../models/device.dart';
import '../models/device_status_history.dart';
import '../models/device_timeline_segment.dart';
import '../services/device_service.dart';
import '../services/history_service.dart';
import '../utils/errors.dart';
import '../utils/formatters.dart';
import '../widgets/device_timeline_chart.dart';
import '../widgets/shell_menu_leading.dart';

/// Route arguments for [TimelineScreen].
class TimelineArgs {
  final int networkId;
  final String networkName;

  const TimelineArgs({required this.networkId, required this.networkName});
}

enum _TimeRange {
  hour1('1 h', Duration(hours: 1)),
  hour6('6 h', Duration(hours: 6)),
  hour24('24 h', Duration(hours: 24)),
  day7('7 d', Duration(days: 7)),
  day30('30 d', Duration(days: 30));

  const _TimeRange(this.label, this.duration);

  final String label;
  final Duration duration;
}

/// Displays a swimlane timeline for all devices in the given network.
///
/// Navigate to this screen by pushing the named route `/timeline` with a
/// [TimelineArgs] object as the route argument.
class TimelineScreen extends StatefulWidget {
  final int networkId;
  final String networkName;

  const TimelineScreen({
    super.key,
    required this.networkId,
    required this.networkName,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _deviceService = DeviceService();
  final _historyService = HistoryService();

  // ── Device list ────────────────────────────────────────────────────────────
  List<Device> _devices = [];
  bool _devicesLoading = true;
  String? _devicesError;
  Set<int> _selectedIds = {};

  // ── Chart ──────────────────────────────────────────────────────────────────
  _TimeRange _range = _TimeRange.hour24;
  List<DeviceTimeline> _timelines = [];
  bool _chartLoading = false;
  String? _chartError;
  DateTime? _chartFrom;
  DateTime? _chartTo;
  // Incremented on every new load; lets async callbacks discard stale results.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadDevices() async {
    setState(() {
      _devicesLoading = true;
      _devicesError = null;
    });
    try {
      final devices = await _deviceService.getDevicesByNetwork(
        widget.networkId,
      );
      if (mounted) {
        setState(() {
          _devices = devices;
          _selectedIds = {};
          _devicesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _devicesError = 'Failed to load devices.\n${errorMessage(e)}';
          _devicesLoading = false;
        });
      }
    }
  }

  Future<void> _loadChart() async {
    if (_devices.isEmpty || _selectedIds.isEmpty) {
      if (mounted) {
        setState(() {
          _timelines = [];
          _chartLoading = false;
        });
      }
      return;
    }

    final generation = ++_loadGeneration;
    final to = DateTime.now().toUtc();
    final from = to.subtract(_range.duration);

    setState(() {
      _chartLoading = true;
      _chartError = null;
      _chartFrom = from;
      _chartTo = to;
    });

    // Preserve the order devices appear in the API response.
    final orderedIds = _devices
        .where((d) => _selectedIds.contains(d.id))
        .map((d) => d.id)
        .toList();

    try {
      final results = await Future.wait(
        orderedIds.map((id) => _fetchTimeline(id, from, to)),
      );
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _timelines = results;
          _chartLoading = false;
        });
      }
    } catch (e) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _chartError = errorMessage(e);
          _chartLoading = false;
        });
      }
    }
  }

  /// Fetches history for one device and converts events to segments.
  Future<DeviceTimeline> _fetchTimeline(
    int deviceId,
    DateTime from,
    DateTime to,
  ) async {
    // Search backwards in exponentially growing windows (×3 each step) up to
    // 3 years to find the last known state before [from]. Starting at 30 days
    // covers the common case cheaply; the cap handles devices with sparse
    // history that haven't changed state in months.
    const maxLookbackDays = 365 * 3;
    DeviceStatusHistory? seedEvent;
    var lookbackDays = 30;
    while (true) {
      final clampedDays = lookbackDays > maxLookbackDays
          ? maxLookbackDays
          : lookbackDays;
      final seedResult = await _historyService.getByDeviceAndTimestampRange(
        deviceId,
        from.subtract(Duration(days: clampedDays)),
        from,
        size: 200,
      );
      final sortedSeed = seedResult.content
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (sortedSeed.isNotEmpty && sortedSeed.last.timestamp.isBefore(from)) {
        seedEvent = sortedSeed.last;
        break;
      }
      if (clampedDays >= maxLookbackDays) break; // exhausted max lookback
      lookbackDays = lookbackDays * 3;
    }

    // Fetch all pages of events within [from, to].
    final events = <DeviceStatusHistory>[];
    var page = 0;
    while (true) {
      final r = await _historyService.getByDeviceAndTimestampRange(
        deviceId,
        from,
        to,
        page: page,
        size: 200,
      );
      events.addAll(r.content);
      if (r.last) break;
      page++;
    }

    final device = _devices.firstWhere((d) => d.id == deviceId);
    return DeviceTimeline(
      deviceId: deviceId,
      deviceName: _deviceLabel(device),
      segments: _buildSegments(events, from, to, seedEvent: seedEvent),
    );
  }

  /// Converts a flat list of state-change events into drawable segments.
  List<TimelineSegment> _buildSegments(
    List<DeviceStatusHistory> events,
    DateTime rangeStart,
    DateTime rangeEnd, {
    DeviceStatusHistory? seedEvent,
  }) {
    final allEvents = <DeviceStatusHistory>[?seedEvent, ...events]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (allEvents.isEmpty) return [];

    final segments = <TimelineSegment>[];
    for (var i = 0; i < allEvents.length; i++) {
      // The seed event (index 0 when present) is extended back to rangeStart
      // so the chart shows the known state for the full visible range.
      final isSeedFirst = i == 0 && seedEvent != null;
      final segStart = isSeedFirst
          ? rangeStart
          : (allEvents[i].timestamp.isBefore(rangeStart)
                ? rangeStart
                : allEvents[i].timestamp);

      final rawEnd = i + 1 < allEvents.length
          ? allEvents[i + 1].timestamp
          : rangeEnd;
      final segEnd = rawEnd.isAfter(rangeEnd) ? rangeEnd : rawEnd;

      if (segStart.isBefore(segEnd)) {
        segments.add(
          TimelineSegment(
            start: segStart,
            end: segEnd,
            online: allEvents[i].online,
          ),
        );
      }
    }
    return segments;
  }

  String _deviceLabel(Device d) => (d.name.isNotEmpty && d.name != '<unnamed>')
      ? d.name
      : d.vendor ?? 'Device ${d.id}';

  // ── Device selection ───────────────────────────────────────────────────────

  void _selectAll() {
    setState(() => _selectedIds = _devices.map((d) => d.id).toSet());
    _loadChart();
  }

  void _clearAll() {
    setState(() => _selectedIds = {});
    _loadChart();
  }

  void _showDeviceSelector() {
    showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeviceSelectorSheet(
        devices: _devices,
        selectedIds: Set.from(_selectedIds),
        deviceLabel: _deviceLabel,
      ),
    ).then((result) {
      if (result != null && mounted) {
        setState(() => _selectedIds = result);
        _loadChart();
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline \u2014 ${widget.networkName}'),
        actions: [
          if (!_devicesLoading && _devicesError == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh chart',
              onPressed: _loadChart,
            ),
          const ShellMenuAction(),
        ],
      ),
      body: _buildBody(isWide),
    );
  }

  Widget _buildBody(bool isWide) {
    if (_devicesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_devicesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_devicesError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDevices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (isWide) {
      return _buildWideLayout();
    }
    return _buildNarrowLayout();
  }

  // ── Wide layout (≥ 700 px) ─────────────────────────────────────────────────

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Text(
                  'Devices',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Row(
                children: [
                  TextButton(onPressed: _selectAll, child: const Text('All')),
                  TextButton(onPressed: _clearAll, child: const Text('None')),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    return CheckboxListTile(
                      dense: true,
                      value: _selectedIds.contains(d.id),
                      title: Text(
                        _deviceLabel(d),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedIds.add(d.id);
                        } else {
                          _selectedIds.remove(d.id);
                        }
                      }),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _loadChart,
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Update chart'),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _buildRangeSelector(),
              ),
              Expanded(child: _buildChartArea()),
            ],
          ),
        ),
      ],
    );
  }

  // ── Narrow layout (< 700 px) ───────────────────────────────────────────────

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildRangeSelector(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Select devices',
                onPressed: _showDeviceSelector,
              ),
            ],
          ),
        ),
        Expanded(child: _buildChartArea()),
      ],
    );
  }

  // ── Shared sub-widgets ─────────────────────────────────────────────────────

  Widget _buildRangeSelector() {
    return SegmentedButton<_TimeRange>(
      segments: _TimeRange.values
          .map((r) => ButtonSegment<_TimeRange>(value: r, label: Text(r.label)))
          .toList(),
      selected: {_range},
      onSelectionChanged: (selection) {
        setState(() => _range = selection.first);
        _loadChart();
      },
    );
  }

  Widget _buildChartArea() {
    if (_chartLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_chartError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_chartError!),
        ),
      );
    }
    if (_selectedIds.isEmpty) {
      return const Center(
        child: Text('Select at least one device to display the chart.'),
      );
    }
    if (_timelines.isEmpty) {
      // Selection is non-empty but no data loaded yet — prompt the user.
      return const Center(
        child: Text('Press “Update chart” to load the selected devices.'),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onlineColor = Colors.green.shade600;
    final offlineColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final from = _chartFrom!;
    final to = _chartTo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend + range label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LegendItem(color: onlineColor, label: 'Online'),
              _LegendItem(color: offlineColor, label: 'Offline'),
              Text(
                '${formatDateTime(from.toLocal())} \u2013 '
                '${formatDateTime(to.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Chart — scrollable vertically if many rows
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DeviceTimelineChart(
              timelines: _timelines,
              rangeStart: from,
              rangeEnd: to,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Device selector bottom sheet ───────────────────────────────────────────

class _DeviceSelectorSheet extends StatefulWidget {
  final List<Device> devices;
  final Set<int> selectedIds;
  final String Function(Device) deviceLabel;

  const _DeviceSelectorSheet({
    required this.devices,
    required this.selectedIds,
    required this.deviceLabel,
  });

  @override
  State<_DeviceSelectorSheet> createState() => _DeviceSelectorSheetState();
}

class _DeviceSelectorSheetState extends State<_DeviceSelectorSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Select Devices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(
                    () => _selected = widget.devices.map((d) => d.id).toSet(),
                  ),
                  child: const Text('All'),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected = {}),
                  child: const Text('None'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: widget.devices.length,
              itemBuilder: (_, i) {
                final d = widget.devices[i];
                return CheckboxListTile(
                  dense: true,
                  value: _selected.contains(d.id),
                  title: Text(
                    widget.deviceLabel(d),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(d.id);
                    } else {
                      _selected.remove(d.id);
                    }
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legend item ────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
