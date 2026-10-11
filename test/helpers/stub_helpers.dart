import 'package:mockito/mockito.dart';

import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';
import 'package:my_first_app/features/cart/data/models/cart_vo.dart';
import 'package:my_first_app/features/order/data/models/order_item_vo.dart';
import 'package:my_first_app/features/order/data/models/order_status.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';
import 'package:my_first_app/features/payment/data/models/pay_result_vo.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_detail.dart';
import 'package:my_first_app/features/product/data/models/product_image.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';
import 'mocks.mocks.dart';

/// 构造一条测试用的商品摘要数据。
///
/// 默认 mainImage 为空字符串，ProductCard 会直接展示占位图标，
/// 避免 widget 测试环境发起真实网络图片请求。
ProductSummary buildTestProduct(
  int id,
  String name, {
  int categoryId = 1,
  String categoryName = '服饰',
  String subtitle = '测试副标题',
  String mainImage = '',
  double minPrice = 89,
  int sales = 100,
}) {
  return ProductSummary(
    id: id,
    categoryId: categoryId,
    categoryName: categoryName,
    name: name,
    subtitle: subtitle,
    mainImage: mainImage,
    minPrice: minPrice,
    sales: sales,
    status: 1,
    createTime: '2026-01-01 10:00:00',
  );
}

/// 构造一个测试用的分类节点。
CategoryNode buildTestCategory(
  int id,
  String name, {
  int parentId = 0,
  List<CategoryNode> children = const <CategoryNode>[],
}) {
  return CategoryNode(
    id: id,
    parentId: parentId,
    name: name,
    sort: id,
    status: 1,
    children: children,
  );
}

/// 给 [MockProductService] 打桩：商品分页固定返回一页数据。
void stubProductPage(
  MockProductService service, {
  List<ProductSummary> products = const <ProductSummary>[],
  bool hasMore = false,
}) {
  when(service.fetchProducts(
    categoryId: anyNamed('categoryId'),
    keyword: anyNamed('keyword'),
    current: anyNamed('current'),
    size: anyNamed('size'),
  )).thenAnswer(
    (Invocation invocation) async => PageResult<ProductSummary>(
      records: List<ProductSummary>.of(products),
      total: products.length,
      pages: hasMore ? 2 : 1,
      current: 1,
      size: 10,
    ),
  );
}

/// 给 [MockProductService] 打桩：分类树固定返回给定节点。
void stubCategoryTree(MockProductService service, List<CategoryNode> nodes) {
  when(service.fetchCategoryTree()).thenAnswer(
    (_) async => List<CategoryNode>.of(nodes),
  );
}

/// 给 [MockProductService] 打桩：详情固定返回同一条数据。
void stubProductDetail(MockProductService service, ProductDetail detail) {
  when(service.fetchProductDetail(any)).thenAnswer((_) async => detail);
}

/// 构造一条测试用的商品详情数据。
ProductDetail buildTestProductDetail(
  int id,
  String name, {
  int categoryId = 1,
  String categoryName = '服饰',
  String subtitle = '测试副标题',
  String detail = '这是测试商品的说明文字。',
  double minPrice = 89,
  int sales = 100,
  List<ProductSku> skus = const <ProductSku>[],
  List<ProductImage> images = const <ProductImage>[],
}) {
  return ProductDetail(
    id: id,
    categoryId: categoryId,
    categoryName: categoryName,
    name: name,
    subtitle: subtitle,
    mainImage: '',
    detail: detail,
    minPrice: minPrice,
    sales: sales,
    status: 1,
    skus: skus,
    images: images,
  );
}

/// 构造一条测试用的购物车条目。
///
/// 默认图片为空字符串（卡片展示占位图标）、价格为 89 元，
/// 与商品测试数据保持一致；小计按单价 × 数量推算。
CartItemVO buildTestCartItem(
  int id,
  String productName, {
  int skuId = 9001,
  int productId = 1,
  String productImage = '',
  String specs = '默认规格',
  double price = 89,
  double originalPrice = 0,
  int quantity = 1,
  bool checked = true,
  int stock = 50,
  bool invalid = false,
  String invalidReason = '',
}) {
  return CartItemVO(
    id: id,
    skuId: skuId,
    productId: productId,
    productName: productName,
    productImage: productImage,
    specs: specs,
    price: price,
    originalPrice: originalPrice,
    quantity: quantity,
    checked: checked,
    stock: stock,
    subtotal: price * quantity,
    invalid: invalid,
    invalidReason: invalidReason,
  );
}

