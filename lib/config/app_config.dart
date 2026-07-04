// ============================================================
// App Configuration
// Base URL cho API gateway
// ============================================================

class AppConfig {
  // Android Emulator: 10.0.2.2 trỏ về localhost của máy host
  // Đổi thành IP thật khi deploy lên thiết bị thật
  // Production: Render.com deployment
  static const String baseUrl = 'https://hemalink-gateway-5ils.onrender.com/';
  // static const String baseUrl = 'http://10.0.2.2:8080/'; // Local Android Emulator

  // Endpoints
  static const String iamBase = 'iam/api/';
  static const String patientBase = 'patient/v1/';
  static const String testOrderBase = 'testorder/api/';
  static const String blogBase = 'blog/api/';
  static const String instrumentBase = 'instrument/api/';

  // App info
  static const String appName = 'BloodTest';
  static const String version = '1.0.0';

  // Storage keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userDataKey = 'userData';
}
