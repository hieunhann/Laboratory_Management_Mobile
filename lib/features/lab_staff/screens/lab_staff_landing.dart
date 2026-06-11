import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/auth_utils.dart';

class LabStaffLanding extends StatefulWidget {
  const LabStaffLanding({super.key});
  @override
  State<LabStaffLanding> createState() => _LabStaffLandingState();
}

class _LabStaffLandingState extends State<LabStaffLanding> {
  String? _role;

  @override
  void initState() {
    super.initState();
    AuthUtils.getCurrentUserRole().then((r) {
      if (mounted) setState(() => _role = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    const Text('Cổng nhân viên phòng lab',
                        style: TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Vai trò: ${_role ?? "Đang tải..."}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Menu cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16, mainAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      icon: Icons.dashboard_rounded,
                      label: 'Tổng quan',
                      color: AppTheme.primary,
                      onTap: () => context.push('/lab-staff/dashboard'),
                    ),
                    _buildMenuCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'Lịch xét nghiệm',
                      color: AppTheme.secondary,
                      onTap: () => context.push('/lab-staff/appointment-schedule'),
                    ),
                    _buildMenuCard(
                      icon: Icons.home_rounded,
                      label: 'Về trang chủ',
                      color: const Color(0xFF7B1FA2),
                      onTap: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 14, color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
