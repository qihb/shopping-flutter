# 分层自动化测试体系落地方案（test+mockito / flutter_test / integration_test+Patrol）

## Context

项目现有 79 个测试、19 个文件，全部基于手写 test double（`CapturingMockAdapter`、`InMemoryTokenStore`、`_FakeAuthService`、`_TestRecommendService` 等）。用户决定采用社区标准分层测试体系：

- **单元测试 ~70%**：`test` + `mockito`（代码生成 Mock，替代全部手写替身）
- **Widget 测试 ~20%**：`flutter_test`（复用 mockito Mock 做装配）
- **集成 E2E ~10%**：`integration_test` + `Patrol`（首个流程：游客购物闭环）

已确认决策：① 存量测试**全量**迁移到 mockito；② E2E 先覆盖游客购物闭环（启动 → 首页 FakeStore 商品 → 详情 → 加购 → 校验角标），不依赖本地后端（已确认 `restoreSession()` 无 token 时直接转 unauthenticated，不发请求）；③ 完成后在本机 iOS 模拟器实际运行 `patrol drive` 验证。

## 一、依赖变更（pubspec.yaml）

dev_dependencies 新增（用 `flutter pub add --dev` 让解析器选最新兼容版，写注释说明用途）：
- `mockito`（~5.8.x，`@GenerateNiceMocks` 推荐 API）
- `build_runner`（~2.7.x，mockito 代码生成必需）
- `patrol`（~4.x）
- `integration_test: {sdk: flutter}`

pubspec 尾部追加 patrol 配置块：

```yaml
patrol:
  app_name: my_first_app
  test_directory: integration_test
  android:
    package_name: com.example.my_first_app   # 以 build.gradle.kts 的 applicationId 为准
  ios:
    bundle_id: com.example.myFirstApp        # 以 project.pbxproj 的 PRODUCT_BUNDLE_IDENTIFIER 为准
```

另需 `flutter pub global activate patrol_cli`（与 patrol 同为 4.x），`patrol doctor` 验证。

## 二、集中 Mock 层：test/helpers/mocks.dart

一个 `@GenerateNiceMocks([...])` 生成全部 Mock（输出 mocks.mocks.dart，提交入库）：

| Mock 类 | 替代的手写替身 |
|---|---|
| `HttpClientAdapter`（dio） | CapturingMockAdapter |
| `TokenStore` | InMemoryTokenStore（**从 lib/ 删除**，grep 已确认无生产引用） |
| `AuthService` | _FakeAuthService 等 5 处子类 |
| `HomeRecommendService` | _TestRecommendService 等 3 处 |
| `PaymentGateway` | _Recording/_Sequenced/_SuccessPaymentGateway |
| `PaymentOrderProvider` | _Fixed/_ThrowingOrderProvider |
| `PaymentSdkInitializer` | _RecordingPaymentSdkInitializer |

不 mock：`ApiClient`（构造只需字符串，直接真实例注入 Mock adapter）、`PaymentService`（纯逻辑）、`lib/features/payment/data/mock/` 下的生产 Mock（业务组件，非测试替身）。

若运行时抛 `MissingDummyValueError`（mock 具体类 AuthService 的构造 dummy 问题），在 mocks.dart 用 `provideDummy(ApiClient(baseUrl: 'https://test.local'))` 兜底。

## 三、迁移映射（19 个文件中 10 个需改，9 个不动）

**不动**（纯模型/生产 Mock 自测）：payment_service_factory_test、mock_payment_gateway_test、mock_payment_order_provider_test、alipay_result_mapper_test、payment_payload_test、order_record_test、cart_item_test、category_page_test、order_confirm_page_test（实施时逐个确认确无替身）。

**代表性迁移模式**：

1. **service 单测 + 请求断言**（auth_service_test.dart 等）——替代 CapturingMockAdapter：
```dart
when(adapter.fetch(any, any, any)).thenAnswer(
  (_) async => jsonResponseBody({'code': 200, 'message': 'ok', 'data': {...}}),
);
final captured = verify(adapter.fetch(captureAny, any, any)).captured.single
    as RequestOptions;
expect(captured.uri.path, '/api/auth/login');
expect(decodedJsonBody(captured)['username'], 'alice');
```

