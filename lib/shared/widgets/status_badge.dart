import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../core/utils/format_utils.dart';

/// Status badge để hiển thị trạng thái booking, bài viết, v.v.
class StatusBadge extends StatelessWidget {
  final String status;
  final StatusType type;

  const StatusBadge({
    super.key,
    required this.status,
    this.type = StatusType.booking,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getConfig() {
    if (type == StatusType.booking) {
      return _bookingConfig();
    } else {
      return _blogConfig();
    }
  }

  _StatusConfig _bookingConfig() {
    switch (status) {
      case 'Pending':
        return _StatusConfig(
          label: 'Chờ xác nhận',
          bgColor: const Color(0xFFFFF3E0),
          textColor: AppTheme.warning,
        );
      case 'Confirmed':
        return _StatusConfig(
          label: 'Đã xác nhận',
          bgColor: const Color(0xFFE3F2FD),
          textColor: AppTheme.primary,
        );
      case 'InProgress':
        return _StatusConfig(
          label: 'Đang xét nghiệm',
          bgColor: const Color(0xFFE8F5E9),
          textColor: AppTheme.secondary,
        );
      case 'Completed':
        return _StatusConfig(
          label: 'Hoàn thành',
          bgColor: const Color(0xFFE8F5E9),
          textColor: AppTheme.success,
        );
      case 'Cancelled':
        return _StatusConfig(
          label: 'Đã hủy',
          bgColor: const Color(0xFFFFEBEE),
          textColor: AppTheme.error,
        );
      default:
        return _StatusConfig(
          label: FormatUtils.formatBookingStatus(status),
          bgColor: const Color(0xFFF1F5F9),
          textColor: AppTheme.textSecondary,
        );
    }
  }

  _StatusConfig _blogConfig() {
    switch (status) {
      case '0':
      case 'pending':
        return _StatusConfig(
          label: 'Chờ duyệt',
          bgColor: const Color(0xFFFFF3E0),
          textColor: AppTheme.warning,
        );
      case '1':
      case 'approved':
        return _StatusConfig(
          label: 'Đã duyệt',
          bgColor: const Color(0xFFE8F5E9),
          textColor: AppTheme.success,
        );
      case '2':
      case 'rejected':
        return _StatusConfig(
          label: 'Bị từ chối',
          bgColor: const Color(0xFFFFEBEE),
          textColor: AppTheme.error,
        );
      default:
        return _StatusConfig(
          label: status,
          bgColor: const Color(0xFFF1F5F9),
          textColor: AppTheme.textSecondary,
        );
    }
  }
}

enum StatusType { booking, blog }

class _StatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}
