import 'package:flutter/material.dart';

import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

/// 地址管理页。
///
/// 这里先把它做成一个“查看地址列表 + 设置默认地址”的页面，
/// 方便把个人中心和订单确认页通过同一份地址数据串起来。
class AddressManagementPage extends StatelessWidget {
  final List<UserAddress> addresses;
  final ValueChanged<UserAddress>? onSetDefaultAddress;

  const AddressManagementPage({
    super.key,
    required this.addresses,
    this.onSetDefaultAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地址管理')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemBuilder: (context, index) {
          final UserAddress address = addresses[index];

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.recipientName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '默认地址',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(address.phone),
                const SizedBox(height: 8),
                Text(address.fullAddress),
                const SizedBox(height: 16),
                if (!address.isDefault)
                  FilledButton.tonal(
                    key: ValueKey<String>(
                      'address-set-default-${address.fullAddress}',
                    ),
                    onPressed: () => onSetDefaultAddress?.call(address),
                    child: const Text('设为默认地址'),
                  ),
              ],
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemCount: addresses.length,
      ),
    );
  }
}
