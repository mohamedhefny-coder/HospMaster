import 'package:flutter/material.dart';
import 'package:hospmaster/auth/account_button.dart';
import 'package:hospmaster/auth/mode_selection_page.dart';
import 'package:hospmaster/auth/service_access.dart';
import 'package:hospmaster/clinic/obgyn_patient_form_page.dart';
import 'package:hospmaster/clinic/pediatric_patient_form_page.dart';
import 'package:hospmaster/parameters/medical_formulas_page.dart';
import 'package:hospmaster/surgery/admin_access.dart';
import 'package:hospmaster/surgery/custom_waiting_lists_section.dart';
import 'package:hospmaster/surgery/oncology_surgery_page.dart';
import 'package:hospmaster/surgery/patient_follow_up_sheet_page.dart';
import 'package:hospmaster/surgery/patient_repository.dart';
import 'package:hospmaster/surgery/pediatric_surgery_waiting_repository.dart';
import 'package:hospmaster/surgery/surgery_department_page.dart';
import 'package:hospmaster/surgery/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SurgerySupabaseConfig.initialize();
  runApp(const HospMasterApp());
}

const navy = Color(0xFF102A43);
const teal = Color(0xFF1585A6);
const _englishFontFamily = 'Tinos';

enum AppTab {
  overview,
  hospitalManager,
  clinicManager,
  departments,
  waitingLists,
  queue,
  appointments,
  patients,
}

enum ClinicKind { obgyn, pediatrics }

const _obgynRose = Color(0xFFD6457F);
const _pediatricSky = Color(0xFF1E88E5);

enum QueueStatus { waiting, serving, completed }

class QueueEntry {
  QueueEntry(
    this.number,
    this.patient,
    this.clinic,
    this.time,
    this.status, {
    this.priority = false,
  });

  final String number;
  final String patient;
  final String clinic;
  final String time;
  QueueStatus status;
  final bool priority;
}

class HospMasterApp extends StatelessWidget {
  const HospMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HospMaster',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          SafeArea(top: false, child: child ?? const SizedBox.shrink()),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        useMaterial3: true,
        fontFamily: _englishFontFamily,
        fontFamilyFallback: const ['Arial'],
      ),
      home: const ModeSelectionPage(dashboardBuilder: _buildDashboard),
    );
  }
}

