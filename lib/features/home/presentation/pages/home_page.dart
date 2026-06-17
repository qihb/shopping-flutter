import 'package:flutter/material.dart';

/// 首页占位页面。
///
/// 这个页面现在不再自己包 `Scaffold`，
/// 因为外层已经有一个统一承载底部导航的主页面。
///
/// 你可以先把它理解成“首页这个 Tab 自己负责的内容区域”。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            // 限制内容最大宽度，避免在大屏设备上文字铺得太宽。
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '首页内容建设中',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  '这里会逐步补上 Banner、分类入口和推荐商品等首页模块。',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
