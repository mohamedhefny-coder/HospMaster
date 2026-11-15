import 'package:flutter/material.dart';
import 'package:hospmaster/auth/account_button.dart';
import 'package:hospmaster/surgery/patient_follow_up_sheet_page.dart';
import 'package:hospmaster/surgery/patient_profile_page.dart';
import 'package:hospmaster/surgery/patient_repository.dart';

class OncologySurgeryPage extends StatefulWidget {
  final SurgeryPatientRepository? repository;

  const OncologySurgeryPage({super.key, this.repository});

  @override
  State<OncologySurgeryPage> createState() => _OncologySurgeryPageState();
}

class _OncologySurgeryPageState extends State<OncologySurgeryPage> {
  static const _accent = Color.fromARGB(255, 124, 72, 188);

  late final SurgeryPatientRepository _repository =
      widget.repository ?? SurgeryPatientRepository();
  List<PatientRecord> _patients = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final patients = await _repository.fetchPatients(
        SurgeryDepartment.oncology,
      );
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = describeSupabaseError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _addPatient() async {
    final patient = await Navigator.of(context).push<PatientRecord>(
      MaterialPageRoute(
        builder: (_) => PatientDetailsPage(
          isNew: true,
          department: SurgeryDepartment.oncology,
          repository: _repository,
          patient: const PatientRecord(
            department: SurgeryDepartment.oncology,
            name: '',
            fileNumber: '',
            roomNumber: '',
            diagnosis: '',
            statusLabel: 'جديد',
            accentColor: _accent,
          ),
        ),
      ),
    );
    if (patient == null || !mounted) return;

    setState(() => _patients.insert(0, patient));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ المريض في قسم جراحة الأورام.')),
    );
  }

  Future<void> _openPatient(PatientRecord patient) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PatientProfilePage(patient: patient, repository: _repository),
      ),
    );
    if (mounted) _loadPatients();
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _patients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 56, color: _accent),
              const SizedBox(height: 14),
              Text(
                'تعذر تحميل المرضى',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5B6B7B),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _loadPatients,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 56,
                color: _accent,
              ),
              const SizedBox(height: 14),
              Text(
                'لا يوجد مرضى بعد',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط على زر إضافة مريض لتسجيل أول حالة.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B6B7B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _patients.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final patient = _patients[index];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: _accent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(patient.name),
              subtitle: Text(
                [
                  if (patient.diagnosis.isNotEmpty) patient.diagnosis,
                  if (patient.fileNumber.isNotEmpty)
                    'ملف ${patient.fileNumber}',
                  if (patient.roomNumber.isNotEmpty)
                    'غرفة ${patient.roomNumber}',
                ].join(' • '),
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _openPatient(patient),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('جراحة الأورام'),
          actions: [
            const AccountButton(),
            IconButton(
              tooltip: 'تحديث',
              onPressed: _isLoading ? null : _loadPatients,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'إضافة مريض',
              onPressed: _addPatient,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPatient,
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('إضافة مريض'),
        ),
        body: SafeArea(child: _buildBody(theme)),
      ),
    );
  }
}