Widget _buildDashboard(
  BuildContext context,
  bool isGuest,
  Set<HospService>? services,
) => HospitalDashboard(isGuest: isGuest, services: services);

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key, this.isGuest = false, this.services});

  final bool isGuest;

  /// Services the signed-in subscriber may open; `null` means unrestricted
  /// (guest mode).
  final Set<HospService>? services;

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  final List<QueueEntry> _queue = [
    QueueEntry(
      'A-014',
      'Mariam Hassan',
      'Cardiology',
      '09:30',
      QueueStatus.serving,
    ),
    QueueEntry(
      'A-015',
      'Omar Khaled',
      'Cardiology',
      '09:45',
      QueueStatus.waiting,
      priority: true,
    ),
    QueueEntry(
      'B-007',
      'Noura Ali',
      'Dermatology',
      '10:00',
      QueueStatus.waiting,
    ),
    QueueEntry(
      'C-021',
      'Yousef Adel',
      'Orthopedics',
      '10:15',
      QueueStatus.waiting,
    ),
  ];

  AppTab _tab = AppTab.overview;
  ClinicKind? _openClinic;
  final List<ClinicPatient> _clinicPatients = [];
  final List<PediatricPatient> _pediatricPatients = [];
  bool _isArabic = true;
  String _role = 'Doctor';
  String _search = '';

  bool get _rtl => _isArabic;

  bool _can(HospService service) => widget.services?.contains(service) ?? true;
  bool get _canSurgeryDepartments =>
      _can(HospService.generalSurgery) || _can(HospService.oncologySurgery);
  bool get _canWaitingLists =>
      _can(HospService.pediatricSurgery) || _can(HospService.otherWaitingLists);
  bool get _canHospital => _canSurgeryDepartments || _canWaitingLists;
  bool get _canClinics =>
      _can(HospService.obgynClinic) || _can(HospService.pediatricsClinic);
  int get _waiting =>
      _queue.where((entry) => entry.status == QueueStatus.waiting).length;

  String tr(String ar, String en) => _isArabic ? ar : en;
  TextDirection get _direction => _rtl ? TextDirection.rtl : TextDirection.ltr;

  void _callNext() {
    final current = _queue
        .where((entry) => entry.status == QueueStatus.serving)
        .firstOrNull;
    final next = _queue
        .where((entry) => entry.status == QueueStatus.waiting)
        .firstOrNull;
    if (next == null) return;
    setState(() {
      if (current != null) current.status = QueueStatus.completed;
      next.status = QueueStatus.serving;
    });
  }

  void _showNewAppointment() {
    final controller = TextEditingController();
    var clinic = 'Cardiology';
    showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: _direction,
        child: AlertDialog(
          title: Text(tr('إضافة موعد جديد', 'Add new appointment')),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  textAlign: _rtl ? TextAlign.right : TextAlign.left,
                  decoration: InputDecoration(
                    labelText: tr('اسم المريض', 'Patient name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: clinic,
                  decoration: InputDecoration(
                    labelText: tr('العيادة', 'Clinic'),
                    border: const OutlineInputBorder(),
                  ),
                  items: const ['Cardiology', 'Dermatology', 'Orthopedics']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => clinic = value ?? clinic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('إلغاء', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                setState(() {
                  _queue.add(
                    QueueEntry(
                      'N-${(_queue.length + 14).toString().padLeft(3, '0')}',
                      controller.text.trim(),
                      clinic,
                      '11:00',
                      QueueStatus.waiting,
                    ),
                  );
                  _tab = AppTab.queue;
                });
                Navigator.pop(context);
              },
              child: Text(tr('حفظ الموعد', 'Save appointment')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _direction,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Scaffold(
              body: Row(
                children: [
                  if (wide) _sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _header(wide),
                        Expanded(child: _body(wide)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 258,
      color: navy,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF19A7CE),
                child: Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HospMaster',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'HEALTHCARE OS',
                    style: TextStyle(
                      color: Color(0xFF8FAFC6),
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF173B5A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('مستشفى الحياة التخصصي', 'Al Hayat Specialty Hospital'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('العيادات الخارجية', 'Outpatient clinics'),
                  style: const TextStyle(
                    color: Color(0xFF9DB9CB),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _navTile(
            AppTab.overview,
            Icons.grid_view_outlined,
            tr('نظرة عامة', 'Overview'),
          ),
          if (_canClinics) ...[
            _navTile(
              AppTab.appointments,
              Icons.calendar_month_outlined,
              tr('المواعيد', 'Appointments'),
            ),
            _navTile(
              AppTab.patients,
              Icons.people_outline,
              tr('المرضى', 'Patients'),
            ),
            _navTile(
              AppTab.queue,
              Icons.format_list_numbered,
              tr('قائمة الانتظار', 'Waiting list'),
              badge: _waiting,
            ),
          ],
          const Spacer(),
          const Divider(color: Color(0xFF244D6C)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF43B2D8),
              child: Text(
                'AS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: const Text(
              'Dr. Ahmed Saleh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _role,
              style: const TextStyle(color: Color(0xFF91B5CB), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile(AppTab tab, IconData icon, String label, {int? badge}) {
    final active = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? const Color(0xFF1A4A70) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? Colors.white : const Color(0xFFAFC5D5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFFAFC5D5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badge != null)
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: const Color(0xFFF97316),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _backToModes() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => ModeSelectionPage(
          dashboardBuilder: _buildDashboard,
          isArabic: _isArabic,
          autoOpen: false,
        ),
      ),
      (_) => false,
    );
  }

  void _goBack() {
    if (_tab == AppTab.overview) {
      _backToModes();
      return;
    }
    setState(() {
      if (_tab == AppTab.clinicManager && _openClinic != null) {
        _openClinic = null;
      } else {
        _tab = switch (_tab) {
          AppTab.departments || AppTab.waitingLists => AppTab.hospitalManager,
          _ => AppTab.overview,
        };
      }
    });
  }

  Widget _header(bool wide) {
    final back = IconButton(
      tooltip: tr('رجوع', 'Back'),
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back),
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: tr('العودة إلى الأوضاع', 'Back to modes'),
          onPressed: _backToModes,
          icon: const Icon(Icons.home_outlined),
        ),
        AccountButton(isArabic: _isArabic),
        OutlinedButton.icon(
          onPressed: () => setState(() => _isArabic = !_isArabic),
          icon: const Icon(Icons.language, size: 16),
          label: Text(_isArabic ? 'English' : 'العربية'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (!widget.isGuest) ...[
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _role,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(
              fontSize: 12,
              color: teal,
              fontWeight: FontWeight.bold,
            ),
            items: const ['Admin', 'Receptionist', 'Doctor', 'Patient']
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (role) => setState(() => _role = role ?? _role),
          ),
        ],
      ],
    );
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('صباح الخير، د. أحمد', 'Good morning, Dr. Ahmed'),
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          tr('إليك ملخص العمل اليوم', "Here's your work summary today"),
          style: const TextStyle(color: Color(0xFF6B7C93), fontSize: 12),
        ),
      ],
    );
    final horizontal = wide ? 34.0 : 14.0;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        horizontal,
        6 + MediaQuery.paddingOf(context).top,
        horizontal,
        widget.isGuest ? 6 : 12,
      ),
      child: widget.isGuest
          ? Row(children: [back, const Spacer(), controls])
          : wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                back,
                Expanded(child: greeting),
                controls,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [back, const Spacer(), controls]),
                greeting,
              ],
            ),
    );
  }

  Widget _body(bool wide) {
    final content = switch (_tab) {
      AppTab.overview => _overview(wide),
      AppTab.hospitalManager => _hospitalManager(wide),
      AppTab.clinicManager => switch (_openClinic) {
        null => _clinicList(),
        final kind => _clinicManager(kind),
      },
      AppTab.departments => _departmentsManager(wide),
      AppTab.waitingLists => _waitingListsManager(wide),
      AppTab.queue => _queueCard(expanded: true),
      AppTab.appointments => _appointmentsCard(expanded: true),
      AppTab.patients => _patientsCard(),
    };
    return SingleChildScrollView(
      padding: EdgeInsets.all(wide ? 30 : 16),
      child: content,
    );
  }

  Widget _overview(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF071E33), Color(0xFF0D3B5E), Color(0xFF1C8FB0)],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D176E8F),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                PositionedDirectional(
                  top: -60,
                  end: -40,
                  child: _decorCircle(220, 0.08),
                ),
                PositionedDirectional(
                  bottom: -70,
                  start: 40,
                  child: _decorCircle(180, 0.06),
                ),
                PositionedDirectional(
                  bottom: 14,
                  end: 18,
                  child: Icon(
                    Icons.monitor_heart_outlined,
                    size: wide ? 120 : 84,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(wide ? 32 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 13,
                              color: Color(0xFFFFD166),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                tr(
                                  'نظام إدارة الرعاية الصحية',
                                  'HEALTHCARE MANAGEMENT SYSTEM',
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFD6F4FC),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        tr(
                          'مركز التحكم الإداري',
                          'Your management command center',
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: wide ? 32 : 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(
                          'أدر المستشفى والعيادات والإعدادات من مكان واحد.',
                          'Manage hospital operations, clinics, and system settings from one place.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFD6EAF2),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _heroChip(
                            Icons.local_hospital_outlined,
                            tr('المستشفى', 'Hospital'),
                          ),
                          _heroChip(
                            Icons.medical_services_outlined,
                            tr('العيادات', 'Clinics'),
                          ),
                          _heroChip(
                            Icons.calculate_outlined,
                            tr('المعادلات الطبية', 'Medical formulas'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tr('مساحات الإدارة', 'Management workspaces'),
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('اختر المساحة التي ترغب في إدارتها', 'Choose an area to manage'),
          style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (_canHospital)
              SizedBox(
                width: wide ? 280 : double.infinity,
                child: _managerCard(
                  title: 'Hospitals Manager',
                  arabicTitle: 'إدارة المستشفيات',
                  arabicDescription:
                      'الأقسام، الأسرة، الأطباء والعمليات اليومية',
                  description:
                      'Departments, beds, doctors, and daily operations',
                  icon: Icons.local_hospital_outlined,
                  colors: const [Color(0xFF2463C5), Color(0xFF1C4F9B)],
                  onTap: () => setState(() => _tab = AppTab.hospitalManager),
                ),
              ),
            if (_canClinics)
              SizedBox(
                width: wide ? 280 : double.infinity,
                child: _managerCard(
                  title: 'Clinic Manager',
                  arabicTitle: 'إدارة العيادات',
                  arabicDescription:
                      'المواعيد، قوائم الانتظار وسير عمل العيادات',
                  description:
                      'Appointments, waiting lists, and clinic workflow',
                  icon: Icons.medical_services_outlined,
                  colors: const [Color(0xFF008C8A), Color(0xFF006A75)],
                  onTap: () => setState(() {
                    _openClinic = null;
                    _tab = AppTab.clinicManager;
                  }),
                ),
              ),
            SizedBox(
              width: wide ? 280 : double.infinity,
              child: _managerCard(
                title: 'Medical Parameters',
                arabicTitle: 'المعايير الطبية',
                arabicDescription: 'المعادلات الطبية، اللغة وإعدادات النظام',
                description:
                    'Medical formulas, language, and system preferences',
                icon: Icons.tune_outlined,
                colors: const [Color(0xFF7A4CB3), Color(0xFF513086)],
                onTap: _showParameters,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hospitalManager(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _tab = AppTab.overview),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(tr('العودة إلى مركز التحكم', 'Back to command center')),
          style: TextButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            foregroundColor: teal,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: EdgeInsets.all(wide ? 28 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5FC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF2463C5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hospital Manager',
                      style: TextStyle(
                        color: Color(0xFF172B4D),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        'إدارة العمليات والخدمات المركزية للمستشفى',
                        'Manage hospital-wide operations and central services',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF58708A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          tr('خدمات المستشفى', 'Hospital services'),
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('اختر الخدمة التي ترغب في إدارتها', 'Choose a service to manage'),
          style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (_canSurgeryDepartments)
              SizedBox(
                width: wide ? 310 : double.infinity,
                child: _managerCard(
                  title: 'Departments Management',
                  arabicTitle: 'إدارة الأقسام',
                  arabicDescription:
                      'إدارة أقسام المستشفى والوصول إلى صفحات الأقسام',
                  description:
                      'Manage hospital departments and open their workspaces',
                  icon: Icons.apartment_outlined,
                  colors: const [Color(0xFF1E6FD9), Color(0xFF22A38A)],
                  onTap: () => setState(() => _tab = AppTab.departments),
                ),
              ),
            if (_canWaitingLists)
              SizedBox(
                width: wide ? 310 : double.infinity,
                child: _managerCard(
                  title: 'Waiting Lists',
                  arabicTitle: 'قوائم الانتظار',
                  arabicDescription:
                      'راقب أدوار المرضى وحالة الخدمة في جميع العيادات',
                  description:
                      'Monitor patient queues and service status across all clinics',
                  icon: Icons.format_list_numbered_rounded,
                  colors: const [Color(0xFFE87920), Color(0xFFC64F12)],
                  onTap: () => setState(() => _tab = AppTab.waitingLists),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _departmentsManager(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _tab = AppTab.hospitalManager),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(
            tr('العودة إلى إدارة المستشفيات', 'Back to Hospitals Manager'),
          ),
          style: TextButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            foregroundColor: teal,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr('إدارة الأقسام', 'Departments Management'),
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('اختر القسم الذي ترغب في إدارته', 'Choose a department to manage'),
          style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (_can(HospService.generalSurgery))
              SizedBox(
                width: wide ? 310 : double.infinity,
                child: _managerCard(
                  title: 'General Surgery',
                  arabicTitle: 'الجراحة العامة',
                  arabicDescription: 'قائمة انتظار العمليات والمتابعة',
                  description: 'Surgery waiting list and follow-up',
                  icon: Icons.local_hospital_outlined,
                  colors: const [Color(0xFF1E6FD9), Color(0xFF22A38A)],
                  onTap: () => _openSurgeryPage(
                    (_) => PatientFollowUpSheetPage(
                      repository: widget.isGuest
                          ? _demoSurgeryRepository
                          : null,
                    ),
                  ),
                ),
              ),
            if (_can(HospService.oncologySurgery))
              SizedBox(
                width: wide ? 310 : double.infinity,
                child: _managerCard(
                  title: 'Oncology Surgery',
                  arabicTitle: 'جراحة الأورام',
                  arabicDescription: 'تسجيل مرضى جراحة الأورام ومتابعتهم',
                  description:
                      'Register and follow up oncology surgery patients',
                  icon: Icons.healing_outlined,
                  colors: const [Color(0xFF7A4CB3), Color(0xFF513086)],
                  onTap: () => _openSurgeryPage(
                    (_) => OncologySurgeryPage(
                      repository: widget.isGuest
                          ? _demoSurgeryRepository
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _waitingListsManager(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _tab = AppTab.hospitalManager),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(
            tr('العودة إلى إدارة المستشفيات', 'Back to Hospitals Manager'),
          ),
          style: TextButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            foregroundColor: teal,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Waiting Lists',
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('اختر قائمة الانتظار', 'Choose a waiting list'),
          style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          children: [
            if (_can(HospService.pediatricSurgery))
              SizedBox(
                width: wide ? 310 : double.infinity,
                child: _managerCard(
                  title: 'Pediatric Surgery',
                  arabicTitle: 'جراحة الأطفال',
                  arabicDescription: 'قائمة انتظار جراحة الأطفال حسب الطبيب',
                  description: 'Pediatric surgery waiting list by doctor',
                  icon: Icons.child_care_outlined,
                  colors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  onTap: () => _openSurgeryPage(
                    (_) => PediatricSurgeryDoctorsPage(
                      waitingRepository: widget.isGuest
                          ? _demoWaitingRepository
                          : null,
                      doctorsRepository: widget.isGuest
                          ? _demoDoctorsRepository
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_can(HospService.otherWaitingLists) &&
            (widget.isGuest || SurgerySupabaseConfig.isConfigured))
          CustomWaitingListsSection(
            repository: widget.isGuest
                ? _demoListsRepository
                : _listsRepository,
            canManage: widget.isGuest || isCurrentUserAdmin(),
            cardBuilder: _managerCard,
            wide: wide,
          ),
      ],
    );
  }

  final _listsRepository = WaitingListsRepository();
  final _demoListsRepository = DemoWaitingListsRepository();
  final _demoSurgeryRepository = DemoSurgeryPatientRepository();
  final _demoWaitingRepository = DemoPediatricSurgeryWaitingRepository();
  final _demoDoctorsRepository = DemoPediatricSurgeryDoctorsRepository();

  void _openSurgeryPage(WidgetBuilder builder) {
    // Guests get in-memory demo data, so Supabase is not needed.
    if (!widget.isGuest && !SurgerySupabaseConfig.isConfigured) {
      showDialog<void>(
        context: context,
        builder: (context) => Directionality(
          textDirection: _direction,
          child: AlertDialog(
            title: Text(tr('إعداد Supabase مطلوب', 'Supabase setup required')),
            content: Text(
              tr(
                'لا يمكن فتح قسم الجراحة لأن اتصال Supabase غير مهيأ. شغّل التطبيق مع HOSPMASTER_SUPABASE_URL وHOSPMASTER_SUPABASE_PUBLISHABLE_KEY.',
                'The surgery department cannot open because Supabase is not configured. Run the app with HOSPMASTER_SUPABASE_URL and HOSPMASTER_SUPABASE_PUBLISHABLE_KEY.',
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('حسنًا', 'OK')),
              ),
            ],
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: builder));
  }

  Widget _managerCard({
    required String title,
    required String arabicTitle,
    required String arabicDescription,
    required String description,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    const radius = 26.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                PositionedDirectional(
                  top: -40,
                  end: -30,
                  child: _decorCircle(150, 0.10),
                ),
                PositionedDirectional(
                  bottom: -50,
                  start: -40,
                  child: _decorCircle(130, 0.07),
                ),
                PositionedDirectional(
                  top: 14,
                  end: 14,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _rtl ? Icons.arrow_back : Icons.arrow_forward,
                      color: colors.last,
                      size: 17,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(icon, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: 34,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    arabicTitle,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    title,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      color: Color(0xFFD6F4FC),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        arabicDescription,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE9F6FA),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        textDirection: TextDirection.ltr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFBFE3EE),
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD6F4FC)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  void _showParameters() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalFormulasPage(
          isArabic: _isArabic,
          role: _role,
          onLanguageChanged: (value) => setState(() => _isArabic = value),
        ),
      ),
    );
  }

  Widget _cardHeader(String title, String subtitle, {Widget? action}) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF172B4D),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF7B8EA2), fontSize: 11),
            ),
          ],
        ),
      ),
      ...?(action == null ? null : [action]),
    ],
  );

  Future<void> _showAddClinicPatient(ClinicKind kind) async {
    final navigator = Navigator.of(context);
    switch (kind) {
      case ClinicKind.obgyn:
        final patient = await navigator.push<ClinicPatient>(
          MaterialPageRoute(
            builder: (_) => ObgynPatientFormPage(isArabic: _isArabic),
          ),
        );
        if (patient != null && mounted) {
          setState(() => _clinicPatients.insert(0, patient));
        }
      case ClinicKind.pediatrics:
        final patient = await navigator.push<PediatricPatient>(
          MaterialPageRoute(
            builder: (_) => PediatricPatientFormPage(isArabic: _isArabic),
          ),
        );
        if (patient != null && mounted) {
          setState(() => _pediatricPatients.insert(0, patient));
        }
    }
  }

  Widget _clinicList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _tab = AppTab.overview),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(tr('العودة إلى مركز التحكم', 'Back to command center')),
          style: TextButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            foregroundColor: teal,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'إدارة العيادات  ·  Clinic Manager',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('اختر العيادة', 'Choose a clinic'),
          style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (_can(HospService.obgynClinic))
              SizedBox(
                width: MediaQuery.sizeOf(context).width >= 900
                    ? 280
                    : double.infinity,
                child: _managerCard(
                  title: 'Obstetrics & Gynecology Clinic',
                  arabicTitle: 'عيادة النسا والتوليد',
                  arabicDescription: 'إدارة مرضى عيادة النسا والتوليد',
                  description: 'Manage Obstetrics & Gynecology clinic patients',
                  icon: Icons.pregnant_woman_rounded,
                  colors: const [Color(0xFFD6457F), Color(0xFF9B2C62)],
                  onTap: () => setState(() => _openClinic = ClinicKind.obgyn),
                ),
              ),
            if (_can(HospService.pediatricsClinic))
              SizedBox(
                width: MediaQuery.sizeOf(context).width >= 900
                    ? 280
                    : double.infinity,
                child: _managerCard(
                  title: 'Pediatrics Clinic',
                  arabicTitle: 'عيادة الأطفال',
                  arabicDescription:
                      'إدارة مرضى عيادة الأطفال والنمو والتطعيمات',
                  description:
                      'Manage pediatric patients, growth and vaccinations',
                  icon: Icons.child_care_rounded,
                  colors: const [Color(0xFF29A3F0), Color(0xFF0F5FA8)],
                  onTap: () =>
                      setState(() => _openClinic = ClinicKind.pediatrics),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _clinicManager(ClinicKind kind) {
    final obgyn = kind == ClinicKind.obgyn;
    final accent = obgyn ? _obgynRose : _pediatricSky;
    final addButton = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          colors: obgyn
              ? const [Color(0xFF9B2C62), Color(0xFFD6457F)]
              : const [Color(0xFF0F5FA8), Color(0xFF29A3F0)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddClinicPatient(kind),
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'إضافة مريض  ·  Add patient',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _openClinic = null),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(tr('العودة إلى العيادات', 'Back to clinics')),
          style: TextButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            foregroundColor: teal,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          obgyn
              ? 'عيادة النسا والتوليد  ·  Obstetrics & Gynecology'
              : 'عيادة الأطفال  ·  Pediatrics',
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        if ((obgyn ? _clinicPatients.length : _pediatricPatients.length) == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    obgyn
                        ? Icons.pregnant_woman_rounded
                        : Icons.child_care_rounded,
                    size: 48,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 28),
                addButton,
              ],
            ),
          )
        else ...[
          Align(alignment: AlignmentDirectional.centerStart, child: addButton),
          const SizedBox(height: 16),
          if (obgyn)
            for (final patient in _clinicPatients)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EEF4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _obgynRose.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_outline,
                        color: _obgynRose,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              color: Color(0xFF263E59),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            [
                              if (patient.age.isNotEmpty)
                                '${tr('العمر', 'Age')}: ${patient.age}',
                              if (patient.phone.isNotEmpty) patient.phone,
                              if (patient.bloodGroup.isNotEmpty)
                                patient.bloodGroup,
                            ].join(' · '),
                            style: const TextStyle(
                              color: Color(0xFF8495A8),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              patient.visitType,
                              'G${patient.gravida} P${patient.para} A${patient.abortions}',
                              if (patient.gestationalAge() case final ga?)
                                '${ga.$1}w+${ga.$2}d',
                              if (patient.edd case final edd?)
                                'EDD ${edd.day}/${edd.month}/${edd.year}',
                            ].join(' · '),
                            style: const TextStyle(
                              color: Color(0xFFB03A73),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          if (!obgyn)
            for (final child in _pediatricPatients) _pediatricTile(child),
        ],
      ],
    );
  }

  Widget _pediatricTile(PediatricPatient child) {
    final color = child.isBoy ? _pediatricSky : const Color(0xFFEC5B9A);
    final age = child.age();
    final ageText = age == null
        ? ''
        : age.$1 > 0
        ? tr('${age.$1} سنة و ${age.$2} شهر', '${age.$1}y ${age.$2}m')
        : age.$2 > 0
        ? tr('${age.$2} شهر', '${age.$2}m')
        : tr('${age.$3} يوم', '${age.$3}d');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(
              child.isBoy ? Icons.boy_rounded : Icons.girl_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    color: Color(0xFF263E59),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  [
                    if (ageText.isNotEmpty) ageText,
                    if (child.guardian.isNotEmpty) child.guardian,
                    if (child.phone.isNotEmpty) child.phone,
                  ].join(' · '),
                  style: const TextStyle(
                    color: Color(0xFF8495A8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (child.weight.isNotEmpty) '${child.weight} kg',
                    if (child.height.isNotEmpty) '${child.height} cm',
                    if (child.bmi case final bmi?)
                      'BMI ${bmi.toStringAsFixed(1)}',
                    ...child.reasons,
                  ].join(' · '),
                  style: const TextStyle(
                    color: Color(0xFF0F5FA8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueCard({bool expanded = false}) {
    final visible = expanded ? _queue : _queue.take(4);
    return _panel(
      Column(
        children: [
          _cardHeader(
            tr('قائمة الانتظار المباشرة', 'Live waiting list'),
            tr('تحديثات فورية للعيادات', 'Real-time clinic updates'),
            action: FilledButton.icon(
              onPressed: _callNext,
              icon: const Icon(Icons.campaign_outlined, size: 16),
              label: Text(tr('استدعاء التالي', 'Call next')),
            ),
          ),
          const SizedBox(height: 15),
          for (final entry in visible) _queueRow(entry),
        ],
      ),
    );
  }

  Widget _queueRow(QueueEntry entry) {
    final status = switch (entry.status) {
      QueueStatus.serving => (
        tr('يتم خدمته', 'Serving'),
        const Color(0xFFDCF6F5),
        const Color(0xFF087B83),
      ),
      QueueStatus.waiting => (
        tr('في الانتظار', 'Waiting'),
        const Color(0xFFFFF3DF),
        const Color(0xFFA55D00),
      ),
      QueueStatus.completed => (
        tr('مكتمل', 'Completed'),
        const Color(0xFFEAF0F5),
        const Color(0xFF5C7083),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEF2F6))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: entry.status == QueueStatus.serving
                ? const Color(0xFFDCF6F5)
                : const Color(0xFFEDF3F8),
            child: Text(
              entry.number.split('-').last,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF405B75),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.patient}${entry.priority ? ' • VIP' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF263E59),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.number} · ${entry.clinic} · ${entry.time}',
                  style: const TextStyle(
                    color: Color(0xFF8495A8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: status.$2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.$1,
              style: TextStyle(
                color: status.$3,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentsCard({bool expanded = false}) {
    const appointments = [
      (
        '09:30',
        'Mariam Hassan',
        'Cardiology · Dr. Ahmed Saleh',
        Color(0xFF2563EB),
      ),
      (
        '09:45',
        'Omar Khaled',
        'Cardiology · Dr. Ahmed Saleh',
        Color(0xFF7C3AED),
      ),
      ('10:00', 'Noura Ali', 'Dermatology · Dr. Mona Fathy', Color(0xFF059669)),
      (
        '10:15',
        'Yousef Adel',
        'Orthopedics · Dr. Karim Samir',
        Color(0xFFEA580C),
      ),
    ];
    return _panel(
      Column(
        children: [
          _cardHeader(
            tr('جدول اليوم', "Today's schedule"),
            'Thursday, 18 October',
            action: FilledButton(
              onPressed: _showNewAppointment,
              child: Text('+ ${tr('موعد', 'Appointment')}'),
            ),
          ),
          const SizedBox(height: 15),
          for (final item in appointments.take(
            expanded ? appointments.length : 3,
          ))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEF2F6))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: Color(0xFF526A84),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.$4,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: Color(0xFF263E59),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: Color(0xFF8495A8),
                            fontSize: 10,
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

  Widget _patientsCard() {
    const patients = [
      ('Mariam Hassan', 'MR-104822', '47', 'Today, 09:20'),
      ('Omar Khaled', 'MR-103910', '34', 'Today, 09:35'),
      ('Noura Ali', 'MR-102715', '29', 'Today, 09:50'),
      ('Yousef Adel', 'MR-101064', '55', 'Today, 10:05'),
    ];
    final results = patients.where(
      (patient) => '${patient.$1} ${patient.$2}'.toLowerCase().contains(
        _search.toLowerCase(),
      ),
    );
    return _panel(
      Column(
        children: [
          _cardHeader(
            tr('آخر المرضى', 'Recent patients'),
            tr('ملفات المرضى', 'Patient records'),
            action: FilledButton(
              onPressed: _showNewAppointment,
              child: Text('+ ${tr('مريض جديد', 'New patient')}'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _search = value),
            textAlign: _rtl ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr(
                'ابحث بالاسم أو رقم الملف',
                'Search name or medical record',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final patient in results)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEF2F6))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE0F3F7),
                    child: Text(
                      patient.$1.split(' ').map((word) => word[0]).join(),
                      style: const TextStyle(
                        color: teal,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.$1,
                          style: const TextStyle(
                            color: Color(0xFF263E59),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${patient.$2} · ${patient.$3} ${tr('سنة', 'years')}',
                          style: const TextStyle(
                            color: Color(0xFF8495A8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    patient.$4,
                    style: const TextStyle(
                      color: Color(0xFF667B91),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8EEF4)),
    ),
    child: child,
  );
}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
