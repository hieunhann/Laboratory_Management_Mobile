import '../../../core/network/api_client.dart';
import '../../../shared/models/patient_model.dart';
import '../../../shared/models/bundle_model.dart';
import '../../../shared/models/booking_model.dart';

class BookingRepository {
  // ─── Patients of current user ─────────────────────────────
  static Future<List<PatientModel>> getMyPatients() async {
    final response = await ApiClient.get('patient/v1/patients/mine',
        params: {'page': 1, 'pageSize': 50});
    final data = response.data;
    List items = data['items'] ?? data['data'] ?? data ?? [];
    return items
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Bundles ──────────────────────────────────────────────
  static Future<List<BundleModel>> getAllBundles() async {
    final response = await ApiClient.get('testorder/api/CatalogBundle',
        params: {'pageNumber': 1, 'pageSize': 100});
    final data = response.data;
    List items = data['items'] ?? data['data'] ?? data ?? [];
    return items
        .map((e) => BundleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<BundleModel?> getBundleById(dynamic id) async {
    final response = await ApiClient.get('testorder/api/TestBundle/$id');
    final data = response.data;
    final d = data['data'] ?? data;
    return d != null ? BundleModel.fromJson(d as Map<String, dynamic>) : null;
  }

  // ─── Catalogs ─────────────────────────────────────────────
  static Future<List<CatalogModel>> getAllCatalogs() async {
    final response = await ApiClient.get('testorder/api/TestCatalog',
        params: {'pageNumber': 1, 'pageSize': 100});
    final data = response.data;
    List items = [];
    if (data is Map) {
      items = data['catalogDTOs'] ?? data['items'] ?? data['data'] ?? [];
    } else if (data is List) {
      items = data;
    }
    return items
        .map((e) => CatalogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Appointment Slots ────────────────────────────────────
  static Future<dynamic> getAppointmentSlotCounts() async {
    final response = await ApiClient.get(
        'testorder/api/AppointmentSlot/count-all',
        params: {'pageNumber': 1, 'pageSize': 10000});
    return response.data;
  }

  // ─── Create Booking ───────────────────────────────────────
  static Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> payload) async {
    final response =
        await ApiClient.post('testorder/api/Booking', data: payload);
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {};
  }

  // ─── Get booking by ID ────────────────────────────────────
  static Future<BookingModel?> getBookingById(dynamic bookingId) async {
    final response = await ApiClient.get(
        'testorder/api/Booking',
        params: {'bookingId': bookingId});
    final data = response.data;
    final d = data['data'] ?? data;
    return d != null
        ? BookingModel.fromJson(d as Map<String, dynamic>)
        : null;
  }

  // ─── VNPay URL ────────────────────────────────────────────
  static Future<String?> getVnPayUrl(dynamic bookingId, num amount) async {
    final response = await ApiClient.post(
      'testorder/api/Payment/vnpay-url',
      data: {'bookingId': bookingId, 'amount': amount},
    );
    final data = response.data;
    return data['url']?.toString() ??
        data['paymentUrl']?.toString() ??
        data['data']?.toString();
  }
}
