import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_result.dart';
import 'package:my_first_app/features/cart/data/models/cart_vo.dart';

/// 购物车域数据服务，对接 spring-shop 的购物车接口。
///
/// 与商品域 [ProductService] 的分层思路一致：
/// - [ApiClient] 负责 baseUrl、token 注入和 HTTP 异常
/// - 本服务负责 `Result<T>` 解包和 JSON 到模型的映射
///
/// 注意：后端 8 个购物车接口中只有 `GET /api/cart` 返回 `CartVO`，
/// 其余变更接口都只返回 `Result<Void>`，成功即视为生效；
/// 最新列表与汇总需要调用方重新拉取 [fetchCart] 获得。
class CartService {
  final ApiClient _apiClient;

  CartService({required this._apiClient});

  /// 购物车列表（含服务端汇总）。
  Future<CartVO> fetchCart() async {
    final dynamic data = parseResultData(await _apiClient.get('/api/cart'));
    return CartVO.fromJson(data as Map<String, dynamic>);
  }

  /// 加入购物车。
  ///
  /// `CartAddRequest` 只需要 SKU id 与数量，商品与规格信息由后端按 SKU 解析，
  /// 所以列表页无法直接加购（没有 SKU），统一从商品详情页发起。
  Future<void> addItem({required int skuId, int quantity = 1}) async {
    await parseResultData(
      await _apiClient.post(
        '/api/cart/items',
        body: <String, dynamic>{'skuId': skuId, 'quantity': quantity},
      ),
    );
  }

  /// 修改条目购买数量（至少为 1）。
  Future<void> updateQuantity({
    required int itemId,
    required int quantity,
  }) async {
    await parseResultData(
      await _apiClient.put(
        '/api/cart/items/$itemId',
        body: <String, dynamic>{'quantity': quantity},
      ),
    );
  }

  /// 删除单条。
  Future<void> removeItem(int itemId) async {
    await parseResultData(await _apiClient.delete('/api/cart/items/$itemId'));
  }

  /// 单条勾选 / 取消勾选。
  Future<void> setItemChecked({
    required int itemId,
    required bool checked,
  }) async {
    await parseResultData(
      await _apiClient.put(
        '/api/cart/items/$itemId/checked',
        body: <String, dynamic>{'checked': checked},
      ),
    );
  }

  /// 全选 / 全不选。
  Future<void> setAllChecked({required bool checked}) async {
    await parseResultData(
      await _apiClient.put(
        '/api/cart/checked',
        body: <String, dynamic>{'checked': checked},
      ),
    );
  }

  /// 删除已勾选条目（下单成功后清理购物车用）。
  Future<void> removeCheckedItems() async {
    await parseResultData(await _apiClient.delete('/api/cart/checked'));
  }

  /// 清空购物车。
  Future<void> clearCart() async {
    await parseResultData(await _apiClient.delete('/api/cart'));
  }
}