/// 构造一个测试用购物车，汇总字段（总件数 / 勾选件数 / 勾选金额）
/// 按服务端口径从条目推算：仅统计有效且勾选的条目。
CartVO buildTestCart(List<CartItemVO> items) {
  final List<CartItemVO> settleableItems = items
      .where((CartItemVO item) => item.checked && !item.invalid)
      .toList(growable: false);

  return CartVO(
    items: List<CartItemVO>.of(items),
    totalQuantity:
        items.fold<int>(0, (int sum, CartItemVO item) => sum + item.quantity),
    checkedQuantity: settleableItems
        .fold<int>(0, (int sum, CartItemVO item) => sum + item.quantity),
    checkedAmount: settleableItems
        .fold<double>(0, (double sum, CartItemVO item) => sum + item.subtotal),
  );
}

/// 构造默认测试购物车：一件已勾选的有效商品「夏季轻运动鞋」。
CartVO buildDefaultTestCart() {
  return buildTestCart(<CartItemVO>[buildTestCartItem(1, '夏季轻运动鞋')]);
}

/// 给 [MockCartService] 打桩：fetchCart 固定返回给定购物车。
void stubCartFetch(MockCartService service, CartVO cart) {
  when(service.fetchCart()).thenAnswer((_) async => cart);
}

/// 给 [MockCartService] 打桩：所有变更操作默认成功。
void stubCartMutationsSuccess(MockCartService service) {
  when(service.addItem(
    skuId: anyNamed('skuId'),
    quantity: anyNamed('quantity'),
  )).thenAnswer((_) async {});
  when(service.updateQuantity(
    itemId: anyNamed('itemId'),
    quantity: anyNamed('quantity'),
  )).thenAnswer((_) async {});
  when(service.removeItem(any)).thenAnswer((_) async {});
  when(service.setItemChecked(
    itemId: anyNamed('itemId'),
    checked: anyNamed('checked'),
  )).thenAnswer((_) async {});
  when(service.setAllChecked(checked: anyNamed('checked')))
      .thenAnswer((_) async {});
  when(service.removeCheckedItems()).thenAnswer((_) async {});
  when(service.clearCart()).thenAnswer((_) async {});
}

/// 构造一条测试用的收货地址。
///
/// 默认为上海市的直辖市地址（省和市取值相同），
/// 用于覆盖 [AddressVO.regionLabel] 的去重展示逻辑。
AddressVO buildTestAddress(
  int id, {
  String receiverName = 'Qi Hai Bing',
  String receiverPhone = '13800001234',
  String province = '上海市',
  String city = '上海市',
  String district = '浦东新区',
  String detailAddress = '张江高科',
  bool isDefault = false,
}) {
  return AddressVO(
    id: id,
    receiverName: receiverName,
    receiverPhone: receiverPhone,
    province: province,
    city: city,
    district: district,
    detailAddress: detailAddress,
    isDefault: isDefault,
  );
}

/// 给 [MockAddressService] 打桩：fetchAddresses 固定返回给定地址列表。
void stubAddressFetch(MockAddressService service, List<AddressVO> addresses) {
  when(service.fetchAddresses()).thenAnswer(
    (_) async => List<AddressVO>.of(addresses),
  );
}

