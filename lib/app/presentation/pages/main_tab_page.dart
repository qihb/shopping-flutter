import 'package:flutter/material.dart';

import 'package:my_first_app/features/category/presentation/pages/category_page.dart';
import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';
import 'package:my_first_app/features/cart/presentation/pages/cart_page.dart';
import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';
import 'package:my_first_app/features/order/presentation/pages/order_confirm_page.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import 'package:my_first_app/features/product/data/product_service.dart';
import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/application/settings_notifier.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';
import 'package:my_first_app/features/profile/presentation/models/user_profile_summary.dart';
import 'package:my_first_app/features/profile/presentation/pages/profile_page.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/auth/presentation/pages/login_page.dart';

/// 带底部导航的主页面。
///
/// 现在页面本身只保留纯粹的 UI 导航状态（当前 Tab、分类定位），
/// 购物车、订单、地址、设置等跨页面状态全部拆到各自的 `ChangeNotifier` 中，
/// 通过 `provider` 包注入到子树。
class MainTabPage extends StatefulWidget {
  /// 可选注入的商品服务，主要用于测试。
  final ProductService? productService;

  const MainTabPage({super.key, this.productService});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  /// 首页分类入口点击后要定位到的分类 id，null 表示分类页用默认选中项。
  int? _selectedCategoryId;

  // ---------- 辅助 getter ----------

