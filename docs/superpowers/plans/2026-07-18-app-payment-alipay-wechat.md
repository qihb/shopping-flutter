# App Payment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为当前 Flutter 电商学习项目接入支付宝和微信支付能力，先完成可运行的 Mock 双端链路，再为真实商户参数预留替换接口。

**Architecture:** 以 `features/payment/` 作为独立支付模块，先把“支付方式选择、支付发起、支付结果回传、订单状态更新”收拢到 Flutter 抽象层，再用 `tobias` 和 `fluwx` 分别承接支付宝与微信原生 SDK。由于当前没有真实商户资质，第一阶段使用 Mock 支付参数和可切换的网关实现，确保 UI、状态流转、平台初始化点和后续真实联调入口都先稳定下来。

**Tech Stack:** Flutter, Dart, `tobias`, `fluwx`, Android Manifest / Gradle, iOS Info.plist / URL Scheme / Universal Link

---

### Task 1: 支付领域模型与订单状态对齐

**Files:**
- Create: `lib/features/payment/presentation/models/payment_method.dart`
- Create: `lib/features/payment/presentation/models/payment_result.dart`
- Modify: `lib/features/order/presentation/models/order_record.dart`
- Test: `test/features/order/presentation/models/order_record_test.dart`

- [ ] 定义 `PaymentMethod` 枚举，先提供 `alipay` 和 `wechatPay` 两种方式，并补充学习型注释。
- [ ] 为支付结果新增统一模型，至少包含 `method`、`status`、`message`、`rawResult`。
- [ ] 把 `OrderRecord.fromCartItems()` 的默认状态从“已支付待发货”调整为“待付款”，避免当前一点击确认就直接越过支付环节。
- [ ] 为订单模型补充支付方式、支付结果摘要等必要字段，保持不可变对象和 `copyWith()` 风格一致。
- [ ] 更新模型测试，覆盖“下单后默认待付款”和“支付成功后状态推进”的断言。

### Task 2: Flutter 支付抽象层

**Files:**
- Create: `lib/features/payment/application/payment_gateway.dart`
- Create: `lib/features/payment/application/payment_service.dart`
- Create: `lib/features/payment/data/mock/mock_payment_gateway.dart`
- Create: `lib/features/payment/data/models/payment_request.dart`
- Test: `test/features/payment/application/payment_service_test.dart`

- [ ] 定义 `PaymentGateway` 抽象接口，把“发起支付”统一成一个入口，屏蔽支付宝和微信的差异。
- [ ] 定义 `PaymentRequest`，先承接订单号、金额、标题、支付方式、服务端返回的预支付参数。
- [ ] 实现 `MockPaymentGateway`，支持延时返回“成功 / 取消 / 失败”三种结果，方便当前学习阶段演示链路。
- [ ] 实现 `PaymentService`，负责根据支付方式选择具体网关，并把 UI 层和原生插件解耦。
- [ ] 为服务层补测试，重点验证“按支付方式路由”“网关结果透传”“异常兜底”。

### Task 3: 结算页支付方式选择与状态展示

**Files:**
- Modify: `lib/features/order/presentation/pages/order_confirm_page.dart`
- Test: `test/features/order/presentation/pages/order_confirm_page_test.dart`

- [ ] 在订单确认页增加“支付方式”区块，提供支付宝与微信支付单选。
- [ ] 把当前“确认支付”按钮改造成异步交互，增加“支付中”禁用态和结果提示。
- [ ] 保留学习型注释，解释为什么这里先让页面只负责收集用户选择，而不是直接持有复杂业务状态。
- [ ] 补充 Widget 测试，覆盖默认支付方式、切换支付方式、支付中按钮禁用等行为。

### Task 4: 主页面订单提交流程改造

**Files:**
- Modify: `lib/app/presentation/pages/main_tab_page.dart`
- Modify: `lib/features/order/presentation/pages/order_detail_page.dart`
- Modify: `lib/features/order/presentation/pages/order_record_page.dart`
- Test: `test/app/presentation/pages/main_tab_page_test.dart`

