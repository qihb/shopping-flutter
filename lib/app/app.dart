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
import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/payment/application/payment_service_factory.dart';
import 'package:my_first_app/features/product/data/product_service.dart';
import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/application/settings_notifier.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

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

  const MyApp({super.key, this.productService, this.authNotifier});

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

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfigStore.instance;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) => authNotifier ?? _createAuthNotifier(),
        ),
        ChangeNotifierProvider<CartNotifier>(
          create: (_) => CartNotifier(),
        ),
        ChangeNotifierProvider<OrderNotifier>(
          create: (_) => OrderNotifier(
            paymentService: PaymentServiceFactory.create(appConfig),
          ),
        ),
        ChangeNotifierProvider<AddressNotifier>(
          create: (_) => AddressNotifier(
            initialAddresses: const <UserAddress>[
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
            ],
          ),
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
