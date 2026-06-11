class PatientModel {
  final String? patientId;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? citizenId;
  final String? insuranceNumber;
  final String? bloodType;
  final String? userId;

  PatientModel({
    this.patientId,
    this.fullName,
    this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.citizenId,
    this.insuranceNumber,
    this.bloodType,
    this.userId,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patientId']?.toString() ?? json['id']?.toString(),
      fullName: json['fullName']?.toString() ?? json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth:
          json['dateOfBirth']?.toString() ?? json['birthday']?.toString(),
      address: json['address']?.toString(),
      citizenId: json['citizenId']?.toString() ?? json['idCard']?.toString(),
      insuranceNumber: json['insuranceNumber']?.toString() ??
          json['healthInsurance']?.toString(),
      bloodType: json['bloodType']?.toString(),
      userId: json['userId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'citizenId': citizenId,
        'insuranceNumber': insuranceNumber,
        'bloodType': bloodType,
        'userId': userId,
      };

  String get displayName => fullName ?? email ?? 'Bệnh nhân';
}
