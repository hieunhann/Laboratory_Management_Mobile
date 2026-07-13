import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../core/utils/format_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<BookingModel> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Bước 1: Lấy danh sách patient của user để lấy patientId
      final patientRes = await ApiClient.get(
        'patient/v1/patients/mine',
        params: {'page': 1, 'pageSize': 10},
      );
      final patientData = patientRes.data;
      final patientList = patientData['items'] ?? patientData['data'] ?? [];

      if (patientList.isEmpty) {
        setState(() { _bookings = []; _loading = false; });
        return;
      }

      // Lấy patientId đầu tiên (hoặc gom tất cả)
      final patientId = patientList[0]['patientId']?.toString()
          ?? patientList[0]['id']?.toString();

      if (patientId == null) {
        setState(() { _bookings = []; _loading = false; });
        return;
      }

      // Bước 2: Lấy booking theo patientId
      final response = await ApiClient.get(
        'testorder/api/Booking/patient',
        params: {
          'patientId': patientId,
          'pageNumber': 1,
          'pageSize': 50,
        },
      );
      final data = response.data;
      List items = [];
      if (data is Map) {
        // Backend trả về mảng danh sách trong biến bookingResponses
        items = data['bookingResponses'] ?? data['items'] ?? data['data'] ?? [];
      } else if (data is List) {
        items = data;
      }

      setState(() {
        _bookings = items
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .where((b) => b.isCompleted) // CHỈ lấy những đơn đã Hoàn thành
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Không tải được lịch sử: $e'; _loading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Lịch sử xét nghiệm')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : _bookings.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: _loadHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _buildBookingCard(_bookings[i]),
                      ),
                    ),
    );
  }

  Widget _buildBookingCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.science_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn #${b.bookingId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (b.patientName != null)
                      Text(b.patientName!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(status: b.status ?? ''),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                b.appointmentDate != null
                    ? '${b.appointmentDate}  ${FormatUtils.formatTime(b.appointmentTime)}'
                    : 'Chưa có lịch',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              if (b.totalAmount != null)
                Text(
                  FormatUtils.formatCurrency(b.totalAmount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
          if (b.isCompleted) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/medical-record?bookingId=${b.bookingId}'),
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Xem kết quả'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text('Chưa có lịch sử xét nghiệm',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('Đặt lịch xét nghiệm đầu tiên của bạn',
              style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/booking'),
            child: const Text('Đặt lịch ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadHistory, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
