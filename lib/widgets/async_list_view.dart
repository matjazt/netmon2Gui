import 'package:flutter/material.dart';

import 'error_display.dart';

/// A non-paginated async list that handles the full display lifecycle:
/// - Initial loading spinner (when [isLoading] is true and [items] is empty)
/// - Error state via [ErrorDisplay] (when [error] is non-null)
/// - Empty state with [emptyMessage]
/// - Loaded list with pull-to-refresh
class AsyncListView<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyMessage;

  const AsyncListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onRefresh,
    required this.itemBuilder,
    this.error,
    this.emptyMessage = 'No items',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return ErrorDisplay(message: error!, onRetry: onRefresh);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text(emptyMessage)),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) => itemBuilder(ctx, items[i]),
            ),
    );
  }
}
