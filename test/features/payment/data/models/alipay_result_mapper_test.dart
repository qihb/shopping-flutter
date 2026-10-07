import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/payment/data/models/alipay_result_mapper.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

void main() {
  group('AlipayResultStatus.fromCode 结果码解析', () {
    test('9000 解析为 success', () {
      expect(AlipayResultStatus.fromCode('9000'), AlipayResultStatus.success);
    });

    test('8000 解析为 processing，6001 解析为 cancelled', () {
      expect(AlipayResultStatus.fromCode('8000'), AlipayResultStatus.processing);
      expect(AlipayResultStatus.fromCode('6001'), AlipayResultStatus.cancelled);
    });

    test('无法识别或缺失的结果码归为 unknown', () {
      expect(AlipayResultStatus.fromCode('9999'), AlipayResultStatus.unknown);
      expect(AlipayResultStatus.fromCode(null), AlipayResultStatus.unknown);
    });
  });

  group('mapAlipayResult 结果映射', () {
    test('resultStatus 9000 映射为支付成功', () {
      final PaymentResult result = mapAlipayResult(
        orderId: 'ORD-0000001',
        raw: <Object?, Object?>{'resultStatus': '9000', 'memo': ''},
      );

      expect(result.method, PaymentMethod.alipay);
      expect(result.status, PaymentStatus.success);
      expect(result.message, '支付宝支付成功');
      expect(result.rawResult['orderId'], 'ORD-0000001');
      expect(result.rawResult['resultStatus'], '9000');
    });

    test('resultStatus 6001 映射为用户取消，订单不推进', () {
      final PaymentResult result = mapAlipayResult(
        orderId: 'ORD-0000002',
        raw: <Object?, Object?>{'resultStatus': '6001', 'memo': '用户取消'},
      );

      expect(result.status, PaymentStatus.cancelled);
      expect(result.message, '已取消支付宝支付');
    });

    test('resultStatus 8000 属于结果未知，按失败处理并提示处理中', () {
      final PaymentResult result = mapAlipayResult(
        orderId: 'ORD-0000003',
        raw: <Object?, Object?>{'resultStatus': '8000', 'memo': ''},
      );

      expect(result.status, PaymentStatus.failure);
      expect(result.message, contains('处理中'));
    });

    test('resultStatus 4000 失败时附带 memo 说明', () {
      final PaymentResult result = mapAlipayResult(
        orderId: 'ORD-0000004',
        raw: <Object?, Object?>{'resultStatus': '4000', 'memo': '系统繁忙'},
      );

      expect(result.status, PaymentStatus.failure);
      expect(result.message, '支付宝支付失败：系统繁忙');
    });
  });
}
