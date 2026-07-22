import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/app/presentation/pages/main_tab_page.dart';
import 'package:my_first_app/app/theme/app_theme.dart';
import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/home/data/home_recommend_service.dart';
import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/payment/application/payment_service_factory.dart';
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
  /// 可选注入的推荐服务，主要用于测试。
  final HomeRecommendService? recommendService;

  const MyApp({super.key, this.recommendService});

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfigStore.instance;

    return MultiProvider(
      providers: [
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
        home: MainTabPage(recommendService: recommendService),
      ),
    );
  }
}
