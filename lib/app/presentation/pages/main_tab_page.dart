import 'package:flutter/material.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/cart/presentation/pages/cart_page.dart';
import 'package:my_first_app/features/category/presentation/pages/category_page.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/order/presentation/pages/order_confirm_page.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';
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
  static const UserProfileSummary _baseProfile = UserProfileSummary(
    displayName: 'Qi Hai Bing',
    email: 'qihaibing@example.com',
    memberLabel: '成长会员',
    defaultAddress: '上海市浦东新区张江高科',
  );

  int _currentIndex = 0;
  String? _selectedCategoryLabel;
  final List<CartItem> _cartItems = <CartItem>[];
  final List<OrderRecord> _orders = <OrderRecord>[];
  List<UserAddress> _addresses = const <UserAddress>[
    UserAddress(
      recipientName: 'Qi Hai Bing',
      phone: '138 0000 1234',
      cityLabel: '上海市',
      detailAddress: '浦东新区张江高科',
      isDefault: true,
    ),
    UserAddress(
      recipientName: 'Qi Hai Bing',
      phone: '138 0000 5678',
      cityLabel: '上海市',
      detailAddress: '徐汇区漕河泾开发区',
    ),
  ];
  ProfileSettings _settings = const ProfileSettings(
    enableNotification: true,
    enableBiometricUnlock: false,
    enablePriceAlert: true,
  );

  UserAddress get _defaultAddress {
    return _addresses.firstWhere((address) => address.isDefault);
  }

  UserProfileSummary get _profile {
    return _baseProfile.copyWith(defaultAddress: _defaultAddress.fullAddress);
  }

  int get _cartItemCount {
    return _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

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

    _showMessage('已加入购物车：${product.name}');
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

  void _removeCartItem(CartItem item) {
    setState(() {
      _cartItems.removeWhere((cartItem) => cartItem.name == item.name);
    });

    _showMessage('已从购物车删除：${item.name}');
  }

  void _clearCart() {
    if (_cartItems.isEmpty) {
      return;
    }

    setState(() {
      _cartItems.clear();
    });

    _showMessage('购物车已清空');
  }

  void _openOrderConfirmPage() {
    if (_cartItems.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrderConfirmPage(
          items: _cartItems,
          address: _defaultAddress,
          onConfirmPayment: () {
            _submitOrder();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _submitOrder() {
    if (_cartItems.isEmpty) {
      return;
    }

    final OrderRecord order = OrderRecord.fromCartItems(
      id: 'ORD-${(_orders.length + 1).toString().padLeft(7, '0')}',
      items: _cartItems,
      shippingAddress: _defaultAddress,
    );

    setState(() {
      _orders.insert(0, order);
      _cartItems.clear();
      _currentIndex = 3;
    });

    _showMessage('支付成功');
  }

  void _advanceOrderStatus(OrderRecord order) {
    final int orderIndex = _orders.indexWhere((item) => item.id == order.id);

    if (orderIndex < 0) {
      return;
    }

    final OrderRecord nextOrder = _orders[orderIndex].advanceStatus();

    if (identical(nextOrder, _orders[orderIndex])) {
      return;
    }

    setState(() {
      _orders[orderIndex] = nextOrder;
    });

    _showMessage('订单状态已更新为：${nextOrder.statusLabel}');
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

  void _setDefaultAddress(UserAddress targetAddress) {
    setState(() {
      _addresses = _addresses
          .map(
            (address) => address.copyWith(
              isDefault: address.fullAddress == targetAddress.fullAddress,
            ),
          )
          .toList(growable: false);
    });

    _showMessage('默认地址已更新');
  }

  @override
  Widget build(BuildContext context) {
    final List<OrderRecord> displayOrders = _orders.isEmpty
        ? OrderRecord.learningSamples
        : _orders;
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
        onRemoveItem: _removeCartItem,
        onClearCart: _clearCart,
        onSubmitOrder: _openOrderConfirmPage,
      ),
      ProfilePage(
        profile: _profile,
        addresses: _addresses,
        settings: _settings,
        orders: displayOrders,
        onAdvanceOrderStatus: _orders.isEmpty ? null : _advanceOrderStatus,
        onSetDefaultAddress: _setDefaultAddress,
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            label: '分类',
          ),
          BottomNavigationBarItem(
            icon: _CartTabIcon(itemCount: _cartItemCount),
            label: '购物车',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class _CartTabIcon extends StatelessWidget {
  final int itemCount;

  const _CartTabIcon({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart_outlined),
        if (itemCount > 0)
          Positioned(
            top: -6,
            right: -10,
            child: Container(
              key: const ValueKey<String>('cart-tab-badge'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$itemCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
