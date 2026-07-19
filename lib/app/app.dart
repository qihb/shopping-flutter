import 'package:flutter/material.dart';

import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/app/presentation/pages/main_tab_page.dart';
import 'package:my_first_app/app/theme/app_theme.dart';
import 'package:my_first_app/features/payment/application/payment_service_factory.dart';

/// 整个应用的根组件。
///
/// 这个文件可以理解成“应用外壳”：
/// - 决定应用使用什么主题
/// - 决定首页先打开哪个页面
/// - 后面也可以在这里接入路由、国际化、全局导航等能力
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfigStore.instance;

    return MaterialApp(
      // 应用名称来自环境配置。
      // 这样一来，开发、预发、生产环境都可以显示不同标题，便于肉眼区分当前包的来源。
      title: appConfig.appName,
      // 全局主题配置统一从 theme 文件读取，避免页面里到处写样式。
      theme: AppTheme.light(),
      // 现在先把应用入口切到带底部导航的主页面，
      // 这样首页、分类、购物车、我的 4 个一级页面就有统一承载容器了。
      home: MainTabPage(
        paymentService: PaymentServiceFactory.create(appConfig),
      ),
    );
  }
}
