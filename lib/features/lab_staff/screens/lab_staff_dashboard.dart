import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../data/lab_staff_repository.dart';

class LabStaffDashboard extends StatefulWidget {
  const LabStaffDashboard({super.key});
  @override
  State<LabStaffDashboard> createState() => _LabStaffDashboardState();
}

class _LabStaffDashboardState extends State<LabStaffDashboard> {
  List<Map<String, dynamic>> _appointments = [];
  bool _loading = true;
  int _totalToday = 0;
  int _totalCompleted = 0;
  int _totalPending = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await LabStaffRepository.getAppointments(date: today);
    if (mounted) {
      setState(() {
        _appointments = data.take(5).toList();
        _totalToday = data.length;
        _totalCompleted = data.where((a) => a['status'] == 'Completed').length;
        _totalPending = data.where((a) => a['status'] == 'Pending').length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tổng quan hôm nay'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Tổng hôm nay', _totalToday.toString(),
                            Icons.calendar_today_rounded, AppTheme.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Hoàn thành', _totalCompleted.toString(),
                            Icons.check_circle_rounded, AppTheme.success)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Chờ xử lý', _totalPending.toString(),
                            Icons.pending_rounded, AppTheme.warning)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Quick access
                    const Text('Truy cập nhanh',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildQuickAccess(context),
                    const SizedBox(height: 24),
                    // Recent appointments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lịch hẹn gần đây',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        TextButton(
                          onPressed: () => context.push('/lab-staff/appointment-schedule'),
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_appointments.isEmpty)
                      const Center(child: Text('Không có lịch hẹn hôm nay',
                          style: TextStyle(color: AppTheme.textSecondary)))
                    else
                      ..._appointments.map((a) => _buildAppointmentCard(a)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickCard(
            Icons.calendar_month_rounded, 'Lịch xét nghiệm',
            AppTheme.secondary,
            () => context.push('/lab-staff/appointment-schedule'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickCard(
            Icons.home_rounded, 'Trang chủ',
            const Color(0xFF7B1FA2),
            () => context.go('/'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['patientName']?.toString() ?? 'Bệnh nhân',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(a['time']?.toString() ?? a['appointmentTime']?.toString() ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(a['status']?.toString() ?? '',
                style: const TextStyle(color: AppTheme.primary, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
