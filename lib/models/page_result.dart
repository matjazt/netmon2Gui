/// Generic wrapper for Spring's paginated responses (Page* DTOs).
///
/// Usage:
/// ```dart
/// PageResult<LogEntry>.fromJson(json, (e) => LogEntry.fromJson(e))
/// ```
class PageResult<T> {
  final int totalElements;
  final int totalPages;
  final int size;
  final int number; // current page index (0-based)
  final bool first;
  final bool last;
  final bool empty;
  final List<T> content;

  const PageResult({
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
    required this.content,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawContent = json['content'] as List<dynamic>? ?? [];
    return PageResult<T>(
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      empty: json['empty'] as bool? ?? true,
      content: rawContent
          .map((e) => fromItem(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
