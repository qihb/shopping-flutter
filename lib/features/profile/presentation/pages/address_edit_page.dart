import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';

/// 地址新增 / 编辑表单页。
///
/// [initialAddress] 为空表示新增，否则为编辑该条地址。
/// 保存直接调用 [AddressNotifier]（服务端接口），成功后退出页面，
/// 失败时保留表单并弹出可读错误，方便用户修正后重试。
///
/// 省市区按后端 `AddressSaveRequest` 拆成三个独立字段录入，
/// 不做级联选择器，保持这一步聚焦在接口对接本身。
class AddressEditPage extends StatefulWidget {
  final AddressVO? initialAddress;

  const AddressEditPage({super.key, this.initialAddress});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialAddress?.receiverName ?? '');
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.initialAddress?.receiverPhone ?? '');
  late final TextEditingController _provinceController =
      TextEditingController(text: widget.initialAddress?.province ?? '');
  late final TextEditingController _cityController =
      TextEditingController(text: widget.initialAddress?.city ?? '');
  late final TextEditingController _districtController =
      TextEditingController(text: widget.initialAddress?.district ?? '');
  late final TextEditingController _detailController =
      TextEditingController(text: widget.initialAddress?.detailAddress ?? '');

  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isDefault = widget.initialAddress?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.initialAddress != null;

  Future<void> _handleSave() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final AddressNotifier addressNotifier = context.read<AddressNotifier>();
    final bool didSucceed = _isEditing
        ? await addressNotifier.updateAddress(
            id: widget.initialAddress!.id,
            receiverName: _nameController.text.trim(),
            receiverPhone: _phoneController.text.trim(),
            province: _provinceController.text.trim(),
            city: _cityController.text.trim(),
            district: _districtController.text.trim(),
            detailAddress: _detailController.text.trim(),
            isDefault: _isDefault,
          )
        : await addressNotifier.addAddress(
            receiverName: _nameController.text.trim(),
            receiverPhone: _phoneController.text.trim(),
            province: _provinceController.text.trim(),
            city: _cityController.text.trim(),
            district: _districtController.text.trim(),
            detailAddress: _detailController.text.trim(),
            isDefault: _isDefault,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (didSucceed) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(addressNotifier.errorMessage ?? '保存地址失败，请稍后重试'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑地址' : '新增地址')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextFormField(
              key: const ValueKey<String>('address-edit-name'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '收货人姓名',
                hintText: '不超过 50 个字符',
              ),
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return '请填写收货人姓名';
                }
                if (text.length > 50) {
                  return '收货人姓名不能超过 50 个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey<String>('address-edit-phone'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '手机号',
                hintText: '11 位大陆手机号',
              ),
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return '请填写手机号';
                }
                if (!RegExp(r'^1\d{10}$').hasMatch(text)) {
                  return '手机号格式不正确';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey<String>('address-edit-province'),
                    controller: _provinceController,
                    decoration: const InputDecoration(labelText: '省份'),
                    validator: (String? value) =>
                        (value?.trim().isEmpty ?? true) ? '请填写省份' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey<String>('address-edit-city'),
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: '城市'),
                    validator: (String? value) =>
                        (value?.trim().isEmpty ?? true) ? '请填写城市' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey<String>('address-edit-district'),
                    controller: _districtController,
                    decoration: const InputDecoration(labelText: '区/县'),
                    validator: (String? value) =>
                        (value?.trim().isEmpty ?? true) ? '请填写区/县' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey<String>('address-edit-detail'),
              controller: _detailController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '详细地址',
                hintText: '街道、门牌号等，不超过 200 个字符',
              ),
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return '请填写详细地址';
                }
                if (text.length > 200) {
                  return '详细地址不能超过 200 个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey<String>('address-edit-default-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('设为默认地址'),
              value: _isDefault,
              onChanged: (bool value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey<String>('address-edit-save'),
              onPressed: _isSaving ? null : _handleSave,
              child: Text(_isSaving ? '保存中...' : '保存地址'),
            ),
          ],
        ),
      ),
    );
  }
}
