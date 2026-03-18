/// Generic wrapper for Spring's paginated responses serialized via
/// PageSerializationMode.VIA_DTO.
///
/// Wire format:
/// ```json
/// { "content": [...], "page": { "size": 50, "number": 0, "totalElements": 100, "totalPages": 2 } }
/// ```
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
  final List<T> content;

  const PageResult({
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.content,
  });

  bool get first => number == 0;
  bool get last => number >= totalPages - 1;
  bool get empty => content.isEmpty;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawContent = json['content'] as List<dynamic>? ?? [];
    final page = json['page'] as Map<String, dynamic>? ?? {};
    return PageResult<T>(
      totalElements: page['totalElements'] as int? ?? 0,
      totalPages: page['totalPages'] as int? ?? 0,
      size: page['size'] as int? ?? 0,
      number: page['number'] as int? ?? 0,
      content: rawContent
          .map((e) => fromItem(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
