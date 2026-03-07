/// Represents a paginated API response.
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta pagination;

  const PaginatedResponse({
    required this.data,
    required this.pagination,
  });

  /// Parse from raw API JSON map.
  /// [dataKey] is the key in 'data' where the list lives (e.g. 'products', 'orders').
  /// [fromMap] converts each raw map to type T.
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json, {
    required String dataKey,
    required T Function(Map<String, dynamic>) fromMap,
  }) {
    final rawData = json['data']?[dataKey] as List? ?? [];
    final items = rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => fromMap(e))
        .toList();

    final pag = json['pagination'] as Map<String, dynamic>?;

    return PaginatedResponse(
      data: items,
      pagination: pag != null
          ? PaginationMeta.fromJson(pag)
          : PaginationMeta(
              page: 1,
              limit: items.length,
              total: items.length,
              pages: 1,
            ),
    );
  }

  /// Parse when data items are raw Maps (no conversion needed).
  factory PaginatedResponse.fromJsonRaw(
    Map<String, dynamic> json, {
    required String dataKey,
  }) {
    final rawData = json['data']?[dataKey] as List? ?? [];
    final items = rawData
        .whereType<Map<String, dynamic>>()
        .cast<T>()
        .toList();

    final pag = json['pagination'] as Map<String, dynamic>?;

    return PaginatedResponse(
      data: items,
      pagination: pag != null
          ? PaginationMeta.fromJson(pag)
          : PaginationMeta(
              page: 1,
              limit: items.length,
              total: items.length,
              pages: 1,
            ),
    );
  }

  bool get hasNextPage => pagination.page < pagination.pages;
  bool get hasPreviousPage => pagination.page > 1;
}

/// Metadata about pagination (from backend response).
class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 50,
      total: json['total'] as int? ?? 0,
      pages: json['pages'] as int? ?? 1,
    );
  }
}
