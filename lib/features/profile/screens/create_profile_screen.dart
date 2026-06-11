import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../data/patient_repository.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});
  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _citizenCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  String _gender = 'Male';
  String _bloodType = 'A_POSITIVE';
  bool _loading = false;

  final _genders = ['Male', 'Female'];
  final _bloodTypes = ['A_POSITIVE', 'A_NEGATIVE', 'B_POSITIVE', 'B_NEGATIVE',
      'AB_POSITIVE', 'AB_NEGATIVE', 'O_POSITIVE', 'O_NEGATIVE'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _dobCtrl.dispose(); _addressCtrl.dispose(); _citizenCtrl.dispose();
    _insuranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final patient = await PatientRepository.createProfile({
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'dateOfBirth': _dobCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'citizenId': _citizenCtrl.text.trim(),
        'insuranceNumber': _insuranceCtrl.text.trim(),
        'gender': _gender,
        'bloodType': _bloodType,
      });
      if (patient != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo hồ sơ thành công!'),
              backgroundColor: AppTheme.success),
        );
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tạo hồ sơ bệnh nhân'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard([
                _buildField('Họ và tên *', _nameCtrl, Icons.badge_outlined,
                    validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null),
                _buildField('Số điện thoại *', _phoneCtrl, Icons.phone_outlined,
                    type: TextInputType.phone,
                    validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null),
                _buildField('Email', _emailCtrl, Icons.email_outlined,
                    type: TextInputType.emailAddress),
                _buildField('Ngày sinh (dd/MM/yyyy)', _dobCtrl, Icons.cake_outlined),
                _buildField('Địa chỉ', _addressCtrl, Icons.location_on_outlined),
                _buildField('CCCD/CMND', _citizenCtrl, Icons.badge_rounded),
                _buildField('Số BHYT', _insuranceCtrl, Icons.health_and_safety_outlined),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildDropdown('Giới tính', _gender, _genders,
                    labels: {'Male': 'Nam', 'Female': 'Nữ'},
                    onChanged: (v) => setState(() => _gender = v!)),
                _buildDropdown('Nhóm máu', _bloodType, _bloodTypes,
                    labels: {
                      'A_POSITIVE': 'A+', 'A_NEGATIVE': 'A-',
                      'B_POSITIVE': 'B+', 'B_NEGATIVE': 'B-',
                      'AB_POSITIVE': 'AB+', 'AB_NEGATIVE': 'AB-',
                      'O_POSITIVE': 'O+', 'O_NEGATIVE': 'O-',
                    },
                    onChanged: (v) => setState(() => _bloodType = v!)),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu hồ sơ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              Padding(padding: const EdgeInsets.all(16), child: e.value),
              if (e.key < children.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? type, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options,
      {Map<String, String>? labels, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: options.map((o) => DropdownMenuItem(
        value: o,
        child: Text(labels?[o] ?? o),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
