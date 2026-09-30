import 'package:flutter/material.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

/// 订单确认页。
///
/// 位于“购物车”和“订单生成”之间，对应结算流程中的“最后确认信息”步骤。
///
/// 使用 `StatefulWidget`，因为“当前选中的支付方式”属于页面本地交互状态。
class OrderConfirmPage extends StatefulWidget {
  final List<CartItem> items;
  final UserAddress address;
  final Future<void> Function(PaymentMethod method) onConfirmPayment;

  const OrderConfirmPage({
    super.key,
    required this.items,
    required this.address,
    required this.onConfirmPayment,
  });

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.alipay;

  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  Future<void> _handleConfirmPayment() async {
    await widget.onConfirmPayment(_selectedPaymentMethod);
  }

  @override
  Widget build(BuildContext context) {
    final int totalPrice = widget.items.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('订单确认')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ConfirmSectionCard(
            title: '收货地址',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.address.recipientName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(widget.address.phone),
                const SizedBox(height: 8),
                Text(widget.address.fullAddress),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmSectionCard(
            title: '商品信息',
            child: Column(
              children: widget.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text('x${item.quantity}'),
                          const SizedBox(width: 12),
                          Text(item.totalPriceLabel),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmSectionCard(
            title: '支付方式',
            child: Column(
              children: [
                RadioListTile<PaymentMethod>(
                  key: const ValueKey<String>('payment-method-alipay'),
                  contentPadding: EdgeInsets.zero,
                  value: PaymentMethod.alipay,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    _selectPaymentMethod(value);
                  },
                  title: const Text('支付宝'),
                ),
                RadioListTile<PaymentMethod>(
                  key: const ValueKey<String>('payment-method-wechat'),
                  contentPadding: EdgeInsets.zero,
                  value: PaymentMethod.wechatPay,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    _selectPaymentMethod(value);
                  },
                  title: const Text('微信支付'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmSectionCard(
            title: '支付说明',
            child: Text(
              '当前阶段先把支付方式选择和订单状态流转搭起来，'
              '后续再把真实支付宝 / 微信 SDK 接进来。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '应付 EUR $totalPrice',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton(
                key: const ValueKey<String>('order-confirm-pay'),
                onPressed: _handleConfirmPayment,
                child: const Text('确认支付'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ConfirmSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: child,
          ),
        ],
      ),
    );
  }
}
