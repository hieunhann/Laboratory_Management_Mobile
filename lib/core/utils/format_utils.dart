import 'package:intl/intl.dart';

class FormatUtils {
  // ─── Date Formatting ─────────────────────────────────────
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatDateFull(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date);
  }

  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    // Convert "08:00:00" -> "08:00"
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }

  // ─── Currency Formatting ─────────────────────────────────
  static String formatCurrency(num? amount) {
    if (amount == null) return '0 đ';
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  // ─── String utils ─────────────────────────────────────────
  static String capitalize(String? str) {
    if (str == null || str.isEmpty) return '';
    return str[0].toUpperCase() + str.substring(1).toLowerCase();
  }

  // ─── Blood type ───────────────────────────────────────────
  static String formatBloodType(String? type) {
    const bloodTypes = {
      'A_POSITIVE': 'A+',
      'A_NEGATIVE': 'A-',
      'B_POSITIVE': 'B+',
      'B_NEGATIVE': 'B-',
      'AB_POSITIVE': 'AB+',
      'AB_NEGATIVE': 'AB-',
      'O_POSITIVE': 'O+',
      'O_NEGATIVE': 'O-',
    };
    return bloodTypes[type] ?? type ?? '';
  }

  // ─── Gender ───────────────────────────────────────────────
  static String formatGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
      case 'nam':
        return 'Nam';
      case 'female':
      case 'nu':
      case 'nữ':
        return 'Nữ';
      default:
        return gender ?? '';
    }
  }

  // ─── Booking Status ───────────────────────────────────────
  static String formatBookingStatus(String? status) {
    const statusMap = {
      'Pending': 'Chờ xác nhận',
      'Confirmed': 'Đã xác nhận',
      'InProgress': 'Đang xét nghiệm',
      'Completed': 'Hoàn thành',
      'Cancelled': 'Đã hủy',
    };
    return statusMap[status] ?? status ?? '';
  }
}
