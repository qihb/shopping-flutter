import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';

import 'package:my_first_app/features/auth/data/auth_service.dart';
import 'package:my_first_app/features/auth/data/token_store.dart';
import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_order_provider.dart';
import 'package:my_first_app/features/payment/application/payment_sdk_initializer.dart';
import 'package:my_first_app/features/product/data/product_service.dart';

/// 项目统一的 Mock 声明入口。
///
/// 所有测试替身都集中在这里用 mockito 的 `@GenerateNiceMocks` 声明，
/// 由 `dart run build_runner build --delete-conflicting-outputs` 生成到
/// `mocks.mocks.dart`，测试文件只需要导入生成文件即可使用对应 Mock 类。
///
/// 生成规则：接口类（如 [PaymentGateway]）直接实现接口；
/// 具体类（如 [AuthService]、[ProductService]）mockito 会生成
/// `implements` 式的 Mock，调用未打桩方法时 nice mock 返回 null/默认值
/// 而不是抛错，所以测试里只应调用打桩过的方法。
@GenerateNiceMocks([
  // dio 的传输层接口：拦截真实 HTTP，替代手写 CapturingMockAdapter。
  MockSpec<HttpClientAdapter>(),
  // 本地存储接口：替代原 lib 内的 InMemoryTokenStore。
  MockSpec<TokenStore>(),
  // 认证服务：widget 测试与 AuthNotifier 单测的登录态替身。
  MockSpec<AuthService>(),
  // 商品域服务：首页/分类/详情相关测试的数据源替身。
  MockSpec<ProductService>(),
  // 支付网关接口：支付流程测试的替身。
  MockSpec<PaymentGateway>(),
  // 支付参数提供方接口：支付宝网关测试的替身。
  // 注意：lib 下的生产 MockPaymentOrderProvider 与此类名不同冲突，
  // 同用时生产侧 import 需要加前缀区分。
  MockSpec<PaymentOrderProvider>(),
  // 支付 SDK 初始化器接口：bootstrap 测试的替身。
  MockSpec<PaymentSdkInitializer>(),
])
class Mocks {}
