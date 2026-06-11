import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true, _obscureNew = true, _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(_currentCtrl.text, _newCtrl.text);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: AppTheme.success),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Đổi mật khẩu thất bại'),
            backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildPassField('Mật khẩu hiện tại', _currentCtrl,
                        _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent),
                        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null),
                    const Divider(),
                    _buildPassField('Mật khẩu mới', _newCtrl,
                        _obscureNew, () => setState(() => _obscureNew = !_obscureNew),
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Bắt buộc';
                          if (v!.length < 6) return 'Tối thiểu 6 ký tự';
                          return null;
                        }),
                    const Divider(),
                    _buildPassField('Xác nhận mật khẩu mới', _confirmCtrl,
                        _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Bắt buộc';
                          if (v != _newCtrl.text) return 'Không khớp';
                          return null;
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleSubmit,
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Xác nhận đổi mật khẩu'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback toggle, {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
