import 'package:flutter/material.dart';

enum VitalShift {
  morning('صباحًا'),
  evening('مساءً');

  const VitalShift(this.label);
  final String label;
}

class SurgeryDepartment {
  const SurgeryDepartment._();

  static const String general = 'general';
  static const String oncology = 'oncology';

  static String label(String department) =>
      department == oncology ? 'جراحة الأورام' : 'الجراحة العامة';

  static Color accent(String department) => department == oncology
      ? const Color(0xFF7A4CB3)
      : const Color(0xFF1E6FD9);
}

String formatPatientDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}

String formatPatientTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

List<String> _stringList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList(growable: false);
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

class VitalReading {
  final DateTime date;
  final VitalShift shift;
  final String bp;
  final String hr;
  final String rr;
  final String spo2;
  final String temp;
  final String consciousLevel;

  const VitalReading({
    required this.date,
    required this.shift,
    required this.bp,
    required this.hr,
    required this.rr,
    required this.spo2,
    required this.temp,
    required this.consciousLevel,
  });

  bool get hasValues =>
      bp.isNotEmpty ||
      hr.isNotEmpty ||
      rr.isNotEmpty ||
      spo2.isNotEmpty ||
      temp.isNotEmpty;

  factory VitalReading.fromJson(Map<String, dynamic> json) {
    return VitalReading(
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      shift: VitalShift.values.firstWhere(
        (shift) => shift.name == json['shift'],
        orElse: () => VitalShift.morning,
      ),
      bp: '${json['bp'] ?? ''}',
      hr: '${json['hr'] ?? ''}',
      rr: '${json['rr'] ?? ''}',
      spo2: '${json['spo2'] ?? ''}',
      temp: '${json['temp'] ?? ''}',
      consciousLevel: '${json['conscious_level'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'shift': shift.name,
      'bp': bp,
      'hr': hr,
      'rr': rr,
      'spo2': spo2,
      'temp': temp,
      'conscious_level': consciousLevel,
    };
  }
}

class DoctorOrder {
  final String text;
  final DateTime createdAt;
  bool done;

  DoctorOrder({required this.text, required this.createdAt, this.done = false});

  factory DoctorOrder.fromJson(Map<String, dynamic> json) {
    return DoctorOrder(
      text: '${json['text'] ?? ''}',
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      done: json['done'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'done': done,
    };
  }
}

/// A lab or imaging study with its typed result and optional attachment.
class PatientTest {
  final String name;
  final String result;
  final String? imagePath;
  final String? imageName;

  const PatientTest({
    required this.name,
    this.result = '',
    this.imagePath,
    this.imageName,
  });

  factory PatientTest.fromJson(Map<String, dynamic> json) {
    return PatientTest(
      name: '${json['name'] ?? ''}',
      result: '${json['result'] ?? ''}',
      imagePath: json['image_path'] as String?,
      imageName: json['image_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'result': result,
      'image_path': imagePath,
      'image_name': imageName,
    };
  }
}

class PatientRecord {
  final String? id;
  final String department;
  final String name;
  final String fileNumber;
  final String roomNumber;
  final String diagnosis;
  final String statusLabel;
  final Color accentColor;
  final String doctor;
  final String residence;
  final String phone;
  final String? photoPath;
  final String? photoName;
  final List<String> signs;
  final List<String> symptoms;
  final List<String> pastHistory;
  final List<String> operationHistory;
  final List<VitalReading> vitalReadings;
  final List<PatientTest> labs;
  final List<PatientTest> imaging;
  final String lastOperativeDetails;
  final String currentTreatment;
  final String currentTreatmentDetail;
  final String currentDose;
  final List<DoctorOrder> doctorOrders;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientRecord({
    this.id,
    this.department = SurgeryDepartment.general,
    required this.name,
    required this.fileNumber,
    required this.roomNumber,
    required this.diagnosis,
    required this.statusLabel,
    required this.accentColor,
    this.doctor = '',
    this.residence = '',
    this.phone = '',
    this.photoPath,
    this.photoName,
    this.signs = const [],
    this.symptoms = const [],
    this.pastHistory = const [],
    this.operationHistory = const [],
    this.vitalReadings = const [],
    this.labs = const [],
    this.imaging = const [],
    this.lastOperativeDetails = '',
    this.currentTreatment = '',
    this.currentTreatmentDetail = '',
    this.currentDose = '',
    this.doctorOrders = const [],
    this.createdAt,
    this.updatedAt,
  });

