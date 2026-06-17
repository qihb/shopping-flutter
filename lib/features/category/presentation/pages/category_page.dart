import 'package:flutter/material.dart';

/// 分类页。
///
/// 这个页面先保留成占位结构，方便后续继续往里加分类导航、
/// 商品分组和筛选等典型电商内容。
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // `SafeArea` 会避开刘海、状态栏、底部手势区域，
      // 可以先把它理解成“帮页面内容留出安全边距”的容器。
      child: Center(
        child: Text(
          '分类内容建设中',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
