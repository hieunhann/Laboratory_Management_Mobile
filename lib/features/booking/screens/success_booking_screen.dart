import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';

class SuccessBookingScreen extends StatelessWidget {
  final String? bookingId;
  const SuccessBookingScreen({super.key, this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success animation
              Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 72, color: AppTheme.success),
              ),
              const SizedBox(height: 24),
              const Text('Đặt lịch thành công!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              if (bookingId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Mã đặt lịch: #$bookingId',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ),
              const SizedBox(height: 12),
              const Text(
                'Chúng tôi sẽ liên hệ xác nhận lịch hẹn.\nVui lòng đến đúng giờ để được phục vụ tốt nhất.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),
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
    );
  }
}
