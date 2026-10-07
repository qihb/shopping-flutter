import 'package:tobias/tobias.dart';

import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_order_provider.dart';
import 'package:my_first_app/features/payment/data/models/alipay_payment_payload.dart';
import 'package:my_first_app/features/payment/data/models/alipay_result_mapper.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 支付宝 SDK 支付调用函数签名。
///
/// 抽成函数类型而不是直接依赖 `Tobias` 实例，
/// 是为了让单元测试能在不触达平台通道的情况下模拟 SDK 同步结果。
typedef AlipayPayExecutor =
    Future<Map<Object?, Object?>> Function(String orderStr);

/// 默认通过 `tobias` 调起支付宝 SDK。
///
/// `showPayLoading` 仅 Android 生效；沙箱联调时可传 `AliPayEvn.sandbox`。
Future<Map<Object?, Object?>> _invokeTobiasPay(String orderStr) async {
  return await Tobias().pay(orderStr);
}

/// 支付宝真实支付网关。
///
/// 职责链路：向 [PaymentOrderProvider] 获取服务端签名后的 orderStr，
/// 交给支付宝 SDK 调起收银台，再把同步结果映射成统一的 [PaymentResult]。
///
/// 平台差异：
/// - iOS 通过 URL Scheme 回跳（由 `pubspec.yaml` 的 tobias 配置自动注入 Info.plist）
/// - Android 通过 Activity 回调返回结果，无需额外配置
class AlipayGateway implements PaymentGateway {
  final PaymentOrderProvider orderProvider;
  final AlipayPayExecutor payExecutor;

  AlipayGateway({required this.orderProvider, AlipayPayExecutor? payExecutor})
    : payExecutor = payExecutor ?? _invokeTobiasPay;

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    try {
      final AlipayPaymentPayload payload =
          await orderProvider.fetchAlipayPayload(request);

      if (payload.orderString.isEmpty) {
        return PaymentResult(
          method: PaymentMethod.alipay,
          status: PaymentStatus.failure,
          message: '未获取到支付宝支付参数，请检查支付服务配置',
          rawResult: <String, Object?>{'orderId': request.orderId},
        );
      }

      // tobias 返回的是支付宝原生 SDK 透传的结果 Map：
      // resultStatus 为结果码，memo 为附加说明。
      final Map<Object?, Object?> raw = await payExecutor(payload.orderString);

      return mapAlipayResult(orderId: request.orderId, raw: raw);
    } catch (error) {
      // SDK 未初始化、参数校验失败等异常统一收敛为失败结果，
      // 保证上层订单状态流转拿到的是稳定的 PaymentResult 而不是未捕获异常。
      return PaymentResult(
        method: PaymentMethod.alipay,
        status: PaymentStatus.failure,
        message: '支付宝支付发起失败：$error',
        rawResult: <String, Object?>{'orderId': request.orderId},
      );
    }
  }
}
