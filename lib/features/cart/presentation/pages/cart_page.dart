import 'package:flutter/material.dart';

/// 购物车页。
///
/// 这里先放一个简单占位内容，后续可以逐步补商品列表、
/// 数量修改、价格汇总和结算入口。
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '购物车内容建设中',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
