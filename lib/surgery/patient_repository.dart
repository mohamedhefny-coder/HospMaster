import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'patient_record.dart';

/// Turns Supabase errors into a short Arabic message the user can act on.
String describeSupabaseError(Object error) {
  final text = '$error';
  if (text.contains('PGRST205') || text.contains('surgery_patients')) {
    return 'جدول surgery_patients غير موجود في Supabase. شغّل ملف '
        'supabase/migrations/20261025_surgery_patients.sql في SQL Editor ثم أعد المحاولة.';
  }
  if (text.contains('Bucket not found') ||
      text.contains('surgery_patient_files')) {
    return 'مخزن الملفات surgery_patient_files غير موجود. شغّل ملف '
        'الـ SQL الخاص بالمرضى في Supabase.';
  }
  if (text.contains('row-level security') || text.contains('42501')) {
    return 'سياسات الأمان (RLS) في Supabase ترفض العملية. شغّل ملف الـ SQL '
        'الخاص بالمرضى لإنشاء السياسات المطلوبة.';
  }
  return text;
}

class SurgeryPatientRepository {
  SurgeryPatientRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static const String _tableName = 'surgery_patients';
  static const String _bucketName = 'surgery_patient_files';
  static const Duration _requestTimeout = Duration(seconds: 45);

  Future<List<PatientRecord>> fetchPatients(String department) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('department', department)
        .order('created_at', ascending: false)
        .timeout(_requestTimeout);

    return (response as List<dynamic>)
        .map(
          (row) =>
              PatientRecord.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  /// Inserts the patient, or updates it when it already has an id.
  Future<PatientRecord> savePatient(PatientRecord patient) async {
    final id = patient.id;
    final payload = patient.toJson();

    final response = id == null
        ? await _client
              .from(_tableName)
              .insert(payload)
              .select()
              .single()
              .timeout(_requestTimeout)
        : await _client
              .from(_tableName)
              .update({
                ...payload,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', id)
              .select()
              .single()
              .timeout(_requestTimeout);

    return PatientRecord.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deletePatient(PatientRecord patient) async {
    final id = patient.id;
    if (id == null) return;

    await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .timeout(_requestTimeout);
    await removeFiles(patient.filePaths);
  }

  Future<String> uploadFile(Uint8List bytes, String fileName) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final extension = safeName.contains('.')
        ? safeName.split('.').last.toLowerCase()
        : '';
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final path = 'patients/${DateTime.now().microsecondsSinceEpoch}_$safeName';

    await _client.storage
        .from(_bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        )
        .timeout(_requestTimeout);
    return path;
  }

  Future<Uint8List> downloadFile(String path) {
    return _client.storage
        .from(_bucketName)
        .download(path)
        .timeout(_requestTimeout);
  }

  Future<void> removeFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage
          .from(_bucketName)
          .remove(paths)
          .timeout(_requestTimeout);
    } on TimeoutException {
      // The patient record has already been saved. An orphaned attachment can
      // be removed later and should not make the successful save appear failed.
    }
  }
}

/// In-memory stand-in used in guest mode: nothing is sent to Supabase and
/// everything is lost when the user leaves.
class DemoSurgeryPatientRepository extends SurgeryPatientRepository {
  DemoSurgeryPatientRepository();

  final List<Map<String, dynamic>> _rows = [];
  final Map<String, Uint8List> _files = {};
  int _nextId = 1;

  @override
  Future<List<PatientRecord>> fetchPatients(String department) async => [
    for (final row in _rows.reversed)
      if (row['department'] == department) PatientRecord.fromJson(row),
  ];

  @override
  Future<PatientRecord> savePatient(PatientRecord patient) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = patient.id;
    final index = id == null ? -1 : _rows.indexWhere((r) => r['id'] == id);
    final row = {
      ...patient.toJson(),
      'id': id ?? 'demo-${_nextId++}',
      'created_at': index >= 0 ? _rows[index]['created_at'] : now,
      'updated_at': now,
    };
    if (index >= 0) {
      _rows[index] = row;
    } else {
      _rows.add(row);
    }
    return PatientRecord.fromJson(row);
  }

  @override
  Future<void> deletePatient(PatientRecord patient) async {
    _rows.removeWhere((row) => row['id'] == patient.id);
    await removeFiles(patient.filePaths);
  }

  @override
  Future<String> uploadFile(Uint8List bytes, String fileName) async {
    final path = 'demo/${_nextId++}_$fileName';
    _files[path] = bytes;
    return path;
  }

  @override
  Future<Uint8List> downloadFile(String path) async {
    final bytes = _files[path];
    if (bytes == null) throw StateError('File not found.');
    return bytes;
  }

  @override
  Future<void> removeFiles(List<String> paths) async =>
      paths.forEach(_files.remove);
}
