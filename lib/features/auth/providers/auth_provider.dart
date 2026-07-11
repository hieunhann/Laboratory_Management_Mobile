import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  UserModel? _currentUser;
  String? _role;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get role => _role;

  // ─── Khởi tạo khi app start ──────────────────────────────
  Future<void> init() async {
    _isAuthenticated = await AuthUtils.isAuthenticated();
    _role = await AuthUtils.getCurrentUserRole();
    if (_isAuthenticated) {
      _currentUser = await AuthRepository.getCurrentUser();
    }
    notifyListeners();
  }

  // ─── Login ───────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // MOCK LOGIN ĐỂ TEST NHANH (Khôi phục nguyên trạng khi yêu cầu)
      if ((username == 'customer' || username == 'labstaff') &&
          password == '123') {
        final role = username == 'customer' ? 'Customer' : 'LabUser';
        final sub = username == 'customer' ? 'cust_mock_123' : 'staff_mock_123';
        final name = username == 'customer'
            ? 'Khách Hàng Thử Nghiệm'
            : 'Kỹ Thuật Viên Thử Nghiệm';
        final email = '$username@gmail.com';

        final header = base64Url.encode(
          utf8.encode(jsonEncode({"alg": "HS256", "typ": "JWT"})),
        );
        final payload = base64Url.encode(
          utf8.encode(
            jsonEncode({
              "sub": sub,
              "role": role,
              "http://schemas.microsoft.com/ws/2008/06/identity/claims/role":
                  role,
              "exp":
                  DateTime.now()
                      .add(const Duration(days: 30))
                      .millisecondsSinceEpoch ~/
                  1000,
            }),
          ),
        );
        final mockToken = "$header.$payload.signature";

        await SecureStorageService.saveAccessToken(mockToken);
        final user = UserModel(
          userId: sub,
          username: username,
          email: email,
          fullName: name,
          role: role,
        );
        await SecureStorageService.saveUserData(jsonEncode(user.toJson()));

        _isAuthenticated = true;
        _role = role;
        _currentUser = user;
        notifyListeners();
        return true;
      }

      final res = await AuthRepository.login(username, password);
      if (res['success'] == false || res['isSuccess'] == false) {
        _errorMessage = res['message']?.toString() ?? 'Đăng nhập thất bại';
        notifyListeners();
        return false;
      }

      // Kiểm tra xem đã lưu được token hợp lệ hay chưa
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        _errorMessage = res['message']?.toString() ??
            res['error']?.toString() ??
            'Tên đăng nhập hoặc mật khẩu không đúng';
        notifyListeners();
        return false;
      }

      _isAuthenticated = true;
      _role = await AuthUtils.getCurrentUserRole();
      // DEBUG: In ra role thực tế từ JWT để kiểm tra
      debugPrint('====== [AUTH] Role từ JWT: $_role ======');

      // Lấy thông tin user
      final user = await AuthRepository.getCurrentUser();
      if (user == null) {
        await SecureStorageService.clearAll();
        _isAuthenticated = false;
        _role = null;
        _errorMessage = 'Không lấy được thông tin người dùng từ máy chủ';
        notifyListeners();
        return false;
      }

      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Register ─────────────────────────────────────────────
  Future<bool> register(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await AuthRepository.register(payload);
      if (res['success'] == false || res['isSuccess'] == false) {
        _errorMessage = res['message']?.toString() ?? 'Đăng ký thất bại';
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Forgot Password ──────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthRepository.forgotPassword(email);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Change Password ──────────────────────────────────────
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthRepository.changePassword(currentPassword, newPassword);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Logout ───────────────────────────────────────────────
  Future<void> logout() async {
    await AuthRepository.logout();
    _isAuthenticated = false;
    _currentUser = null;
    _role = null;
    notifyListeners();
  }

  // ─── Parse error message. ─────────────────────────────────
  String _parseError(dynamic e) {
    if (e.toString().contains('SocketException') ||
        e.toString().contains('Connection')) {
      return 'Không kết nối được server. Vui lòng kiểm tra mạng!';
    }
    try {
      final resp = (e as dynamic).response?.data;
      if (resp is Map) {
        if (resp['errors'] != null) {
          final errors = resp['errors'];
          if (errors is Map) {
            final firstErrorList = errors.values.first;
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              return firstErrorList.first.toString();
            }
          } else if (errors is List && errors.isNotEmpty) {
            return errors.first.toString();
          }
        }
        return resp['detail']?.toString() ??
            resp['message']?.toString() ??
            resp['error']?.toString() ??
            'Có lỗi xảy ra. Vui lòng thử lại!';
      }
    } catch (_) {}
    return 'Có lỗi xảy ra. Vui lòng thử lại!';
  }
}
