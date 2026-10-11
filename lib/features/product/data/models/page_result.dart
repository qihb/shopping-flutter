/// 后端统一分页响应体（对应 `PageResult<XxxVO>`）。
///
/// 用泛型把"分页骨架"和"每条记录的模型类型"拆开：
/// 分页字段（total/pages/current/size）由本类解析，
/// 每条记录怎么转模型交给调用方传入的 [PageResult.fromJson] 回调。
class PageResult<T> {
  final List<T> records;
  final int total;
  final int pages;
  final int current;
  final int size;

  const PageResult({
    required this.records,
    required this.total,
    required this.pages,
    required this.current,
    required this.size,
  });

  /// 是否还有下一页。
  ///
  /// 边界约定：当前页码大于等于总页数时返回 false；
  /// 当前页没有任何记录时也视为没有更多，避免空页继续触发加载。
  bool get hasMore => records.isNotEmpty && current < pages;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final List<dynamic> jsonRecords =
        json['records'] as List<dynamic>? ?? <dynamic>[];

    return PageResult<T>(
      records: jsonRecords
          .map((record) => itemFromJson(record as Map<String, dynamic>))
          .toList(growable: false),
      total: json['total'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
      current: json['current'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
    );
  }
}
