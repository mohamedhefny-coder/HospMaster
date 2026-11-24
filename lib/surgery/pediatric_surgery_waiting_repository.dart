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
    this.opDetails = const [],
    this.hasOpDetailsColumn = false,
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

  /// Dated operation/event lines: `{date, text}`.
  final List<Map<String, dynamic>> opDetails;

  /// Whether the row came from a table that already has `op_details`; the
  /// column is only written when it exists or when there is something to save,
  /// so the app keeps working before the migration is applied.
  final bool hasOpDetailsColumn;

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
      opDetails: (json['op_details'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false),
      hasOpDetailsColumn: json.containsKey('op_details'),
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
      if (opDetails.isNotEmpty) 'op_details': opDetails,
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
      if (opDetails.isNotEmpty || hasOpDetailsColumn) 'op_details': opDetails,
    };
  }
}

class PediatricSurgeryWaitingRepository {
  PediatricSurgeryWaitingRepository({
    SupabaseClient? client,
    String tableName = 'pediatric_surgery_waiting_patients',
    String imagesBucket = 'pediatric_surgery_patient_images',
    this.listId,
  }) : _clientOverride = client,
       _tableName = tableName,
       _imagesBucket = imagesBucket;

  /// Waiting list of the other medical departments (created by admins).
  PediatricSurgeryWaitingRepository.forList(String this.listId)
    : _clientOverride = null,
      _tableName = 'waiting_list_patients',
      _imagesBucket = 'waiting_list_patient_images';

  /// Set for admin-created lists; `null` for the pediatric surgery list.
  final String? listId;
  final SupabaseClient? _clientOverride;
  final String _tableName;
  final String _imagesBucket;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

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
    var query = _client.from(_tableName).select();
    final list = listId;
    if (list != null) query = query.eq('list_id', list);
    final response = await query
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
        .insert({
          ...patient.toInsertJson(),
          if (listId != null) 'list_id': listId,
        })
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
    : _clientOverride = client,
      listId = null,
      _tableName = 'pediatric_surgery_doctors';

  /// Doctors of an admin-created waiting list.
  PediatricSurgeryDoctorsRepository.forList(String this.listId)
    : _clientOverride = null,
      _tableName = 'waiting_list_doctors';

  final String? listId;
  final SupabaseClient? _clientOverride;
  final String _tableName;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static const Duration _requestTimeout = Duration(seconds: 45);

  Future<List<String>> fetchDoctorNames() async {
    var query = _client.from(_tableName).select('name');
    final list = listId;
    if (list != null) query = query.eq('list_id', list);
    final response = await query
        .order('created_at', ascending: true)
        .timeout(_requestTimeout);
    return (response as List<dynamic>)
        .map((row) => (row as Map)['name'] as String)
        .toList(growable: false);
  }

  Future<void> addDoctor(String name) {
    return _client
        .from(_tableName)
        .insert({'name': name, if (listId != null) 'list_id': listId})
        .timeout(_requestTimeout);
  }

  /// Throws when nothing was updated, e.g. because the user is not an admin.
  Future<void> renameDoctor(String oldName, String newName) async {
    var query = _client
        .from(_tableName)
        .update({'name': newName})
        .eq('name', oldName);
    final list = listId;
    if (list != null) query = query.eq('list_id', list);
    final updated = await query.select('id').timeout(_requestTimeout);
    if ((updated as List).isEmpty) {
      throw StateError('Doctor was not updated.');
    }
  }

  Future<void> deleteDoctor(String name) async {
    var query = _client.from(_tableName).delete().eq('name', name);
    final list = listId;
    if (list != null) query = query.eq('list_id', list);
    final deleted = await query.select('id').timeout(_requestTimeout);
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
  DemoPediatricSurgeryDoctorsRepository({
    List<String> seed = const ['قائمة الطبيب 1', 'قائمة الطبيب 2'],
  }) : _names = [...seed];

  final List<String> _names;

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

/// A waiting list created by an admin for another medical department.
class WaitingList {
  const WaitingList({required this.id, required this.name});

  factory WaitingList.fromJson(Map<String, dynamic> json) => WaitingList(
    id: json['id'] as String,
    name: (json['name'] ?? '') as String,
  );

  final String id;
  final String name;
}

class WaitingListsRepository {
  WaitingListsRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static const String _tableName = 'waiting_lists';
  static const Duration _requestTimeout = Duration(seconds: 45);

  Future<List<WaitingList>> fetchLists() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('created_at', ascending: true)
        .timeout(_requestTimeout);
    return (response as List<dynamic>)
        .map(
          (row) => WaitingList.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  Future<WaitingList> createList(String name) async {
    final response = await _client
        .from(_tableName)
        .insert({'name': name})
        .select()
        .single()
        .timeout(_requestTimeout);
    return WaitingList.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> renameList(String id, String name) async {
    final updated = await _client
        .from(_tableName)
        .update({'name': name})
        .eq('id', id)
        .select('id')
        .timeout(_requestTimeout);
    if ((updated as List).isEmpty) throw StateError('List was not updated.');
  }

  /// Removes the list; its doctors and patients are deleted with it.
  Future<void> deleteList(String id) async {
    final deleted = await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .select('id')
        .timeout(_requestTimeout);
    if ((deleted as List).isEmpty) throw StateError('List was not deleted.');
  }

  PediatricSurgeryWaitingRepository waitingRepositoryFor(String listId) =>
      PediatricSurgeryWaitingRepository.forList(listId);

  PediatricSurgeryDoctorsRepository doctorsRepositoryFor(String listId) =>
      PediatricSurgeryDoctorsRepository.forList(listId);
}

/// In-memory stand-in used in guest mode.
class DemoWaitingListsRepository extends WaitingListsRepository {
  DemoWaitingListsRepository();

  final List<WaitingList> _lists = [];
  final Map<String, DemoPediatricSurgeryWaitingRepository> _waiting = {};
  final Map<String, DemoPediatricSurgeryDoctorsRepository> _doctors = {};
  int _nextId = 1;

  @override
  Future<List<WaitingList>> fetchLists() async => [..._lists];

  @override
  Future<WaitingList> createList(String name) async {
    final list = WaitingList(id: 'demo-list-${_nextId++}', name: name);
    _lists.add(list);
    return list;
  }

  @override
  Future<void> renameList(String id, String name) async {
    final index = _lists.indexWhere((list) => list.id == id);
    if (index >= 0) _lists[index] = WaitingList(id: id, name: name);
  }

  @override
  Future<void> deleteList(String id) async {
    _lists.removeWhere((list) => list.id == id);
    _waiting.remove(id);
    _doctors.remove(id);
  }

  @override
  PediatricSurgeryWaitingRepository waitingRepositoryFor(String listId) =>
      _waiting.putIfAbsent(listId, DemoPediatricSurgeryWaitingRepository.new);

  @override
  PediatricSurgeryDoctorsRepository doctorsRepositoryFor(String listId) =>
      _doctors.putIfAbsent(
        listId,
        () => DemoPediatricSurgeryDoctorsRepository(seed: const []),
      );
}
