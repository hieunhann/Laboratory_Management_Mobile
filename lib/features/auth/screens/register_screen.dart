import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../config/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register({
      'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'fullName': _fullNameCtrl.text.trim(),
    });

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng ký thất bại'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_add_rounded, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Đăng ký tài khoản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Điền thông tin để tạo tài khoản mới',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildLabel('Họ và tên'),
              TextFormField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Nguyễn Văn A',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primary),
                ),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),

              // Username
              _buildLabel('Tên đăng nhập'),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  hintText: 'username123',
                  prefixIcon:
                      Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Vui lòng nhập tên đăng nhập';
                  if (v!.length < 4) return 'Tối thiểu 4 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              _buildLabel('Email'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: AppTheme.primary),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Vui lòng nhập email';
                  if (!v!.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              _buildLabel('Mật khẩu'),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu';
                  if (v!.length < 6) return 'Tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _buildLabel('Xác nhận mật khẩu'),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Vui lòng xác nhận mật khẩu';
                  if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Register Button
              Consumer<AuthProvider>(
                builder: (_, auth, __) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Đăng ký'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