/// 给 [MockAddressService] 打桩：所有变更操作默认成功。
/// 新增地址固定返回新地址 id 100。
void stubAddressMutationsSuccess(MockAddressService service) {
  when(service.addAddress(
    receiverName: anyNamed('receiverName'),
    receiverPhone: anyNamed('receiverPhone'),
    province: anyNamed('province'),
    city: anyNamed('city'),
    district: anyNamed('district'),
    detailAddress: anyNamed('detailAddress'),
    isDefault: anyNamed('isDefault'),
  )).thenAnswer((_) async => 100);
  when(service.updateAddress(
    id: anyNamed('id'),
    receiverName: anyNamed('receiverName'),
    receiverPhone: anyNamed('receiverPhone'),
    province: anyNamed('province'),
    city: anyNamed('city'),
    district: anyNamed('district'),
    detailAddress: anyNamed('detailAddress'),
    isDefault: anyNamed('isDefault'),
  )).thenAnswer((_) async {});
  when(service.deleteAddress(any)).thenAnswer((_) async {});
  when(service.setDefaultAddress(any)).thenAnswer((_) async {});
}

/// 构造一条测试用的订单明细快照。
///
/// 默认价格为 89 元、数量 1，小计按单价 × 数量推算，与订单快照口径一致。
OrderItemVO buildTestOrderItemVO(
  int productId,
  String productName, {
  int skuId = 9001,
  String skuSpecs = '默认规格',
  String productImage = '',
  double price = 89,
  int quantity = 1,
}) {
  return OrderItemVO(
    productId: productId,
    skuId: skuId,
    productName: productName,
    skuSpecs: skuSpecs,
    productImage: productImage,
    price: price,
    quantity: quantity,
    subtotal: price * quantity,
  );
}

/// 构造一条测试用的订单。
///
/// 默认待发货状态、实付 89 元，明细缺省为一件「夏季轻运动鞋」，
/// 单价取实付金额，保证金额文案与明细小计能对上。
OrderVO buildTestOrderVO(
  int id,
  String orderNo, {
  OrderStatus status = OrderStatus.pendingShipment,
  double totalAmount = 89,
  double payAmount = 89,
  String receiverName = 'Qi Hai Bing',
  String receiverPhone = '13800001234',
  String receiverAddress = '上海市浦东新区张江高科',
  String remark = '',
  String createTime = '2026-01-01 10:00:00',
  List<OrderItemVO> items = const <OrderItemVO>[],
}) {
  return OrderVO(
    id: id,
    orderNo: orderNo,
    totalAmount: totalAmount,
    payAmount: payAmount,
    status: status,
    statusDesc: status.label,
    receiverName: receiverName,
    receiverPhone: receiverPhone,
    receiverAddress: receiverAddress,
    remark: remark,
    createTime: createTime,
    payTime: '',
    shipTime: '',
    finishTime: '',
    cancelTime: '',
    items: items.isEmpty
        ? <OrderItemVO>[buildTestOrderItemVO(1, '夏季轻运动鞋', price: payAmount)]
        : List<OrderItemVO>.of(items),
  );
}

/// 构造一条测试用的支付结果，默认支付成功。
PayResultVO buildTestPayResultVO(
  String orderNo, {
  double amount = 89,
  int status = PayResultVO.statusSuccess,
  String payTime = '2026-01-01 10:05:00',
}) {
  return PayResultVO(
    orderNo: orderNo,
    amount: amount,
    status: status,
    payTime: payTime,
  );
}

/// 给 [MockOrderService] 打桩：fetchOrders 固定返回给定订单列表。
void stubOrderFetch(MockOrderService service, List<OrderVO> orders) {
  when(service.fetchOrders(current: anyNamed('current')))
      .thenAnswer((_) async => List<OrderVO>.of(orders));
}

/// 给 [MockOrderService] 打桩：所有变更操作默认成功，
/// 下单固定返回服务端生成的订单号 ORD-0000001。
void stubOrderMutationsSuccess(MockOrderService service) {
  when(service.createOrder(
    addressId: anyNamed('addressId'),
    remark: anyNamed('remark'),
  )).thenAnswer((_) async => 'ORD-0000001');
  when(service.confirmReceipt(any)).thenAnswer((_) async {});
  when(service.cancelOrder(any)).thenAnswer((_) async {});
}

/// 给 [MockPayService] 打桩：mockPay 固定返回给定支付结果。
void stubPayResult(MockPayService service, PayResultVO result) {
  when(service.mockPay(any)).thenAnswer((_) async => result);
}
