import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hospmaster/auth/account_button.dart';

import 'patient_follow_up_sheet_page.dart';
import 'patient_repository.dart';

const Color _ink = Color(0xFF16324F);
const Color _muted = Color(0xFF5B6B7B);
const Color _line = Color(0xFFD9E1EA);
const Color _canvas = Color(0xFFF4F7FC);

/// Read-only profile that shows everything stored for a patient.
class PatientProfilePage extends StatefulWidget {
  final PatientRecord patient;
  final SurgeryPatientRepository? repository;

  const PatientProfilePage({super.key, required this.patient, this.repository});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  late PatientRecord _patient = widget.patient;
  late final SurgeryPatientRepository _repository =
      widget.repository ?? SurgeryPatientRepository();
  Future<Uint8List>? _photoFuture;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  void _loadPhoto() {
    final path = _patient.photoPath;
    _photoFuture = path == null ? null : _repository.downloadFile(path);
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<PatientRecord>(
      MaterialPageRoute(
        builder: (_) => PatientDetailsPage(
          patient: _patient,
          department: _patient.department,
          repository: _repository,
        ),
      ),
    );
    if (saved == null || !mounted) return;

    setState(() {
      _patient = saved;
      _loadPhoto();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات المريض')));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المريض'),
          content: Text('هل تريد حذف ${_patient.name} وكل بياناته نهائيًا؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isBusy = true);
    try {
      await _repository.deletePatient(_patient);
      messenger.showSnackBar(const SnackBar(content: Text('تم حذف المريض')));
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل حذف المريض: ${describeSupabaseError(error)}'),
        ),
      );
    }
  }