- [ ] 把 `_submitOrder()` 拆成“创建待付款订单”“调用支付服务”“根据结果更新订单状态”三步。
- [ ] 成功支付时把订单从 `pendingPayment` 推进到 `pendingShipment`，取消或失败时保留待付款订单，便于后续继续支付。
- [ ] 在订单列表和详情页补充支付方式、支付结果文案和“继续支付”入口占位。
- [ ] 更新主页面测试，验证支付成功会清空购物车并生成已支付订单，支付失败则保留待付款订单。

### Task 5: 应用配置与环境参数预留

**Files:**
- Modify: `lib/app/config/app_config.dart`
- Modify: `assets/config/dev.json`
- Modify: `assets/config/staging.json`
- Modify: `assets/config/prod.json`
- Modify: `lib/bootstrap.dart`
- Test: `test/app/config/app_config_loader_test.dart`

- [ ] 在 `AppConfig` 中新增支付相关字段，例如支付宝 App ID、微信 App ID、微信 Universal Link、是否启用真实支付。
- [ ] 在环境 JSON 中先写 Mock 占位值，并明确注释“当前仅为学习阶段占位，不可用于生产”。
- [ ] 在 `bootstrap()` 中预留支付 SDK 初始化入口，保证后续接真实插件时不必把初始化散落到页面层。
- [ ] 更新配置加载测试，确保新增字段能被正确解析。

### Task 6: 原生 SDK 接入骨架

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/Runner/SceneDelegate.swift`
- Create: `lib/features/payment/data/gateways/alipay_gateway.dart`
- Create: `lib/features/payment/data/gateways/wechat_pay_gateway.dart`

- [ ] 引入 `tobias` 和 `fluwx`，并在代码注释中说明它们分别承担支付宝和微信 SDK 封装职责。
- [ ] 支付宝侧接入 `tobias` 网关，先接 Mock 参数调用；真实阶段再替换成服务端生成的 `orderStr`。
- [ ] 微信侧接入 `fluwx` 网关，先完成 SDK 注册、能力检测和统一结果监听。
- [ ] Android 预留微信/支付宝所需的回调与查询配置；iOS 预留 URL Scheme 和 Universal Link 配置入口。
- [ ] 由于当前没有真实资质，本阶段只保证项目可编译、初始化点清晰，不强行完成真机支付闭环。

### Task 7: 真实商户联调切换点

**Files:**
- Create: `lib/features/payment/data/mock/mock_payment_payload_factory.dart`
- Create: `docs/iteration_logs/2026-07-18-支付能力接入方案.md`
- Modify: `AGENTS.md`（如需要补充支付学习约定）

- [ ] 把 Mock 支付参数工厂和真实服务端返回结构对齐，例如支付宝 `orderStr`、微信 `partnerId/prepayId/packageValue/nonceStr/timeStamp/sign`。
- [ ] 在代码或文档中明确说明：签名和下单必须由服务端完成，客户端不能持有私钥。
- [ ] 生成本轮阶段日志，记录本次方案涉及的 Flutter 抽象、原生配置点和后续真实联调清单。
- [ ] 如接入过程中新增了支付专项约束，再补充到 `AGENTS.md`。

### Task 8: 联调与验证清单

**Files:**
- Test: `flutter analyze`
- Test: `flutter test`
- Manual: Android 真机
- Manual: iOS 真机

- [ ] 执行 `flutter pub get`
- [ ] 执行 `flutter analyze`
- [ ] 执行 `flutter test`
- [ ] Android 真机验证：未安装微信/支付宝、有安装 App、取消支付、失败支付、成功支付。
- [ ] iOS 真机验证：URL Scheme / Universal Link 回跳是否成功、支付结果是否正确落回 Flutter。
- [ ] 记录“当前是 Mock 闭环还是已切真实商户”的验证结论，避免阶段日志和真实代码状态不一致。
