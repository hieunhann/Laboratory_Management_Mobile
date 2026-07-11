import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/patient_model.dart';
import '../../../shared/models/booking_model.dart';

class PatientRepository {
  // ─── Get current patient profile ─────────────────────────
  static Future<PatientModel?> getMyProfile() async {
    try {
      final response = await ApiClient.get('patient/v1/patients/me');
      final data = response.data;
      final d = data['data'] ?? data;
      return d != null
          ? PatientModel.fromJson(d as Map<String, dynamic>)
          : null;
    } catch (e) {
      return null;
    }
  }

  // ─── Get patient by ID ────────────────────────────────────
  static Future<PatientModel?> getPatientById(String patientId) async {
    final response = await ApiClient.get('patient/v1/patients/$patientId');
    final data = response.data;
    final d = data['data'] ?? data;
    return d != null
        ? PatientModel.fromJson(d as Map<String, dynamic>)
        : null;
  }

  static const _bloodTypes = [
    'A_POSITIVE', 'A_NEGATIVE', 'B_POSITIVE', 'B_NEGATIVE',
    'AB_POSITIVE', 'AB_NEGATIVE', 'O_POSITIVE', 'O_NEGATIVE'
  ];

  // ─── Create profile ───────────────────────────────────────
  static Future<PatientModel?> createProfile(
      Map<String, dynamic> payload) async {
    final apiPayload = Map<String, dynamic>.from(payload);
    if (apiPayload['gender'] == 'Male') {
      apiPayload['gender'] = 0;
    } else if (apiPayload['gender'] == 'Female') {
      apiPayload['gender'] = 1;
    }

    final bt = apiPayload['bloodType'];
    if (bt != null) {
      final idx = _bloodTypes.indexOf(bt.toString());
      if (idx != -1) {
        apiPayload['bloodType'] = idx;
      }
    }

    final response =
        await ApiClient.post('patient/v1/patients', data: apiPayload);
    final data = response.data;
    final d = data['data'] ?? data;
    return d != null
        ? PatientModel.fromJson(d as Map<String, dynamic>)
        : null;
  }

  // ─── Update profile ───────────────────────────────────────
  static Future<PatientModel?> updateProfile(
      String patientId, Map<String, dynamic> payload) async {
    final apiPayload = Map<String, dynamic>.from(payload);
    if (apiPayload['gender'] == 'Male') {
      apiPayload['gender'] = 0;
    } else if (apiPayload['gender'] == 'Female') {
      apiPayload['gender'] = 1;
    }

    final bt = apiPayload['bloodType'];
    if (bt != null) {
      final idx = _bloodTypes.indexOf(bt.toString());
      if (idx != -1) {
        apiPayload['bloodType'] = idx;
      }
    }

    final response =
        await ApiClient.put('patient/v1/patients/$patientId', data: apiPayload);
    final data = response.data;
    final d = data['data'] ?? data;
    return d != null
        ? PatientModel.fromJson(d as Map<String, dynamic>)
        : null;
  }

  // ─── Get medical records ──────────────────────────────────
  static Future<List<BookingModel>> getMedicalRecords(
      {int page = 1, int pageSize = 20}) async {
    try {
      // 1. Lấy danh sách patients của user
      final patientRes = await ApiClient.get(
        'patient/v1/patients/mine',
        params: {'page': 1, 'pageSize': 100},
      );
      final patientData = patientRes.data;
      List patientList = [];
      if (patientData is List) {
        patientList = patientData;
      } else if (patientData is Map) {
        patientList = patientData['items'] ?? patientData['data'] ?? [];
      }

      if (patientList.isEmpty) return [];

      List<BookingModel> allBookings = [];

      // 2. Lấy bookings của từng patient và gộp lại
      for (var p in patientList) {
        final patientId = p['patientId']?.toString() ?? p['id']?.toString();
        if (patientId == null) continue;

        final response = await ApiClient.get(
          'testorder/api/Booking/patient',
          params: {
            'patientId': patientId,
            'pageNumber': 1,
            'pageSize': 100,
          },
        );
        final data = response.data;
        List items = [];
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = data['items'] ?? data['data'] ?? [];
        }

        final bookings = items
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .where((b) => b.isCompleted) // Chỉ lấy các đơn hoàn thành
            .toList();

        allBookings.addAll(bookings);
      }

      // Sắp xếp theo ngày mới nhất
      allBookings.sort((a, b) {
        final dateA = a.appointmentDate ?? '';
        final dateB = b.appointmentDate ?? '';
        return dateB.compareTo(dateA);
      });

      return allBookings;
    } catch (e) {
      return [];
    }
  }

  // ─── Download test report PDF ─────────────────────────────
  static Future<List<int>?> downloadReport(String bookingId) async {
    try {
      final response = await ApiClient.instance.get(
        'testorder/api/TestReport/DownloadReport/$bookingId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>?;
    } catch (e) {
      return null;
    }
  }
}
