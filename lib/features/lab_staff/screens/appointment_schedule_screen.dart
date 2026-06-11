import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../data/lab_staff_repository.dart';
import '../../../core/utils/format_utils.dart';

class AppointmentScheduleScreen extends StatefulWidget {
  const AppointmentScheduleScreen({super.key});
  @override
  State<AppointmentScheduleScreen> createState() => _AppointmentScheduleScreenState();
}

class _AppointmentScheduleScreenState extends State<AppointmentScheduleScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    final dateStr = '${_selectedDate.year}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
    final data = await LabStaffRepository.getAppointments(date: dateStr);
    if (mounted) setState(() { _appointments = data; _loading = false; });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAppointments();
    }
  }

  Future<void> _startInstrumentRun(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Chạy xét nghiệm cho booking #$bookingId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await LabStaffRepository.startInstrumentRun(bookingId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Đã bắt đầu xét nghiệm!' : 'Có lỗi xảy ra'),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Lịch xét nghiệm'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadAppointments),
        ],
      ),
      body: Column(
        children: [
          // ─── Date Picker ──────────────────────────────
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    FormatUtils.formatDate(_selectedDate),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),

          // ─── Count badge ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_appointments.length} lịch hẹn',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── List ─────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _appointments.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _loadAppointments,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _appointments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _buildAppointmentCard(_appointments[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> a) {
    final bookingId = a['bookingId']?.toString() ?? '';
    final status = a['status']?.toString() ?? '';
    final canStart = status == 'Confirmed' || status == 'Pending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['patientName']?.toString() ?? 'Bệnh nhân',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Booking #$bookingId',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: _statusColor(status), fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(a['time']?.toString() ?? a['appointmentTime']?.toString() ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const Spacer(),
              if (canStart && bookingId.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _startInstrumentRun(bookingId),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Chạy xét nghiệm', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return AppTheme.success;
      case 'InProgress': return AppTheme.secondary;
      case 'Confirmed': return AppTheme.primary;
      case 'Cancelled': return AppTheme.error;
      default: return AppTheme.warning;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 56, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text('Không có lịch hẹn ngày này',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextButton(onPressed: _pickDate, child: const Text('Chọn ngày khác')),
        ],
      ),
    );
  }
}
