import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';

/// 购物车出参：条目列表 + 服务端汇总（对应后端 `CartVO`）。
///
/// 汇总字段由后端统一计算（仅统计有效且勾选的条目），
/// 前端只做展示，不再本地重复计算金额。
class CartVO {
  final List<CartItemVO> items;

  /// 购物车总件数（所有条目数量之和），底部导航角标用它。
  final int totalQuantity;

  /// 已勾选件数（仅统计有效且勾选的条目）。
  final int checkedQuantity;

  /// 已勾选金额合计，单位：元。
  final double checkedAmount;

  const CartVO({
    required this.items,
    required this.totalQuantity,
    required this.checkedQuantity,
    required this.checkedAmount,
  });

  factory CartVO.fromJson(Map<String, dynamic> json) {
    return CartVO(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                CartItemVO.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      totalQuantity: json['totalQuantity'] as int? ?? 0,
      checkedQuantity: json['checkedQuantity'] as int? ?? 0,
      checkedAmount: (json['checkedAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