  Future<void> _toggleOrder(int index, bool done) async {
    final previous = _patient;
    final orders = [
      for (var i = 0; i < previous.doctorOrders.length; i++)
        DoctorOrder(
          text: previous.doctorOrders[i].text,
          createdAt: previous.doctorOrders[i].createdAt,
          done: i == index ? done : previous.doctorOrders[i].done,
        ),
    ];
    setState(() => _patient = previous.copyWith(doctorOrders: orders));

    try {
      final saved = await _repository.savePatient(_patient);
      if (!mounted) return;
      setState(() => _patient = saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _patient = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر تحديث الأمر: $error')));
    }
  }

  Future<void> _openAttachment(String title, String path) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _repository.downloadFile(path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(title),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('تعذر عرض الملف كصورة'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر فتح المرفق: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patient;
    final accent = SurgeryDepartment.accent(patient.department);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          title: const Text('الملف السريري'),
          centerTitle: true,
          actions: [
            const AccountButton(),
            IconButton(
              tooltip: 'تعديل',
              onPressed: _isBusy ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'حذف',
              onPressed: _isBusy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_canvas, Color(0xFFEAF0FA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildHeader(patient, accent),
                _buildClinicalSnapshot(patient, accent),
                _buildBasicInfo(patient, accent),
                _buildComplaint(patient, accent),
                _buildHistory(patient, accent),
                _buildVitals(patient, accent),
                _buildTests(
                  title: 'التحاليل المعملية',
                  icon: Icons.biotech_outlined,
                  tests: patient.labs,
                  accent: accent,
                ),
                _buildTests(
                  title: 'الأشعة والفحوصات',
                  icon: Icons.medical_information_outlined,
                  tests: patient.imaging,
                  accent: accent,
                ),
                _buildOperative(patient, accent),
                _buildTreatment(patient, accent),
                _buildDoctorOrders(patient, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PatientRecord patient, Color accent) {
    final photoFuture = _photoFuture;

    Widget avatar(Widget child) => Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    const fallbackAvatar = Icon(Icons.person, color: Colors.white, size: 44);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(accent, Colors.white, 0.08)!,
            Color.lerp(accent, Colors.black, 0.38)!,
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -60,
            end: -42,
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 180,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATIENT OVERVIEW',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  avatar(
                    photoFuture == null
                        ? fallbackAvatar
                        : FutureBuilder<Uint8List>(
                            future: photoFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => fallbackAvatar,
                                );
                              }
                              return fallbackAvatar;
                            },
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          SurgeryDepartment.label(patient.department),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (patient.fileNumber.isNotEmpty)
                    _HeaderChip(
                      icon: Icons.folder_open_outlined,
                      label: 'ملف ${patient.fileNumber}',
                    ),
                  if (patient.roomNumber.isNotEmpty)
                    _HeaderChip(
                      icon: Icons.bed_outlined,
                      label: 'غرفة ${patient.roomNumber}',
                    ),
                  if (patient.statusLabel.isNotEmpty)
                    _HeaderChip(
                      icon: Icons.flag_outlined,
                      label: patient.statusLabel,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalSnapshot(PatientRecord patient, Color accent) {
    final completedOrders = patient.doctorOrders
        .where((order) => order.done)
        .length;
    final latestVital = patient.vitalReadings.isEmpty
        ? null
        : patient.vitalReadings.reduce(
            (latest, reading) =>
                reading.date.isAfter(latest.date) ? reading : latest,
          );

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100D2742),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الحالة',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.monitor_heart_outlined,
                  label: 'آخر قراءة',
                  value: latestVital == null
                      ? 'غير مسجلة'
                      : formatPatientDate(latestVital.date),
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'أوامر منفذة',
                  value: '$completedOrders / ${patient.doctorOrders.length}',
                  accent: const Color(0xFF17866B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.science_outlined,
                  label: 'الفحوصات',
                  value: '${patient.labs.length + patient.imaging.length}',
                  accent: const Color(0xFF8060C8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(PatientRecord patient, Color accent) {
    return _SectionCard(
      icon: Icons.badge_outlined,
      title: 'البيانات الأساسية',
      accent: accent,
      child: Column(
        children: [
          _InfoRow(label: 'التشخيص', value: patient.diagnosis),
          _InfoRow(label: 'الطبيب المعالج', value: patient.doctor),
          _InfoRow(label: 'محل الإقامة', value: patient.residence),
          _InfoRow(label: 'رقم الهاتف', value: patient.phone, ltr: true),
          if (patient.createdAt != null)
            _InfoRow(
              label: 'تاريخ التسجيل',
              value: formatPatientDate(patient.createdAt!.toLocal()),
            ),
        ],
      ),
    );
  }

  Widget _buildComplaint(PatientRecord patient, Color accent) {
    return _SectionCard(
      icon: Icons.sick_outlined,
      title: 'Complaint',
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledChips(label: 'Signs', values: patient.signs, accent: accent),
          const SizedBox(height: 12),
          _LabeledChips(
            label: 'Symptoms',
            values: patient.symptoms,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(PatientRecord patient, Color accent) {
    return _SectionCard(
      icon: Icons.history_edu_outlined,
      title: 'History',
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledChips(
            label: 'Past history',
            values: patient.pastHistory,
            accent: accent,
          ),
          const SizedBox(height: 12),
          _LabeledChips(
            label: 'Operation history',
            values: patient.operationHistory,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildVitals(PatientRecord patient, Color accent) {
    final byDate = <DateTime, Map<VitalShift, VitalReading>>{};
    for (final reading in patient.vitalReadings) {
      final day = DateTime(
        reading.date.year,
        reading.date.month,
        reading.date.day,
      );
      byDate.putIfAbsent(day, () => {})[reading.shift] = reading;
    }
    final days = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return _SectionCard(
      icon: Icons.monitor_heart_outlined,
      title: 'Vital signs',
      accent: accent,
      child: days.isEmpty
          ? const _EmptyHint()
          : Column(
              children: [
                for (final day in days)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatPatientDate(day),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final shift in VitalShift.values)
                          _VitalShiftRow(
                            shift: shift,
                            reading: byDate[day]![shift],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTests({
    required String title,
    required IconData icon,
    required List<PatientTest> tests,
    required Color accent,
  }) {
    return _SectionCard(
      icon: icon,
      title: title,
      accent: accent,
      child: tests.isEmpty
          ? const _EmptyHint()
          : Column(
              children: [
                for (final test in tests)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        if (test.result.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(test.result),
                        ],
                        if (test.imagePath != null) ...[
                          const SizedBox(height: 6),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                            ),
                            onPressed: () =>
                                _openAttachment(test.name, test.imagePath!),
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(test.imageName ?? 'عرض المرفق'),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildOperative(PatientRecord patient, Color accent) {
    return _SectionCard(
      icon: Icons.content_cut_outlined,
      title: 'Last operative details',
      accent: accent,
      child: patient.lastOperativeDetails.isEmpty
          ? const _EmptyHint()
          : Text(patient.lastOperativeDetails),
    );
  }

  Widget _buildTreatment(PatientRecord patient, Color accent) {
    final hasTreatment = patient.currentTreatment.isNotEmpty;

    return _SectionCard(
      icon: Icons.medication_outlined,
      title: 'العلاج الحالي',
      accent: accent,
      child: !hasTreatment && patient.currentDose.isEmpty
          ? const _EmptyHint()
          : Column(
              children: [
                _InfoRow(label: 'الدواء', value: patient.currentTreatment),
                _InfoRow(
                  label: 'التفاصيل',
                  value: patient.currentTreatmentDetail,
                ),
                _InfoRow(label: 'الجرعة', value: patient.currentDose),
              ],
            ),
    );
  }

  Widget _buildDoctorOrders(PatientRecord patient, Color accent) {
    final orders = patient.doctorOrders;

    return _SectionCard(
      icon: Icons.assignment_outlined,
      title: 'Doctor orders',
      accent: accent,
      child: orders.isEmpty
          ? const _EmptyHint()
          : Column(
              children: [
                for (var i = 0; i < orders.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: orders[i].done
                          ? const Color(0xFFF1FBF5)
                          : const Color(0xFFFDFEFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: orders[i].done,
                          onChanged: (value) => _toggleOrder(i, value ?? false),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orders[i].text,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: orders[i].done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                '${formatPatientDate(orders[i].createdAt)} - ${formatPatientTime(orders[i].createdAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D2742),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ltr;

  const _InfoRow({required this.label, required this.value, this.ltr = false});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: ltr ? TextAlign.right : null,
              style: const TextStyle(fontWeight: FontWeight.w600, color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledChips extends StatelessWidget {
  final String label;
  final List<String> values;
  final Color accent;

  const _LabeledChips({
    required this.label,
    required this.values,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _muted),
        ),
        const SizedBox(height: 6),
        if (values.isEmpty)
          const _EmptyHint()
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Color.lerp(accent, Colors.black, 0.3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _VitalShiftRow extends StatelessWidget {
  final VitalShift shift;
  final VitalReading? reading;

  const _VitalShiftRow({required this.shift, required this.reading});

  @override
  Widget build(BuildContext context) {
    final reading = this.reading;
    final isMorning = shift == VitalShift.morning;
    final values = reading == null
        ? const <String>[]
        : [
            if (reading.bp.isNotEmpty) 'BP ${reading.bp}',
            if (reading.hr.isNotEmpty) 'HR ${reading.hr}',
            if (reading.rr.isNotEmpty) 'RR ${reading.rr}',
            if (reading.spo2.isNotEmpty) 'SpO2 ${reading.spo2}',
            if (reading.temp.isNotEmpty) 'Temp ${reading.temp}',
            if (reading.consciousLevel.isNotEmpty) reading.consciousLevel,
          ];

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMorning ? const Color(0xFFFFFBEA) : const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isMorning ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
            size: 18,
            color: isMorning
                ? const Color(0xFFE09B00)
                : const Color(0xFF4A5BD0),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              shift.label,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
            ),
          ),
          Expanded(
            child: values.isEmpty
                ? const Text('—', style: TextStyle(color: _muted))
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (final value in values)
                          Text(
                            value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Text('لا توجد بيانات', style: TextStyle(color: _muted));
  }
}
