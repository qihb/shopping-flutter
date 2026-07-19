import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/payment/data/models/alipay_payment_payload.dart';
import 'package:my_first_app/features/payment/data/models/wechat_payment_payload.dart';

void main() {
  test('AlipayPaymentPayload 能从服务端 JSON 中读取 orderStr', () {
    final AlipayPaymentPayload payload = AlipayPaymentPayload.fromJson(
      const <String, Object>{
        'orderStr': 'app_id=2026000111111111&biz_content=mock',
      },
    );

    expect(payload.orderString, 'app_id=2026000111111111&biz_content=mock');
  });

  test('WechatPaymentPayload 能从服务端 JSON 中读取预支付参数', () {
    final WechatPaymentPayload payload = WechatPaymentPayload.fromJson(
      const <String, Object>{
        'appId': 'wx1234567890',
        'partnerId': '1900000109',
        'prepayId': 'wx201410272009395522657a690389285100',
        'packageValue': 'Sign=WXPay',
        'nonceStr': '5K8264ILTKCH16CQ2502SI8ZNMTM67VS',
        'timestamp': '1710000123',
        'sign': 'mock-signature',
      },
    );

    expect(payload.appId, 'wx1234567890');
    expect(payload.partnerId, '1900000109');
    expect(payload.prepayId, 'wx201410272009395522657a690389285100');
    expect(payload.packageValue, 'Sign=WXPay');
    expect(payload.nonceStr, '5K8264ILTKCH16CQ2502SI8ZNMTM67VS');
    expect(payload.timestamp, '1710000123');
    expect(payload.sign, 'mock-signature');
  });
}
