class DiscountModel {
  final String code;
  final String description;
  final String discountType; // 'percentage' hoặc 'fixed'
  final double value;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final DateTime expiryDate;
  final bool isActive;

  DiscountModel({
    required this.code,
    required this.description,
    required this.discountType,
    required this.value,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    required this.expiryDate,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'discountType': discountType,
        'value': value,
        'minOrderAmount': minOrderAmount,
        'maxDiscountAmount': maxDiscountAmount,
        'expiryDate': expiryDate.toIso8601String(),
        'isActive': isActive,
      };

  factory DiscountModel.fromJson(Map<String, dynamic> json) => DiscountModel(
        code: json['code'] as String,
        description: json['description'] as String,
        discountType: json['discountType'] as String,
        value: (json['value'] as num).toDouble(),
        minOrderAmount: (json['minOrderAmount'] as num).toDouble(),
        maxDiscountAmount: json['maxDiscountAmount'] != null
            ? (json['maxDiscountAmount'] as num).toDouble()
            : null,
        expiryDate: DateTime.parse(json['expiryDate'] as String),
        isActive: json['isActive'] as bool,
      );
}
