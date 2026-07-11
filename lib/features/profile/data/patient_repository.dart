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
    apiPayload['createdChannel'] = 'self';
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
      final response = await ApiClient.get('testorder/api/Booking/history',
          params: {'page': page, 'pageSize': pageSize});
      final data = response.data;
      final d = data['data'] ?? data;
      List items = [];
      if (d is List) {
        items = d;
      } else if (d is Map && d.containsKey('items')) {
        items = d['items'] as List;
      }
      return items
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
