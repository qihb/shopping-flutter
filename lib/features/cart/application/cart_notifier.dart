import 'package:flutter/foundation.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';

/// 购物车状态管理。
///
/// `ChangeNotifier` 是 Flutter 里最基础的可监听状态容器：
/// - 内部数据变化时调用 `notifyListeners()`
/// - 外部的 `context.watch<CartNotifier>()` 会自动触发 UI 重建
///
/// 把它从 `MainTabPage` 拆出来以后，购物车相关的逻辑不再散落在主页面里，
/// 其他页面也只需要 `context.read<CartNotifier>()` 就能操作购物车。
class CartNotifier extends ChangeNotifier {
  final List<CartItem> _items = <CartItem>[];

  /// 购物车商品列表（不可变视图）。
  List<CartItem> get items => List<CartItem>.unmodifiable(_items);

  /// 购物车商品总件数。
  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// 购物车总价。
  int get totalPrice => _items.fold<int>(0, (sum, item) => sum + item.totalPrice);

  /// 是否为空。
  bool get isEmpty => _items.isEmpty;

  /// 从商品详情 / 首页推荐商品加入购物车。
  ///
  /// 如果同名商品已存在，数量 +1；否则新增一条。
  void addProduct(ProductSummary product) {
    final int existingIndex = _items.indexWhere(
      (item) => item.name == product.name,
    );

    if (existingIndex >= 0) {
      final CartItem existingItem = _items[existingIndex];
      _items[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      _items.add(CartItem.fromProductSummary(product));
    }

    notifyListeners();
  }

  /// 增加指定商品数量。
  void increaseQuantity(CartItem item) {
    final int index = _items.indexWhere((cartItem) => cartItem.name == item.name);

    if (index < 0) {
      return;
    }

    _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    notifyListeners();
  }

  /// 减少指定商品数量（最低保留 1）。
  void decreaseQuantity(CartItem item) {
    final int index = _items.indexWhere((cartItem) => cartItem.name == item.name);

    if (index < 0) {
      return;
    }

    final int nextQuantity = _items[index].quantity - 1;
    _items[index] = _items[index].copyWith(
      quantity: nextQuantity < 1 ? 1 : nextQuantity,
    );
    notifyListeners();
  }

  /// 从购物车中移除指定商品。
  void removeItem(CartItem item) {
    _items.removeWhere((cartItem) => cartItem.name == item.name);
    notifyListeners();
  }

  /// 清空购物车。
  void clear() {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();
    notifyListeners();
  }
}
