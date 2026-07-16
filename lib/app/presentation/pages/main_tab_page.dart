import 'package:flutter/material.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/cart/presentation/pages/cart_page.dart';
import 'package:my_first_app/features/category/presentation/pages/category_page.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/profile/presentation/models/profile_settings.dart';
import 'package:my_first_app/features/profile/presentation/models/user_profile_summary.dart';
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
  static const UserProfileSummary _profile = UserProfileSummary(
    displayName: 'Qi Hai Bing',
    email: 'qihaibing@example.com',
    memberLabel: '成长会员',
    defaultAddress: '上海市浦东新区张江高科',
  );

  int _currentIndex = 0;
  String? _selectedCategoryLabel;
  final List<CartItem> _cartItems = <CartItem>[];
  final List<OrderRecord> _orders = <OrderRecord>[];
  ProfileSettings _settings = const ProfileSettings(
    enableNotification: true,
    enableBiometricUnlock: false,
    enablePriceAlert: true,
  );

  void _openCategoryFromHome(String categoryLabel) {
    setState(() {
      _selectedCategoryLabel = categoryLabel;
      _currentIndex = 1;
    });
  }

  void _addProductToCart(HomeRecommendProduct product) {
    final int existingIndex = _cartItems.indexWhere(
      (item) => item.name == product.name,
    );

    setState(() {
      if (existingIndex >= 0) {
        final CartItem existingItem = _cartItems[existingIndex];
        _cartItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );
      } else {
        _cartItems.add(CartItem.fromHomeRecommendProduct(product));
      }

      _currentIndex = 2;
    });
  }

  void _increaseCartItemQuantity(CartItem item) {
    final int itemIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.name == item.name,
    );

    if (itemIndex < 0) {
      return;
    }

    setState(() {
      final CartItem existingItem = _cartItems[itemIndex];
      _cartItems[itemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    });
  }

  void _decreaseCartItemQuantity(CartItem item) {
    final int itemIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.name == item.name,
    );

    if (itemIndex < 0) {
      return;
    }

    setState(() {
      final CartItem existingItem = _cartItems[itemIndex];
      final int nextQuantity = existingItem.quantity - 1;

      _cartItems[itemIndex] = existingItem.copyWith(
        quantity: nextQuantity < 1 ? 1 : nextQuantity,
      );
    });
  }

  void _submitOrder() {
    if (_cartItems.isEmpty) {
      return;
    }

    final OrderRecord order = OrderRecord.fromCartItems(
      id: 'ORD-${_orders.length + 1}'.padLeft(7, '0'),
      items: _cartItems,
    );

    setState(() {
      _orders.insert(0, order);
      _cartItems.clear();
      _currentIndex = 3;
    });
  }

  void _updateNotificationSetting(bool value) {
    setState(() {
      _settings = _settings.copyWith(enableNotification: value);
    });
  }

  void _updateBiometricSetting(bool value) {
    setState(() {
      _settings = _settings.copyWith(enableBiometricUnlock: value);
    });
  }

  void _updatePriceAlertSetting(bool value) {
    setState(() {
      _settings = _settings.copyWith(enablePriceAlert: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4 个一级页面还是通过 `IndexedStack` 统一承载，
    // 只是首页和分类页现在需要和外层交换一点点状态。
    final List<Widget> pages = [
      HomePage(
        onCategoryTap: _openCategoryFromHome,
        onAddToCart: _addProductToCart,
      ),
      CategoryPage(
        initialCategoryLabel: _selectedCategoryLabel,
        onAddToCart: _addProductToCart,
      ),
      CartPage(
        items: _cartItems,
        onIncreaseQuantity: _increaseCartItemQuantity,
        onDecreaseQuantity: _decreaseCartItemQuantity,
        onSubmitOrder: _submitOrder,
      ),
      ProfilePage(
        profile: _profile,
        settings: _settings,
        orders: _orders,
        onNotificationChanged: _updateNotificationSetting,
        onBiometricUnlockChanged: _updateBiometricSetting,
        onPriceAlertChanged: _updatePriceAlertSetting,
      ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: '分类',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: '购物车',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
