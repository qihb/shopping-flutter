import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';
import 'package:my_first_app/features/profile/presentation/pages/address_edit_page.dart';

/// 地址管理页（服务端化版本）。
///
/// 与购物车页相同的取数方式：页面自己 watch [AddressNotifier]，
/// 设默认 / 删除直接调用 notifier（服务端接口），失败时弹出 SnackBar；
/// 新增 / 编辑跳转表单页 [AddressEditPage]，保存结果由表单页自行处理。
class AddressManagementPage extends StatelessWidget {
  const AddressManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AddressNotifier addressNotifier = context.watch<AddressNotifier>();
    final List<AddressVO> addresses = addressNotifier.addresses;

    return Scaffold(
      appBar: AppBar(title: const Text('地址管理')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('address-add-entry'),
        onPressed: () => _openAddressEditPage(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('新增地址'),
      ),
      body: _buildBody(context, addressNotifier, addresses),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AddressNotifier addressNotifier,
    List<AddressVO> addresses,
  ) {
    if (addressNotifier.isLoading && addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (addresses.isEmpty) {
      final String? errorMessage = addressNotifier.errorMessage;

      if (errorMessage != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: const ValueKey<String>('address-retry'),
                onPressed: addressNotifier.refresh,
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('还没有收货地址'),
            const SizedBox(height: 4),
            Text(
              '点击右下角按钮添加第一个地址',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: addresses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final AddressVO address = addresses[index];
        return _AddressCard(
          address: address,
          onSetDefault: () => _runOperation(
            context,
            addressNotifier.setDefaultAddress(address.id),
            successMessage: '默认地址已更新',
          ),
          onDelete: () => _runOperation(
            context,
            addressNotifier.deleteAddress(address.id),
            successMessage: '地址已删除',
          ),
          onEdit: () => _openAddressEditPage(context, initialAddress: address),
        );
      },
    );
  }

  /// 跳转新增 / 编辑表单页；[initialAddress] 为空表示新增。
  void _openAddressEditPage(
    BuildContext context, {
    AddressVO? initialAddress,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddressEditPage(initialAddress: initialAddress),
      ),
    );
  }

  /// 执行一次地址操作：成功弹轻提示，失败弹 notifier 记录的可读错误。
  Future<void> _runOperation(
    BuildContext context,
    Future<bool> operation, {
    required String successMessage,
  }) async {
    final bool didSucceed = await operation;

    if (!context.mounted) {
      return;
    }

    final AddressNotifier addressNotifier = context.read<AddressNotifier>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          didSucceed ? successMessage : addressNotifier.errorMessage ?? '操作失败，请稍后重试',
        ),
      ),
    );
  }
}

/// 单条地址卡片。
class _AddressCard extends StatelessWidget {
  final AddressVO address;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.receiverName,
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
                    color: colorScheme.primaryContainer,
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
          Text(address.receiverPhone),
          const SizedBox(height: 8),
          Text(address.fullAddress),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!address.isDefault)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.tonal(
                    key: ValueKey<String>('address-set-default-${address.id}'),
                    onPressed: onSetDefault,
                    child: const Text('设为默认'),
                  ),
                ),
              OutlinedButton(
                key: ValueKey<String>('address-edit-${address.id}'),
                onPressed: onEdit,
                child: const Text('编辑'),
              ),
              const Spacer(),
              TextButton(
                key: ValueKey<String>('address-delete-${address.id}'),
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
