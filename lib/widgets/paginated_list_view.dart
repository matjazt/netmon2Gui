import 'package:flutter/material.dart';

import 'error_display.dart';

/// A generic paginated list that handles the full display lifecycle:
/// - Initial loading spinner (when [isLoading] is true and [items] is empty)
/// - Error state via [ErrorDisplay] (when [error] is non-null)
/// - Empty state with [emptyMessage]
/// - Loaded list with infinite-scroll load-more sentinel
class PaginatedListView<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyMessage;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
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
              itemCount: items.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                if (i == items.length) {
                  if (!isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => onLoadMore(),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return itemBuilder(ctx, items[i]);
              },
            ),
    );
  }
}
