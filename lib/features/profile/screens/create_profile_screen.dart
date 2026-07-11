import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../shared/models/patient_model.dart';
import '../data/patient_repository.dart';

class CreateProfileScreen extends StatefulWidget {
  final PatientModel? existingPatient; // null = create, non-null = edit
  const CreateProfileScreen({super.key, this.existingPatient});
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

  bool get _isEditMode => widget.existingPatient != null;

  final _genders = ['Male', 'Female'];
  final _bloodTypes = [
    'A_POSITIVE', 'A_NEGATIVE', 'B_POSITIVE', 'B_NEGATIVE',
    'AB_POSITIVE', 'AB_NEGATIVE', 'O_POSITIVE', 'O_NEGATIVE'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill khi đang ở edit mode
    final p = widget.existingPatient;
    if (p != null) {
      _nameCtrl.text = p.fullName ?? '';
      _phoneCtrl.text = p.phone ?? '';
      _emailCtrl.text = p.email ?? '';
      _dobCtrl.text = p.dateOfBirth ?? '';
      _addressCtrl.text = p.address ?? '';
      _citizenCtrl.text = p.citizenId ?? '';
      _insuranceCtrl.text = p.insuranceNumber ?? '';
      if (p.gender != null && _genders.contains(p.gender)) {
        _gender = p.gender!;
      }
      if (p.bloodType != null && _bloodTypes.contains(p.bloodType)) {
        _bloodType = p.bloodType!;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _citizenCtrl.dispose();
    _insuranceCtrl.dispose();
    super.dispose();
  }

  // Mở DatePicker để chọn ngày sinh
  Future<void> _selectDate(BuildContext context) async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 20)); // Mặc định 20 tuổi
    if (_dobCtrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobCtrl.text.trim());
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Parse lỗi chi tiết từ API
  String _parseError(dynamic e) {
    if (e.toString().contains('SocketException') ||
        e.toString().contains('Connection')) {
      return 'Không kết nối được server. Vui lòng kiểm tra mạng!';
    }
    try {
      final resp = (e as dynamic).response?.data;
      if (resp is Map) {
        if (resp['errors'] != null) {
          final errors = resp['errors'];
          if (errors is Map) {
            final firstErrorList = errors.values.first;
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              return firstErrorList.first.toString();
            }
          } else if (errors is List && errors.isNotEmpty) {
            return errors.first.toString();
          }
        }
        return resp['detail']?.toString() ??
            resp['message']?.toString() ??
            resp['error']?.toString() ??
            'Lưu hồ sơ thất bại';
      }
    } catch (_) {}
    return 'Có lỗi xảy ra. Vui lòng thử lại!';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'dateOfBirth': _dobCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'citizenId': _citizenCtrl.text.trim(),
        'insuranceNumber': _insuranceCtrl.text.trim(),
        'gender': _gender,
        'bloodType': _bloodType,
      };

      PatientModel? result;
      if (_isEditMode) {
        final patientId = widget.existingPatient!.patientId?.toString() ?? '';
        result = await PatientRepository.updateProfile(patientId, payload);
      } else {
        result = await PatientRepository.createProfile(payload);
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Cập nhật hồ sơ thành công!'
                : 'Tạo hồ sơ thành công!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        final result = true;
        if (context.canPop()) {
          context.pop(result);
        } else {
          context.go('/profile');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu hồ sơ thất bại. Vui lòng kiểm tra lại!'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_parseError(e)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
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
        title: Text(_isEditMode ? 'Chỉnh sửa hồ sơ' : 'Tạo hồ sơ bệnh nhân'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard([
                _buildField('Họ và tên *', _nameCtrl, Icons.badge_outlined,
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Bắt buộc nhập họ tên' : null),
                _buildField('Số điện thoại *', _phoneCtrl, Icons.phone_outlined,
                    type: TextInputType.phone,
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Bắt buộc nhập số điện thoại' : null),
                _buildField('Email', _emailCtrl, Icons.email_outlined,
                    type: TextInputType.emailAddress),
                
                // Ngày sinh: Dùng DatePicker
                TextFormField(
                  controller: _dobCtrl,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Ngày sinh (yyyy-MM-dd) *',
                    prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.primary, size: 20),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng chọn ngày sinh' : null,
                ),

                _buildField('Địa chỉ', _addressCtrl, Icons.location_on_outlined),
                _buildField('CCCD/CMND', _citizenCtrl, Icons.badge_rounded),
                _buildField('Số BHYT', _insuranceCtrl, Icons.health_and_safety_outlined),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildDropdown(
                  'Giới tính',
                  _gender,
                  _genders,
                  labels: {'Male': 'Nam', 'Female': 'Nữ'},
                  onChanged: (v) => setState(() => _gender = v!),
                ),
                _buildDropdown(
                  'Nhóm máu',
                  _bloodType,
                  _bloodTypes,
                  labels: {
                    'A_POSITIVE': 'A+',
                    'A_NEGATIVE': 'A-',
                    'B_POSITIVE': 'B+',
                    'B_NEGATIVE': 'B-',
                    'AB_POSITIVE': 'AB+',
                    'AB_NEGATIVE': 'AB-',
                    'O_POSITIVE': 'O+',
                    'O_NEGATIVE': 'O-',
                  },
                  onChanged: (v) => setState(() => _bloodType = v!),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditMode ? 'Cập nhật hồ sơ' : 'Lưu hồ sơ'),
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
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

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options, {
    Map<String, String>? labels,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(labels?[o] ?? o),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
