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
  final _bloodTypes = ['A_POSITIVE', 'A_NEGATIVE', 'B_POSITIVE', 'B_NEGATIVE',
      'AB_POSITIVE', 'AB_NEGATIVE', 'O_POSITIVE', 'O_NEGATIVE'];

  @override
  void initState() {
    super.initState();
    // Pre-fill khi Ä‘ang á»Ÿ edit mode
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
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _dobCtrl.dispose(); _addressCtrl.dispose(); _citizenCtrl.dispose();
    _insuranceCtrl.dispose();
    super.dispose();
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
            content: Text(_isEditMode ? 'Cáº­p nháº­t há»“ sÆ¡ thÃ nh cÃ´ng!' : 'Táº¡o há»“ sÆ¡ thÃ nh cÃ´ng!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lá»—i: $e'), backgroundColor: AppTheme.error),
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
        title: Text(_isEditMode ? 'Chá»‰nh sá»­a há»“ sÆ¡' : 'Táº¡o há»“ sÆ¡ bá»‡nh nhÃ¢n'),
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
                _buildField('Há» vÃ  tÃªn *', _nameCtrl, Icons.badge_outlined,
                    validator: (v) => v?.isEmpty == true ? 'Báº¯t buá»™c' : null),
                _buildField('Sá»‘ Ä‘iá»‡n thoáº¡i *', _phoneCtrl, Icons.phone_outlined,
                    type: TextInputType.phone,
                    validator: (v) => v?.isEmpty == true ? 'Báº¯t buá»™c' : null),
                _buildField('Email', _emailCtrl, Icons.email_outlined,
                    type: TextInputType.emailAddress),
                _buildField('NgÃ y sinh (yyyy-MM-dd)', _dobCtrl, Icons.cake_outlined),
                _buildField('Äá»‹a chá»‰', _addressCtrl, Icons.location_on_outlined),
                _buildField('CCCD/CMND', _citizenCtrl, Icons.badge_rounded),
                _buildField('Sá»‘ BHYT', _insuranceCtrl, Icons.health_and_safety_outlined),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildDropdown('Giá»›i tÃ­nh', _gender, _genders,
                    labels: {'Male': 'Nam', 'Female': 'Ná»¯'},
                    onChanged: (v) => setState(() => _gender = v!)),
                _buildDropdown('NhÃ³m mÃ¡u', _bloodType, _bloodTypes,
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
                      : Text(_isEditMode ? 'Cáº­p nháº­t há»“ sÆ¡' : 'LÆ°u há»“ sÆ¡'),
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
