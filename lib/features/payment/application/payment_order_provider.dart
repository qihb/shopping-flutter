import 'package:my_first_app/features/payment/data/models/alipay_payment_payload.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';

/// 支付参数提供方抽象。
///
/// 支付宝 App 支付的 `orderStr` 必须由服务端用商户私钥签名后下发，
/// 客户端只负责获取参数并调用 SDK，不参与签名。
/// 网关只依赖这个抽象，后续从本地 Mock 切换到真实后端接口时，
/// 网关与上层页面都无需改动。
abstract class PaymentOrderProvider {
  /// 获取支付宝 App 支付参数（服务端签名后的 orderStr）。
  Future<AlipayPaymentPayload> fetchAlipayPayload(PaymentRequest request);
}
