import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/app/config/app_config.dart';
import 'package:my_first_app/app/config/app_config_loader.dart';
import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/app/config/app_environment.dart';
import 'package:my_first_app/bootstrap.dart';
import 'package:my_first_app/features/payment/application/payment_sdk_initializer.dart';

void main() {
  group('AppEnvironment', () {
    test('未传环境值时默认回退到 dev', () {
      expect(AppEnvironment.fromValue(null), AppEnvironment.dev);
      expect(AppEnvironment.fromValue(''), AppEnvironment.dev);
      expect(AppEnvironment.fromValue('unknown'), AppEnvironment.dev);
    });

    test('能够识别常用环境名称', () {
      expect(AppEnvironment.fromValue('dev'), AppEnvironment.dev);
      expect(AppEnvironment.fromValue('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromValue('prod'), AppEnvironment.prod);
      expect(AppEnvironment.fromValue('production'), AppEnvironment.prod);
    });
  });

  group('AppConfigLoader', () {
    test('会根据当前环境读取对应的 JSON 配置文件', () async {
      final AppConfigLoader loader = AppConfigLoader(
        bundle: FakeAssetBundle({
          'assets/config/staging.json': jsonEncode(<String, Object>{
            'appName': 'My First App Staging',
            'apiBaseUrl': 'https://staging-api.example.com',
            'enableDebugTools': true,
            'enableRealPayment': false,
            'alipayAppId': 'mock-alipay-app-id',
            'wechatAppId': 'mock-wechat-app-id',
            'wechatUniversalLink': 'https://example.com/wechat/link/',
          }),
        }),
        environmentValue: 'staging',
      );

      final AppConfig config = await loader.load();

      expect(config.environment, AppEnvironment.staging);
      expect(config.appName, 'My First App Staging');
      expect(config.apiBaseUrl, 'https://staging-api.example.com');
      expect(config.enableDebugTools, isTrue);
      expect(config.enableRealPayment, isFalse);
      expect(config.alipayAppId, 'mock-alipay-app-id');
      expect(config.wechatAppId, 'mock-wechat-app-id');
      expect(config.wechatUniversalLink, 'https://example.com/wechat/link/');
    });
  });

  group('bootstrap', () {
    testWidgets('启动前会先完成环境配置初始化', (WidgetTester tester) async {
      AppConfigStore.resetForTest();

      await bootstrap(
        const SizedBox(key: ValueKey<String>('bootstrapped-app')),
        configLoader: AppConfigLoader(
          bundle: FakeAssetBundle({
            'assets/config/prod.json': jsonEncode(<String, Object>{
              'appName': 'My First App',
              'apiBaseUrl': 'https://api.example.com',
              'enableDebugTools': false,
            'enableRealPayment': false,
            'alipayAppId': 'prod-alipay-app-id',
            'wechatAppId': 'prod-wechat-app-id',
            'wechatUniversalLink': 'https://example.com/prod/link/',
            }),
          }),
          environmentValue: 'prod',
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey<String>('bootstrapped-app')), findsOneWidget);
      expect(AppConfigStore.instance.environment, AppEnvironment.prod);
      expect(AppConfigStore.instance.apiBaseUrl, 'https://api.example.com');
      expect(AppConfigStore.instance.enableRealPayment, isFalse);
      expect(AppConfigStore.instance.alipayAppId, 'prod-alipay-app-id');
      expect(
        AppConfigStore.instance.wechatUniversalLink,
        'https://example.com/prod/link/',
      );
    });

    testWidgets('启动前会预留支付 SDK 初始化入口', (WidgetTester tester) async {
      AppConfigStore.resetForTest();
      final _RecordingPaymentSdkInitializer initializer =
          _RecordingPaymentSdkInitializer();

      await bootstrap(
        const SizedBox(key: ValueKey<String>('bootstrapped-app-with-payment')),
        configLoader: AppConfigLoader(
          bundle: FakeAssetBundle({
            'assets/config/dev.json': jsonEncode(<String, Object>{
              'appName': 'My First App Dev',
              'apiBaseUrl': 'https://dev-api.example.com',
              'enableDebugTools': true,
              'enableRealPayment': false,
              'alipayAppId': 'dev-alipay-app-id',
              'wechatAppId': 'dev-wechat-app-id',
              'wechatUniversalLink': 'https://example.com/dev/link/',
            }),
          }),
          environmentValue: 'dev',
        ),
        paymentSdkInitializer: initializer,
      );
      await tester.pump();

      expect(initializer.receivedConfig, isNotNull);
      expect(initializer.receivedConfig?.environment, AppEnvironment.dev);
      expect(initializer.receivedConfig?.wechatAppId, 'dev-wechat-app-id');
      expect(find.byKey(const ValueKey<String>('bootstrapped-app-with-payment')), findsOneWidget);
    });
  });
}

class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final String? content = _assets[key];

    if (content == null) {
      throw FlutterError('未找到测试资源: $key');
    }

    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
    return ByteData.sublistView(bytes);
  }
}

class _RecordingPaymentSdkInitializer implements PaymentSdkInitializer {
  AppConfig? receivedConfig;

  @override
  Future<void> initialize(AppConfig config) async {
    receivedConfig = config;
  }
}
