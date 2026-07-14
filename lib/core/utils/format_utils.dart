import 'package:intl/intl.dart';

class FormatUtils {
  // ─── Parse UTC string to Local DateTime ───────────────────
  static DateTime? parseUtcToLocal(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      String formattedStr = dateStr;
      // Nếu chuỗi không chứa chỉ thị múi giờ (Z hoặc offset +/-), ta tự động coi nó là UTC
      if (!dateStr.contains('Z') && !dateStr.contains(RegExp(r'[+-]\d{2}'))) {
        // Chuỗi có thể chứa khoảng trắng thay vì chữ T (vd: 2026-07-14 15:10:00)
        formattedStr = dateStr.replaceAll(' ', 'T');
        if (!formattedStr.endsWith('Z')) {
          formattedStr = '${formattedStr}Z';
        }
      }
      return DateTime.tryParse(formattedStr)?.toLocal();
    } catch (_) {
      return DateTime.tryParse(dateStr)?.toLocal();
    }
  }

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
      // backend tra ve so (byte enum): 1=A+ ... 8=O-
      '0': '', '1': 'A+', '2': 'A-', '3': 'B+', '4': 'B-',
      '5': 'AB+', '6': 'AB-', '7': 'O+', '8': 'O-',
    };
    return bloodTypes[type] ?? type ?? '';
  }

  // ─── Gender ───────────────────────────────────────────────
  static String formatGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
      case 'nam':
      case '1':
        return 'Nam';
      case 'female':
      case 'nu':
      case 'nữ':
      case '2':
        return 'Nữ';
      case '3':
        return 'Khác';
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
