import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_result.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';

/// 订单域数据服务，对接 spring-shop 的订单接口。
///
/// 与购物车 [CartService] 的分层思路一致：
/// - [ApiClient] 负责 baseUrl、token 注入和 HTTP 异常
/// - 本服务负责 `Result<T>` 解包和 JSON 到模型的映射
///
/// 注意：
/// - 支付动作不在本服务里，统一走支付域的 `PayService`（/api/pay 系列接口）
/// - 变更接口（确认收货 / 取消）只返回 `Result<Void>`，成功即视为生效，
///   最新订单列表需要调用方重新拉取 [fetchOrders] 获得
/// - 列表接口支持分页，当前个人订单量级下单页拉取足够，
///   翻页加载后续有真实需求时再补
class OrderService {
  /// 单页拉取条数：覆盖个人订单的常规量级，避免分页 UI 提前上线。
  static const int _pageSize = 50;

  final ApiClient _apiClient;

  OrderService({required this._apiClient});

  /// 我的订单分页（服务端按下单时间倒序）。
  Future<List<OrderVO>> fetchOrders({int current = 1}) async {
    final dynamic data = parseResultData(
      await _apiClient.get(
        '/api/orders',
        queryParameters: <String, String>{
          'current': '$current',
          'size': '$_pageSize',
        },
      ),
    );
    final List<dynamic> records =
        (data as Map<String, dynamic>)['records'] as List<dynamic>? ?? <dynamic>[];
    return records
        .map((dynamic item) => OrderVO.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// 下单（来源固定为购物车勾选项），返回服务端生成的订单号。
  ///
  /// [addressId] 是下单时的收货地址 id，服务端会把它固化成订单的收货快照。
  Future<String> createOrder({required int addressId, String? remark}) async {
    final dynamic data = parseResultData(
      await _apiClient.post(
        '/api/orders',
        body: <String, dynamic>{
          'addressId': addressId,
          'remark': ?remark,
        },
      ),
    );
    return data as String;
  }

  /// 确认收货：待收货 → 已完成。
  Future<void> confirmReceipt(String orderNo) async {
    await parseResultData(await _apiClient.post('/api/orders/$orderNo/confirm'));
  }

  /// 取消订单：待付款 → 已取消（服务端回滚库存）。
  Future<void> cancelOrder(String orderNo) async {
    await parseResultData(await _apiClient.post('/api/orders/$orderNo/cancel'));
  }
}
