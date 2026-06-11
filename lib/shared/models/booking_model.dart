class BookingModel {
  final dynamic bookingId;
  final String? patientId;
  final String? patientName;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? status;
  final num? totalAmount;
  final String? paymentStatus;
  final List<dynamic>? items;
  final DateTime? createdAt;

  BookingModel({
    this.bookingId,
    this.patientId,
    this.patientName,
    this.appointmentDate,
    this.appointmentTime,
    this.status,
    this.totalAmount,
    this.paymentStatus,
    this.items,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] ?? json['id'],
      patientId: json['patientId']?.toString(),
      patientName: json['patientName']?.toString(),
      appointmentDate: json['appointmentDate']?.toString() ??
          json['date']?.toString(),
      appointmentTime: json['appointmentTime']?.toString() ??
          json['time']?.toString(),
      status: json['status']?.toString(),
      totalAmount: json['totalAmount'] as num? ?? json['amount'] as num?,
      paymentStatus: json['paymentStatus']?.toString(),
      items: json['items'] as List<dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get isPending => status == 'Pending';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';
  bool get isPaid => paymentStatus == 'Paid';
}
