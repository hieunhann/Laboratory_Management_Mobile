import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../config/app_theme.dart';
import '../../../shared/models/discount_model.dart';
import '../../booking/data/discount_repository.dart';

class DiscountManagementScreen extends StatefulWidget {
  const DiscountManagementScreen({super.key});

  @override
  State<DiscountManagementScreen> createState() =>
      _DiscountManagementScreenState();
}

class _DiscountManagementScreenState extends State<DiscountManagementScreen> {
  List<DiscountModel> _discounts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await DiscountRepository.getDiscounts();
      setState(() {
        _discounts = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? AppTheme.error : AppTheme.secondary,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // ─── Actions: Toggle Status ───────────────────────────────────────────────
  Future<void> _toggleStatus(String code, bool isActive) async {
    await DiscountRepository.toggleDiscountStatus(code, isActive);
    _loadData();
    _showToast('Đã ${isActive ? "kích hoạt" : "vô hiệu hóa"} mã $code');
  }

  // ─── Actions: Delete Voucher ──────────────────────────────────────────────
  Future<void> _deleteVoucher(String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa mã giảm giá "$code" không? Action này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DiscountRepository.deleteDiscount(code);
      _loadData();
      _showToast('Đã xóa mã giảm giá $code');
    }
  }

  // ─── Actions: Add Voucher Dialog ──────────────────────────────────────────
  void _openAddVoucherDialog() {
    final formKey = GlobalKey<FormState>();
    String code = '';
    String description = '';
    String discountType = 'percentage'; // 'percentage' | 'fixed'
    double value = 0;
    double minOrderAmount = 0;
    double? maxDiscountAmount;
    DateTime expiryDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Tạo mã giảm giá mới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Code
                      TextFormField(
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Mã giảm giá (Ví dụ: HEALTH20)',
                          hintText: 'Chữ in hoa liền nhau, không dấu',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mã giảm giá';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                            return 'Mã giảm giá chỉ gồm chữ cái và số';
                          }
                          return null;
                        },
                        onSaved: (val) => code = val!.trim().toUpperCase(),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Mô tả khuyến mãi',
                          hintText:
                              'Nhập nội dung hiển thị (Ví dụ: Giảm 20% đơn khám)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                        onSaved: (val) => description = val!.trim(),
                      ),
                      const SizedBox(height: 16),

                      // Discount Type
                      DropdownButtonFormField<String>(
                        initialValue: discountType,
                        decoration: const InputDecoration(
                          labelText: 'Loại hình giảm giá',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'percentage',
                            child: Text('Phần trăm (%)'),
                          ),
                          DropdownMenuItem(
                            value: 'fixed',
                            child: Text('Số tiền cố định (đ)'),
                          ),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            discountType = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Value & Min Order Amount
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá trị giảm',
                                suffixText: discountType == 'percentage'
                                    ? '%'
                                    : 'đ',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    double.tryParse(value) == null) {
                                  return 'Giá trị không hợp lệ';
                                }
                                final val = double.parse(value);
                                if (val <= 0) return 'Phải lớn hơn 0';
                                if (discountType == 'percentage' && val > 100)
                                  return 'Tối đa 100%';
                                return null;
                              },
                              onSaved: (val) => value = double.parse(val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Đơn hàng tối thiểu (đ)',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    double.tryParse(value) == null) {
                                  return 'Số tiền không hợp lệ';
                                }
                                final val = double.parse(value);
                                if (val < 0) return 'Không được âm';
                                return null;
                              },
                              onSaved: (val) =>
                                  minOrderAmount = double.parse(val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Max Discount Amount (Percentage only)
                      if (discountType == 'percentage') ...[
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText:
                                'Số tiền giảm tối đa (đ - Bỏ trống nếu không giới hạn)',
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              if (double.tryParse(value) == null ||
                                  double.parse(value) <= 0) {
                                return 'Số tiền không hợp lệ';
                              }
                            }
                            return null;
                          },
                          onSaved: (val) => maxDiscountAmount =
                              (val != null && val.trim().isNotEmpty)
                              ? double.parse(val)
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Expiry Date Selector
                      InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: expiryDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 5),
                            ),
                          );
                          if (selected != null) {
                            setModalState(() {
                              expiryDate = selected;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày hết hạn',
                            suffixIcon: Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                            ),
                          ),
                          child: Text(
                            '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  final voucher = DiscountModel(
                                    code: code,
                                    description: description,
                                    discountType: discountType,
                                    value: value,
                                    minOrderAmount: minOrderAmount,
                                    maxDiscountAmount: maxDiscountAmount,
                                    expiryDate: expiryDate,
                                    isActive: true,
                                  );

                                  final success =
                                      await DiscountRepository.addDiscount(
                                        voucher,
                                      );
                                  if (success) {
                                    _showToast(
                                      'Đã thêm thành công mã giảm giá $code',
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _loadData();
                                  } else {
                                    _showToast(
                                      'Mã giảm giá $code đã tồn tại trên hệ thống!',
                                      isError: true,
                                    );
                                  }
                                }
                              },
                              child: const Text('Lưu lại'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDiscounts = _discounts.where((d) {
      final code = d.code.toLowerCase();
      final desc = d.description.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return code.contains(q) || desc.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Quản lý Voucher Khuyến mãi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddVoucherDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm mã voucher...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : filteredDiscounts.isEmpty
                ? const Center(
                    child: Text(
                      'Không có mã giảm giá nào',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDiscounts.length,
                    itemBuilder: (context, index) {
                      final d = filteredDiscounts[index];
                      final isExpired = d.expiryDate.isBefore(DateTime.now());
                      final color = d.isActive && !isExpired
                          ? AppTheme.primary
                          : Colors.grey[500]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          child: Banner(
                            message: isExpired
                                ? 'HẾT HẠN'
                                : d.isActive
                                ? 'ĐANG MỞ'
                                : 'TẠM KHOÁ',
                            location: BannerLocation.topEnd,
                            color: isExpired
                                ? Colors.red
                                : d.isActive
                                ? AppTheme.secondary
                                : Colors.grey,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Voucher Code Badge (Ticket look)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          border: Border.all(
                                            color: color,
                                            style: BorderStyle.solid,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          d.code,
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Switch control
                                      Switch(
                                        value: d.isActive,
                                        activeThumbColor: AppTheme.primary,
                                        onChanged: isExpired
                                            ? null
                                            : (val) =>
                                                  _toggleStatus(d.code, val),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteVoucher(d.code),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    d.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Min đơn: ${_formatAmount(d.minOrderAmount)}đ',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'Hạn dùng: ${d.expiryDate.day}/${d.expiryDate.month}/${d.expiryDate.year}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isExpired
                                              ? Colors.red
                                              : AppTheme.textSecondary,
                                          fontWeight: isExpired
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amt) {
    return amt.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
