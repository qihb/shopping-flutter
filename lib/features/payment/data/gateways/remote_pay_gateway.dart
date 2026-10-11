import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/data/pay_service.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 服务端模拟支付网关。
///
/// 支付动作落到 spring-shop 的 `/api/pay/{orderNo}/mockPay`，
/// 由后端模拟网关一次性完成扣款与订单状态流转；
/// 本网关只负责把服务端支付结果翻译成统一的 [PaymentResult]，
/// 上层订单流程与页面无需感知接口细节。
///
/// 与真实 SDK 网关（支付宝 / 微信）的差异：
/// - 不需要预支付参数（orderStr / 预支付单），订单号即支付凭据
/// - 渠道选择当前不影响请求结果，仅保留在结果模型里供 UI 展示
class RemotePayGateway implements PaymentGateway {
  final PayService _payService;

  RemotePayGateway({required this._payService});

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    try {
      final result = await _payService.mockPay(request.orderId);

      return PaymentResult(
        method: request.method,
        status: result.isSuccess ? PaymentStatus.success : PaymentStatus.failure,
        message: result.isSuccess ? '支付成功' : '支付失败，请稍后重试',
        rawResult: <String, Object?>{
          'orderNo': result.orderNo,
          'payTime': result.payTime,
        },
      );
    } on ApiException catch (error) {
      // 业务失败（如订单状态不允许支付）后端会给出明确原因，直接透出。
      return PaymentResult(
        method: request.method,
        status: PaymentStatus.failure,
        message: error.message,
      );
    } catch (error) {
      // 网络异常等非业务错误统一收敛为失败结果，
      // 保证订单流程拿到稳定的 PaymentResult 而不是未捕获异常。
      return PaymentResult(
        method: request.method,
        status: PaymentStatus.failure,
        message: '支付失败，请稍后重试',
      );
    }
  }
}
