import '../../../core/network/api_client.dart';

class LabStaffRepository {
  // ─── Get appointment schedules ────────────────────────────
  static Future<List<Map<String, dynamic>>> getAppointments({
    String? date,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'pageNumber': page,
        'pageSize': pageSize,
      };
      if (date != null) params['date'] = date;

      final response = await ApiClient.get(
          'testorder/api/AppointmentSlot',
          params: params);
      final data = response.data;
      List items = data['items'] ?? data['data'] ?? data ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ─── Get appointment counts ───────────────────────────────
  static Future<List<Map<String, dynamic>>> getAppointmentCounts() async {
    try {
      final response = await ApiClient.get(
          'testorder/api/AppointmentSlot/count-all',
          params: {'pageNumber': 1, 'pageSize': 10000});
      final data = response.data;
      List items = data['items'] ?? data['data'] ?? data ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ─── Get bookings for a slot ──────────────────────────────
  static Future<List<Map<String, dynamic>>> getBookingsBySlot(
      dynamic slotId) async {
    try {
      final response = await ApiClient.get(
          'testorder/api/Booking',
          params: {'slotId': slotId});
      final data = response.data;
      List items = data['items'] ?? data['data'] ?? data ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ─── Start instrument run ─────────────────────────────────
  static Future<bool> startInstrumentRun(String bookingId) async {
    try {
      // Generate instrument code như web
      final code = _generateInstrumentCode();
      await ApiClient.post(
        'instrument/api/instrument/runs/start',
        data: {'bookingId': bookingId, 'instrumentCode': code},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static String _generateInstrumentCode() {
    final rand = List.generate(
        10, (_) => (DateTime.now().millisecondsSinceEpoch % 10).toString());
    return 'INSTRUMENT${rand.join()}';
  }

  // ─── Update booking status ────────────────────────────────
  static Future<bool> updateBookingStatus(
      dynamic bookingId, String status) async {
    try {
      await ApiClient.put(
        'testorder/api/Booking/$bookingId/status',
        data: {'status': status},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
