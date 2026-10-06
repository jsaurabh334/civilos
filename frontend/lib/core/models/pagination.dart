class PaginationMeta {
  final int total;
  final int page;
  final int pageSize;

  const PaginationMeta({
    this.total = 0,
    this.page = 1,
    this.pageSize = 50,
  });

  int get totalPages => pageSize > 0 ? (total / pageSize).ceil() : 0;
  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory PaginationMeta.fromHeaders(Map<String, String> headers) {
    return PaginationMeta(
      total: int.tryParse(headers['x-total-count'] ?? '') ?? 0,
      page: int.tryParse(headers['x-page'] ?? '') ?? 1,
      pageSize: int.tryParse(headers['x-page-size'] ?? '') ?? 50,
    );
  }
}
