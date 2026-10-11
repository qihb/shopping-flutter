import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_result.dart';
import 'package:my_first_app/features/payment/data/models/pay_result_vo.dart';

/// 支付域数据服务，对接 spring-shop 的支付接口。
///
/// 后端提供的是模拟支付网关：一次请求直接完成「待付款 → 待发货」，
/// 并返回支付结果。支付渠道（支付宝 / 微信）在模拟网关阶段不参与分流，
/// 接入真实渠道后服务端会按渠道下发各自的支付参数。
class PayService {
  final ApiClient _apiClient;

  PayService({required this._apiClient});

  /// 模拟支付：订单待付款 → 待发货，返回支付结果。
  Future<PayResultVO> mockPay(String orderNo) async {
    final dynamic data =
        parseResultData(await _apiClient.post('/api/pay/$orderNo/mockPay'));
    return PayResultVO.fromJson(data as Map<String, dynamic>);
  }
}
