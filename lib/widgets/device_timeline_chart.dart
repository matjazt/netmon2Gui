import 'package:flutter/material.dart';

import '../models/device_timeline_segment.dart';

/// Swimlane timeline chart showing device online/offline history.
///
/// Each row represents one [DeviceTimeline]. Green bars = online,
/// grey bars = offline. A time axis with tick marks is rendered below.
///
/// The widget sizes its height automatically based on the number of rows.
/// Wrap in a [SingleChildScrollView] if vertical overflow is possible.
class DeviceTimelineChart extends StatelessWidget {
  final List<DeviceTimeline> timelines;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const DeviceTimelineChart({
    super.key,
    required this.timelines,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final totalHeight =
        timelines.length * _TimelinePainter.rowHeight +
        _TimelinePainter.axisHeight +
        _TimelinePainter.topPadding;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _TimelinePainter(
          timelines: timelines,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          onlineColor: Colors.green.shade600,
          offlineColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          axisColor: cs.outlineVariant,
          altRowColor: cs.onSurface.withAlpha(15),
          labelStyle: TextStyle(
            fontSize: 11,
            color: cs.onSurface,
            fontFamily: theme.textTheme.bodySmall?.fontFamily,
          ),
          axisStyle: TextStyle(
            fontSize: 10,
            color: cs.onSurfaceVariant,
            fontFamily: theme.textTheme.bodySmall?.fontFamily,
          ),
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  static const double labelWidth = 160.0;
  static const double rowHeight = 34.0;
  static const double segPad = 5.0;
  static const double axisHeight = 30.0;
  static const double topPadding = 4.0;

  final List<DeviceTimeline> timelines;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final Color onlineColor;
  final Color offlineColor;
  final Color axisColor;
  final Color altRowColor;
  final TextStyle labelStyle;
  final TextStyle axisStyle;

  const _TimelinePainter({
    required this.timelines,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onlineColor,
    required this.offlineColor,
    required this.axisColor,
    required this.altRowColor,
    required this.labelStyle,
    required this.axisStyle,
  });

  double _timeToX(DateTime t, double chartWidth) {
    final totalUs = rangeEnd.difference(rangeStart).inMicroseconds;
    if (totalUs == 0) return labelWidth;
    final offsetUs = t.difference(rangeStart).inMicroseconds.clamp(0, totalUs);
    return labelWidth + offsetUs / totalUs * chartWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - labelWidth;
    if (chartWidth <= 0) return;

    // 1. Alternating row backgrounds
    final altPaint = Paint()..color = altRowColor;
    for (var i = 0; i < timelines.length; i++) {
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(0, topPadding + i * rowHeight, size.width, rowHeight),
          altPaint,
        );
      }
    }

    // 2. Device rows: label + segments
    for (var i = 0; i < timelines.length; i++) {
      final tl = timelines[i];
      final rowY = topPadding + i * rowHeight;

      // Device name label
      final labelTp = TextPainter(
        text: TextSpan(text: tl.deviceName, style: labelStyle),
        textDirection: TextDirection.ltr,
        ellipsis: '\u2026',
        maxLines: 1,
      )..layout(maxWidth: labelWidth - 10);
      labelTp.paint(canvas, Offset(6, rowY + (rowHeight - labelTp.height) / 2));

      // Segments
      for (final seg in tl.segments) {
        final x1 = _timeToX(
          seg.start,
          chartWidth,
        ).clamp(labelWidth, size.width);
        final x2 = _timeToX(seg.end, chartWidth).clamp(labelWidth, size.width);
        if (x2 <= x1 + 0.5) continue;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x1, rowY + segPad, x2, rowY + rowHeight - segPad),
            const Radius.circular(3),
          ),
          Paint()..color = seg.online ? onlineColor : offlineColor,
        );
      }
    }

    // 3. Vertical separator between label column and chart area
    final linePaint = Paint()
      ..color = axisColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(labelWidth, topPadding),
      Offset(
        labelWidth,
        topPadding + timelines.length * rowHeight + axisHeight,
      ),
      linePaint,
    );

    // 4. Horizontal axis baseline
    final axisY = topPadding + timelines.length * rowHeight;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(labelWidth, axisY),
      Offset(size.width, axisY),
      axisPaint,
    );

    // 5. Tick marks and labels
    final rangeDuration = rangeEnd.difference(rangeStart);
    final tickInterval = _computeTickInterval(rangeDuration);
    var tickTime = _roundUpToInterval(rangeStart, tickInterval);
    while (tickTime.isBefore(rangeEnd)) {
      final x = _timeToX(tickTime, chartWidth);
      canvas.drawLine(Offset(x, axisY), Offset(x, axisY + 5), axisPaint);

      final label = _formatTick(tickTime, rangeDuration);
      final ltp = TextPainter(
        text: TextSpan(text: label, style: axisStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (x - ltp.width / 2).clamp(labelWidth, size.width - ltp.width);
      ltp.paint(canvas, Offset(lx, axisY + 7));
      tickTime = tickTime.add(tickInterval);
    }

    // Range-end label, right-aligned
    final endLabel = _formatTick(rangeEnd, rangeDuration);
    final endTp = TextPainter(
      text: TextSpan(text: endLabel, style: axisStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    endTp.paint(canvas, Offset(size.width - endTp.width - 2, axisY + 7));
  }

  Duration _computeTickInterval(Duration range) {
    const targets = [
      Duration(minutes: 10),
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration(hours: 2),
      Duration(hours: 4),
      Duration(hours: 6),
      Duration(hours: 12),
      Duration(days: 1),
      Duration(days: 2),
    ];
    for (final t in targets) {
      if (range.inSeconds / t.inSeconds <= 8) return t;
    }
    return const Duration(days: 2);
  }

  /// Rounds [dt] up to the next multiple of [interval] in milliseconds.
  DateTime _roundUpToInterval(DateTime dt, Duration interval) {
    final ms = interval.inMilliseconds;
    final dtMs = dt.millisecondsSinceEpoch;
    final rem = dtMs % ms;
    if (rem == 0) return dt;
    return DateTime.fromMillisecondsSinceEpoch(dtMs + (ms - rem));
  }

  String _formatTick(DateTime t, Duration range) {
    final local = t.toLocal();
    if (range.inHours >= 48) {
      return '${_monthAbbr(local.month)} ${local.day}';
    }
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _monthAbbr(int m) => _months[m - 1];

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.timelines != timelines ||
      old.rangeStart != rangeStart ||
      old.rangeEnd != rangeEnd ||
      old.onlineColor != onlineColor ||
      old.offlineColor != offlineColor;
}
