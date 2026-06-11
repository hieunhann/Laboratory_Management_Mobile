import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/patient_model.dart';
import '../data/patient_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PatientModel? _patient;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final patient = await PatientRepository.getMyProfile();
    if (mounted) setState(() { _patient = patient; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ─── Header ──────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppTheme.surfaceVariant,
                            child: Text(
                              _patient?.displayName.isNotEmpty == true
                                  ? _patient!.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _patient?.displayName ?? auth.currentUser?.fullName ?? 'Người dùng',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.currentUser?.email ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Info Section ─────────────────────────
                    if (_patient != null) ...[
                      _buildInfoCard([
                        _InfoItem(Icons.badge_outlined, 'Họ và tên', _patient!.fullName),
                        _InfoItem(Icons.phone_outlined, 'Số điện thoại', _patient!.phone),
                        _InfoItem(Icons.email_outlined, 'Email', _patient!.email),
                        _InfoItem(Icons.person_outline_rounded, 'Giới tính', _patient!.gender),
                        _InfoItem(Icons.cake_outlined, 'Ngày sinh', _patient!.dateOfBirth),
                        _InfoItem(Icons.location_on_outlined, 'Địa chỉ', _patient!.address),
                        _InfoItem(Icons.badge_rounded, 'CCCD/CMND', _patient!.citizenId),
                        _InfoItem(Icons.health_and_safety_outlined, 'Bảo hiểm y tế', _patient!.insuranceNumber),
                      ]),
                      const SizedBox(height: 16),
                    ] else ...[
                      _buildNeedProfileCard(),
                      const SizedBox(height: 16),
                    ],

                    // ─── Menu Options ─────────────────────────
                    _buildMenuCard([
                      _MenuItem(Icons.edit_rounded, 'Chỉnh sửa hồ sơ',
                          () => context.push(_patient != null ? '/profile/edit' : '/create-profile')),
                      _MenuItem(Icons.medical_services_rounded, 'Kết quả xét nghiệm',
                          () => context.push('/medical-record')),
                      _MenuItem(Icons.article_rounded, 'Tin tức y tế',
                          () => context.push('/blog')),
                      _MenuItem(Icons.lock_outline_rounded, 'Đổi mật khẩu',
                          () => context.push('/change-password')),
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              _buildInfoRow(e.value),
              if (!isLast)
                const Divider(height: 1, indent: 48),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textHint)),
                const SizedBox(height: 2),
                Text(
                  item.value ?? 'Chưa cập nhật',
                  style: TextStyle(
                    fontSize: 14,
                    color: item.value != null
                        ? AppTheme.textPrimary
                        : AppTheme.textHint,
                    fontStyle: item.value == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_add_alt_1_rounded,
              size: 40, color: AppTheme.primary),
          const SizedBox(height: 12),
          const Text('Chưa có hồ sơ bệnh nhân',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              )),
          const SizedBox(height: 8),
          const Text(
            'Tạo hồ sơ để đặt lịch xét nghiệm',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/create-profile'),
            child: const Text('Tạo hồ sơ ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Icon(e.value.icon, color: AppTheme.primary, size: 22),
                title: Text(e.value.label,
                    style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppTheme.textHint),
                onTap: e.value.onTap,
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
}
