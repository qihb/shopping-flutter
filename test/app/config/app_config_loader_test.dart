import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/app/config/app_config.dart';
import 'package:my_first_app/app/config/app_config_loader.dart';
import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/app/config/app_environment.dart';
import 'package:my_first_app/bootstrap.dart';

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
          }),
        }),
        environmentValue: 'staging',
      );

      final AppConfig config = await loader.load();

      expect(config.environment, AppEnvironment.staging);
      expect(config.appName, 'My First App Staging');
      expect(config.apiBaseUrl, 'https://staging-api.example.com');
      expect(config.enableDebugTools, isTrue);
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
            }),
          }),
          environmentValue: 'prod',
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey<String>('bootstrapped-app')), findsOneWidget);
      expect(AppConfigStore.instance.environment, AppEnvironment.prod);
      expect(AppConfigStore.instance.apiBaseUrl, 'https://api.example.com');
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
