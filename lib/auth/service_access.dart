import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Services a subscriber can request. [key] matches `service_access.service`
/// in the database.
enum HospService {
  generalSurgery(
    'general_surgery',
    'الجراحة العامة',
    'General Surgery',
    Icons.local_hospital_outlined,
  ),
  oncologySurgery(
    'oncology_surgery',
    'جراحة الأورام',
    'Oncology Surgery',
    Icons.healing_outlined,
  ),
  pediatricSurgery(
    'pediatric_surgery',
    'جراحة الأطفال',
    'Pediatric Surgery',
    Icons.child_care_outlined,
  ),
  obgynClinic(
    'obgyn_clinic',
    'عيادة النسا والتوليد',
    'Obstetrics & Gynecology Clinic',
    Icons.pregnant_woman_rounded,
  ),
  pediatricsClinic(
    'pediatrics_clinic',
    'عيادة الأطفال',
    'Pediatrics Clinic',
    Icons.child_care_rounded,
  );

  const HospService(this.key, this.arabicName, this.englishName, this.icon);

  final String key;
  final String arabicName;
  final String englishName;
  final IconData icon;

  String label(bool isArabic) => isArabic ? arabicName : englishName;

  static HospService? fromKey(String key) {
    for (final service in values) {
      if (service.key == key) return service;
    }
    return null;
  }
}

enum AccessStatus {
  pending,
  approved,
  rejected;

  static AccessStatus fromKey(String key) => values.firstWhere(
    (status) => status.name == key,
    orElse: () => AccessStatus.pending,
  );

  String label(bool isArabic) => switch (this) {
    pending => isArabic ? 'قيد المراجعة' : 'Pending',
    approved => isArabic ? 'مقبول' : 'Approved',
    rejected => isArabic ? 'مرفوض' : 'Rejected',
  };
}

class ServiceAccessEntry {
  const ServiceAccessEntry({
    required this.id,
    required this.email,
    required this.service,
    required this.status,
    this.userId,
    this.requestedAt,
  });

  factory ServiceAccessEntry.fromRow(Map<String, dynamic> row) {
    return ServiceAccessEntry(
      id: row['id'] as String,
      userId: row['user_id'] as String?,
      email: (row['email'] as String? ?? '').toLowerCase(),
      service: HospService.fromKey(row['service'] as String? ?? ''),
      status: AccessStatus.fromKey(row['status'] as String? ?? ''),
      requestedAt: DateTime.tryParse(row['requested_at'] as String? ?? ''),
    );
  }

  final String id;
  final String? userId;
  final String email;
  final HospService? service;
  final AccessStatus status;
  final DateTime? requestedAt;
}

/// What the signed-in user is allowed to open.
class ServiceAccess {
  const ServiceAccess({required this.isAdmin, required this.statuses});

  factory ServiceAccess.forUser(
    Iterable<ServiceAccessEntry> entries, {
    required bool isAdmin,
    required String? userId,
    required String? email,
  }) {
    final mail = email?.toLowerCase();
    final statuses = <HospService, AccessStatus>{};
    for (final entry in entries) {
      final service = entry.service;
      if (service == null) continue;
      final mine =
          (userId != null && entry.userId == userId) || entry.email == mail;
      if (mine) statuses[service] = entry.status;
    }
    return ServiceAccess(isAdmin: isAdmin, statuses: statuses);
  }

  final bool isAdmin;
  final Map<HospService, AccessStatus> statuses;

  Set<HospService> get approved => isAdmin
      ? HospService.values.toSet()
      : {
          for (final entry in statuses.entries)
            if (entry.value == AccessStatus.approved) entry.key,
        };

  bool get hasAccess => approved.isNotEmpty;
}

class ServiceAccessRepository {
  ServiceAccessRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  static const _table = 'service_access';

  final SupabaseClient _client;

  User? get _user => _client.auth.currentUser;

  Future<List<ServiceAccessEntry>> _select() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('requested_at', ascending: false);
    return rows.map(ServiceAccessEntry.fromRow).toList();
  }

  Future<ServiceAccess> loadMine() async {
    final user = _user;
    final entries = await _select();
    return ServiceAccess.forUser(
      entries,
      isAdmin: user?.appMetadata['role'] == 'admin',
      userId: user?.id,
      email: user?.email,
    );
  }

  /// Files pending requests for services the user has no row for yet.
  Future<void> request(Iterable<HospService> services) async {
    final user = _user;
    if (user == null || services.isEmpty) return;
    await _client.from(_table).insert([
      for (final service in services)
        {
          'user_id': user.id,
          'email': (user.email ?? '').toLowerCase(),
          'service': service.key,
          'status': 'pending',
        },
    ]);
  }

  /// Admin only (enforced by RLS).
  Future<List<ServiceAccessEntry>> listAll() => _select();

  Future<void> setStatus(String id, AccessStatus status) async {
    await _client
        .from(_table)
        .update({
          'status': status.name,
          'decided_at': DateTime.now().toUtc().toIso8601String(),
          'decided_by': _user?.id,
        })
        .eq('id', id);
  }

  Future<void> remove(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Admin only: creates a confirmed account through the `admin-create-user`
  /// Edge Function (it needs the service-role key) and approves [services].
  Future<void> createUser(
    String email,
    String password,
    Iterable<HospService> services,
  ) async {
    await _client.functions.invoke(
      'admin-create-user',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'services': [for (final service in services) service.key],
      },
    );
  }

  /// Pre-approves [services] for [email]. The user receives them when they
  /// sign up or sign in with that address.
  Future<void> grant(String email, Iterable<HospService> services) async {
    final mail = email.trim().toLowerCase();
    final existing = (await _client.from(_table).select().eq('email', mail))
        .map(ServiceAccessEntry.fromRow)
        .toList();
    for (final service in services) {
      final match = existing.where((entry) => entry.service == service);
      if (match.isNotEmpty) {
        if (match.first.status != AccessStatus.approved) {
          await setStatus(match.first.id, AccessStatus.approved);
        }
      } else {
        await _client.from(_table).insert({
          'email': mail,
          'service': service.key,
          'status': 'approved',
          'decided_at': DateTime.now().toUtc().toIso8601String(),
          'decided_by': _user?.id,
        });
      }
    }
  }
}
