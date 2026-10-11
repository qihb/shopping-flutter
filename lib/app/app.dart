import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/app/presentation/pages/main_tab_page.dart';
import 'package:my_first_app/app/theme/app_theme.dart';
import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/auth_service.dart';
import 'package:my_first_app/features/auth/data/token_store.dart';
import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/cart/data/cart_service.dart';
import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/order/data/order_service.dart';
import 'package:my_first_app/features/payment/application/payment_service_factory.dart';
import 'package:my_first_app/features/product/data/product_service.dart';
import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/application/settings_notifier.dart';
import 'package:my_first_app/features/profile/data/address_service.dart';

/// 整个应用的根组件。
///
/// `MultiProvider` 是 `provider` 包提供的多状态容器：
/// - 它把多个 `ChangeNotifier` 注册到 Widget 树顶部
/// - 子树中任何位置都可以通过 `context.watch<T>()` / `context.read<T>()` 访问
///
/// 以前这些状态全部挤在 `MainTabPage` 的 State 里，
/// 现在这些状态各自拆成独立的 Notifier，职责更清晰。
class MyApp extends StatelessWidget {
  /// 可选注入的商品服务，主要用于测试。
  final ProductService? productService;

  /// 可选注入的登录态 Notifier，主要用于测试时替换真实网络实现。
  final AuthNotifier? authNotifier;

  /// 可选注入的购物车 Notifier，主要用于测试时替换服务端购物车实现。
  final CartNotifier? cartNotifier;

  /// 可选注入的收货地址 Notifier，主要用于测试时替换服务端地址实现。
  final AddressNotifier? addressNotifier;

  /// 可选注入的订单 Notifier，主要用于测试时替换服务端订单实现。
  final OrderNotifier? orderNotifier;

  const MyApp({
    super.key,
    this.productService,
    this.authNotifier,
    this.cartNotifier,
    this.addressNotifier,
    this.orderNotifier,
  });

  /// 创建真实环境的登录态管理。
  ///
  /// 装配关系：
  /// - [SharedPrefsTokenStore] 负责本地持久化 token / clientId
  /// - [ApiClient] 每次请求前通过 tokenProvider 读最新 token 注入请求头
  /// - [AuthService] 对接后端认证接口
  /// - [AuthNotifier.restoreSession] 在 App 启动时尝试恢复登录态
  AuthNotifier _createAuthNotifier() {
    final TokenStore tokenStore = SharedPrefsTokenStore();
    final ApiClient apiClient = ApiClient(
      baseUrl: AppConfigStore.instance.apiBaseUrl,
      tokenProvider: tokenStore.readToken,
    );
    final AuthService authService = AuthService(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    // `..` 是 Dart 的级联语法，对同一个对象连续调用，
    // 这里等价于：先创建 Notifier，再异步触发一次会话恢复。
    return AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    )..restoreSession();
  }

  /// 创建真实环境的商品域服务。
  ///
  /// 首页推荐流、分类页、商品详情共用同一个 [ProductService]，
  /// baseUrl 取当前环境配置。
  ProductService _createProductService() {
    return ProductService(
      apiClient: ApiClient(baseUrl: AppConfigStore.instance.apiBaseUrl),
    );
  }

  /// 创建真实环境的购物车状态管理。
  ///
  /// 购物车接口需要登录态，所以这里的 [ApiClient] 与认证模块一样
  /// 携带 tokenProvider，每次请求前从本地存储读取最新 token 注入请求头。
  CartNotifier _createCartNotifier() {
    final ApiClient apiClient = ApiClient(
      baseUrl: AppConfigStore.instance.apiBaseUrl,
      tokenProvider: SharedPrefsTokenStore().readToken,
    );

    return CartNotifier(cartService: CartService(apiClient: apiClient));
  }

  /// 创建真实环境的收货地址状态管理。
  ///
  /// 地址接口同样需要登录态，与购物车使用相同的 token 注入方式。
  AddressNotifier _createAddressNotifier() {
    final ApiClient apiClient = ApiClient(
      baseUrl: AppConfigStore.instance.apiBaseUrl,
      tokenProvider: SharedPrefsTokenStore().readToken,
    );

    return AddressNotifier(
      addressService: AddressService(apiClient: apiClient),
    );
  }

  /// 创建真实环境的订单状态管理。
  ///
  /// 下单与状态流转走订单接口，支付动作经 [PaymentServiceFactory]
  /// 组装为服务端模拟支付网关；两者共用同一个带登录态的 [ApiClient]。
  OrderNotifier _createOrderNotifier() {
    final ApiClient apiClient = ApiClient(
      baseUrl: AppConfigStore.instance.apiBaseUrl,
      tokenProvider: SharedPrefsTokenStore().readToken,
    );

    return OrderNotifier(
      orderService: OrderService(apiClient: apiClient),
      paymentService: PaymentServiceFactory.create(
        AppConfigStore.instance,
        apiClient: apiClient,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfigStore.instance;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) => authNotifier ?? _createAuthNotifier(),
        ),
        ChangeNotifierProvider<CartNotifier>(
          create: (context) {
            final CartNotifier notifier = cartNotifier ?? _createCartNotifier();
            // 登录 / 退出时自动拉取或清空购物车，无需页面手动编排。
            notifier.attachAuth(context.read<AuthNotifier>());
            return notifier;
          },
        ),
        ChangeNotifierProvider<OrderNotifier>(
          create: (context) {
            final OrderNotifier notifier =
                orderNotifier ?? _createOrderNotifier();
            // 登录 / 退出时自动拉取或清空订单，无需页面手动编排。
            notifier.attachAuth(context.read<AuthNotifier>());
            return notifier;
          },
        ),
        ChangeNotifierProvider<AddressNotifier>(
          create: (context) {
            final AddressNotifier notifier =
                addressNotifier ?? _createAddressNotifier();
            // 登录 / 退出时自动拉取或清空地址，无需页面手动编排。
            notifier.attachAuth(context.read<AuthNotifier>());
            return notifier;
          },
        ),
        ChangeNotifierProvider<SettingsNotifier>(
          create: (_) => SettingsNotifier(),
        ),
      ],
      child: MaterialApp(
        title: appConfig.appName,
        theme: AppTheme.light(),
        home: MainTabPage(
          productService: productService ?? _createProductService(),
        ),
      ),
    );
  }
}