  PatientRecord copyWith({List<DoctorOrder>? doctorOrders}) {
    return PatientRecord(
      id: id,
      department: department,
      name: name,
      fileNumber: fileNumber,
      roomNumber: roomNumber,
      diagnosis: diagnosis,
      statusLabel: statusLabel,
      accentColor: accentColor,
      doctor: doctor,
      residence: residence,
      phone: phone,
      photoPath: photoPath,
      photoName: photoName,
      signs: signs,
      symptoms: symptoms,
      pastHistory: pastHistory,
      operationHistory: operationHistory,
      vitalReadings: vitalReadings,
      labs: labs,
      imaging: imaging,
      lastOperativeDetails: lastOperativeDetails,
      currentTreatment: currentTreatment,
      currentTreatmentDetail: currentTreatmentDetail,
      currentDose: currentDose,
      doctorOrders: doctorOrders ?? this.doctorOrders,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Storage paths of every file attached to this patient.
  List<String> get filePaths => [
    ?photoPath,
    for (final test in [...labs, ...imaging]) ?test.imagePath,
  ];

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    final department = '${json['department'] ?? SurgeryDepartment.general}';
    final details = Map<String, dynamic>.from(
      (json['details'] as Map?) ?? const {},
    );

    return PatientRecord(
      id: json['id'] as String?,
      department: department,
      name: '${json['name'] ?? ''}',
      fileNumber: '${json['file_number'] ?? ''}',
      roomNumber: '${json['room_number'] ?? ''}',
      diagnosis: '${json['diagnosis'] ?? ''}',
      statusLabel: '${json['status_label'] ?? ''}',
      accentColor: SurgeryDepartment.accent(department),
      doctor: '${json['doctor'] ?? ''}',
      residence: '${json['residence'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      photoPath: json['photo_path'] as String?,
      photoName: json['photo_name'] as String?,
      signs: _stringList(details['signs']),
      symptoms: _stringList(details['symptoms']),
      pastHistory: _stringList(details['past_history']),
      operationHistory: _stringList(details['operation_history']),
      vitalReadings: _mapList(
        details['vital_readings'],
      ).map(VitalReading.fromJson).toList(growable: false),
      labs: _mapList(
        details['labs'],
      ).map(PatientTest.fromJson).toList(growable: false),
      imaging: _mapList(
        details['imaging'],
      ).map(PatientTest.fromJson).toList(growable: false),
      lastOperativeDetails: '${details['last_operative_details'] ?? ''}',
      currentTreatment: '${details['current_treatment'] ?? ''}',
      currentTreatmentDetail: '${details['current_treatment_detail'] ?? ''}',
      currentDose: '${details['current_dose'] ?? ''}',
      doctorOrders: _mapList(
        details['doctor_orders'],
      ).map(DoctorOrder.fromJson).toList(growable: false),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse('${json['updated_at']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'department': department,
      'name': name,
      'file_number': fileNumber,
      'room_number': roomNumber,
      'diagnosis': diagnosis,
      'status_label': statusLabel,
      'doctor': doctor,
      'residence': residence,
      'phone': phone,
      'photo_path': photoPath,
      'photo_name': photoName,
      'details': {
        'signs': signs,
        'symptoms': symptoms,
        'past_history': pastHistory,
        'operation_history': operationHistory,
        'vital_readings': vitalReadings.map((item) => item.toJson()).toList(),
        'labs': labs.map((item) => item.toJson()).toList(),
        'imaging': imaging.map((item) => item.toJson()).toList(),
        'last_operative_details': lastOperativeDetails,
        'current_treatment': currentTreatment,
        'current_treatment_detail': currentTreatmentDetail,
        'current_dose': currentDose,
        'doctor_orders': doctorOrders.map((item) => item.toJson()).toList(),
      },
    };
  }
}
