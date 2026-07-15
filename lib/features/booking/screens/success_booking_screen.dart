import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/bundle_model.dart';
import '../data/booking_repository.dart';

class SuccessBookingScreen extends StatefulWidget {
  final String? bookingId;
  const SuccessBookingScreen({super.key, this.bookingId});

  @override
  State<SuccessBookingScreen> createState() => _SuccessBookingScreenState();
}

class _SuccessBookingScreenState extends State<SuccessBookingScreen> {
  BookingModel? _booking;
  String _testName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.bookingId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final booking = await BookingRepository.getBookingById(widget.bookingId);
      String testName = '';
      if (booking != null) {
        if (booking.bundleId != null) {
          final bundle = await BookingRepository.getBundleById(booking.bundleId);
          if (bundle != null) {
            testName = bundle.displayName;
          }
        } else if (booking.testCatalogs != null && booking.testCatalogs!.isNotEmpty) {
          final catalogs = await BookingRepository.getAllCatalogs();
          final names = booking.testCatalogs!
              .map((id) {
                final cat = catalogs.firstWhere(
                  (c) => c.catalogId == id || c.catalogId?.toString() == id?.toString(),
                  orElse: () => CatalogModel(),
                );
                return cat.displayName;
              })
              .where((n) => n.isNotEmpty)
              .toList();
          if (names.isNotEmpty) {
            testName = names.join(', ');
          }
        }
      }

      if (mounted) {
        setState(() {
          _booking = booking;
          _testName = testName;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Success animation
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đặt lịch thành công!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cảm ơn bạn đã lựa chọn dịch vụ của chúng tôi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Invoice details container
                _buildInvoiceSection(),

                const SizedBox(height: 24),
                const Text(
                  'Chúng tôi sẽ liên hệ xác nhận lịch hẹn.\nVui lòng đến đúng giờ để được phục vụ tốt nhất.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/history'),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Xem lịch sử'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Về trang chủ'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push('/booking'),
                  child: const Text('Đặt lịch mới'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSection() {
    if (_loading) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_booking == null) {
      // Fallback
      if (widget.bookingId == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Text(
          'Mã đặt lịch: #${widget.bookingId}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    final isPaid = _booking!.isPaid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of Receipt
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HÓA ĐƠN ĐẶT LỊCH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? AppTheme.success : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã đặt lịch: #${_booking!.bookingCode ?? _booking!.bookingId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          _buildDashedLine(),

          // Body of Receipt
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReceiptRow('Bệnh nhân', _booking!.patientName ?? 'N/A'),
                const SizedBox(height: 8),
                _buildReceiptRow('Số điện thoại', _booking!.patientPhoneNumber ?? 'N/A'),
                const SizedBox(height: 8),
                _buildReceiptRow(
                  'Thời gian hẹn',
                  _booking!.appointmentDate != null
                      ? '${_booking!.appointmentDate}  ${_booking!.appointmentTime ?? ""}'
                      : 'N/A',
                ),
              ],
            ),
          ),

          _buildDashedLine(),

          // Service / Items Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dịch vụ xét nghiệm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _testName.isNotEmpty ? _testName : 'Gói xét nghiệm',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          _buildDashedLine(),

          // Total section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  FormatUtils.formatCurrency(_booking!.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }
}
