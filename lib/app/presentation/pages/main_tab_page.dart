import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/cart/presentation/pages/cart_page.dart';
import 'package:my_first_app/features/category/presentation/pages/category_page.dart';
import 'package:my_first_app/features/home/data/home_recommend_service.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/order/presentation/pages/order_confirm_page.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';
import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/application/settings_notifier.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';
import 'package:my_first_app/features/profile/presentation/models/user_profile_summary.dart';
import 'package:my_first_app/features/profile/presentation/pages/profile_page.dart';

/// 带底部导航的主页面。
///
/// 现在页面本身只保留纯粹的 UI 导航状态（当前 Tab、分类定位），
/// 购物车、订单、地址、设置等跨页面状态全部拆到各自的 `ChangeNotifier` 中，
/// 通过 `provider` 包注入到子树。
class MainTabPage extends StatefulWidget {
  /// 可选注入的推荐服务，主要用于测试。
  final HomeRecommendService? recommendService;

  const MainTabPage({super.key, this.recommendService});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;
  String? _selectedCategoryLabel;

  // ---------- 辅助 getter ----------

  /// 个人信息摘要，依赖地址 Notifier 计算默认地址。
  UserProfileSummary _profile({
    required AddressNotifier addressNotifier,
  }) {
    const UserProfileSummary baseProfile = UserProfileSummary(
      displayName: 'Qi Hai Bing',
      email: 'qihaibing@example.com',
      memberLabel: '成长会员',
      defaultAddress: '上海市浦东新区张江高科',
    );

    return baseProfile.copyWith(
      defaultAddress: addressNotifier.defaultAddress.fullAddress,
    );
  }

  // ---------- 导航与 SnackBar ----------

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openCategoryFromHome(String categoryLabel) {
    setState(() {
      _selectedCategoryLabel = categoryLabel;
      _currentIndex = 1;
    });
  }

  // ---------- 加购 ----------

  void _addProductToCart(BuildContext context, HomeRecommendProduct product) {
    context.read<CartNotifier>().addProduct(product);
    setState(() {
      _currentIndex = 2;
    });
    _showMessage(context, '已加入购物车：${product.name}');
  }

  // ---------- 提交订单 ----------

  void _openOrderConfirmPage(BuildContext context) {
    final CartNotifier cartNotifier = context.read<CartNotifier>();

    if (cartNotifier.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrderConfirmPage(
          items: cartNotifier.items,
          address: context.read<AddressNotifier>().defaultAddress,
          onConfirmPayment: (method) async {
            final bool didSucceed = await _submitOrder(context, method);
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
            if (didSucceed) {
              _switchTab(3);
            }
          },
        ),
      ),
    );
  }

  Future<bool> _submitOrder(
    BuildContext context,
    PaymentMethod method,
  ) async {
    final CartNotifier cartNotifier = context.read<CartNotifier>();
    final OrderNotifier orderNotifier = context.read<OrderNotifier>();
    final AddressNotifier addressNotifier = context.read<AddressNotifier>();

    if (cartNotifier.isEmpty) {
      return false;
    }

    final PaymentResult result = await orderNotifier.submitOrder(
      cartItems: cartNotifier.items,
      shippingAddress: addressNotifier.defaultAddress,
      method: method,
    );

    if (result.status == PaymentStatus.success) {
      cartNotifier.clear();
    }

    _showMessage(context, result.message);
    return result.status == PaymentStatus.success;
  }

  // ---------- 重新支付 ----------

  Future<bool> _openRepayOrderConfirmPage(
    BuildContext context, {
    required OrderRecord order,
  }) async {
    final bool? didSucceed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => OrderConfirmPage(
          items: order.items,
          address: order.shippingAddress,
          onConfirmPayment: (method) async {
            final bool ok = await _repayOrder(context, order: order, method: method);
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop(ok);
          },
        ),
      ),
    );

    if (didSucceed == true) {
      _switchTab(3);
    }

    return didSucceed ?? false;
  }

  Future<bool> _repayOrder(
    BuildContext context, {
    required OrderRecord order,
    required PaymentMethod method,
  }) async {
    final OrderNotifier orderNotifier = context.read<OrderNotifier>();
    final bool didSucceed = await orderNotifier.repayOrder(order, method);
    return didSucceed;
  }

  // ---------- 推进订单状态 ----------

  void _advanceOrderStatus(BuildContext context, OrderRecord order) {
    final OrderNotifier orderNotifier = context.read<OrderNotifier>();
    orderNotifier.advanceStatus(order);
    _showMessage(context, '订单状态已更新为：${order.nextStatusLabel}');
  }

  // ---------- 设置 ----------

  void _updateNotificationSetting(BuildContext context, bool value) {
    context.read<SettingsNotifier>().updateNotification(value);
  }

  void _updateBiometricSetting(BuildContext context, bool value) {
    context.read<SettingsNotifier>().updateBiometric(value);
  }

  void _updatePriceAlertSetting(BuildContext context, bool value) {
    context.read<SettingsNotifier>().updatePriceAlert(value);
  }

  // ---------- 默认地址 ----------

  void _setDefaultAddress(BuildContext context, UserAddress address) {
    context.read<AddressNotifier>().setDefault(address);
    _showMessage(context, '默认地址已更新');
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final CartNotifier cartNotifier = context.watch<CartNotifier>();

    final List<Widget> pages = [
      HomePage(
        onCategoryTap: _openCategoryFromHome,
        onAddToCart: (product) => _addProductToCart(context, product),
        recommendService: widget.recommendService,
      ),
      CategoryPage(
        initialCategoryLabel: _selectedCategoryLabel,
        onAddToCart: (product) => _addProductToCart(context, product),
      ),
      // 购物车页现在直接从 CartNotifier 读取数据，
      // 但仍然预留回调出口，由 MainTabPage 编排跨 Notifier 的操作。
      CartPage(
        onOpenConfirmPage: () => _openOrderConfirmPage(context),
      ),
      Builder(
        builder: (ctx) {
          final AddressNotifier addressNotifier = ctx.watch<AddressNotifier>();
          final SettingsNotifier settingsNotifier = ctx.watch<SettingsNotifier>();
          final OrderNotifier orderNotifier = ctx.watch<OrderNotifier>();

          return ProfilePage(
            profile: _profile(addressNotifier: addressNotifier),
            addresses: addressNotifier.addresses,
            settings: settingsNotifier.settings,
            orders: orderNotifier.displayOrders,
            onAdvanceOrderStatus: orderNotifier.orders.isEmpty
                ? null
                : (order) => _advanceOrderStatus(context, order),
            onRepayOrder: orderNotifier.orders.isEmpty
                ? null
                : (order) => _openRepayOrderConfirmPage(context, order: order),
            onSetDefaultAddress: (address) =>
                _setDefaultAddress(context, address),
            onNotificationChanged: (value) =>
                _updateNotificationSetting(context, value),
            onBiometricUnlockChanged: (value) =>
                _updateBiometricSetting(context, value),
            onPriceAlertChanged: (value) =>
                _updatePriceAlertSetting(context, value),
          );
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _switchTab,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '首页',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: '分类',
          ),
          BottomNavigationBarItem(
            icon: _CartTabIcon(itemCount: cartNotifier.itemCount),
            label: '购物车',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
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
