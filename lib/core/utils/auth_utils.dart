import 'package:jwt_decoder/jwt_decoder.dart';
import '../storage/secure_storage.dart';

class AuthUtils {
  // Claim key cho role trong JWT (giống web)
  static const String _roleClaim =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  // ─── Lấy role từ JWT token ───────────────────────────────
  static Future<String?> getCurrentUserRole() async {
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final decoded = JwtDecoder.decode(token);
      return decoded[_roleClaim]?.toString() ?? decoded['role']?.toString();
    } catch (e) {
      return null;
    }
  }

  // ─── Check authentication ────────────────────────────────
  static Future<bool> isAuthenticated() async {
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) return false;
      // Check token chưa hết hạn
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  // ─── Role checks ─────────────────────────────────────────
  static Future<bool> isAdmin() async =>
      await getCurrentUserRole() == 'Admin';

  static Future<bool> isManager() async =>
      await getCurrentUserRole() == 'Manager';

  static Future<bool> isLabStaff() async {
    final role = await getCurrentUserRole();
    return role == 'LabUser' || role == 'Receptionist';
  }

  static Future<bool> isLabBlogger() async =>
      await getCurrentUserRole() == 'LabBlogger';

  static Future<bool> isTechnician() async =>
      await getCurrentUserRole() == 'Technician';

  // Có thể access management (Lab Staff portal)
  static Future<bool> canAccessLabStaff() async {
    final role = await getCurrentUserRole();
    return role == 'Admin' ||
        role == 'Manager' ||
        role == 'LabUser' ||
        role == 'Receptionist' ||
        role == 'LabBlogger' ||
        role == 'Technician';
  }

  // ─── Get user ID từ token ────────────────────────────────
  static Future<String?> getUserId() async {
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) return null;
      final decoded = JwtDecoder.decode(token);
      return decoded['sub']?.toString() ??
          decoded['userId']?.toString() ??
          decoded[
                  'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
              ?.toString();
    } catch (e) {
      return null;
    }
  }
}
