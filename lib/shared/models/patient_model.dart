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
    String? genderStr;
    final rawGender = json['gender'];
    if (rawGender != null) {
      final rawStr = rawGender.toString().toLowerCase();
      if (rawGender == 0 || rawStr == '0' || rawStr == 'male') {
        genderStr = 'Male';
      } else if (rawGender == 1 || rawStr == '1' || rawStr == 'female') {
        genderStr = 'Female';
      } else {
        genderStr = rawGender.toString();
      }
    }

    String? bloodTypeStr;
    final rawBloodType = json['bloodType'];
    if (rawBloodType != null) {
      final bloodTypesList = [
        'A_POSITIVE', 'A_NEGATIVE', 'B_POSITIVE', 'B_NEGATIVE',
        'AB_POSITIVE', 'AB_NEGATIVE', 'O_POSITIVE', 'O_NEGATIVE'
      ];
      int? bloodIdx;
      if (rawBloodType is int) {
        bloodIdx = rawBloodType;
      } else {
        bloodIdx = int.tryParse(rawBloodType.toString());
      }
      if (bloodIdx != null && bloodIdx >= 0 && bloodIdx < bloodTypesList.length) {
        bloodTypeStr = bloodTypesList[bloodIdx];
      } else {
        bloodTypeStr = rawBloodType.toString();
      }
    }

    return PatientModel(
      patientId: json['patientId']?.toString() ?? json['id']?.toString(),
      fullName: json['fullName']?.toString() ?? json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
      gender: genderStr,
      dateOfBirth:
          json['dateOfBirth']?.toString() ?? json['birthday']?.toString(),
      address: json['address']?.toString(),
      citizenId: json['citizenId']?.toString() ?? json['idCard']?.toString(),
      insuranceNumber: json['insuranceNumber']?.toString() ??
          json['healthInsurance']?.toString(),
      bloodType: bloodTypeStr,
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
