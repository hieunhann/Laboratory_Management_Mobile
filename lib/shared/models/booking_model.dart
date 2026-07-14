class BookingModel {
  final String? bookingCode;
  final dynamic bookingId;
  final String? patientId;
  final String? patientName;
  final String? patientPhoneNumber;
  final String? patientEmail;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? status;
  final num? totalAmount;
  final String? paymentStatus;
  final List<dynamic>? items;
  final DateTime? createdAt;
  final int? bundleId;
  final List<dynamic>? testCatalogs;

  BookingModel({
    this.bookingCode,
    this.bookingId,
    this.patientId,
    this.patientName,
    this.patientPhoneNumber,
    this.patientEmail,
    this.appointmentDate,
    this.appointmentTime,
    this.status,
    this.totalAmount,
    this.paymentStatus,
    this.items,
    this.createdAt,
    this.bundleId,
    this.testCatalogs,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    var slotInfo = json['slotInfo'] ?? json['slotDTO'];
    return BookingModel(
      bookingCode: json['bookingCode']?.toString(),
      bookingId: json['bookingId'] ?? json['id'],
      patientId: json['patientId']?.toString(),
      patientName: json['patientName']?.toString(),
      patientPhoneNumber: json['patientPhoneNumber']?.toString(),
      patientEmail: json['patientEmail']?.toString(),
      appointmentDate: json['appointmentDate']?.toString() ??
          json['date']?.toString() ?? 
          slotInfo?['appointmentDate']?.toString(),
      appointmentTime: json['appointmentTime']?.toString() ??
          json['time']?.toString() ??
          slotInfo?['timeBlock']?.toString() ??
          slotInfo?['time']?.toString(),
      status: json['status']?.toString(),
      totalAmount: json['totalAmount'] as num? ?? json['amount'] as num?,
      paymentStatus: json['paymentStatus']?.toString(),
      items: json['items'] as List<dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      bundleId: json['bundleId'] as int?,
      testCatalogs: json['testCatalogs'] as List<dynamic>?,
    );
  }

  bool get isPending => status == 'Pending';
  bool get isConfirmed => status == 'Confirmed';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';
  bool get isPaid => paymentStatus == 'Paid' || 
                     status == 'Confirmed' || 
                     status == 'InProgress' || 
                     status == 'Completed';
}
