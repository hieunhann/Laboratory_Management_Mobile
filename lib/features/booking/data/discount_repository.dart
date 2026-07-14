import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/discount_model.dart';

class DiscountRepository {
  static const _key = 'discount_list_data';

  // ─── Default Mock Discounts ────────────────────────────────────────────────
  static List<DiscountModel> get _defaultDiscounts => [
        DiscountModel(
          code: 'GIAM20',
          description: 'Giảm 20% cho đơn hàng tối thiểu 200,000 đ (Tối đa 100,000 đ)',
          discountType: 'percentage',
          value: 20,
          minOrderAmount: 200000,
          maxDiscountAmount: 100000,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          isActive: true,
        ),
        DiscountModel(
          code: 'FPT50K',
          description: 'Giảm ngay 50,000 đ cho tất cả các xét nghiệm từ 150,000 đ',
          discountType: 'fixed',
          value: 50000,
          minOrderAmount: 150000,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          isActive: true,
        ),
        DiscountModel(
          code: 'HEALTHTEST',
          description: 'Giảm 10% tổng giá trị lịch đặt khám',
          discountType: 'percentage',
          value: 10,
          minOrderAmount: 100000,
          expiryDate: DateTime.now().add(const Duration(days: 180)),
          isActive: true,
        ),
      ];

  // ─── Fetch All ────────────────────────────────────────────────────────────
  static Future<List<DiscountModel>> getDiscounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        // Khởi tạo các mã mặc định
        await saveDiscounts(_defaultDiscounts);
        return _defaultDiscounts;
      }
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => DiscountModel.fromJson(item)).toList();
    } catch (_) {
      return _defaultDiscounts;
    }
  }

  // ─── Save All ─────────────────────────────────────────────────────────────
  static Future<void> saveDiscounts(List<DiscountModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(list.map((d) => d.toJson()).toList());
      await prefs.setString(_key, jsonStr);
    } catch (e) {
      print('====== [DiscountRepository] saveDiscounts Error: $e ======');
    }
  }

  // ─── Add New ──────────────────────────────────────────────────────────────
  static Future<bool> addDiscount(DiscountModel discount) async {
    try {
      final list = await getDiscounts();
      // Kiểm tra trùng mã (Không phân biệt hoa thường)
      final exists = list.any(
        (d) => d.code.trim().toUpperCase() == discount.code.trim().toUpperCase(),
      );
      if (exists) return false;

      list.insert(0, discount);
      await saveDiscounts(list);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────
  static Future<void> deleteDiscount(String code) async {
    try {
      final list = await getDiscounts();
      list.removeWhere((d) => d.code.trim().toUpperCase() == code.trim().toUpperCase());
      await saveDiscounts(list);
    } catch (_) {}
  }

  // ─── Toggle Active Status ──────────────────────────────────────────────────
  static Future<void> toggleDiscountStatus(String code, bool isActive) async {
    try {
      final list = await getDiscounts();
      final idx = list.indexWhere(
        (d) => d.code.trim().toUpperCase() == code.trim().toUpperCase(),
      );
      if (idx != -1) {
        final d = list[idx];
        list[idx] = DiscountModel(
          code: d.code,
          description: d.description,
          discountType: d.discountType,
          value: d.value,
          minOrderAmount: d.minOrderAmount,
          maxDiscountAmount: d.maxDiscountAmount,
          expiryDate: d.expiryDate,
          isActive: isActive,
        );
        await saveDiscounts(list);
      }
    } catch (_) {}
  }

  // ─── Validate Voucher ──────────────────────────────────────────────────────
  // Trả về chuỗi lỗi nếu không hợp lệ, hoặc null nếu hợp lệ
  static Future<String?> validateDiscountCode(String code, double orderAmount) async {
    try {
      final list = await getDiscounts();
      final match = list.firstWhere(
        (d) => d.code.trim().toUpperCase() == code.trim().toUpperCase(),
        orElse: () => throw 'Mã giảm giá không tồn tại trên hệ thống.',
      );

      if (!match.isActive) {
        return 'Mã giảm giá hiện tại đã bị tạm khóa.';
      }

      if (match.expiryDate.isBefore(DateTime.now())) {
        return 'Mã giảm giá này đã quá hạn sử dụng.';
      }

      if (orderAmount < match.minOrderAmount) {
        return 'Giá trị đơn hàng chưa đạt tối thiểu ${match.minOrderAmount.toInt()} đ để áp dụng.';
      }

      return null; // Hợp lệ
    } catch (e) {
      return e.toString();
    }
  }
}
