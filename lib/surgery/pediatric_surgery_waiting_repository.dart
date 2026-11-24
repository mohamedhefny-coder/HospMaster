import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

// Doctor names are matched by exact string; data may hold "د.أحمد" or "د. أحمد".
String _normalizeDoctor(String doctor) =>
    doctor.replaceFirst(RegExp(r'^د\.\s*'), 'د. ');

class PediatricSurgeryWaitingPatient {
  const PediatricSurgeryWaitingPatient({
    this.id,
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.doctor,
    required this.date,
    required this.priority,
    required this.workflowStage,
    this.phone = '',
    this.notes = '',
    this.images = const [],
    this.operationListDate,
    this.callStatus = '',
    this.createdAt,
  });

  final String? id;
  final String name;
  final String age;
  final String diagnosis;
  final String doctor;
  final String date;
  final String priority;
  final String workflowStage;
  final String phone;
  final String notes;
  final List<Map<String, dynamic>> images;
  final String? operationListDate;
  final String callStatus;
  final DateTime? createdAt;

  factory PediatricSurgeryWaitingPatient.fromJson(Map<String, dynamic> json) {
    return PediatricSurgeryWaitingPatient(
      id: json['id'] as String?,
      name: (json['name'] ?? '') as String,
      age: (json['age'] ?? '') as String,
      diagnosis: (json['diagnosis'] ?? '') as String,
      doctor: _normalizeDoctor((json['doctor'] ?? '') as String),
      date: (json['date'] ?? '') as String,
      priority: (json['priority'] ?? '') as String,
      workflowStage: (json['workflow_stage'] ?? 'waiting') as String,
      phone: (json['phone'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      images: (json['images'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((image) => Map<String, dynamic>.from(image))
          .toList(growable: false),
      operationListDate: json['operation_list_date'] as String?,
      callStatus: (json['call_status'] ?? '') as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'age': age,
      'diagnosis': diagnosis,
      'doctor': doctor,
      'date': date,
      'priority': priority,
      'workflow_stage': workflowStage,
      'phone': phone,
      'notes': notes,
      'images': images,
      'operation_list_date': operationListDate,
      'call_status': callStatus,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'age': age,
      'diagnosis': diagnosis,
      'doctor': doctor,
      'date': date,
      'priority': priority,
      'workflow_stage': workflowStage,
      'phone': phone,
      'notes': notes,
      'images': images,
      'operation_list_date': operationListDate,
      'call_status': callStatus,
    };
  }
}

class PediatricSurgeryWaitingRepository {
  PediatricSurgeryWaitingRepository({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static const String _tableName = 'pediatric_surgery_waiting_patients';
  static const String _imagesBucket = 'pediatric_surgery_patient_images';
  static const Duration _requestTimeout = Duration(seconds: 45);

  /// Uploads a patient image and returns its storage path.
  Future<String> uploadImage(
    Uint8List bytes,
    String fileName,
    String contentType,
  ) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'patients/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _client.storage
        .from(_imagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return path;
  }

  Future<String> imageUrl(String path) =>
      _client.storage.from(_imagesBucket).createSignedUrl(path, 60 * 60);

  /// Image bytes held in memory (demo mode only); `null` means use [imageUrl].
  Future<Uint8List?> memoryImage(String path) async => null;

  Future<void> removeImages(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(_imagesBucket).remove(paths);
    } catch (_) {}
  }

  Future<List<PediatricSurgeryWaitingPatient>> fetchPatients() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: true)
        .order('created_at', ascending: true)
        .timeout(_requestTimeout);

    return (response as List<dynamic>)
        .map(
          (row) => PediatricSurgeryWaitingPatient.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<PediatricSurgeryWaitingPatient> addPatient(
    PediatricSurgeryWaitingPatient patient,
  ) async {
    final response = await _client
        .from(_tableName)
        .insert(patient.toInsertJson())
        .select()
        .single()
        .timeout(_requestTimeout);

    return PediatricSurgeryWaitingPatient.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<PediatricSurgeryWaitingPatient> updatePatient(
    PediatricSurgeryWaitingPatient patient,
  ) async {
    final id = patient.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Patient id is required for updates.');
    }

    final response = await _client
        .from(_tableName)
        .update(patient.toUpdateJson())
        .eq('id', id)
        .select()
        .single()
        .timeout(_requestTimeout);

    return PediatricSurgeryWaitingPatient.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> deletePatient(String id) {
    return _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .timeout(_requestTimeout);
  }

  Future<void> deletePatients(List<String> ids) {
    if (ids.isEmpty) return Future.value();
    return _client
        .from(_tableName)
        .delete()
        .inFilter('id', ids)
        .timeout(_requestTimeout);
  }

  Future<void> setDoctorForPatients(List<String> ids, String doctor) {
    if (ids.isEmpty) return Future.value();
    return _client
        .from(_tableName)
        .update({'doctor': doctor})
        .inFilter('id', ids)
        .timeout(_requestTimeout);
  }
}

class PediatricSurgeryDoctorsRepository {
  PediatricSurgeryDoctorsRepository({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static const String _tableName = 'pediatric_surgery_doctors';
  static const Duration _requestTimeout = Duration(seconds: 45);

  Future<List<String>> fetchDoctorNames() async {
    final response = await _client
        .from(_tableName)
        .select('name')
        .order('created_at', ascending: true)
        .timeout(_requestTimeout);
    return (response as List<dynamic>)
        .map((row) => (row as Map)['name'] as String)
        .toList(growable: false);
  }

  Future<void> addDoctor(String name) {
    return _client
        .from(_tableName)
        .insert({'name': name})
        .timeout(_requestTimeout);
  }

  /// Throws when nothing was updated, e.g. because the user is not an admin.
  Future<void> renameDoctor(String oldName, String newName) async {
    final updated = await _client
        .from(_tableName)
        .update({'name': newName})
        .eq('name', oldName)
        .select('id')
        .timeout(_requestTimeout);
    if ((updated as List).isEmpty) {
      throw StateError('Doctor was not updated.');
    }
  }

  Future<void> deleteDoctor(String name) async {
    final deleted = await _client
        .from(_tableName)
        .delete()
        .eq('name', name)
        .select('id')
        .timeout(_requestTimeout);
    if ((deleted as List).isEmpty) {
      throw StateError('Doctor was not deleted.');
    }
  }
}

/// In-memory stand-in used in guest mode: nothing is sent to Supabase and
/// everything is lost when the user leaves.
class DemoPediatricSurgeryWaitingRepository
    extends PediatricSurgeryWaitingRepository {
  DemoPediatricSurgeryWaitingRepository();

  final List<PediatricSurgeryWaitingPatient> _patients = [];
  final Map<String, Uint8List> _images = {};
  int _nextId = 1;

  PediatricSurgeryWaitingPatient _build(
    Map<String, dynamic> json,
    String id,
    DateTime createdAt,
  ) => PediatricSurgeryWaitingPatient.fromJson({
    ...json,
    'id': id,
    'created_at': createdAt.toIso8601String(),
  });

  @override
  Future<List<PediatricSurgeryWaitingPatient>> fetchPatients() async {
    final sorted = [..._patients]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return (a.createdAt ?? DateTime(0)).compareTo(
          b.createdAt ?? DateTime(0),
        );
      });
    return sorted;
  }

  @override
  Future<PediatricSurgeryWaitingPatient> addPatient(
    PediatricSurgeryWaitingPatient patient,
  ) async {
    final saved = _build(
      patient.toInsertJson(),
      'demo-${_nextId++}',
      DateTime.now(),
    );
    _patients.add(saved);
    return saved;
  }

  @override
  Future<PediatricSurgeryWaitingPatient> updatePatient(
    PediatricSurgeryWaitingPatient patient,
  ) async {
    final index = _patients.indexWhere((item) => item.id == patient.id);
    if (index < 0) throw StateError('Patient not found.');
    final saved = _build(
      patient.toUpdateJson(),
      patient.id!,
      _patients[index].createdAt ?? DateTime.now(),
    );
    _patients[index] = saved;
    return saved;
  }

  @override
  Future<void> deletePatient(String id) async =>
      _patients.removeWhere((item) => item.id == id);

  @override
  Future<void> deletePatients(List<String> ids) async =>
      _patients.removeWhere((item) => ids.contains(item.id));

  @override
  Future<void> setDoctorForPatients(List<String> ids, String doctor) async {
    for (var i = 0; i < _patients.length; i++) {
      final patient = _patients[i];
      if (!ids.contains(patient.id)) continue;
      _patients[i] = _build(
        {...patient.toUpdateJson(), 'doctor': doctor},
        patient.id!,
        patient.createdAt ?? DateTime.now(),
      );
    }
  }

  @override
  Future<String> uploadImage(
    Uint8List bytes,
    String fileName,
    String contentType,
  ) async {
    final path = 'demo/${_nextId++}_$fileName';
    _images[path] = bytes;
    return path;
  }

  @override
  Future<String> imageUrl(String path) async => path;

  @override
  Future<Uint8List?> memoryImage(String path) async => _images[path];

  @override
  Future<void> removeImages(List<String> paths) async =>
      paths.forEach(_images.remove);
}

class DemoPediatricSurgeryDoctorsRepository
    extends PediatricSurgeryDoctorsRepository {
  DemoPediatricSurgeryDoctorsRepository();

  final List<String> _names = ['قائمة الطبيب 1', 'قائمة الطبيب 2'];

  @override
  Future<List<String>> fetchDoctorNames() async => [..._names];

  @override
  Future<void> addDoctor(String name) async => _names.add(name);

  @override
  Future<void> renameDoctor(String oldName, String newName) async {
    final index = _names.indexOf(oldName);
    if (index >= 0) _names[index] = newName;
  }

  @override
  Future<void> deleteDoctor(String name) async => _names.remove(name);
}
