import 'package:flutter/material.dart';

import 'package:my_first_app/features/cart/presentation/pages/cart_page.dart';
import 'package:my_first_app/features/category/presentation/pages/category_page.dart';
import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import 'package:my_first_app/features/profile/presentation/pages/profile_page.dart';

/// 带底部导航的主页面。
///
/// 这里使用 `StatefulWidget`，是因为当前选中的菜单索引会变化。
/// 你可以先把它理解成“页面里有一小块会随点击变化的本地状态”。
class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;
  String? _selectedCategoryLabel;

  void _openCategoryFromHome(String categoryLabel) {
    setState(() {
      _selectedCategoryLabel = categoryLabel;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4 个一级页面还是通过 `IndexedStack` 统一承载，
    // 只是首页和分类页现在需要和外层交换一点点状态。
    final List<Widget> pages = [
      HomePage(onCategoryTap: _openCategoryFromHome),
      CategoryPage(initialCategoryLabel: _selectedCategoryLabel),
      const CartPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      // `IndexedStack` 很适合做 Tab 场景。
      // 它会像网页里“切换页签但保留内容”那样，只显示当前索引对应的页面。
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: '分类'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: '购物车',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
