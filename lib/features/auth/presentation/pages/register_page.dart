import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/auth/application/auth_notifier.dart';

/// 注册页。
///
/// 后端约定：用户名长度 4-20，密码长度 6-32，昵称和手机号选填。
/// 注册成功后 [AuthNotifier.register] 会自动登录并直接回到“我的”页面。
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // `context.read` 不会建立监听依赖，允许在 initState 里调用。
    context.read<AuthNotifier>().clearError();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final AuthNotifier notifier = context.read<AuthNotifier>();
    final bool didSucceed = await notifier.register(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      nickname: _nicknameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (didSucceed) {
      // 注册即自动登录，登录页也一并关闭，避免返回后又落在未登录的登录页。
      Navigator.of(context)..pop()..pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthNotifier notifier = context.watch<AuthNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '创建账号',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '注册成功后会自动登录',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                key: const ValueKey<String>('register-username'),
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final String username = value?.trim() ?? '';
                  if (username.isEmpty) {
                    return '请输入用户名';
                  }
                  if (username.length < 4 || username.length > 20) {
                    return '用户名长度需要为 4-20 个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey<String>('register-password'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final String password = value ?? '';
                  if (password.isEmpty) {
                    return '请输入密码';
                  }
                  if (password.length < 6 || password.length > 32) {
                    return '密码长度需要为 6-32 个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey<String>('register-confirm-password'),
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '两次输入的密码不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey<String>('register-nickname'),
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '昵称（选填）',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey<String>('register-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手机号（选填）',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              if (notifier.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    notifier.errorMessage!,
                    key: const ValueKey<String>('register-error-message'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                key: const ValueKey<String>('register-submit'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('注册并登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