2. **widget 测试装配**（widget_test / main_tab_page_test / login_flow_test / home_page_test / product_detail_flow_test）：
```dart
when(tokenStore.readToken()).thenAnswer((_) async => null); // 未登录访客
final notifier = AuthNotifier(authService: mockAuthService, tokenStore: mockTokenStore)
  ..restoreSession();
```
调用次数断言：`logoutCallCount` → `verify(authService.logout()).called(1)`；`tokenStore.token` → `verify(tokenStore.clearToken()).called(1)`。

3. **网关分发验证**（payment_service_test / auth_notifier_test）：`verifyNever(gateway.pay(any))`；失败+重试序列用 `thenReturnInOrder([failure, success])`。

## 四、删除的手写替身

- test/helpers/mock_api_adapter.dart：删 `CapturingMockAdapter`，**保留** `decodedJsonBody` / `jsonResponseBody`（数据构造器非替身），文件改名 `http_body_helpers.dart`，更新各处 import
- lib/features/auth/data/token_store.dart：删 `InMemoryTokenStore`（仅测试用）

## 五、E2E：integration_test/guest_shopping_flow_test.dart

用 `patrolTest()` 编写游客购物闭环：加载 dev 配置（`AppConfigLoader().load()` → `AppConfigStore.setConfig`）→ `$.pumpWidgetAndSettle(const MyApp())`（**不调用** `WidgetsFlutterBinding.ensureInitialized()`、**不用** `runApp()`，按 Patrol 文档要求）→ 首页推荐商品可见（FakeStore 公网）→ 点进商品详情 → 加入购物车 → 底部 tab 校验购物车数量角标。

注意：首页 Banner 视频自动播放会导致 settle 不停，需带超时的 settle（trySettle / 等待策略）或先滚过 Banner。

## 六、Patrol 原生配置

**iOS**（本机有模拟器，实际运行验证）：
1. 检查 ios/Podfile，platform 提到 13.0，Runner target 内嵌 `target 'RunnerUITests' do inherit! :complete end`
2. 新建 UI Testing Bundle target `RunnerUITests`：优先用 xcodeproj（Ruby gem）脚本自动化创建并写入 `RunnerUITests.m`（内容：`@import patrol; PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)`）；若脚本方案不稳，退回让用户在 Xcode 里手动建（File > New > Target > UI Testing Bundle）
3. `pod install`

**Android**（同步配置好，暂不运行）：
1. 新建 `android/app/src/androidTest/java/com/example/my_first_app/MainActivityTest.java`（PatrolJUnitRunner 模板，包名与 applicationId 一致）
2. build.gradle.kts：`testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"`、`testOptions { execution = "ANDROIDX_TEST_ORCHESTRATOR" }`、`androidTestUtil("androidx.test:orchestrator:...")`

## 七、实施顺序与验证

1. pubspec 加依赖 + patrol 配置块 → `flutter pub get` → `patrol_cli` 全局安装
2. 建 test/helpers/mocks.dart → `dart run build_runner build --delete-conflicting-outputs`
3. 逐文件迁移 10 个测试文件；删除手写替身（第四节）
4. `flutter analyze` + `flutter test`（79 用例全绿）
5. Patrol 原生配置（第六节）+ 写 E2E 用例
6. iOS 验证：`patrol build ios --simulator` 先隔离构建错误 → `patrol test -t integration_test/guest_shopping_flow_test.dart`（或 `patrol drive` 调试模式）
7. 按 AGENTS.md 第 13 节文档维护规则，在 AGENTS.md 补充测试体系约定（三分层比例、mockito 标准用法、E2E 运行命令）

## 风险点

1. **mockito mock 具体类**：AuthService/HomeRecommendService 的构造 dummy 问题（第二节已有兜底方案）
2. **版本兼容**：patrol 与 patrol_cli 必须 4.x 配套；mockito/build_runner 与 Dart 3.12 的兼容性由 pub 解析器保证，实施时以实际解析版本为准
3. **FakeStore 公网依赖**：E2E 可能 flaky，断言用等待可见而非固定 pump，关键步骤加超时重试
4. **fluwx/tobias 只影响构建期**（pod install 拉 SDK），不参与运行时初始化（enableRealPayment=false 时 initializer 空操作，已确认）
5. **iOS UI Test target 创建**：优先脚本自动化，失败则需用户在 Xcode 手动操作一次
