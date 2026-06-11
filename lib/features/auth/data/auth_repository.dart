import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  // ─── Login ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await ApiClient.post(
      'iam/api/Auth/login',
      data: {'username': username, 'password': password},
    );
    final data = response.data;
    // Lưu token
    final accessToken =
        data['accessToken'] ?? data['token'] ?? data['data']?['accessToken'];
    final refreshToken =
        data['refreshToken'] ?? data['data']?['refreshToken'];
    if (accessToken != null) {
      await SecureStorageService.saveAccessToken(accessToken.toString());
    }
    if (refreshToken != null) {
      await SecureStorageService.saveRefreshToken(refreshToken.toString());
    }
    return data is Map<String, dynamic> ? data : {};
  }

  // ─── Register ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> payload) async {
    final response = await ApiClient.post('iam/api/Auth/register', data: payload);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  // ─── Forgot Password ──────────────────────────────────────
  static Future<void> forgotPassword(String email) async {
    await ApiClient.post(
      'iam/api/Auth/forgot-password',
      data: {'UsernameOrEmail': email},
    );
  }

  // ─── Reset Password ───────────────────────────────────────
  static Future<void> resetPassword(String token, String newPassword) async {
    await ApiClient.post(
      'iam/api/Auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  // ─── Change Password ──────────────────────────────────────
  static Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await ApiClient.post(
      'iam/api/Auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  // ─── Get Current User ─────────────────────────────────────
  static Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiClient.get('iam/api/Users/me');
      final data = response.data;
      final userData = data['data'] ?? data;
      if (userData is Map<String, dynamic>) {
        final user = UserModel.fromJson(userData);
        // Cache user data
        await SecureStorageService.saveUserData(jsonEncode(userData));
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Logout ───────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      await ApiClient.post(
        'iam/api/Auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // Swallow error
    } finally {
      await SecureStorageService.clearAll();
    }
  }
}
