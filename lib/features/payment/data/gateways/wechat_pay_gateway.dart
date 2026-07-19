import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 微信支付真实支付网关骨架。
///
/// 后续拿到服务端返回的预支付参数后，
/// 这里会接入 `fluwx` 注册 SDK、发起支付并监听回调结果。
class WechatPayGateway implements PaymentGateway {
  const WechatPayGateway();

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    return PaymentResult(
      method: PaymentMethod.wechatPay,
      status: PaymentStatus.failure,
      message: '微信真实支付暂未启用，请先补齐 AppID、Universal Link 和预支付参数',
      rawResult: <String, Object?>{
        'orderId': request.orderId,
        'placeholder': true,
      },
    );
  }
}