  /// 个人信息摘要。
  ///
  /// 已登录时优先用后端返回的用户信息（昵称 > 用户名），
  /// 未登录时回退到访客占位信息，由页面侧引导登录。
  UserProfileSummary _profile({
    required AddressNotifier addressNotifier,
    required AuthNotifier authNotifier,
  }) {
    final UserInfo? user = authNotifier.user;

    return UserProfileSummary(
      displayName: user?.displayName ?? '访客',
      phone: user?.phone ?? '',
      memberLabel: user != null ? '成长会员' : '',
      defaultAddress: addressNotifier.defaultAddress?.fullAddress ?? '暂未设置',
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

  /// 首页分类入口：携带一级分类 id 跳到分类页并选中对应分类。
  void _openCategoryFromHome(CategoryNode category) {
    setState(() {
      _selectedCategoryId = category.id;
      _currentIndex = 1;
    });
  }

  // ---------- 加购 ----------

  /// 详情页「加入购物车」的统一编排：
  /// - 未登录 → 跳登录页（购物车数据依赖服务端登录态），登录后回来可再次加购
  /// - 未选到有效 SKU → 提示先选择规格
  /// - 已登录 → 调服务端加购，成功后切到购物车 tab
  ///
  /// 返回 `true` 表示本次点击发生了页面导航（跳登录页），
  /// 详情页据此决定是否把自己 pop 出栈。
  bool _addProductToCart(
    BuildContext context,
    ProductSummary product,
    ProductSku? sku,
  ) {
    final AuthNotifier authNotifier = context.read<AuthNotifier>();

    if (!authNotifier.isAuthenticated) {
      _openLoginPage(context);
      return true;
    }

    final int? skuId = sku?.id;

    if (skuId == null) {
      _showMessage(context, '请先选择商品规格');
      return false;
    }

    // 加购是异步操作，详情页无需等待结果，立即退出由购物车 tab 反馈。
    _addToCart(context, product, skuId);
    return false;
  }

  Future<void> _addToCart(
    BuildContext context,
    ProductSummary product,
    int skuId,
  ) async {
    final CartNotifier cartNotifier = context.read<CartNotifier>();
    final bool didSucceed = await cartNotifier.addToCart(skuId: skuId);

    if (!context.mounted) {
      return;
    }

    if (didSucceed) {
      setState(() {
        _currentIndex = 2;
      });
      _showMessage(context, '已加入购物车：${product.name}');
    } else {
      _showMessage(
        context,
        cartNotifier.errorMessage ?? '加入购物车失败，请稍后重试',
      );
    }
  }

  // ---------- 提交订单 ----------

  void _openOrderConfirmPage(BuildContext context) {
    final CartNotifier cartNotifier = context.read<CartNotifier>();
    // 下单来源固定为购物车勾选项（已勾选且有效的条目）。
    final List<CartItemVO> selectedItems = cartNotifier.selectedItems;

    if (selectedItems.isEmpty) {
      return;
    }

    // 收货地址是服务端数据，账号还没维护地址时先引导，不让流程带着空地址往下走。
    final AddressVO? address = context.read<AddressNotifier>().defaultAddress;

    if (address == null) {
      _showMessage(context, '请先在「我的-地址管理」中添加收货地址');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrderConfirmPage(
          items: selectedItems,
          address: address,
          onConfirmPayment: (method) async {
            final bool didSucceed = await _submitOrder(
              context,
              addressId: address.id,
              method: method,
            );
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

  /// 下单 + 支付的完整编排：先创建订单拿到服务端订单号，再发起支付。
  ///
  /// 订单创建成功但支付失败时，订单会停留在「待付款」，
  /// 用户可以在订单记录里继续支付；支付成功后清理购物车勾选项。
  Future<bool> _submitOrder(
    BuildContext context, {
    required int addressId,
    required PaymentMethod method,
  }) async {
    final OrderNotifier orderNotifier = context.read<OrderNotifier>();

    final String? orderNo = await orderNotifier.createOrder(
      addressId: addressId,
    );

    if (!context.mounted) {
      return false;
    }

    if (orderNo == null) {
      _showMessage(context, orderNotifier.errorMessage ?? '创建订单失败，请稍后重试');
      return false;
    }

    final bool didSucceed = await orderNotifier.payOrder(orderNo, method: method);

    if (!context.mounted) {
      return didSucceed;
    }

    if (didSucceed) {
      // 下单来源是购物车勾选项，支付成功后从服务端移除已勾选条目。
      await context.read<CartNotifier>().removeCheckedItems();
      if (!context.mounted) {
        return true;
      }
      _showMessage(context, '支付成功');
    } else {
      _showMessage(context, orderNotifier.errorMessage ?? '支付失败，请稍后重试');
    }

    return didSucceed;
  }

  // ---------- 订单动作 ----------

  /// 继续支付待付款订单（支付渠道沿用默认收银台渠道）。
  Future<bool> _repayOrder(BuildContext context, OrderVO order) async {
    final OrderNotifier orderNotifier = context.read<OrderNotifier>();
    final bool didSucceed = await orderNotifier.payOrder(order.orderNo);

    if (context.mounted) {
      _showMessage(
        context,
        didSucceed ? '支付成功' : orderNotifier.errorMessage ?? '支付失败，请稍后重试',
      );
    }

    if (didSucceed) {
      _switchTab(3);
    }

    return didSucceed;
  }

  /// 确认收货：待收货 → 已完成。
  Future<bool> _confirmReceipt(BuildContext context, OrderVO order) async {
    final OrderNotifier orderNotifier = context.read<OrderNotifier>();
    final bool didSucceed = await orderNotifier.confirmReceipt(order.orderNo);

    if (context.mounted) {
      _showMessage(
        context,
        didSucceed ? '已确认收货' : orderNotifier.errorMessage ?? '确认收货失败，请稍后重试',
      );
    }

    return didSucceed;
  }

  /// 取消订单：待付款 → 已取消（服务端回滚库存）。
  Future<bool> _cancelOrder(BuildContext context, OrderVO order) async {
    final OrderNotifier orderNotifier = context.read<OrderNotifier>();
    final bool didSucceed = await orderNotifier.cancelOrder(order.orderNo);

    if (context.mounted) {
      _showMessage(
        context,
        didSucceed ? '订单已取消' : orderNotifier.errorMessage ?? '取消订单失败，请稍后重试',
      );
    }

    return didSucceed;
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

  // ---------- 登录态 ----------

  void _openLoginPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthNotifier>().logout();
    if (context.mounted) {
      _showMessage(context, '已退出登录');
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final CartNotifier cartNotifier = context.watch<CartNotifier>();

    final List<Widget> pages = [
      HomePage(
        onCategoryTap: _openCategoryFromHome,
        onAddToCart: (product, sku) => _addProductToCart(context, product, sku),
        productService: widget.productService,
      ),
      CategoryPage(
        initialCategoryId: _selectedCategoryId,
        onAddToCart: (product, sku) => _addProductToCart(context, product, sku),
        productService: widget.productService,
      ),
      // 购物车页直接从 CartNotifier 读取服务端数据，
      // 提交订单与去登录的导航编排仍由 MainTabPage 承担。
      CartPage(
        onOpenConfirmPage: () => _openOrderConfirmPage(context),
        onLogin: () => _openLoginPage(context),
      ),
      Builder(
        builder: (ctx) {
          final AddressNotifier addressNotifier = ctx.watch<AddressNotifier>();
          final SettingsNotifier settingsNotifier = ctx.watch<SettingsNotifier>();
          final OrderNotifier orderNotifier = ctx.watch<OrderNotifier>();
          final AuthNotifier authNotifier = ctx.watch<AuthNotifier>();

          return ProfilePage(
            profile: _profile(
              addressNotifier: addressNotifier,
              authNotifier: authNotifier,
            ),
            isLoggedIn: authNotifier.isAuthenticated,
            addresses: addressNotifier.addresses,
            settings: settingsNotifier.settings,
            orders: orderNotifier.orders,
            onRepayOrder: orderNotifier.orders.isEmpty
                ? null
                : (order) => _repayOrder(context, order),
            onConfirmOrder: orderNotifier.orders.isEmpty
                ? null
                : (order) => _confirmReceipt(context, order),
            onCancelOrder: orderNotifier.orders.isEmpty
                ? null
                : (order) => _cancelOrder(context, order),
            onNotificationChanged: (value) =>
                _updateNotificationSetting(context, value),
            onBiometricUnlockChanged: (value) =>
                _updateBiometricSetting(context, value),
            onPriceAlertChanged: (value) =>
                _updatePriceAlertSetting(context, value),
            onLogin: () => _openLoginPage(context),
            onLogout: () => _logout(context),
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
            // 角标用服务端汇总的总件数（含未勾选与失效条目）。
            icon: _CartTabIcon(itemCount: cartNotifier.totalQuantity),
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
