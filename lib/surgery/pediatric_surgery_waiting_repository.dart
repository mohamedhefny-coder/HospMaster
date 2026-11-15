import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

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
      doctor: (json['doctor'] ?? '') as String,
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
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _tableName = 'pediatric_surgery_waiting_patients';
  static const Duration _requestTimeout = Duration(seconds: 45);

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
}
