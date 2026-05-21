import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_loading_overlay.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// Màn hình đăng nhập / đăng ký.
class AuthPage extends StatefulWidget {
  /// Khởi tạo [AuthPage].
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      }

      if (!mounted) return;
      AppSnackBar.success(
        context,
        _isLogin ? 'Đăng nhập thành công!' : 'Tạo tài khoản thành công!',
      );
      Navigator.pop(context);
    } on Exception catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') ||
        raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'Email này đã được đăng ký. Hãy đăng nhập!';
    }
    if (raw.contains('weak-password')) {
      return 'Mật khẩu quá yếu. Dùng ít nhất 6 ký tự.';
    }
    if (raw.contains('invalid-email')) {
      return 'Định dạng email không hợp lệ.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Mất kết nối mạng. Kiểm tra lại internet!';
    }
    if (raw.contains('too-many-requests')) {
      return 'Quá nhiều lần thử. Vui lòng đợi một lúc.';
    }
    return 'Đã xảy ra lỗi. Thử lại nhé!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
      ),
      body: AppLoadingWrapper(
        isLoading: _isLoading,
        message: _isLogin ? 'Đang đăng nhập...' : 'Đang tạo tài khoản...',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.video_camera_back_outlined,
                      size: 72,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nhập họ và tên'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || !v.contains('@')
                              ? 'Email không hợp lệ'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? 'Mật khẩu ít nhất 6 ký tự'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _isLogin ? 'Đăng nhập' : 'Đăng ký',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Chưa có tài khoản? Đăng ký ngay'
                            : 'Đã có tài khoản? Đăng nhập',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}