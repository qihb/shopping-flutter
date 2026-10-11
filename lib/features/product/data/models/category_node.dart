/// 分类树节点（对应后端 `CategoryNodeVO`）。
///
/// 后端返回的是一棵可递归的树：一级分类的 [children] 里挂二级分类，
/// [fromJson] 会递归解析整棵子树。
class CategoryNode {
  final int id;
  final int parentId;
  final String name;

  /// 排序值，越小越靠前。
  final int sort;

  /// 状态：后端只返回启用的分类。
  final int status;
  final List<CategoryNode> children;

  const CategoryNode({
    required this.id,
    required this.parentId,
    required this.name,
    required this.sort,
    required this.status,
    required this.children,
  });

  /// 是否有子分类，决定分类页右侧是否展示二级分类 chips。
  bool get hasChildren => children.isNotEmpty;

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    final List<dynamic> jsonChildren =
        json['children'] as List<dynamic>? ?? <dynamic>[];

    return CategoryNode(
      id: json['id'] as int? ?? 0,
      parentId: json['parentId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sort: json['sort'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      // 递归解析子分类，树上任意深度的节点都用同一套规则。
      children: jsonChildren
          .map((child) =>
              CategoryNode.fromJson(child as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
