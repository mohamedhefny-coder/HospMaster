import 'dart:convert';
import 'package:hospmaster/auth/account_button.dart';
import 'package:hospmaster/surgery/admin_access.dart';
import 'package:hospmaster/surgery/patient_follow_up_sheet_page.dart';
import 'package:hospmaster/surgery/pediatric_surgery_waiting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SurgeryDepartmentPage extends StatelessWidget {
  const SurgeryDepartmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('قسم الجراحة'),
          actions: const [AccountButton()],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختر القسم المطلوب',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16324F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك الدخول إلى صفحة الجراحة العامة الحالية أو فتح صفحة جراحة الأطفال.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B6B7B),
                  ),
                ),
                const SizedBox(height: 20),
                _DepartmentCard(
                  title: 'قسم الجراحة العامة',
                  subtitle: 'فتح صفحة الجراحة الحالية',
                  icon: Icons.local_hospital_outlined,
                  colors: const [Color(0xFF1E6FD9), Color(0xFF22A38A)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PatientFollowUpSheetPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _DepartmentCard(
                  title: 'جراحة الأطفال',
                  subtitle: 'فتح صفحة فارغة',
                  icon: Icons.child_care_outlined,
                  colors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PediatricSurgeryDoctorsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PediatricDoctor {
  const _PediatricDoctor({
    required this.name,
    required this.colors,
    required this.accent,
  });

  final String name;
  final List<Color> colors;
  final Color accent;
}

const List<_PediatricDoctor> _defaultPediatricSurgeryDoctors = [
  _PediatricDoctor(
    name: 'د. أحمد أبو الحسب',
    colors: [Color(0xFF0F4C81), Color(0xFF14B8A6)],
    accent: Color(0xFF0F766E),
  ),
  _PediatricDoctor(
    name: 'د. حمدي السيد',
    colors: [Color(0xFF5B21B6), Color(0xFFDB2777)],
    accent: Color(0xFF9D174D),
  ),
];

const List<List<Color>> _extraDoctorPalette = [
  [Color(0xFF075985), Color(0xFF06B6D4)],
  [Color(0xFF166534), Color(0xFF22C55E)],
  [Color(0xFF9A3412), Color(0xFFF97316)],
  [Color(0xFF374151), Color(0xFF6366F1)],
];

_PediatricDoctor _pediatricDoctorFor(String name, int index) {
  for (final doctor in _defaultPediatricSurgeryDoctors) {
    if (doctor.name == name) return doctor;
  }
  final colors = _extraDoctorPalette[index % _extraDoctorPalette.length];
  return _PediatricDoctor(name: name, colors: colors, accent: colors.last);
}

class _AddDoctorDialog extends StatefulWidget {
  const _AddDoctorDialog();

  @override
  State<_AddDoctorDialog> createState() => _AddDoctorDialogState();
}

class _AddDoctorDialogState extends State<_AddDoctorDialog> {
  final _titleController = TextEditingController(text: 'د.');
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'يرجى إدخال اسم الطبيب');
      return;
    }
    final title = _titleController.text.trim();
    Navigator.pop(context, title.isEmpty ? name : '$title $name');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة طبيب جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اللقب',
                  hintText: 'مثال: د. / أ.د.',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'اسم الطبيب',
                  hintText: 'مثال: محمد أحمد',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _submit, child: const Text('إضافة البطاقة')),
        ],
      ),
    );
  }
}

class _RenameDoctorDialog extends StatefulWidget {
  const _RenameDoctorDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDoctorDialog> createState() => _RenameDoctorDialogState();
}

class _RenameDoctorDialogState extends State<_RenameDoctorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'يرجى إدخال اسم الطبيب');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تعديل بطاقة الطبيب'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'اسم الطبيب',
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _submit, child: const Text('حفظ')),
        ],
      ),
    );
  }
}

class PediatricSurgeryDoctorsPage extends StatefulWidget {
  const PediatricSurgeryDoctorsPage({
    super.key,
    this.waitingRepository,
    this.doctorsRepository,
    this.title = 'جراحة الأطفال',
    this.customList = false,
  });

  /// Guest mode passes in-memory repositories, so nothing is saved.
  final PediatricSurgeryWaitingRepository? waitingRepository;
  final PediatricSurgeryDoctorsRepository? doctorsRepository;

  final String title;

  /// An admin-created list: its doctors are managed by admins only.
  final bool customList;

  bool get isDemo => waitingRepository is DemoPediatricSurgeryWaitingRepository;

  @override
  State<PediatricSurgeryDoctorsPage> createState() =>
      _PediatricSurgeryDoctorsPageState();
}

class _PediatricSurgeryDoctorsPageState
    extends State<PediatricSurgeryDoctorsPage> {
  late final PediatricSurgeryWaitingRepository _repository =
      widget.waitingRepository ?? PediatricSurgeryWaitingRepository();
  late final PediatricSurgeryDoctorsRepository _doctorsRepository =
      widget.doctorsRepository ?? PediatricSurgeryDoctorsRepository();
  List<PediatricSurgeryWaitingPatient> _patients = const [];
  late List<_PediatricDoctor> _doctors = widget.isDemo || widget.customList
      ? []
      : [..._defaultPediatricSurgeryDoctors];

  bool get _isAdmin => widget.isDemo || isCurrentUserAdmin();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadPatients();
  }

  Future<void> _loadDoctors() async {
    try {
      final names = await _doctorsRepository.fetchDoctorNames();
      if (!mounted) return;
      setState(() {
        _doctors = [
          for (var i = 0; i < names.length; i++)
            _pediatricDoctorFor(names[i], i),
        ];
      });
    } catch (_) {
      // The default doctors stay visible when the list cannot be loaded.
    }
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _repository.fetchPatients();
      if (!mounted) return;
      setState(() => _patients = patients);
    } catch (_) {
      // Counts stay at zero when the list cannot be loaded.
    }
  }

  int _countForStage(String stage) =>
      _patients.where((patient) => patient.workflowStage == stage).length;

  int _countForDoctor(String doctor, String stage) => _patients
      .where(
        (patient) => patient.doctor == doctor && patient.workflowStage == stage,
      )
      .length;

  Future<void> _openDoctor(String doctor) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PediatricSurgeryPage(
          doctor: doctor,
          waitingRepository: widget.isDemo || widget.customList
              ? _repository
              : null,
          title: widget.title,
          customList: widget.customList,
          doctorOptions: _doctors.map((d) => d.name).toList(growable: false),
        ),
      ),
    );
    if (mounted) _loadPatients();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _doctorExists(String name) =>
      _doctors.any((doctor) => doctor.name.toLowerCase() == name.toLowerCase());

  Future<void> _addDoctor() async {
    final normalized = await showDialog<String>(
      context: context,
      builder: (_) => const _AddDoctorDialog(),
    );
    if (normalized == null || normalized.isEmpty) return;
    if (_doctorExists(normalized)) {
      _showMessage('هذا الطبيب مضاف بالفعل');
      return;
    }

    try {
      await _doctorsRepository.addDoctor(normalized);
    } catch (_) {
      _showMessage('تعذر حفظ الطبيب. تأكد من تطبيق تحديث قاعدة البيانات.');
      return;
    }
    await _loadDoctors();
  }

  Future<void> _editDoctor(_PediatricDoctor doctor) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDoctorDialog(initialName: doctor.name),
    );
    if (newName == null || newName == doctor.name) return;
    if (_doctorExists(newName) &&
        newName.toLowerCase() != doctor.name.toLowerCase()) {
      _showMessage('هذا الطبيب مضاف بالفعل');
      return;
    }

    try {
      await _doctorsRepository.renameDoctor(doctor.name, newName);
      await _repository.setDoctorForPatients(
        _patientIdsForDoctor(doctor.name),
        newName,
      );
    } catch (_) {
      _showMessage('تعذر تعديل بطاقة الطبيب. هذه الصلاحية للأدمن فقط.');
    }
    await _loadDoctors();
    await _loadPatients();
  }

  List<String> _patientIdsForDoctor(String doctor) => [
    for (final patient in _patients)
      if (patient.doctor == doctor && patient.id != null) patient.id!,
  ];

  Future<void> _deleteDoctor(_PediatricDoctor doctor) async {
    final doctorPatients = _patients
        .where((patient) => patient.doctor == doctor.name)
        .toList(growable: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف قائمة الطبيب'),
          content: Text(
            doctorPatients.isEmpty
                ? 'هل تريد حذف قائمة ${doctor.name}؟'
                : 'سيتم حذف قائمة ${doctor.name} مع ${doctorPatients.length} '
                      'مريض وصورهم نهائياً. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await _doctorsRepository.deleteDoctor(doctor.name);
      final imagePaths = [
        for (final patient in doctorPatients)
          for (final image in patient.images)
            if (image['path'] is String) image['path'] as String,
      ];
      if (imagePaths.isNotEmpty) await _repository.removeImages(imagePaths);
      await _repository.deletePatients([
        for (final patient in doctorPatients)
          if (patient.id != null) patient.id!,
      ]);
    } catch (_) {
      _showMessage('تعذر حذف القائمة. هذه الصلاحية للأدمن فقط.');
    }
    await _loadDoctors();
    await _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(widget.title),
          actions: const [AccountButton()],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _PediatricHeaderCard(
                title: widget.title,
                waitingCount: _countForStage('waiting'),
                followUpCount: _countForStage('follow_up'),
                admissionCount: _countForStage('admission'),
                showDoctorName: !widget.isDemo && !widget.customList,
              ),
              const SizedBox(height: 12),
              if (widget.isDemo) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'نسخة تجريبية: أي بيانات تضيفها هنا مؤقتة وتُحذف بمجرد خروجك من الموقع. سجّل الدخول كمشترك لحفظ بياناتك.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!widget.customList || _isAdmin)
                FilledButton.icon(
                  onPressed: _addDoctor,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(
                    widget.customList
                        ? 'إضافة طبيب للقائمة'
                        : 'إضافة طبيب جديد وإدارة قائمته',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16324F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              if (widget.customList && _doctors.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا يوجد أطباء في هذه القائمة بعد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              const SizedBox(height: 16),
              for (final doctor in _doctors) ...[
                _ModernDoctorCard(
                  badge: widget.customList
                      ? widget.title
                      : 'استشاري جراحة أطفال',
                  name: doctor.name,
                  colors: doctor.colors,
                  accent: doctor.accent,
                  waitingCount: _countForDoctor(doctor.name, 'waiting'),
                  followUpCount: _countForDoctor(doctor.name, 'follow_up'),
                  admissionCount: _countForDoctor(doctor.name, 'admission'),
                  onTap: () => _openDoctor(doctor.name),
                  onEdit: _isAdmin ? () => _editDoctor(doctor) : null,
                  onDelete: _isAdmin ? () => _deleteDoctor(doctor) : null,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PediatricSurgeryPage extends StatefulWidget {
  const PediatricSurgeryPage({
    super.key,
    this.doctor,
    this.doctorOptions = const [],
    this.waitingRepository,
    this.title = 'جراحة الأطفال',
    this.customList = false,
  });

  final String title;

  /// An admin-created list: the built-in pediatric doctors do not apply.
  final bool customList;

  /// Guest mode passes an in-memory repository, so nothing is saved.
  final PediatricSurgeryWaitingRepository? waitingRepository;

  bool get isDemo => waitingRepository is DemoPediatricSurgeryWaitingRepository;

  /// When set, the page only shows and creates patients for this doctor.
  final String? doctor;

  /// Doctors created from the doctors page, in addition to the built-in ones.
  final List<String> doctorOptions;

  @override
  State<PediatricSurgeryPage> createState() => _PediatricSurgeryPageState();
}

class _PediatricSurgeryPageState extends State<PediatricSurgeryPage>
    with SingleTickerProviderStateMixin {
  static const String _stageWaiting = 'waiting';
  static const String _stageFollowUp = 'follow_up';
  static const String _stageAdmission = 'admission';
  static const String _stageStagedOperations = 'staged_operations';
  static const String _stagePicu = 'picu';
  static const String _stageNicu = 'nicu';
  static const String _stageEmergency = 'emergency';
  final List<String> _diagnosisOptions = [
    'فتق اربي',
    'فتق سري',
    'قيلة مائية',
    'كيس درقي',
    'خصية معلقة',
  ];
  static const List<String> _sideOptions = ['ج.أيمن', 'ج.أيسر', 'الجانبان'];
  static const List<String> _builtInDoctorOptions = [
    'د. أحمد أبو الحسب',
    'د. حمدي السيد',
    'د. عبد الرحمن جمعة',
  ];

  List<String> get _doctorOptions => {
    if (!widget.isDemo && !widget.customList) ..._builtInDoctorOptions,
    ...widget.doctorOptions,
  }.toList(growable: false);

  late final TabController _tabController;
  late final PediatricSurgeryWaitingRepository _waitingRepository =
      widget.waitingRepository ?? PediatricSurgeryWaitingRepository();
  int _currentTabIndex = 0;
  List<_WaitingPatient> _waitingPatients = const [];
  final Map<int, ScrollPosition> _tabScrollPositions = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDoctorFilter;
  String? _selectedDiagnosisFilter;
  bool _isLoadingPatients = true;
  bool _isSavingPatient = false;
  String? _patientsError;

  bool get _isAdmin => widget.isDemo || isCurrentUserAdmin();

  final ValueNotifier<ScrollPosition?> _activeScrollPosition =
      ValueNotifier<ScrollPosition?>(null);

  void _setTabScrollPosition(int tabIndex, ScrollPosition? position) {
    if (!mounted) return;
    if (position == null) {
      if (_tabScrollPositions.remove(tabIndex) == null) return;
    } else {
      if (identical(_tabScrollPositions[tabIndex], position)) return;
      _tabScrollPositions[tabIndex] = position;
    }

    _activeScrollPosition.value = _tabScrollPositions[_currentTabIndex];
  }

  bool _matchesSearchFilters(
    _WaitingPatient patient, {
    String additionalSearchText = '',
  }) {
    if (widget.doctor != null && patient.doctor != widget.doctor) {
      return false;
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty &&
        !'${patient.name} ${patient.phone} ${patient.diagnosis} '
                '${patient.doctor} ${patient.date} $additionalSearchText'
            .toLowerCase()
            .contains(query)) {
      return false;
    }

    if (_selectedDoctorFilter != null &&
        patient.doctor != _selectedDoctorFilter) {
      return false;
    }

    final diagnosisFilter = _selectedDiagnosisFilter?.toLowerCase();
    if (diagnosisFilter != null &&
        !patient.diagnosis.toLowerCase().contains(diagnosisFilter)) {
      return false;
    }

    return true;
  }

  List<_WaitingPatient> _patientsForStage(String stage) {
    return _waitingPatients
        .where((patient) => patient.workflowStage == stage)
        .where(_matchesSearchFilters)
        .toList(growable: false);
  }

  List<_WaitingPatient> get _waitingStagePatients =>
      _patientsForStage(_stageWaiting);
  List<_WaitingPatient> get _followUpStagePatients =>
      _patientsForStage(_stageFollowUp);
  List<_WaitingPatient> get _admissionStagePatients =>
      _patientsForStage(_stageAdmission);
  List<_WaitingPatient> get _stagedOperationsStagePatients =>
      _patientsForStage(_stageStagedOperations);
  List<_WaitingPatient> get _picuStagePatients => _patientsForStage(_stagePicu);
  List<_WaitingPatient> get _nicuStagePatients => _patientsForStage(_stageNicu);
  List<_WaitingPatient> get _emergencyStagePatients =>
      _patientsForStage(_stageEmergency);

  String get _newPatientWorkflowStage => switch (_currentTabIndex) {
    5 => _stagePicu,
    6 => _stageNicu,
    7 => _stageEmergency,
    _ => _stageWaiting,
  };

  bool get _canAddPatientFromCurrentTab =>
      _currentTabIndex == 0 ||
      _currentTabIndex == 5 ||
      _currentTabIndex == 6 ||
      _currentTabIndex == 7;

  List<Color> _tabGradientForIndex(int index) => switch (index) {
    0 => const [Color(0xFFD8F5E8), Color(0xFFB5E8D1)],
    1 => const [Color(0xFFD8F4F4), Color(0xFFB5E4E7)],
    2 => const [Color(0xFFFFE9C7), Color(0xFFFFD49A)],
    3 => const [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
    4 => const [Color(0xFFD5F2EF), Color(0xFFB2E3DC)],
    5 => const [Color(0xFFDDEAFF), Color(0xFFBBD1FA)],
    6 => const [Color(0xFFFFE4ED), Color(0xFFF5C2D5)],
    7 => const [Color(0xFFFFE2DB), Color(0xFFF9C1B5)],
    _ => const [Color(0xFFE8EEF1), Color(0xFFD2DCE1)],
  };

  Map<String, List<_WaitingPatient>> get _operationPatientsByDate {
    final grouped = <String, List<_WaitingPatient>>{};
    for (final patient in _waitingPatients) {
      final operationDate = patient.operationListDate;
      if (operationDate == null || operationDate.isEmpty) continue;
      if (!_matchesSearchFilters(
        patient,
        additionalSearchText: operationDate,
      )) {
        continue;
      }
      grouped.putIfAbsent(operationDate, () => []).add(patient);
    }
    final dates = grouped.keys.toList()..sort();
    return {
      for (final date in dates) date: _sortPatientsByDate(grouped[date]!),
    };
  }

  List<String> get _searchKeywords =>
      {..._doctorOptions, ..._diagnosisOptions}.toList(growable: false);

  @override
  void initState() {
    super.initState();
    _loadWaitingPatients();
    _tabController = TabController(length: 8, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        if (_currentTabIndex == _tabController.index) return;
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _activeScrollPosition.value = _tabScrollPositions[_currentTabIndex];
      });
  }

  @override
  void dispose() {
    _activeScrollPosition.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showPatientSearchDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateQuery(String value) {
              _searchController.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
              setState(() {
                _searchQuery = value;
              });
              setDialogState(() {});
            }

            void updateDoctorFilter(String? value) {
              setState(() => _selectedDoctorFilter = value);
              setDialogState(() {});
            }

            void updateDiagnosisFilter(String? value) {
              setState(() => _selectedDiagnosisFilter = value);
              setDialogState(() {});
            }

            void clearFilters() {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedDoctorFilter = null;
                _selectedDiagnosisFilter = null;
              });
              setDialogState(() {});
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: const Color(0xFFFCFEFF),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              title: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF087E8B), Color(0xFF138A69)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.manage_search_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بحث وتصفية المرضى',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'اكتب كلمة أو اختر الطبيب والتشخيص',
                            style: TextStyle(
                              color: Color(0xFFE6FFFA),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: updateQuery,
                        decoration: InputDecoration(
                          hintText: 'اسم المريض أو الطبيب أو التشخيص',
                          prefixIcon: const Icon(Icons.manage_search_rounded),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'مسح البحث',
                                  onPressed: () => updateQuery(''),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: const Color(0xFFF2F7F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9E7E9),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9E7E9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  widget.doctor ?? _selectedDoctorFilter,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'الطبيب',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E7E9),
                                  ),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  child: Text('كل الأطباء'),
                                ),
                                for (final doctor in _doctorOptions)
                                  DropdownMenuItem<String>(
                                    value: doctor,
                                    child: Text(
                                      doctor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: widget.doctor == null
                                  ? updateDoctorFilter
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedDiagnosisFilter,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'التشخيص',
                                prefixIcon: const Icon(
                                  Icons.medical_information_outlined,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E7E9),
                                  ),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  child: Text('كل التشخيصات'),
                                ),
                                for (final diagnosis in _diagnosisOptions)
                                  DropdownMenuItem<String>(
                                    value: diagnosis,
                                    child: Text(
                                      diagnosis,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: updateDiagnosisFilter,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'بحث سريع',
                        style: TextStyle(
                          color: Color(0xFF16324F),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _searchKeywords
                            .map(
                              (keyword) => ActionChip(
                                label: Text(keyword),
                                avatar: Icon(
                                  _doctorOptions.contains(keyword)
                                      ? Icons.person_pin_outlined
                                      : Icons.medical_information_outlined,
                                  size: 17,
                                ),
                                onPressed: () {
                                  updateQuery(keyword);
                                  Navigator.of(dialogContext).pop();
                                },
                                backgroundColor: const Color(0xFFEAF3FA),
                                side: const BorderSide(
                                  color: Color(0xFFD7E5F2),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: clearFilters,
                  child: const Text('مسح الكل'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('تم'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF087E8B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportPatientsToExcel() async {
    final patients = switch (_currentTabIndex) {
      0 => _waitingStagePatients,
      1 => _followUpStagePatients,
      2 => _admissionStagePatients,
      3 => _stagedOperationsStagePatients,
      _ => const <_WaitingPatient>[],
    };
    if (patients.isEmpty) return;

    final rows = <List<String>>[
      [
        'اسم المريض',
        'رقم الهاتف',
        'العمر',
        'التشخيص',
        'الجهة',
        'الطبيب المعالج',
        'التاريخ',
        'الأولوية',
        'المرحلة',
        'ملاحظات هامة',
      ],
      ...patients.map(
        (patient) => [
          patient.name,
          patient.phone,
          patient.currentAge,
          patient.diagnosis,
          _sideFromDiagnosis(patient.diagnosis),
          patient.doctor,
          patient.date,
          patient.priority,
          _stageLabelForExport(patient.workflowStage),
          patient.notes,
        ],
      ),
    ];

    String escapeCsv(String value) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    final csv = rows.map((row) => row.map(escapeCsv).join(',')).join('\r\n');
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: 'pediatric_waiting_patients.csv',
            mimeType: 'text/csv',
          ),
        ],
        text: 'بيانات مرضى قائمة الانتظار',
      ),
    );
  }

  String _sideFromDiagnosis(String diagnosis) {
    final separator = diagnosis.lastIndexOf(' - ');
    return separator == -1 ? '' : diagnosis.substring(separator + 3).trim();
  }

  String _stageLabelForExport(String stage) {
    switch (stage) {
      case _stageFollowUp:
        return 'المتابعة';
      case _stageAdmission:
        return 'الحجز';
      case _stageStagedOperations:
        return 'العمليات المرحلية';
      case _stagePicu:
        return 'PICU';
      case _stageNicu:
        return 'NICU';
      case _stageEmergency:
        return 'Emergency';
      case _stageWaiting:
      default:
        return 'الانتظار';
    }
  }

  Future<void> _loadWaitingPatients() async {
    setState(() {
      _isLoadingPatients = true;
      _patientsError = null;
    });

    try {
      final patients = await _waitingRepository.fetchPatients();
      if (!mounted) return;

      setState(() {
        _waitingPatients = _sortPatientsByDate(
          patients.map(_WaitingPatient.fromRepository).toList(),
        );
        _isLoadingPatients = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _patientsError = 'تعذر تحميل قائمة الانتظار من Supabase\n$error';
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> _showAddPatientDialog([_WaitingPatient? initialPatient]) async {
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final isEditing = initialPatient != null;
    final canChangeDate = _isAdmin || !isEditing;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final yearsController = TextEditingController();
    final monthsController = TextEditingController();
    final daysController = TextEditingController();
    final dateController = TextEditingController();
    final customDiagnosisController = TextEditingController();
    final customDiagnosisFocusNode = FocusNode();
    final notesController = TextEditingController();
    final patientImages = List<_PatientImageAttachment>.from(
      initialPatient?.images ?? const [],
    );
    final ageParts = _parseAgeParts(initialPatient?.age ?? '');
    final diagnosisParts = _parseDiagnosisParts(
      initialPatient?.diagnosis ?? '',
    );
    for (final patient in _waitingPatients) {
      for (final diagnosisName in _parseDiagnosisParts(patient.diagnosis).$1) {
        if (!_diagnosisOptions.contains(diagnosisName)) {
          _diagnosisOptions.add(diagnosisName);
        }
      }
    }
    for (final diagnosisName in diagnosisParts.$1) {
      if (!_diagnosisOptions.contains(diagnosisName)) {
        _diagnosisOptions.add(diagnosisName);
      }
    }
    final selectedDiagnoses = List<String>.from(diagnosisParts.$1);
    String? selectedSide = diagnosisParts.$2;
    String? selectedDoctor = _doctorOptions.contains(initialPatient?.doctor)
        ? initialPatient?.doctor
        : widget.doctor ??
              _suggestedDoctorForDate(
                initialPatient?.date ?? _formatDate(DateTime.now()),
              );
    bool isSubmitting = false;
    String? ageError;
    String? diagnosisError;
    final scrollController = ScrollController();
    final basicKey = GlobalKey();
    final ageKey = GlobalKey();
    final diagnosisKey = GlobalKey();
    final thumbnailFutures = <String, Future<Widget>>{};

    nameController.text = initialPatient?.name ?? '';
    phoneController.text = initialPatient?.phone ?? '';
    yearsController.text = ageParts.$1;
    monthsController.text = ageParts.$2;
    daysController.text = ageParts.$3;
    dateController.text = initialPatient?.date ?? _formatDate(DateTime.now());
    notesController.text = initialPatient?.notes ?? '';

    final result = await showDialog<_WaitingPatient>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDate() async {
              if (!canChangeDate) return;

              final pickedDate = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.tryParse(dateController.text) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (pickedDate == null || !dialogContext.mounted) return;

              setDialogState(() {
                dateController.text = _formatDate(pickedDate);
                if (!isEditing) {
                  selectedDoctor =
                      widget.doctor ??
                      _suggestedDoctorForDate(dateController.text);
                }
              });
            }

            void addCustomDiagnosis() {
              final newDiagnosis = customDiagnosisController.text.trim();
              if (newDiagnosis.isEmpty) return;
              setDialogState(() {
                if (!_diagnosisOptions.contains(newDiagnosis)) {
                  _diagnosisOptions.add(newDiagnosis);
                }
                if (!selectedDiagnoses.contains(newDiagnosis)) {
                  selectedDiagnoses.add(newDiagnosis);
                }
                diagnosisError = null;
                customDiagnosisController.clear();
              });
            }

            Future<void> selectPatientImages() async {
              final pickedImages = await ImagePicker().pickMultiImage(
                imageQuality: 85,
                maxWidth: 2048,
                maxHeight: 2048,
              );
              if (pickedImages.isEmpty || !dialogContext.mounted) return;

              setDialogState(() {
                patientImages.addAll(
                  pickedImages.map(
                    (image) => _PatientImageAttachment(
                      uploadDate: _formatDate(DateTime.now()),
                      localFile: image,
                    ),
                  ),
                );
              });
            }

            Future<void> selectPatientImageDate(int index) async {
              final image = patientImages[index];
              final pickedDate = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.tryParse(image.uploadDate) ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (pickedDate == null || !dialogContext.mounted) return;

              setDialogState(() {
                patientImages[index] = image.copyWith(
                  uploadDate: _formatDate(pickedDate),
                );
              });
            }

            Future<void> previewAttachment(
              _PatientImageAttachment attachment,
            ) async {
              try {
                final Widget page;
                final localFile = attachment.localFile;
                if (localFile != null) {
                  page = Image.memory(
                    await localFile.readAsBytes(),
                    fit: BoxFit.contain,
                  );
                } else {
                  page = await _storedImagePage(attachment.path!);
                }
                if (!dialogContext.mounted) return;
                await showDialog<void>(
                  context: dialogContext,
                  builder: (_) => _ImageViewerDialog(
                    title: 'صورة المريض',
                    pages: [page],
                    captions: ['تاريخ الرفع: ${attachment.uploadDate}'],
                  ),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('تعذر فتح الصورة: $error')),
                );
              }
            }

            void scrollTo(GlobalKey key) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final target = key.currentContext;
                if (target == null) return;
                Scrollable.ensureVisible(
                  target,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: 0.05,
                );
              });
            }

            void closeDialog([_WaitingPatient? value]) {
              FocusManager.instance.primaryFocus?.unfocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(value);
                }
              });
            }

            void submit() {
              if (isSubmitting) return;
              final formOk = formKey.currentState!.validate();
              final ageText = _formatAge(
                years: yearsController.text,
                months: monthsController.text,
                days: daysController.text,
              );
              setDialogState(() {
                ageError = ageText == null
                    ? 'املأ سنة أو شهر أو يوم على الأقل'
                    : null;
                diagnosisError = selectedDiagnoses.isEmpty
                    ? 'اختر تشخيصًا واحدًا على الأقل'
                    : null;
              });

              if (!formOk) {
                scrollTo(basicKey);
                return;
              }
              if (ageText == null) {
                scrollTo(ageKey);
                return;
              }
              if (selectedDiagnoses.isEmpty) {
                scrollTo(diagnosisKey);
                return;
              }

              final diagnosisJoined = selectedDiagnoses.join('، ');
              final side = selectedSide?.trim();
              final diagnosisFieldValue = (side != null && side.isNotEmpty)
                  ? '$diagnosisJoined - $side'
                  : diagnosisJoined;

              setDialogState(() => isSubmitting = true);
              closeDialog(
                _WaitingPatient(
                  id: initialPatient?.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  age: ageText,
                  diagnosis: diagnosisFieldValue,
                  notes: notesController.text.trim(),
                  doctor: selectedDoctor ?? _doctorOptions.first,
                  date: dateController.text.trim(),
                  priority: initialPatient?.priority ?? 'جديد',
                  workflowStage:
                      initialPatient?.workflowStage ?? _newPatientWorkflowStage,
                  images: List<_PatientImageAttachment>.from(patientImages),
                  operationListDate: initialPatient?.operationListDate,
                  callStatus: initialPatient?.callStatus ?? '',
                  opDetails: initialPatient?.opDetails ?? const [],
                  hasOpDetailsColumn:
                      initialPatient?.hasOpDetailsColumn ?? false,
                ),
              );
            }

            const teal = Color(0xFF087E8B);
            final size = MediaQuery.sizeOf(context);
            final compact = size.width < 640;
            final ageSummary = _formatAge(
              years: yearsController.text,
              months: monthsController.text,
              days: daysController.text,
            );
            final doneCount = [
              nameController.text.trim().isNotEmpty,
              ageSummary != null,
              selectedDiagnoses.isNotEmpty,
            ].where((done) => done).length;
            final doctors = _doctorOptions;

            Widget errorText(String? text) => text == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                      ),
                    ),
                  );

            Widget ageField(
              TextEditingController controller,
              String label,
              int max,
            ) {
              return Expanded(
                child: TextFormField(
                  controller: controller,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(max),
                  ],
                  decoration: InputDecoration(labelText: label, isDense: true),
                  onChanged: (_) => setDialogState(() => ageError = null),
                ),
              );
            }

            Widget imageTile(int index) {
              final attachment = patientImages[index];
              final cacheKey = attachment.localFile?.path ?? attachment.path!;
              final thumbnail = thumbnailFutures.putIfAbsent(
                cacheKey,
                () async {
                  final local = attachment.localFile;
                  if (local != null) {
                    return Image.memory(
                      await local.readAsBytes(),
                      fit: BoxFit.cover,
                    );
                  }
                  final bytes = await _waitingRepository.memoryImage(
                    attachment.path!,
                  );
                  if (bytes != null) {
                    return Image.memory(bytes, fit: BoxFit.cover);
                  }
                  return Image.network(
                    await _waitingRepository.imageUrl(attachment.path!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  );
                },
              );
              return SizedBox(
                width: 96,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => previewAttachment(attachment),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: FutureBuilder<Widget>(
                                future: thumbnail,
                                builder: (context, snapshot) =>
                                    snapshot.data ??
                                    const ColoredBox(
                                      color: Color(0xFFE2E8F0),
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          top: 2,
                          end: 2,
                          child: InkWell(
                            onTap: () => setDialogState(
                              () => patientImages.removeAt(index),
                            ),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Color(0xCC0F172A),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                      ),
                      onPressed: () => selectPatientImageDate(index),
                      child: Text(
                        attachment.uploadDate,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }

            final header = Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF087E8B), Color(0xFF25A77F)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'تعديل بيانات المريض' : 'مريض جديد',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'المطلوب: $doneCount/3',
                          style: const TextStyle(
                            color: Color(0xFFE5F7F4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: isSubmitting ? null : () => closeDialog(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            );

            final form = Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  fillColor: Color(0xFFF8FBFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: Color(0xFFC9DDE2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: Color(0xFFC9DDE2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: teal, width: 1.5),
                  ),
                ),
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    Column(
                      key: basicKey,
                      children: [
                        TextFormField(
                          controller: nameController,
                          autofocus: !isEditing,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'name',
                            prefixIcon: Icon(Icons.person_outline),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'أدخل اسم المريض';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: phoneController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '11 رقمًا',
                            isDense: true,
                          ),
                          validator: _validatePhoneNumbers,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      key: ageKey,
                      children: [
                        Row(
                          children: [
                            ageField(yearsController, 'yrs', 2),
                            const SizedBox(width: 8),
                            ageField(monthsController, 'mth', 2),
                            const SizedBox(width: 8),
                            ageField(daysController, 'days', 3),
                          ],
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: errorText(ageError),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      key: diagnosisKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'اختر التشخيص',
                            prefixIcon: Icon(
                              Icons.medical_information_outlined,
                            ),
                            isDense: true,
                          ),
                          items: _diagnosisOptions
                              .map(
                                (diagnosis) => DropdownMenuItem<String>(
                                  value: diagnosis,
                                  child: Text(
                                    diagnosis,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              if (!selectedDiagnoses.contains(value)) {
                                selectedDiagnoses.add(value);
                              }
                              diagnosisError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) =>
                              RawAutocomplete<String>(
                                textEditingController:
                                    customDiagnosisController,
                                focusNode: customDiagnosisFocusNode,
                                optionsBuilder: (value) {
                                  final query = value.text.trim().toLowerCase();
                                  if (query.isEmpty) {
                                    return const Iterable<String>.empty();
                                  }
                                  return _diagnosisOptions.where(
                                    (diagnosis) =>
                                        !selectedDiagnoses.contains(
                                          diagnosis,
                                        ) &&
                                        diagnosis.toLowerCase().contains(query),
                                  );
                                },
                                onSelected: (diagnosis) {
                                  setDialogState(() {
                                    if (!selectedDiagnoses.contains(
                                      diagnosis,
                                    )) {
                                      selectedDiagnoses.add(diagnosis);
                                    }
                                    diagnosisError = null;
                                    customDiagnosisController.clear();
                                  });
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      textController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) => TextFormField(
                                      controller: textController,
                                      focusNode: focusNode,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) =>
                                          addCustomDiagnosis(),
                                      decoration: InputDecoration(
                                        labelText:
                                            'تشخيص جديد (اكتب لعرض الاقتراحات)',
                                        prefixIcon: const Icon(
                                          Icons.edit_note_outlined,
                                        ),
                                        isDense: true,
                                        suffixIcon: IconButton(
                                          tooltip: 'إضافة التشخيص',
                                          onPressed: addCustomDiagnosis,
                                          icon: const Icon(Icons.add_rounded),
                                        ),
                                      ),
                                    ),
                                optionsViewBuilder:
                                    (context, onSelected, options) => Align(
                                      alignment: AlignmentDirectional.topStart,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(12),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: 200,
                                            maxWidth: constraints.maxWidth,
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (context, index) {
                                              final option = options.elementAt(
                                                index,
                                              );
                                              return ListTile(
                                                dense: true,
                                                title: Text(option),
                                                onTap: () => onSelected(option),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                        ),
                        if (selectedDiagnoses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final diagnosis in selectedDiagnoses)
                                InputChip(
                                  label: Text(diagnosis),
                                  visualDensity: VisualDensity.compact,
                                  onDeleted: () => setDialogState(
                                    () => selectedDiagnoses.remove(diagnosis),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        errorText(diagnosisError),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: doctors.contains(selectedDoctor)
                                ? selectedDoctor
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Doctor',
                              prefixIcon: Icon(Icons.person_pin_outlined),
                              isDense: true,
                            ),
                            items: [
                              for (final doctor in doctors)
                                DropdownMenuItem<String>(
                                  value: doctor,
                                  child: Text(
                                    doctor,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => selectedDoctor = value),
                            validator: (value) => value == null || value.isEmpty
                                ? 'اختر الطبيب المعالج'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSide,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'side (اختياري)',
                              prefixIcon: const Icon(Icons.swap_horiz_rounded),
                              isDense: true,
                              suffixIcon: selectedSide == null
                                  ? null
                                  : IconButton(
                                      tooltip: 'مسح الاختيار',
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () => setDialogState(
                                        () => selectedSide = null,
                                      ),
                                    ),
                            ),
                            items: [
                              for (final side in _sideOptions)
                                DropdownMenuItem<String>(
                                  value: side,
                                  child: Text(side),
                                ),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => selectedSide = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      onTap: canChangeDate ? selectDate : null,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        suffixIcon: canChangeDate
                            ? TextButton(
                                onPressed: () => setDialogState(() {
                                  dateController.text = _formatDate(
                                    DateTime.now(),
                                  );
                                }),
                                child: const Text('اليوم'),
                              )
                            : const Icon(Icons.lock_outline),
                        isDense: true,
                        helperText: canChangeDate
                            ? null
                            : 'لا يمكن تغيير التاريخ إلا للأدمن',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اختر التاريخ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات هامة (اختياري)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        isDense: true,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'صور المريض',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: selectPatientImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('إضافة صور'),
                        ),
                      ],
                    ),
                    if (patientImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < patientImages.length; i++)
                            imageTile(i),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );

            final footer = Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFD9E7EB))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: isSubmitting ? null : () => closeDialog(),
                    child: const Text('إلغاء'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isSubmitting ? null : submit,
                    icon: Icon(
                      isEditing ? Icons.save_outlined : Icons.check_rounded,
                    ),
                    label: Text(isEditing ? 'حفظ التعديل' : 'إضافة المريض'),
                  ),
                ],
              ),
            );

            final content = Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: const Color(0xFFF4F8FA),
                resizeToAvoidBottomInset: true,
                body: Column(
                  children: [
                    header,
                    LinearProgressIndicator(
                      value: doneCount / 3,
                      minHeight: 3,
                      backgroundColor: const Color(0xFFD9E7EB),
                      color: const Color(0xFF25A77F),
                    ),
                    Expanded(child: form),
                    footer,
                  ],
                ),
              ),
            );

            if (compact) {
              return Dialog.fullscreen(child: content);
            }
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SizedBox(
                width: 680,
                height: size.height * 0.9,
                child: content,
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    yearsController.dispose();
    monthsController.dispose();
    daysController.dispose();
    customDiagnosisController.dispose();
    customDiagnosisFocusNode.dispose();
    notesController.dispose();
    dateController.dispose();
    scrollController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      _isSavingPatient = true;
    });

    final uploadedPaths = <String>[];
    try {
      final savedImages = <_PatientImageAttachment>[];
      for (final image in result.images) {
        if (image.localFile == null) {
          savedImages.add(image);
          continue;
        }
        final uploadedPath = await _uploadPatientImage(image.localFile!);
        uploadedPaths.add(uploadedPath);
        savedImages.add(
          image.copyWith(path: uploadedPath, clearLocalFile: true),
        );
      }

      final patientWithImages = result.copyWith(images: savedImages);
      final savedPatient = isEditing
          ? await _waitingRepository.updatePatient(
              patientWithImages.toRepositoryModel(),
            )
          : await _waitingRepository.addPatient(
              patientWithImages.toRepositoryModel(),
            );

      final retainedPaths = savedImages
          .map((image) => image.path)
          .whereType<String>()
          .toSet();
      final removedPaths = (initialPatient?.images ?? const [])
          .map((image) => image.path)
          .whereType<String>()
          .where((path) => !retainedPaths.contains(path))
          .toList();
      if (removedPaths.isNotEmpty) {
        await _waitingRepository.removeImages(removedPaths);
      }

      if (!mounted) return;

      setState(() {
        _upsertLocalPatient(_WaitingPatient.fromRepository(savedPatient));
        _isSavingPatient = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'تم تحديث بيانات المريض'
                : widget.isDemo
                ? 'تمت الإضافة تجريبياً (تُحذف عند الخروج)'
                : 'تم حفظ المريض في Supabase',
          ),
        ),
      );
    } catch (error) {
      await _waitingRepository.removeImages(uploadedPaths);
      if (!mounted) return;

      setState(() {
        _isSavingPatient = false;
      });

      messenger.showSnackBar(SnackBar(content: Text('فشل حفظ المريض: $error')));
    }
  }

  Future<String> _uploadPatientImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      throw Exception('حجم الصورة يتجاوز الحد المسموح (10 ميجابايت)');
    }

    final extension = image.name.split('.').last.toLowerCase();
    final contentType =
        image.mimeType ??
        switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'heic' => 'image/heic',
          _ => 'image/jpeg',
        };
    return _waitingRepository.uploadImage(bytes, image.name, contentType);
  }

  Future<Widget> _storedImagePage(String path) async {
    final bytes = await _waitingRepository.memoryImage(path);
    if (bytes != null) return Image.memory(bytes, fit: BoxFit.contain);
    return _NetworkZoomImage(url: await _waitingRepository.imageUrl(path));
  }

  Future<void> _showPatientImages(_WaitingPatient patient) async {
    try {
      final imagePages = await Future.wait(
        patient.images.map((image) => _storedImagePage(image.path!)),
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => _ImageViewerDialog(
          title: 'صور ${patient.name}',
          pages: imagePages,
          captions: [
            for (final image in patient.images)
              'تاريخ الرفع: ${image.uploadDate}',
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر فتح صور المريض: $error')));
    }
  }

  Future<void> _deletePatient(_WaitingPatient patient) async {
    final id = patient.id;
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المريض'),
          content: Text('هل تريد حذف ${patient.name}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSavingPatient = true;
    });

    try {
      await _waitingRepository.deletePatient(id);
      final imagePaths = patient.images
          .map((image) => image.path)
          .whereType<String>()
          .toList();
      await _waitingRepository.removeImages(imagePaths);
      if (!mounted) return;

      setState(() {
        _waitingPatients.removeWhere((current) => current.id == id);
        _isSavingPatient = false;
      });

      messenger.showSnackBar(const SnackBar(content: Text('تم حذف المريض')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingPatient = false;
      });
      messenger.showSnackBar(SnackBar(content: Text('فشل حذف المريض: $error')));
    }
  }

  Future<void> _movePatientToStage(
    _WaitingPatient patient,
    String workflowStage,
    String successMessage,
  ) async {
    if (patient.workflowStage == workflowStage) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSavingPatient = true;
    });

    try {
      final savedPatient = await _waitingRepository.updatePatient(
        patient.copyWith(workflowStage: workflowStage).toRepositoryModel(),
      );
      if (!mounted) return;

      setState(() {
        _upsertLocalPatient(_WaitingPatient.fromRepository(savedPatient));
        _isSavingPatient = false;
      });

      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingPatient = false;
      });
      messenger.showSnackBar(SnackBar(content: Text('فشل نقل المريض: $error')));
    }
  }

  Future<void> _setCallStatus(_WaitingPatient patient, String status) async {
    if (patient.callStatus == status) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final savedPatient = await _waitingRepository.updatePatient(
        patient.copyWith(callStatus: status).toRepositoryModel(),
      );
      if (!mounted) return;
      setState(() {
        _upsertLocalPatient(_WaitingPatient.fromRepository(savedPatient));
      });
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر تحديث حالة التواصل: $error')),
      );
    }
  }

  Future<void> _showOperationListDateDialog(_WaitingPatient patient) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final availableDates = <String>[];
    for (var offset = 0; offset <= 365; offset++) {
      final date = today.add(Duration(days: offset));
      if (date.weekday == DateTime.tuesday ||
          date.weekday == DateTime.saturday) {
        availableDates.add(_formatDate(date));
      }
    }
    final currentDate = patient.operationListDate;
    if (currentDate != null && !availableDates.contains(currentDate)) {
      availableDates.add(currentDate);
      availableDates.sort();
    }
    String? selectedDate = currentDate ?? availableDates.first;

    final chosenDate = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('إضافة إلى قائمة العمليات'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedDate),
                  initialValue: selectedDate,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'مواعيد الثلاثاء والسبت',
                    prefixIcon: Icon(Icons.event_repeat_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: availableDates
                      .map(
                        (date) => DropdownMenuItem<String>(
                          value: date,
                          child: Text(
                            '${_operationWeekdayLabel(date)} - $date',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedDate = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final pickerInitialDate =
                          DateTime.tryParse(selectedDate ?? '') ?? today;
                      final pickedDate = await showDatePicker(
                        context: dialogContext,
                        initialDate: pickerInitialDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate == null || !dialogContext.mounted) return;

                      final manualDate = _formatDate(pickedDate);
                      if (!availableDates.contains(manualDate)) {
                        availableDates.add(manualDate);
                        availableDates.sort();
                      }
                      setDialogState(() => selectedDate = manualDate);
                    },
                    icon: const Icon(Icons.edit_calendar_rounded),
                    label: Text(
                      selectedDate == null
                          ? 'اختيار موعد يدوي'
                          : 'اختيار موعد يدوي  •  $selectedDate',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: selectedDate == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(selectedDate),
              child: const Text('حفظ الموعد'),
            ),
          ],
        ),
      ),
    );

    if (chosenDate == null || chosenDate == currentDate || !mounted) return;
    await _setPatientOperationDate(patient, chosenDate);
  }

  Future<void> _setPatientOperationDate(
    _WaitingPatient patient,
    String? operationDate,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSavingPatient = true);
    try {
      final updated = patient.copyWith(
        operationListDate: operationDate,
        clearOperationListDate: operationDate == null,
      );
      final savedPatient = await _waitingRepository.updatePatient(
        updated.toRepositoryModel(),
      );
      if (!mounted) return;
      setState(() {
        _upsertLocalPatient(_WaitingPatient.fromRepository(savedPatient));
        _isSavingPatient = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            operationDate == null
                ? 'تمت إزالة المريض من قوائم العمليات'
                : 'تمت إضافة المريض إلى قائمة العمليات بتاريخ $operationDate',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingPatient = false);
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر تحديث موعد العملية: $error')),
      );
    }
  }

  void _upsertLocalPatient(_WaitingPatient patient) {
    final index = _waitingPatients.indexWhere(
      (current) => current.id == patient.id,
    );
    if (index == -1) {
      _waitingPatients = _sortPatientsByDate([patient, ..._waitingPatients]);
      return;
    }

    final updated = [..._waitingPatients];
    updated[index] = patient;
    _waitingPatients = _sortPatientsByDate(updated);
  }

  List<_WaitingPatient> _sortPatientsByDate(List<_WaitingPatient> patients) {
    final sorted = [...patients];
    sorted.sort((first, second) {
      final firstDate = DateTime.tryParse(first.date);
      final secondDate = DateTime.tryParse(second.date);
      if (firstDate == null && secondDate == null) return 0;
      if (firstDate == null) return 1;
      if (secondDate == null) return -1;
      final dateComparison = firstDate.compareTo(secondDate);
      if (dateComparison != 0) return dateComparison;

      final firstCreatedAt = first.createdAt;
      final secondCreatedAt = second.createdAt;
      if (firstCreatedAt == null && secondCreatedAt == null) return 0;
      if (firstCreatedAt == null) return 1;
      if (secondCreatedAt == null) return -1;
      return firstCreatedAt.compareTo(secondCreatedAt);
    });
    return sorted;
  }

  String _suggestedDoctorForDate(String date) {
    final parsedDate = DateTime.tryParse(date);
    return parsedDate?.weekday == DateTime.tuesday
        ? 'د. حمدي السيد'
        : 'د. أحمد أبو الحسب';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _operationWeekdayLabel(String date) {
    return switch (DateTime.tryParse(date)?.weekday) {
      DateTime.tuesday => 'الثلاثاء',
      DateTime.saturday => 'السبت',
      _ => 'موعد',
    };
  }

  String? _formatAge({
    required String years,
    required String months,
    required String days,
  }) {
    final parts = <String>[];
    final normalizedYears = years.trim();
    final normalizedMonths = months.trim();
    final normalizedDays = days.trim();

    if (normalizedYears.isNotEmpty) {
      parts.add('$normalizedYears yr');
    }
    if (normalizedMonths.isNotEmpty) {
      parts.add('$normalizedMonths mth');
    }
    if (normalizedDays.isNotEmpty) {
      parts.add('$normalizedDays day');
    }

    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  (String, String, String) _parseAgeParts(String age) {
    String readUnit(List<String> units) {
      final pattern = units.map(RegExp.escape).join('|');
      final match = RegExp('([0-9]+)\\s+(?:$pattern)').firstMatch(age);
      return match?.group(1) ?? '';
    }

    return (
      readUnit(['سنة', 'سنه', 'yr', 'yrs', 'year', 'years']),
      readUnit(['شهر', 'شهور', 'mth', 'mths', 'mo', 'mos', 'month', 'months']),
      readUnit(['يوم', 'ايام', 'day', 'days']),
    );
  }

  (List<String>, String?) _parseDiagnosisParts(String diagnosis) {
    final trimmed = diagnosis.trim();
    if (trimmed.isEmpty) return (<String>[], null);

    final sideSeparatorIndex = trimmed.lastIndexOf(' - ');
    final diagnosisPart = sideSeparatorIndex == -1
        ? trimmed
        : trimmed.substring(0, sideSeparatorIndex).trim();
    final sideCandidate = sideSeparatorIndex == -1
        ? null
        : trimmed.substring(sideSeparatorIndex + 3).trim();
    final side = switch (sideCandidate) {
      'أيمن' || 'الجانب الأيمن' => 'ج.أيمن',
      'أيسر' || 'الجانب الأيسر' => 'ج.أيسر',
      'الجانبين' => 'الجانبان',
      final value when _sideOptions.contains(value) => value,
      _ => null,
    };

    final diagnosisNames = diagnosisPart
        .split('،')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    return (diagnosisNames, side);
  }

  Future<void> _showPatientDetails(_WaitingPatient patient) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PatientDetailsDialog(
        patient: patient,
        imagePage: _storedImagePage,
        formatDate: _formatDate,
        onSave: (updated) => _savePatientDetails(patient, updated),
        onEditBasics: () => _showAddPatientDialog(patient),
      ),
    );
  }

  Future<bool> _savePatientDetails(
    _WaitingPatient original,
    _WaitingPatient updated,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final uploadedPaths = <String>[];
    try {
      final savedImages = <_PatientImageAttachment>[];
      for (final image in updated.images) {
        if (image.localFile == null) {
          savedImages.add(image);
          continue;
        }
        final path = await _uploadPatientImage(image.localFile!);
        uploadedPaths.add(path);
        savedImages.add(image.copyWith(path: path, clearLocalFile: true));
      }

      final saved = await _waitingRepository.updatePatient(
        updated.copyWith(images: savedImages).toRepositoryModel(),
      );

      final retained = savedImages
          .map((image) => image.path)
          .whereType<String>()
          .toSet();
      await _waitingRepository.removeImages(
        original.images
            .map((image) => image.path)
            .whereType<String>()
            .where((path) => !retained.contains(path))
            .toList(),
      );
      if (mounted) {
        setState(
          () => _upsertLocalPatient(_WaitingPatient.fromRepository(saved)),
        );
      }
      messenger.showSnackBar(const SnackBar(content: Text('تم حفظ التفاصيل')));
      return true;
    } catch (error) {
      await _waitingRepository.removeImages(uploadedPaths);
      final missingColumn = '$error'.contains('op_details');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            missingColumn
                ? 'شغّل ملف 20261124_pediatric_op_details.sql في Supabase أولاً'
                : 'فشل الحفظ: $error',
          ),
        ),
      );
      return false;
    }
  }

  Widget _buildPatientCardForStage(
    _WaitingPatient patient,
    int sequenceNumber,
  ) {
    return _WaitingPatientCard(
      patient: patient,
      sequenceNumber: sequenceNumber,
      onViewPressed: () => _showPatientDetails(patient),
      onEditPressed: () => _showAddPatientDialog(patient),
      onImagesPressed: () => _showPatientImages(patient),
      onAddToOperationListPressed: () => _showOperationListDateDialog(patient),
      onRemoveFromOperationListPressed: patient.operationListDate == null
          ? null
          : () => _setPatientOperationDate(patient, null),
      onDeletePressed: () => _deletePatient(patient),
      onMoveToFollowUpPressed: patient.workflowStage == _stageFollowUp
          ? null
          : () => _movePatientToStage(
              patient,
              _stageFollowUp,
              'تم نقل المريض إلى المتابعة',
            ),
      onMoveToAdmissionPressed: patient.workflowStage == _stageAdmission
          ? null
          : () => _movePatientToStage(
              patient,
              _stageAdmission,
              'تم نقل المريض إلى الحجز',
            ),
      onMoveToStagedOperationsPressed:
          patient.workflowStage == _stageStagedOperations
          ? null
          : () => _movePatientToStage(
              patient,
              _stageStagedOperations,
              'تم نقل المريض إلى العمليات المرحلية',
            ),
      onMoveToPicuPressed: patient.workflowStage == _stagePicu
          ? null
          : () => _movePatientToStage(
              patient,
              _stagePicu,
              'تم نقل المريض إلى PICU',
            ),
      onMoveToNicuPressed: patient.workflowStage == _stageNicu
          ? null
          : () => _movePatientToStage(
              patient,
              _stageNicu,
              'تم نقل المريض إلى NICU',
            ),
      onMoveToWaitingPressed: patient.workflowStage == _stageWaiting
          ? null
          : () => _movePatientToStage(
              patient,
              _stageWaiting,
              'تمت إعادة المريض إلى الانتظار',
            ),
      onCallStatusChanged: patient.workflowStage == _stageAdmission
          ? (status) => _setCallStatus(patient, status)
          : null,
    );
  }

  Widget _buildDoctorHeaderCard() {
    final operationCount = _waitingPatients
        .where(
          (patient) =>
              patient.doctor == widget.doctor &&
              patient.operationListDate != null &&
              patient.operationListDate!.isNotEmpty,
        )
        .length;
    // Tab index, label and patient count for every section.
    final sections = <(int, String, int)>[
      (0, 'waiting list', _waitingStagePatients.length),
      (1, 'follow up', _followUpStagePatients.length),
      (2, 'addmission', _admissionStagePatients.length),
      (3, 'staged op.', _stagedOperationsStagePatients.length),
      (4, 'operation lists', operationCount),
      (5, 'PICU', _picuStagePatients.length),
      (6, 'NICU', _nicuStagePatients.length),
      (7, 'Emergency', _emergencyStagePatients.length),
    ].where((section) => section.$3 > 0).toList(growable: false);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC145), Color(0xFFEF4444)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22EF4444),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.child_friendly_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'الأقسام التي بها مرضى - اضغط للدخول',
                      style: TextStyle(color: Color(0xFFFFF7ED), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPatients)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              ),
            )
          else if (sections.isEmpty)
            const Text(
              'لا يوجد مرضى في أي قسم حاليًا',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final section in sections)
                  SizedBox(
                    width: 104,
                    child: _HeaderMetricCard(
                      label: section.$2,
                      value: section.$3.toString(),
                      onTap: () => _tabController.animateTo(section.$1),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        floatingActionButton: _canAddPatientFromCurrentTab
            ? FloatingActionButton.extended(
                onPressed: _isSavingPatient
                    ? null
                    : () => _showAddPatientDialog(),
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                icon: _isSavingPatient
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(_isSavingPatient ? 'Saving...' : 'إضافة مريض'),
              )
            : null,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'رجوع',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Spacer(),
                          const AccountButton(),
                        ],
                      ),
                    ),
                  ),
                  if (widget.doctor != null)
                    SliverToBoxAdapter(child: _buildDoctorHeaderCard()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          if (_currentTabIndex == 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showPatientSearchDialog,
                                icon: const Icon(Icons.search_rounded),
                                label: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'البحث: $_searchQuery'
                                      : _selectedDoctorFilter != null ||
                                            _selectedDiagnosisFilter != null
                                      ? 'تم تطبيق فلاتر البحث'
                                      : 'بحث في قائمة الانتظار',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  alignment: Alignment.centerRight,
                                  foregroundColor: const Color(0xFF16324F),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFD7E5F2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          if (_currentTabIndex <= 3) ...[
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'تصدير بيانات مرضى التبويب إلى Excel',
                              onPressed: _exportPatientsToExcel,
                              icon: const Icon(Icons.table_view_rounded),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xEFFFFFFF),
                                const Color(0xD9EDF5FA),
                                const Color(0xCCFFF0E5),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.82),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2C8793,
                                ).withValues(alpha: 0.16),
                                blurRadius: 22,
                                offset: const Offset(0, 9),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.68),
                                blurRadius: 10,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            indicatorPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            indicator: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _tabGradientForIndex(_currentTabIndex),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _tabGradientForIndex(
                                    _currentTabIndex,
                                  ).first.withValues(alpha: 0.35),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            labelColor: const Color(0xFF122B3A),
                            unselectedLabelColor: const Color(0xFF263D49),
                            dividerColor: Colors.transparent,
                            splashBorderRadius: BorderRadius.circular(15),
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: [
                              _SeparatedTab(
                                label: 'waiting list',
                                accentColor: Color(0xFF138A69),
                                count: _waitingStagePatients.length,
                              ),
                              _SeparatedTab(
                                label: 'follow up',
                                accentColor: Color(0xFF178E9B),
                                count: _followUpStagePatients.length,
                              ),
                              _SeparatedTab(
                                label: 'addmission',
                                accentColor: Color(0xFFC87532),
                                count: _admissionStagePatients.length,
                              ),
                              _SeparatedTab(
                                label: 'staged op.',
                                accentColor: Color(0xFF7C3AED),
                                count: _stagedOperationsStagePatients.length,
                              ),
                              _SeparatedTab(
                                label: 'operation lists',
                                accentColor: Color(0xFF087E8B),
                                count: _waitingPatients
                                    .where(
                                      (patient) =>
                                          (widget.doctor == null ||
                                              patient.doctor ==
                                                  widget.doctor) &&
                                          patient.operationListDate != null &&
                                          patient.operationListDate!.isNotEmpty,
                                    )
                                    .length,
                              ),
                              _SeparatedTab(
                                label: 'PICU',
                                accentColor: Color(0xFF366BC5),
                                count: _picuStagePatients.length,
                              ),
                              _SeparatedTab(
                                label: 'NICU',
                                accentColor: Color(0xFFCB5C86),
                                count: _nicuStagePatients.length,
                              ),
                              _SeparatedTab(
                                label: 'Emergency',
                                accentColor: Color(0xFFD64545),
                                count: _emergencyStagePatients.length,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _PatientStageTab(
                      tabIndex: 0,
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(0, position),
                      title: 'قائمة الانتظار',
                      emptyTitle: 'لا توجد حالات في قائمة الانتظار',
                      emptyDescription: 'استخدم زر الإضافة لإدخال أول مريض.',
                      emptyIcon: Icons.inbox_outlined,
                      patients: _waitingStagePatients,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                    _PatientStageTab(
                      tabIndex: 1,
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(1, position),
                      title: 'المتابعة',
                      emptyTitle: 'لا توجد حالات في المتابعة',
                      emptyDescription:
                          'انقل أي مريض من الانتظار إلى المتابعة ليظهر هنا.',
                      emptyIcon: Icons.monitor_heart_outlined,
                      patients: _followUpStagePatients,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                    _PatientStageTab(
                      tabIndex: 2,
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(2, position),
                      title: 'الحجز',
                      emptyTitle: 'لا توجد حالات في الحجز',
                      emptyDescription:
                          'انقل أي مريض من الانتظار أو المتابعة إلى الحجز ليظهر هنا.',
                      emptyIcon: Icons.bedroom_baby_outlined,
                      patients: _admissionStagePatients,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                    _PatientStageTab(
                      tabIndex: 3,
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(3, position),
                      title: 'العمليات المرحلية',
                      emptyTitle: 'لا توجد حالات في العمليات المرحلية',
                      emptyDescription:
                          'انقل أي مريض إلى العمليات المرحلية ليظهر هنا.',
                      emptyIcon: Icons.medical_services_outlined,
                      patients: _stagedOperationsStagePatients,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                    _OperationListsTab(
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(4, position),
                      datesAndPatients: _operationPatientsByDate,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                    _PatientStageTab(
                      tabIndex: 5,
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(5, position),
                      title: 'PICU',
                      emptyTitle: 'لا توجد حالات في PICU',
                      emptyDescription: 'استخدم زر الإضافة لإدخال مريض جديد.',
                      emptyIcon: Icons.local_hospital_outlined,
                      patients: _picuStagePatients,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                    _PatientStageTab(
                      tabIndex: 6,
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(6, position),
                      title: 'NICU',
                      emptyTitle: 'لا توجد حالات في NICU',
                      emptyDescription: 'استخدم زر الإضافة لإدخال مريض جديد.',
                      emptyIcon: Icons.child_care_outlined,
                      patients: _nicuStagePatients,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                    _PatientStageTab(
                      tabIndex: 7,
                      onScrollPositionChanged: (position) =>
                          _setTabScrollPosition(7, position),
                      title: 'Emergency',
                      emptyTitle: 'لا توجد حالات طارئة',
                      emptyDescription: 'استخدم زر الإضافة لإدخال حالة طارئة.',
                      emptyIcon: Icons.emergency_outlined,
                      patients: _emergencyStagePatients,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientsError,
                      onRetryPressed: _loadWaitingPatients,
                      patientCardBuilder: _buildPatientCardForStage,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: ValueListenableBuilder<ScrollPosition?>(
                  valueListenable: _activeScrollPosition,
                  builder: (context, position, _) =>
                      _ScrollToEdgeButton(position: position),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientStageTab extends StatelessWidget {
  const _PatientStageTab({
    required this.tabIndex,
    required this.onScrollPositionChanged,
    required this.title,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.emptyIcon,
    required this.patients,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetryPressed,
    required this.patientCardBuilder,
  });

  final int tabIndex;
  final ValueChanged<ScrollPosition?> onScrollPositionChanged;
  final String title;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;
  final List<_WaitingPatient> patients;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetryPressed;
  final Widget Function(_WaitingPatient patient, int sequenceNumber)
  patientCardBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? _WaitingListErrorState(
                    message: errorMessage!,
                    onRetryPressed: onRetryPressed,
                  )
                : patients.isEmpty
                ? _EmptyTabState(
                    icon: emptyIcon,
                    title: emptyTitle,
                    description: emptyDescription,
                  )
                : _TabScrollPositionReporter(
                    onPositionChanged: onScrollPositionChanged,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: patients.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          patientCardBuilder(patients[index], index + 1),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OperationListsTab extends StatelessWidget {
  const _OperationListsTab({
    required this.onScrollPositionChanged,
    required this.datesAndPatients,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetryPressed,
    required this.patientCardBuilder,
  });

  final ValueChanged<ScrollPosition?> onScrollPositionChanged;
  final Map<String, List<_WaitingPatient>> datesAndPatients;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetryPressed;
  final Widget Function(_WaitingPatient patient, int sequenceNumber)
  patientCardBuilder;

  String _weekdayLabel(String date) {
    return switch (DateTime.tryParse(date)?.weekday) {
      DateTime.tuesday => 'الثلاثاء',
      DateTime.saturday => 'السبت',
      _ => 'موعد',
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final operationEntries = [
      for (final entry in datesAndPatients.entries)
        (
          entry: entry,
          isPast: DateTime.tryParse(entry.key)?.isBefore(today) ?? false,
        ),
    ];

    Widget content;
    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      content = _WaitingListErrorState(
        message: errorMessage!,
        onRetryPressed: onRetryPressed,
      );
    } else if (datesAndPatients.isEmpty) {
      content = const _EmptyTabState(
        icon: Icons.event_busy_outlined,
        title: 'لا توجد قوائم عمليات قادمة',
        description: 'أضف المرضى إلى موعد الثلاثاء أو السبت من قائمة المقص.',
      );
    } else {
      content = _TabScrollPositionReporter(
        onPositionChanged: onScrollPositionChanged,
        child: ListView(
          children: [
            for (final indexedEntry in operationEntries.asMap().entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: const Color(0x182C8793),
                    highlightColor: const Color(0x102C8793),
                  ),
                  child: ExpansionTile(
                    key: PageStorageKey<String>(
                      'operation-date-${indexedEntry.value.entry.key}',
                    ),
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    collapsedBackgroundColor: indexedEntry.value.isPast
                        ? const Color(0xFFE7F4E8)
                        : const Color(0xFFFFF4CC),
                    backgroundColor: indexedEntry.value.isPast
                        ? const Color(0xFFF2FAF1)
                        : const Color(0xFFFFFAE8),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: indexedEntry.value.isPast
                            ? const Color(0xFF9BC89B)
                            : const Color(0xFFE7CC72),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: indexedEntry.value.isPast
                            ? const Color(0xFF72AA72)
                            : const Color(0xFFD8B84D),
                      ),
                    ),
                    leading: Icon(
                      Icons.event_available_outlined,
                      color: indexedEntry.value.isPast
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB7791F),
                    ),
                    title: Text(
                      '${_weekdayLabel(indexedEntry.value.entry.key)} - ${indexedEntry.value.entry.key}',
                      style: TextStyle(
                        color: indexedEntry.value.isPast
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF9A6A00),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      '${indexedEntry.value.entry.value.length} مرضى',
                      style: TextStyle(
                        color: indexedEntry.value.isPast
                            ? const Color(0xFF4B8050)
                            : const Color(0xFF9A7617),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: [
                      for (
                        var index = 0;
                        index < indexedEntry.value.entry.value.length;
                        index++
                      ) ...[
                        patientCardBuilder(
                          indexedEntry.value.entry.value[index],
                          index + 1,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: content,
    );
  }
}

class PediatricParametersSection extends StatelessWidget {
  const PediatricParametersSection({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            isArabic ? 'معايير الأطفال' : 'Pediatric Parameters',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16324F),
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.rtl,
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ParameterCard(
                icon: Icons.monitor_heart_outlined,
                title: 'معدل BP',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _PediatricBloodPressurePage(),
                    ),
                  );
                },
              ),
              _ParameterCard(
                icon: Icons.favorite_outline,
                title: 'معدل HR',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _PediatricVitalReferencePage(
                        title: 'معدل HR للأطفال',
                        columnTitle: 'النبض / دقيقة',
                        icon: Icons.favorite_outline,
                        ranges: [
                          ('حديثو الولادة (0 - 3 أشهر)', '110 - 160'),
                          ('الرضع (3 - 12 شهرًا)', '90 - 150'),
                          ('الأطفال الصغار (1 - 3 سنوات)', '80 - 125'),
                          ('مرحلة ما قبل المدرسة (3 - 6 سنوات)', '70 - 115'),
                          ('المدرسة (6 - 12 سنة)', '60 - 100'),
                          ('المراهقون (12 - 18 سنة)', '60 - 100'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              _ParameterCard(
                icon: Icons.air_outlined,
                title: 'معدل RR',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _PediatricVitalReferencePage(
                        title: 'معدل RR للأطفال',
                        columnTitle: 'التنفس / دقيقة',
                        icon: Icons.air_outlined,
                        ranges: [
                          ('حديثو الولادة (0 - 3 أشهر)', '30 - 60'),
                          ('الرضع (3 - 12 شهرًا)', '25 - 45'),
                          ('الأطفال الصغار (1 - 3 سنوات)', '20 - 30'),
                          ('مرحلة ما قبل المدرسة (3 - 6 سنوات)', '20 - 25'),
                          ('المدرسة (6 - 12 سنة)', '14 - 22'),
                          ('المراهقون (12 - 18 سنة)', '12 - 18'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              _ParameterCard(
                icon: Icons.monitor_weight_outlined,
                title: 'معدل الوزن',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _PediatricWeightPage(),
                    ),
                  );
                },
              ),
              _ParameterCard(
                icon: Icons.height_outlined,
                title: 'معدل الطول',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _PediatricHeightPage(),
                    ),
                  );
                },
              ),
              _ParameterCard(
                icon: Icons.circle_outlined,
                title: 'محيط الرأس',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _PediatricHeadCircumferencePage(),
                    ),
                  );
                },
              ),
              _ParameterCard(
                icon: Icons.straighten_outlined,
                title: 'محيط البطن',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const _PediatricAbdominalCircumferencePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabScrollPositionReporter extends StatefulWidget {
  const _TabScrollPositionReporter({
    required this.child,
    this.onPositionChanged,
  });

  final Widget child;
  final ValueChanged<ScrollPosition?>? onPositionChanged;

  @override
  State<_TabScrollPositionReporter> createState() =>
      _TabScrollPositionReporterState();
}

class _TabScrollPositionReporterState
    extends State<_TabScrollPositionReporter> {
  ScrollPosition? _reportedPosition;

  bool _handleNotification(Notification notification) {
    final BuildContext? scrollContext;
    final int depth;
    if (notification is ScrollMetricsNotification) {
      scrollContext = notification.context;
      depth = notification.depth;
    } else if (notification is ScrollNotification) {
      scrollContext = notification.context;
      depth = notification.depth;
    } else {
      return false;
    }
    if (depth != 0 || scrollContext == null) return false;

    final position = Scrollable.maybeOf(scrollContext)?.position;
    if (position == null ||
        position.axis != Axis.vertical ||
        identical(position, _reportedPosition)) {
      return false;
    }

    _reportedPosition = position;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_reportedPosition, position)) return;
      widget.onPositionChanged?.call(position);
    });
    return false;
  }

  @override
  void dispose() {
    if (_reportedPosition != null) {
      final onPositionChanged = widget.onPositionChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPositionChanged?.call(null);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<Notification>(
      onNotification: _handleNotification,
      child: widget.child,
    );
  }
}

class _ScrollToEdgeButton extends StatefulWidget {
  const _ScrollToEdgeButton({required this.position});

  final ScrollPosition? position;

  @override
  State<_ScrollToEdgeButton> createState() => _ScrollToEdgeButtonState();
}

class _ScrollToEdgeButtonState extends State<_ScrollToEdgeButton> {
  @override
  void initState() {
    super.initState();
    widget.position?.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant _ScrollToEdgeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position == widget.position) return;
    oldWidget.position?.removeListener(_handleScroll);
    widget.position?.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.position?.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (mounted) setState(() {});
  }

  bool get _canScroll {
    final position = widget.position;
    return position != null &&
        position.hasContentDimensions &&
        position.maxScrollExtent > position.minScrollExtent;
  }

  bool get _isAtBottom => _canScroll && widget.position!.extentAfter <= 64;

  @override
  Widget build(BuildContext context) {
    final canScroll = _canScroll;
    final isAtBottom = _isAtBottom;
    return FloatingActionButton.small(
      heroTag: 'pediatric-list-scroll-edge',
      tooltip: isAtBottom
          ? 'الصعود إلى أعلى القائمة'
          : 'النزول إلى أسفل القائمة',
      onPressed: !canScroll
          ? null
          : () {
              final position = widget.position!;
              position.animateTo(
                isAtBottom
                    ? position.minScrollExtent
                    : position.maxScrollExtent,
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeInOutCubic,
              );
            },
      backgroundColor: const Color(0xFF16324F),
      foregroundColor: Colors.white,
      child: Icon(
        isAtBottom
            ? Icons.keyboard_double_arrow_up_rounded
            : Icons.keyboard_double_arrow_down_rounded,
      ),
    );
  }
}

class _ParameterCard extends StatelessWidget {
  const _ParameterCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (title) {
      'معدل BP' => const Color(0xFF2563EB),
      'معدل HR' => const Color(0xFFE11D48),
      'معدل RR' => const Color(0xFF0891B2),
      'معدل الوزن' => const Color(0xFF7C3AED),
      'معدل الطول' => const Color(0xFF0F766E),
      'محيط الرأس' => const Color(0xFFD97706),
      'محيط البطن' => const Color(0xFFCA8A04),
      _ => const Color(0xFF475569),
    };

    return Material(
      color: const Color(0xFFF8FBFF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 148,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.14), const Color(0xFFF8FBFF)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.26)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -12,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.24),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 21),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16324F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PediatricBloodPressurePage extends StatelessWidget {
  const _PediatricBloodPressurePage();

  static const List<(String, String, String)> _ranges = [
    ('حديثو الولادة (0 - 3 أشهر)', '65 - 85', '45 - 55'),
    ('الرضع (3 - 12 شهرًا)', '70 - 100', '50 - 65'),
    ('الأطفال الصغار (1 - 3 سنوات)', '90 - 105', '55 - 70'),
    ('مرحلة ما قبل المدرسة (3 - 6 سنوات)', '95 - 110', '60 - 75'),
    ('المدرسة (6 - 12 سنة)', '100 - 120', '60 - 75'),
    ('المراهقون (12 - 18 سنة)', '100 - 120', '70 - 80'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('معدل BP للأطفال'),
          actions: const [AccountButton()],
          backgroundColor: const Color(0xFFD7EAF8),
          foregroundColor: const Color(0xFF16324F),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Text(
                'قيم تقريبية إرشادية. التقييم الطبي للأطفال يعتمد أيضًا على الطول والجنس والنسب المئوية، ولا تُستخدم هذه القيم وحدها للتشخيص.',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _BloodPressureHeader(),
            ..._ranges.map(
              (range) => _BloodPressureRow(
                age: range.$1,
                systolic: range.$2,
                diastolic: range.$3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PediatricVitalReferencePage extends StatelessWidget {
  const _PediatricVitalReferencePage({
    required this.title,
    required this.columnTitle,
    required this.icon,
    required this.ranges,
  });

  final String title;
  final String columnTitle;
  final IconData icon;
  final List<(String, String)> ranges;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(title),
          actions: const [AccountButton()],
          backgroundColor: const Color(0xFFD7EAF8),
          foregroundColor: const Color(0xFF16324F),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Text(
                'قيم تقريبية إرشادية أثناء الراحة. يجب تفسير القياس مع عمر الطفل وحالته السريرية، ولا تُستخدم هذه القيم وحدها للتشخيص.',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _VitalReferenceRow(
              age: 'العمر',
              value: columnTitle,
              icon: icon,
              isHeader: true,
            ),
            ...ranges.map(
              (range) => _VitalReferenceRow(
                age: range.$1,
                value: range.$2,
                icon: icon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PediatricWeightPage extends StatelessWidget {
  const _PediatricWeightPage();

  static const List<(String, String, String)> _ranges = [
    ('عند الولادة', '3.3 (2.5 - 4.3)', '3.2 (2.4 - 4.2)'),
    ('3 أشهر', '6.4 (5.0 - 8.0)', '5.8 (4.5 - 7.5)'),
    ('6 أشهر', '7.9 (6.4 - 9.8)', '7.3 (5.7 - 9.3)'),
    ('9 أشهر', '8.9 (7.1 - 11.0)', '8.2 (6.5 - 10.4)'),
    ('سنة واحدة (12 شهرًا)', '9.6 (7.7 - 12.0)', '8.9 (7.0 - 11.5)'),
    ('سنتان (24 شهرًا)', '12.2 (9.7 - 15.3)', '11.5 (9.0 - 14.8)'),
    ('3 سنوات', '14.3 (11.3 - 18.3)', '13.9 (10.8 - 18.1)'),
    ('4 سنوات', '16.3 (12.7 - 21.2)', '16.1 (12.3 - 21.5)'),
    ('5 سنوات', '18.3 (14.1 - 24.2)', '18.2 (13.7 - 24.9)'),
    ('6 سنوات', '20.5 (15.6 - 27.8)', '20.2 (15.1 - 28.5)'),
    ('8 سنوات', '25.6 (19.0 - 35.8)', '25.4 (18.6 - 36.9)'),
    ('10 سنوات', '31.2 (22.7 - 45.0)', '31.9 (22.4 - 46.8)'),
    ('12 سنة', '38.3 (27.3 - 57.0)', '40.2 (28.0 - 59.0)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('معدل الوزن للأطفال'),
          actions: const [AccountButton()],
          backgroundColor: const Color(0xFFD7EAF8),
          foregroundColor: const Color(0xFF16324F),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'جدول معدل الوزن حسب العمر للأطفال (كجم)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
            ),
            const _WeightRow(
              age: 'المرحلة العمرية',
              male: 'وزن الذكور (كجم)',
              female: 'وزن الإناث (كجم)',
              isHeader: true,
            ),
            ..._ranges.map(
              (range) =>
                  _WeightRow(age: range.$1, male: range.$2, female: range.$3),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({
    required this.age,
    required this.male,
    required this.female,
    this.isHeader = false,
  });

  final String age;
  final String male;
  final String female;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: isHeader ? Colors.white : const Color(0xFF16324F),
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
      fontSize: 12,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFF1D4ED8) : const Color(0xFFEAF3FA),
        border: Border(
          bottom: BorderSide(
            color: isHeader ? const Color(0xFF1D4ED8) : const Color(0xFFD7E5F2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(age, style: textStyle)),
          Expanded(
            child: Text(male, textAlign: TextAlign.center, style: textStyle),
          ),
          Expanded(
            child: Text(female, textAlign: TextAlign.center, style: textStyle),
          ),
        ],
      ),
    );
  }
}

class _PediatricAbdominalCircumferencePage extends StatelessWidget {
  const _PediatricAbdominalCircumferencePage();

  static const List<(String, String, String)> _ranges = [
    ('حديثو الولادة (عند الولادة)', '31 - 33', '30 - 32'),
    ('3 أشهر', '38 - 41', '37 - 40'),
    ('6 أشهر', '42 - 44', '41 - 43'),
    ('9 أشهر', '44 - 46', '43 - 45'),
    ('سنة واحدة (12 شهرًا)', '45 - 47', '44 - 46'),
    ('سنتان (24 شهرًا)', '48 - 50', '47 - 49'),
    ('3 سنوات', '50 - 52', '49 - 51'),
    ('4 سنوات', '51 - 54', '50 - 53'),
    ('5 سنوات', '53 - 56', '52 - 55'),
    ('6 سنوات', '55 - 58', '54 - 57'),
    ('8 سنوات', '58 - 62', '57 - 61'),
    ('10 سنوات', '62 - 67', '61 - 66'),
    ('12 سنة', '67 - 73', '66 - 72'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('معدل محيط البطن للأطفال'),
          actions: const [AccountButton()],
          backgroundColor: const Color(0xFFD7EAF8),
          foregroundColor: const Color(0xFF16324F),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'جدول معدل محيط البطن حسب العمر للأطفال (سم)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
            ),
            const _WeightRow(
              age: 'المرحلة العمرية',
              male: 'متوسط محيط البطن للذكور (سم)',
              female: 'متوسط محيط البطن للإناث (سم)',
              isHeader: true,
            ),
            ..._ranges.map(
              (range) =>
                  _WeightRow(age: range.$1, male: range.$2, female: range.$3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PediatricHeightPage extends StatelessWidget {
  const _PediatricHeightPage();

  static const List<(String, String, String)> _ranges = [
    ('عند الولادة', '49.9 (46.3 - 53.4)', '49.1 (45.4 - 52.9)'),
    ('3 أشهر', '61.4 (57.6 - 65.3)', '59.8 (55.8 - 63.8)'),
    ('6 أشهر', '67.6 (63.6 - 71.6)', '65.7 (61.2 - 70.3)'),
    ('9 أشهر', '72.0 (67.7 - 76.2)', '70.1 (65.3 - 75.0)'),
    ('سنة واحدة (12 شهرًا)', '75.7 (71.0 - 80.5)', '74.0 (68.9 - 79.2)'),
    ('سنتان (24 شهرًا)', '87.8 (81.7 - 93.9)', '86.4 (80.0 - 92.9)'),
    ('3 سنوات', '96.1 (88.7 - 103.5)', '95.1 (87.4 - 102.7)'),
    ('4 سنوات', '103.3 (94.9 - 111.7)', '102.7 (94.1 - 111.3)'),
    ('5 سنوات', '110.0 (100.7 - 119.2)', '109.4 (99.9 - 118.9)'),
    ('6 سنوات', '116.0 (106.1 - 125.8)', '115.1 (104.9 - 125.4)'),
    ('8 سنوات', '127.3 (116.0 - 138.6)', '126.6 (115.0 - 138.2)'),
    ('10 سنوات', '138.4 (125.0 - 151.7)', '138.6 (124.8 - 152.5)'),
    ('12 سنة', '149.1 (133.7 - 164.5)', '151.2 (135.2 - 167.1)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('معدل الطول للأطفال'),
          actions: const [AccountButton()],
          backgroundColor: const Color(0xFFD7EAF8),
          foregroundColor: const Color(0xFF16324F),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'جدول معدل الطول حسب العمر للأطفال (سم)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
            ),
            const _WeightRow(
              age: 'المرحلة العمرية',
              male: 'متوسط طول الذكور (سم)',
              female: 'متوسط طول الإناث (سم)',
              isHeader: true,
            ),
            ..._ranges.map(
              (range) =>
                  _WeightRow(age: range.$1, male: range.$2, female: range.$3),
            ),
            const SizedBox(height: 18),
            const _GrowthSection(
              icon: Icons.show_chart_rounded,
              title: 'سرعة النمو (Growth Velocity)',
              lines: [
                'معدل زيادة الطول يختلف باختلاف المرحلة العمرية.',
                'السنة الأولى: ينمو الطفل حوالي 25 سم.',
                'السنة الثانية: ينمو الطفل حوالي 12.5 سم.',
                'من عمر 3 سنوات حتى البلوغ: ينمو بمعدل منتظم يتراوح بين 5 إلى 6 سم سنويًا.',
              ],
            ),
            const SizedBox(height: 14),
            const _GrowthSection(
              icon: Icons.family_restroom_outlined,
              title: 'الطول المستهدف بناءً على الوالدين',
              lines: [
                'يتأثر طول الطفل النهائي بالوراثة بشكل مباشر.',
                'للذكور: (طول الأب + طول الأم + 13) ÷ 2.',
                'للإناث: (طول الأب + طول الأم - 13) ÷ 2.',
                'القيمة الناتجة تقديرية وليست قياسًا نهائيًا للطول.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PediatricHeadCircumferencePage extends StatelessWidget {
  const _PediatricHeadCircumferencePage();

  static const List<(String, String, String)> _ranges = [
    ('عند الولادة', '34.5 (32.0 - 37.0)', '33.9 (31.5 - 36.2)'),
    ('3 أشهر', '40.5 (38.0 - 43.0)', '39.5 (37.0 - 42.0)'),
    ('6 أشهر', '43.3 (41.0 - 45.8)', '42.2 (39.8 - 44.6)'),
    ('9 أشهر', '45.0 (42.6 - 47.5)', '43.8 (41.5 - 46.2)'),
    ('سنة واحدة (12 شهرًا)', '46.1 (43.6 - 48.6)', '44.9 (42.5 - 47.4)'),
    ('سنتان (24 شهرًا)', '48.3 (45.6 - 50.8)', '47.2 (44.6 - 49.8)'),
    ('3 سنوات', '49.5 (46.8 - 52.0)', '48.5 (45.8 - 51.0)'),
    ('5 سنوات', '50.8 (48.0 - 53.4)', '50.0 (47.2 - 52.6)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('معدل محيط الرأس للأطفال'),
          actions: const [AccountButton()],
          backgroundColor: const Color(0xFFD7EAF8),
          foregroundColor: const Color(0xFF16324F),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'جدول معدل محيط الرأس حسب العمر للأطفال (سم)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1A8), Color(0xFFE8A317)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD49A16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Color(0xFF7C4A03)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'متابعة نمو الطفل من مكان واحد تحت إشراف د. أحمد أبو الحسب',
                      style: TextStyle(
                        color: Color(0xFF5B3A00),
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _WeightRow(
              age: 'المرحلة العمرية',
              male: 'متوسط محيط الرأس للذكور (سم)',
              female: 'متوسط محيط الرأس للإناث (سم)',
              isHeader: true,
            ),
            ..._ranges.map(
              (range) =>
                  _WeightRow(age: range.$1, male: range.$2, female: range.$3),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthSection extends StatelessWidget {
  const _GrowthSection({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1D4ED8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF16324F),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
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

class _VitalReferenceRow extends StatelessWidget {
  const _VitalReferenceRow({
    required this.age,
    required this.value,
    required this.icon,
    this.isHeader = false,
  });

  final String age;
  final String value;
  final IconData icon;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: isHeader ? Colors.white : const Color(0xFF16324F),
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
      fontSize: 13,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFF1D4ED8) : const Color(0xFFEAF3FA),
        border: Border(
          bottom: BorderSide(
            color: isHeader ? const Color(0xFF1D4ED8) : const Color(0xFFD7E5F2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(age, style: textStyle)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isHeader)
                Icon(icon, size: 17, color: const Color(0xFF1D4ED8)),
              if (!isHeader) const SizedBox(width: 6),
              Text(value, textAlign: TextAlign.center, style: textStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _BloodPressureHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _BloodPressureRow(
      age: 'العمر',
      systolic: 'الانقباضي',
      diastolic: 'الانبساطي',
      isHeader: true,
    );
  }
}

class _BloodPressureRow extends StatelessWidget {
  const _BloodPressureRow({
    required this.age,
    required this.systolic,
    required this.diastolic,
    this.isHeader = false,
  });

  final String age;
  final String systolic;
  final String diastolic;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: isHeader ? Colors.white : const Color(0xFF16324F),
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
      fontSize: 13,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFF1D4ED8) : const Color(0xFFEAF3FA),
        border: Border(
          bottom: BorderSide(
            color: isHeader ? const Color(0xFF1D4ED8) : const Color(0xFFD7E5F2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(age, style: textStyle)),
          Expanded(
            child: Text(
              systolic,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
          Expanded(
            child: Text(
              diastolic,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeparatedTab extends StatelessWidget {
  const _SeparatedTab({
    required this.label,
    required this.accentColor,
    required this.count,
  });

  final String label;
  final Color accentColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: switch (label) {
        'operation lists' => 170,
        'waiting list' => 148,
        'follow up' => 148,
        'addmission' => 148,
        'Emergency' => 150,
        _ => 118,
      },
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Tab(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
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
}

class _HealthInsuranceShieldLogo extends StatelessWidget {
  const _HealthInsuranceShieldLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _HealthInsuranceShieldClipper(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 7, 4, 11),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFFDF8), Color(0xFFE9F5F4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/hio_logo_ar.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.health_and_safety_outlined,
                    size: 22,
                    color: Color(0xFF0F4C81),
                  ),
                ),
              ),
            ),
          ),
          CustomPaint(painter: _HealthInsuranceShieldBorderPainter()),
        ],
      ),
    );
  }
}

class _HealthInsuranceShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.5, size.height * 0.035)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.02,
        size.width * 0.96,
        size.height * 0.18,
      )
      ..lineTo(size.width * 0.91, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.84,
        size.width * 0.5,
        size.height * 0.98,
      )
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.84,
        size.width * 0.09,
        size.height * 0.62,
      )
      ..lineTo(size.width * 0.04, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.02,
        size.width * 0.5,
        size.height * 0.035,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HealthInsuranceShieldBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _HealthInsuranceShieldClipper().getClip(size);
    final paint = Paint()
      ..color = const Color(0xFFFFF1A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderMetricCard extends StatelessWidget {
  const _HeaderMetricCard({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFF7ED), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _splitPhoneNumbers(String value) {
  return value
      .split(RegExp(r'[,;\n]+'))
      .map((phone) => phone.replaceAll(RegExp(r'[\s-]'), '').trim())
      .where((phone) => phone.isNotEmpty)
      .toList(growable: false);
}

String? _validatePhoneNumbers(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'أدخل رقم الهاتف';
  }

  final numbers = _splitPhoneNumbers(value);
  if (numbers.any((phone) => !RegExp(r'^\d{11}$').hasMatch(phone))) {
    return 'يجب أن يحتوي كل رقم هاتف على 11 رقمًا';
  }
  return null;
}

Future<void> _callPhone(BuildContext context, String phone) async {
  final numbers = _splitPhoneNumbers(phone);
  if (numbers.isEmpty) return;

  final selectedNumber = numbers.length == 1
      ? numbers.first
      : await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('اختر رقم الاتصال'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: numbers
                  .map(
                    (number) => ListTile(
                      leading: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF15803D),
                      ),
                      title: Text(number, textDirection: TextDirection.ltr),
                      onTap: () => Navigator.of(dialogContext).pop(number),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
  if (selectedNumber == null || selectedNumber.isEmpty || !context.mounted) {
    return;
  }
  final normalized = selectedNumber;

  final uri = Uri(scheme: 'tel', path: normalized);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
    );
  }
}

Future<void> _showPatientNoteDialog(BuildContext context, String notes) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)),
          SizedBox(width: 8),
          Text('ملاحظة هامة'),
        ],
      ),
      content: SingleChildScrollView(child: Text(notes)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}

class _PatientNoteBadge extends StatelessWidget {
  const _PatientNoteBadge({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'ملاحظة هامة',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFB91C1C),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'NB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarqueePatientName extends StatefulWidget {
  const _MarqueePatientName({required this.name});

  final String name;

  @override
  State<_MarqueePatientName> createState() => _MarqueePatientNameState();
}

class _MarqueePatientNameState extends State<_MarqueePatientName>
    with SingleTickerProviderStateMixin {
  static const _textStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [Shadow(color: Color(0x99000000), blurRadius: 3)],
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  double? _animatedOverflow;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.name, style: _textStyle),
          maxLines: 1,
          textDirection: TextDirection.rtl,
          textScaler: MediaQuery.textScalerOf(context),
        );
        textPainter.layout();
        final textWidth = textPainter.width;
        textPainter.dispose();
        final overflow = textWidth - constraints.maxWidth;

        if (overflow <= 1) {
          if (_controller.isAnimating) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _controller.stop();
            });
          }
          _animatedOverflow = null;
          return SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: _textStyle,
              ),
            ),
          );
        }

        if (_animatedOverflow != overflow) {
          _animatedOverflow = overflow;
          final duration = Duration(
            milliseconds: (overflow * 40).round().clamp(3500, 12000),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _controller.duration = duration;
            _controller.repeat(reverse: true);
          });
        }

        return RepaintBoundary(
          child: ClipRect(
            child: SizedBox(
              width: constraints.maxWidth,
              height: 28,
              child: AnimatedBuilder(
                animation: _controller,
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: SizedBox(
                    width: textWidth,
                    child: Text(
                      widget.name,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: _textStyle,
                    ),
                  ),
                ),
                builder: (context, child) => Transform.translate(
                  offset: Offset(-overflow * _controller.value, 0),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final RegExp _arabicLetterPattern = RegExp(r'[\u0600-\u06FF]');

class _WaitingPatientCard extends StatelessWidget {
  const _WaitingPatientCard({
    required this.patient,
    required this.sequenceNumber,
    required this.onViewPressed,
    required this.onEditPressed,
    required this.onImagesPressed,
    required this.onAddToOperationListPressed,
    this.onRemoveFromOperationListPressed,
    required this.onDeletePressed,
    this.onMoveToFollowUpPressed,
    this.onMoveToAdmissionPressed,
    this.onMoveToStagedOperationsPressed,
    this.onMoveToPicuPressed,
    this.onMoveToNicuPressed,
    this.onMoveToWaitingPressed,
    this.onCallStatusChanged,
  });

  final _WaitingPatient patient;
  final int sequenceNumber;
  final VoidCallback onViewPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onImagesPressed;
  final VoidCallback onAddToOperationListPressed;
  final VoidCallback? onRemoveFromOperationListPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onMoveToFollowUpPressed;
  final VoidCallback? onMoveToAdmissionPressed;
  final VoidCallback? onMoveToStagedOperationsPressed;
  final VoidCallback? onMoveToPicuPressed;
  final VoidCallback? onMoveToNicuPressed;
  final VoidCallback? onMoveToWaitingPressed;
  final ValueChanged<String>? onCallStatusChanged;

  Color _accentColorForStage() {
    switch (patient.workflowStage) {
      case 'picu':
        return const Color(0xFF0F766E);
      case 'nicu':
        return const Color(0xFF2563EB);
      case 'emergency':
        return const Color(0xFFB91C1C);
      case 'follow_up':
        return const Color(0xFF0F766E);
      case 'admission':
        return const Color(0xFF9A3412);
      case 'staged_operations':
        return const Color(0xFF6D28D9);
      case 'waiting':
      default:
        return const Color(0xFF16A34A);
    }
  }

  String _stageLabel() {
    switch (patient.workflowStage) {
      case 'picu':
        return 'PICU';
      case 'nicu':
        return 'NICU';
      case 'emergency':
        return 'Emergency';
      case 'follow_up':
        return 'المتابعة';
      case 'admission':
        return 'الحجز';
      case 'staged_operations':
        return 'العمليات المرحلية';
      case 'waiting':
      default:
        return 'الانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColorForStage();
    final priority = patient.priority.trim();
    final showPriorityBadge = priority.isNotEmpty && priority != 'جديد';
    final showStageBadge = patient.workflowStage != 'waiting';
    final diagnosisHasArabic = _arabicLetterPattern.hasMatch(patient.diagnosis);

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onViewPressed,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                color: const Color(0xFF6082B6),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.48),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.38),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.07),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              constraints: const BoxConstraints(minWidth: 30),
                              height: 28,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '$sequenceNumber',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _MarqueePatientName(name: patient.name),
                                  if (showStageBadge || showPriorityBadge) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (showStageBadge)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(
                                                alpha: 0.16,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _stageLabel(),
                                              style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        if (onCallStatusChanged != null)
                                          _CallStatusButton(
                                            status: patient.callStatus,
                                            onChanged: onCallStatusChanged!,
                                          ),
                                        if (showPriorityBadge)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              priority,
                                              style: const TextStyle(
                                                color: Color(0xFFB91C1C),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (patient.notes.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _PatientNoteBadge(
                                onPressed: () => _showPatientNoteDialog(
                                  context,
                                  patient.notes,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 112),
                              child: _InfoChip(
                                label: patient.diagnosis,
                                accentColor: accentColor,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.82,
                                ),
                                textAlign: diagnosisHasArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                textDirection: diagnosisHasArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                horizontalPadding: 6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PatientActionsMenu(
                                  accentColor: accentColor,
                                  hasPhone: patient.phone.trim().isNotEmpty,
                                  onEditPressed: onEditPressed,
                                  onAddToOperationListPressed:
                                      onAddToOperationListPressed,
                                  onRemoveFromOperationListPressed:
                                      onRemoveFromOperationListPressed,
                                  onCallPressed: () =>
                                      _callPhone(context, patient.phone),
                                  onDeletePressed: onDeletePressed,
                                  onMoveToFollowUpPressed:
                                      onMoveToFollowUpPressed,
                                  onMoveToAdmissionPressed:
                                      onMoveToAdmissionPressed,
                                  onMoveToStagedOperationsPressed:
                                      onMoveToStagedOperationsPressed,
                                  onMoveToPicuPressed: onMoveToPicuPressed,
                                  onMoveToNicuPressed: onMoveToNicuPressed,
                                  onMoveToWaitingPressed:
                                      onMoveToWaitingPressed,
                                ),
                                if (patient.images.isNotEmpty)
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: IconButton(
                                      tooltip: 'عرض صور المريض',
                                      onPressed: onImagesPressed,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 30,
                                            height: 30,
                                          ),
                                      icon: const Icon(
                                        Icons.image_outlined,
                                        color: Colors.white,
                                        size: 21,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.person_pin_outlined,
                                label: patient.doctor,
                                accentColor: const Color(0xFFB7791F),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFF1A8),
                                    Color(0xFFE8A317),
                                  ],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _DateInfoChip(date: patient.date),
                            const SizedBox(width: 6),
                            _AgeInfoChip(age: patient.currentAge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _workflowStageLabel(String stage) => switch (stage) {
  'picu' => 'PICU',
  'nicu' => 'NICU',
  'emergency' => 'Emergency',
  'follow_up' => 'المتابعة',
  'admission' => 'الحجز',
  'staged_operations' => 'العمليات المرحلية',
  _ => 'الانتظار',
};

/// Opened by tapping a patient card: dated operation lines, pictures and notes
/// that can all be edited and saved.
class _PatientDetailsDialog extends StatefulWidget {
  const _PatientDetailsDialog({
    required this.patient,
    required this.imagePage,
    required this.formatDate,
    required this.onSave,
    required this.onEditBasics,
  });

  final _WaitingPatient patient;
  final Future<Widget> Function(String path) imagePage;
  final String Function(DateTime date) formatDate;
  final Future<bool> Function(_WaitingPatient updated) onSave;
  final VoidCallback onEditBasics;

  @override
  State<_PatientDetailsDialog> createState() => _PatientDetailsDialogState();
}

class _OpLine {
  _OpLine(this.date, String text)
    : controller = TextEditingController(text: text);

  String date;
  final TextEditingController controller;
}

class _PatientDetailsDialogState extends State<_PatientDetailsDialog> {
  static const _teal = Color(0xFF087E8B);
  late final List<_OpLine> _lines = [
    for (final entry in widget.patient.opDetails)
      _OpLine(entry.date, entry.text),
  ];
  late final TextEditingController _notes = TextEditingController(
    text: widget.patient.notes,
  );
  late final List<_PatientImageAttachment> _images = [...widget.patient.images];
  final Map<String, Future<Widget>> _thumbnails = {};
  bool _changed = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final line in _lines) {
      line.controller.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_changed) setState(() => _changed = true);
  }

  Future<void> _pickDate(String current, ValueChanged<String> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _changed = true;
      onPicked(widget.formatDate(picked));
    });
  }

  Future<void> _addImages() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _changed = true;
      _images.addAll(
        picked.map(
          (file) => _PatientImageAttachment(
            uploadDate: widget.formatDate(DateTime.now()),
            localFile: file,
          ),
        ),
      );
    });
  }

  Future<Widget> _thumbnailFor(_PatientImageAttachment image) {
    final key = image.localFile?.path ?? image.path!;
    return _thumbnails.putIfAbsent(key, () async {
      final local = image.localFile;
      if (local != null) {
        return Image.memory(await local.readAsBytes(), fit: BoxFit.cover);
      }
      return widget.imagePage(image.path!);
    });
  }

  Future<void> _preview(_PatientImageAttachment image) async {
    final local = image.localFile;
    final page = local != null
        ? Image.memory(await local.readAsBytes(), fit: BoxFit.contain)
        : await widget.imagePage(image.path!);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ImageViewerDialog(
        title: 'صورة المريض',
        pages: [page],
        captions: ['تاريخ الرفع: ${image.uploadDate}'],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.patient.copyWith(
      notes: _notes.text.trim(),
      images: List<_PatientImageAttachment>.from(_images),
      opDetails: [
        for (final line in _lines)
          if (line.controller.text.trim().isNotEmpty)
            _OpDetailEntry(date: line.date, text: line.controller.text.trim()),
      ],
    );
    final saved = await widget.onSave(updated);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _close() async {
    if (_changed) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تجاهل التغييرات؟'),
            content: const Text('لديك تغييرات غير محفوظة.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('متابعة التعديل'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('تجاهل'),
              ),
            ],
          ),
        ),
      );
      if (discard != true || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _teal),
              const SizedBox(width: 6),
              Text(
                title,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _opLineRow(int index) {
    final line = _lines[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _pickDate(line.date, (value) => line.date = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: _teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    line.date.isEmpty ? 'تاريخ' : line.date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: line.controller,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => _markChanged(),
              decoration: const InputDecoration(
                hintText: 'تفاصيل العملية أو الحدث',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'حذف السطر',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() {
              _changed = true;
              _lines.removeAt(index).controller.dispose();
            }),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _imageTile(int index) {
    final image = _images[index];
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _preview(image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 92,
                    height: 92,
                    color: const Color(0xFFE2E8F0),
                    child: FutureBuilder<Widget>(
                      future: _thumbnailFor(image),
                      builder: (context, snapshot) =>
                          snapshot.data ??
                          Center(
                            child: snapshot.hasError
                                ? const Icon(Icons.broken_image_outlined)
                                : const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                          ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: InkWell(
                  onTap: () => setState(() {
                    _changed = true;
                    _images.removeAt(index);
                  }),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Color(0xCC0F172A),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
            ),
            onPressed: () => _pickDate(image.uploadDate, (value) {
              _images[index] = image.copyWith(uploadDate: value);
            }),
            child: Text(image.uploadDate, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 640;
    final info = [
      _workflowStageLabel(patient.workflowStage),
      patient.currentAge,
      patient.doctor,
      patient.diagnosis,
    ].where((part) => part.trim().isNotEmpty).join(' • ');

    final content = Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FA),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF087E8B), Color(0xFF25A77F)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(Icons.child_care_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          info,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE5F7F4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: _saving ? null : _close,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(12),
                children: [
                  _section('OP. Details', Icons.local_hospital_outlined, [
                    if (_lines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'لا توجد تفاصيل بعد. أضف سطراً لكل عملية أو حدث مع تاريخه.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    for (var i = 0; i < _lines.length; i++) _opLineRow(i),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _changed = true;
                          _lines.add(
                            _OpLine(widget.formatDate(DateTime.now()), ''),
                          );
                        }),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة سطر'),
                      ),
                    ),
                  ]),
                  _section('Pictures', Icons.photo_library_outlined, [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _images.length; i++) _imageTile(i),
                        InkWell(
                          onTap: _addImages,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _teal),
                              color: const Color(0xFFE6F4F1),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: _teal,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'إضافة صور',
                                  style: TextStyle(color: _teal, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _section('Notes', Icons.note_alt_outlined, [
                    TextField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      onChanged: (_) => _markChanged(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب ملاحظاتك هنا',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFD9E7EB))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onEditBasics();
                          },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('البيانات الأساسية'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _teal),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (compact) return Dialog.fullscreen(child: content);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(width: 640, height: size.height * 0.9, child: content),
    );
  }
}

class _CallStatusButton extends StatelessWidget {
  const _CallStatusButton({required this.status, required this.onChanged});

  final String status;
  final ValueChanged<String> onChanged;

  static const _options = <(String, String, Color, IconData)>[
    ('called', 'called', Color(0xFF16A34A), Icons.check_circle),
    ('no_reply', 'no reply', Color(0xFFD97706), Icons.phone_missed),
    ('closed', 'closed', Color(0xFFB91C1C), Icons.phone_disabled),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _options.where((o) => o.$1 == status).firstOrNull;
    final color = selected?.$3 ?? const Color(0xFF475569);

    return PopupMenuButton<String>(
      tooltip: 'حالة التواصل',
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final option in _options)
          PopupMenuItem<String>(
            value: option.$1,
            child: Row(
              children: [
                Icon(option.$4, size: 18, color: option.$3),
                const SizedBox(width: 8),
                Text(option.$2),
              ],
            ),
          ),
        if (status.isNotEmpty)
          const PopupMenuItem<String>(value: '', child: Text('إلغاء الحالة')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected == null ? Colors.white : color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected?.$4 ?? Icons.phone_outlined,
              size: 13,
              color: selected == null ? color : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              selected?.$2 ?? 'الاتصال',
              style: TextStyle(
                color: selected == null ? color : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PatientAction {
  edit,
  call,
  addToOperationList,
  removeFromOperationList,
  delete,
  moveToFollowUp,
  moveToAdmission,
  moveToStagedOperations,
  moveToPicu,
  moveToNicu,
  moveToWaiting,
}

class _GoldenScalpelIcon extends StatefulWidget {
  const _GoldenScalpelIcon();

  @override
  State<_GoldenScalpelIcon> createState() => _GoldenScalpelIconState();
}

class _GoldenScalpelIconState extends State<_GoldenScalpelIcon> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(27), painter: _GoldenRingPainter()),
          Icon(Icons.content_cut_rounded, size: 21, color: Color(0xFFFFD54F)),
        ],
      ),
    );
  }
}

class _GoldenRingPainter extends CustomPainter {
  const _GoldenRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final paint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.7,
      1.8,
      false,
      paint,
    );
    paint.color = const Color(0xFFFFF4B0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.2,
      0.8,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PatientActionsMenu extends StatelessWidget {
  const _PatientActionsMenu({
    required this.accentColor,
    required this.hasPhone,
    required this.onEditPressed,
    required this.onAddToOperationListPressed,
    this.onRemoveFromOperationListPressed,
    required this.onCallPressed,
    required this.onDeletePressed,
    this.onMoveToFollowUpPressed,
    this.onMoveToAdmissionPressed,
    this.onMoveToStagedOperationsPressed,
    this.onMoveToPicuPressed,
    this.onMoveToNicuPressed,
    this.onMoveToWaitingPressed,
  });

  final Color accentColor;
  final bool hasPhone;
  final VoidCallback onEditPressed;
  final VoidCallback onAddToOperationListPressed;
  final VoidCallback? onRemoveFromOperationListPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onMoveToFollowUpPressed;
  final VoidCallback? onMoveToAdmissionPressed;
  final VoidCallback? onMoveToStagedOperationsPressed;
  final VoidCallback? onMoveToPicuPressed;
  final VoidCallback? onMoveToNicuPressed;
  final VoidCallback? onMoveToWaitingPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF475569),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: PopupMenuButton<_PatientAction>(
        tooltip: 'إجراءات المريض',
        padding: EdgeInsets.zero,
        icon: const _GoldenScalpelIcon(),
        iconSize: 22,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        splashRadius: 14,
        elevation: 0,
        color: Colors.white,
        iconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (action) {
          switch (action) {
            case _PatientAction.edit:
              onEditPressed();
            case _PatientAction.call:
              onCallPressed();
            case _PatientAction.addToOperationList:
              onAddToOperationListPressed();
            case _PatientAction.removeFromOperationList:
              onRemoveFromOperationListPressed?.call();
            case _PatientAction.delete:
              onDeletePressed();
            case _PatientAction.moveToFollowUp:
              onMoveToFollowUpPressed?.call();
            case _PatientAction.moveToAdmission:
              onMoveToAdmissionPressed?.call();
            case _PatientAction.moveToStagedOperations:
              onMoveToStagedOperationsPressed?.call();
            case _PatientAction.moveToPicu:
              onMoveToPicuPressed?.call();
            case _PatientAction.moveToNicu:
              onMoveToNicuPressed?.call();
            case _PatientAction.moveToWaiting:
              onMoveToWaitingPressed?.call();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _PatientAction.edit,
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined),
              title: Text('تعديل'),
            ),
          ),
          const PopupMenuItem(
            value: _PatientAction.addToOperationList,
            child: ListTile(
              dense: true,
              leading: Icon(Icons.playlist_add_rounded),
              title: Text('Add into list'),
            ),
          ),
          if (onRemoveFromOperationListPressed != null)
            const PopupMenuItem(
              value: _PatientAction.removeFromOperationList,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.playlist_remove_rounded),
                title: Text('إزالة من قوائم العمليات'),
              ),
            ),
          if (hasPhone)
            const PopupMenuItem(
              value: _PatientAction.call,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.call_outlined, color: Color(0xFF15803D)),
                title: Text('اتصال بالمريض'),
              ),
            ),
          if (onMoveToFollowUpPressed != null)
            const PopupMenuItem(
              value: _PatientAction.moveToFollowUp,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.monitor_heart_outlined),
                title: Text('نقل إلى المتابعة'),
              ),
            ),
          if (onMoveToAdmissionPressed != null)
            const PopupMenuItem(
              value: _PatientAction.moveToAdmission,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.assignment_ind_outlined),
                title: Text('نقل إلى الحجز'),
              ),
            ),
          if (onMoveToStagedOperationsPressed != null)
            const PopupMenuItem(
              value: _PatientAction.moveToStagedOperations,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.medical_services_outlined),
                title: Text('نقل إلى العمليات المرحلية'),
              ),
            ),
          if (onMoveToPicuPressed != null)
            const PopupMenuItem(
              value: _PatientAction.moveToPicu,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.local_hospital_outlined),
                title: Text('نقل إلى PICU'),
              ),
            ),
          if (onMoveToNicuPressed != null)
            const PopupMenuItem(
              value: _PatientAction.moveToNicu,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.child_care_outlined),
                title: Text('نقل إلى NICU'),
              ),
            ),
          if (onMoveToWaitingPressed != null)
            const PopupMenuItem(
              value: _PatientAction.moveToWaiting,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.list_alt_rounded),
                title: Text('إعادة إلى الانتظار'),
              ),
            ),
          const PopupMenuItem(
            value: _PatientAction.delete,
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline, color: Color(0xFFB91C1C)),
              title: Text('حذف'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    this.icon,
    required this.label,
    this.accentColor = const Color(0xFF47607A),
    this.gradient,
    this.backgroundColor,
    this.textAlign,
    this.textDirection,
    this.horizontalPadding = 10,
  });

  final IconData? icon;
  final String label;
  final Color accentColor;
  final Gradient? gradient;
  final Color? backgroundColor;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? accentColor.withValues(alpha: 0.08))
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.10)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                softWrap: true,
                textAlign: textAlign,
                textDirection: textDirection,
                style: const TextStyle(
                  color: Color(0xFF16324F),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInfoChip extends StatelessWidget {
  const _DateInfoChip({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    final parts = date.split('-');
    final month = parts.length >= 2 ? parts[1] : date;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: parts.isNotEmpty ? parts.first : '',
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
                const TextSpan(
                  text: '-',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                TextSpan(
                  text: month,
                  style: const TextStyle(color: Color(0xFFEA580C)),
                ),
                if (parts.length >= 3) ...[
                  const TextSpan(
                    text: '-',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  TextSpan(
                    text: parts[2],
                    style: const TextStyle(color: Color(0xFF334155)),
                  ),
                ],
              ],
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeInfoChip extends StatelessWidget {
  const _AgeInfoChip({required this.age});

  final String age;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF7E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7E4C7)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              age,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF5B6B7B)),
          ),
        ],
      ),
    );
  }
}

class _WaitingListErrorState extends StatelessWidget {
  const _WaitingListErrorState({
    required this.message,
    required this.onRetryPressed,
  });

  final String message;
  final Future<void> Function() onRetryPressed;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetryPressed,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _NetworkZoomImage extends StatelessWidget {
  const _NetworkZoomImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  const _ImageViewerDialog({
    required this.title,
    required this.pages,
    required this.captions,
  });

  final String title;
  final List<Widget> pages;
  final List<String> captions;

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'إغلاق',
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.pages.length > 1
                          ? '${widget.title} (${_index + 1}/${widget.pages.length})'
                          : widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: widget.pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) =>
                    _ZoomableImage(child: widget.pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.captions[_index],
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.child});

  final Widget child;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  static const double _doubleTapScale = 2.5;

  final TransformationController _controller = TransformationController();
  Offset _doubleTapPosition = Offset.zero;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _controller.value = Matrix4.identity();
      return;
    }
    final scale = _doubleTapScale;
    _controller.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        -_doubleTapPosition.dx * (scale - 1),
        -_doubleTapPosition.dy * (scale - 1),
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 6,
        panEnabled: _isZoomed,
        child: Center(child: widget.child),
      ),
    );
  }
}

class _PatientImageAttachment {
  const _PatientImageAttachment({
    this.path,
    required this.uploadDate,
    this.localFile,
  });

  factory _PatientImageAttachment.fromJson(Map<String, dynamic> json) {
    return _PatientImageAttachment(
      path: json['path'] as String,
      uploadDate: (json['upload_date'] ?? '') as String,
    );
  }

  final String? path;
  final String uploadDate;
  final XFile? localFile;

  _PatientImageAttachment copyWith({
    String? path,
    String? uploadDate,
    XFile? localFile,
    bool clearLocalFile = false,
  }) {
    return _PatientImageAttachment(
      path: path ?? this.path,
      uploadDate: uploadDate ?? this.uploadDate,
      localFile: clearLocalFile ? null : localFile ?? this.localFile,
    );
  }

  Map<String, dynamic> toJson() => {'path': path, 'upload_date': uploadDate};
}

class _WaitingPatient {
  const _WaitingPatient({
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

  factory _WaitingPatient.fromRepository(
    PediatricSurgeryWaitingPatient patient,
  ) {
    return _WaitingPatient(
      id: patient.id,
      name: patient.name,
      age: patient.age,
      diagnosis: patient.diagnosis,
      doctor: patient.doctor,
      date: patient.date,
      priority: patient.priority,
      workflowStage: patient.workflowStage,
      phone: patient.phone,
      notes: patient.notes,
      images: patient.images
          .map(_PatientImageAttachment.fromJson)
          .toList(growable: false),
      operationListDate: patient.operationListDate,
      callStatus: patient.callStatus,
      createdAt: patient.createdAt,
      opDetails: patient.opDetails
          .map(_OpDetailEntry.fromJson)
          .toList(growable: false),
      hasOpDetailsColumn: patient.hasOpDetailsColumn,
    );
  }

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
  final List<_PatientImageAttachment> images;
  final String? operationListDate;
  final String callStatus;
  final DateTime? createdAt;
  final List<_OpDetailEntry> opDetails;
  final bool hasOpDetailsColumn;

  /// The stored age is the age on the registration date; this adds the time
  /// elapsed since then so the displayed age stays current.
  String get currentAge => _ageSinceRegistration(
    age: age,
    registrationDate: DateTime.tryParse(date) ?? createdAt,
  );

  _WaitingPatient copyWith({
    String? id,
    String? name,
    String? age,
    String? diagnosis,
    String? doctor,
    String? date,
    String? priority,
    String? workflowStage,
    String? phone,
    String? notes,
    List<_PatientImageAttachment>? images,
    String? operationListDate,
    bool clearOperationListDate = false,
    String? callStatus,
    DateTime? createdAt,
    List<_OpDetailEntry>? opDetails,
  }) {
    return _WaitingPatient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      diagnosis: diagnosis ?? this.diagnosis,
      doctor: doctor ?? this.doctor,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      workflowStage: workflowStage ?? this.workflowStage,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      operationListDate: clearOperationListDate
          ? null
          : operationListDate ?? this.operationListDate,
      callStatus: callStatus ?? this.callStatus,
      createdAt: createdAt ?? this.createdAt,
      opDetails: opDetails ?? this.opDetails,
      hasOpDetailsColumn: hasOpDetailsColumn,
    );
  }

  PediatricSurgeryWaitingPatient toRepositoryModel() {
    return PediatricSurgeryWaitingPatient(
      id: id,
      name: name,
      age: age,
      diagnosis: diagnosis,
      doctor: doctor,
      date: date,
      priority: priority,
      workflowStage: workflowStage,
      phone: phone,
      notes: notes,
      images: images.map((image) => image.toJson()).toList(growable: false),
      operationListDate: operationListDate,
      callStatus: callStatus,
      opDetails: opDetails
          .map((entry) => entry.toJson())
          .toList(growable: false),
      hasOpDetailsColumn: hasOpDetailsColumn,
    );
  }
}

/// One dated line of a patient's operation / event log.
class _OpDetailEntry {
  const _OpDetailEntry({required this.date, required this.text});

  factory _OpDetailEntry.fromJson(Map<String, dynamic> json) => _OpDetailEntry(
    date: (json['date'] ?? '') as String,
    text: (json['text'] ?? '') as String,
  );

  final String date;
  final String text;

  Map<String, dynamic> toJson() => {'date': date, 'text': text};
}

String _ageSinceRegistration({
  required String age,
  required DateTime? registrationDate,
  DateTime? now,
}) {
  if (registrationDate == null) return age;

  int readUnit(List<String> units) {
    final pattern = units.map(RegExp.escape).join('|');
    final match = RegExp('([0-9]+)\\s+(?:$pattern)').firstMatch(age);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  final years = readUnit(['سنة', 'سنه', 'yr', 'yrs', 'year', 'years']);
  final months = readUnit([
    'شهر',
    'شهور',
    'mth',
    'mths',
    'mo',
    'mos',
    'month',
    'months',
  ]);
  final days = readUnit(['يوم', 'ايام', 'day', 'days']);
  if (years == 0 && months == 0 && days == 0) return age;

  final today = now ?? DateTime.now();
  final end = DateTime(today.year, today.month, today.day);
  final start = DateTime(
    registrationDate.year,
    registrationDate.month,
    registrationDate.day,
  );
  if (!end.isAfter(start)) return age;

  // Equivalent birth date implied by the age recorded on the registration date.
  final birth = DateTime(
    start.year - years,
    start.month - months,
    start.day - days,
  );

  var currentYears = end.year - birth.year;
  var currentMonths = end.month - birth.month;
  var currentDays = end.day - birth.day;
  if (currentDays < 0) {
    currentMonths -= 1;
    currentDays += DateTime(end.year, end.month, 0).day;
  }
  if (currentMonths < 0) {
    currentYears -= 1;
    currentMonths += 12;
  }

  final parts = <String>[
    if (currentYears > 0) '$currentYears yr',
    if (currentMonths > 0) '$currentMonths mth',
    if (currentYears == 0 && currentDays > 0) '$currentDays day',
  ];
  return parts.isEmpty ? '0 day' : parts.join(' ');
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _PediatricHeaderCard extends StatelessWidget {
  const _PediatricHeaderCard({
    this.title = 'جراحة الأطفال',
    required this.waitingCount,
    required this.followUpCount,
    required this.admissionCount,
    this.showDoctorName = true,
  });

  final String title;
  final int waitingCount;
  final int followUpCount;
  final int admissionCount;
  final bool showDoctorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC145), Color(0xFFEF4444)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22EF4444),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.child_friendly_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      showDoctorName
                          ? 'تنظيم قائمة الانتظار والمتابعة والحجز تحت إشراف'
                          : 'تنظيم قائمة الانتظار والمتابعة والحجز',
                      style: const TextStyle(
                        color: Color(0xFFFFF7ED),
                        fontSize: 14,
                      ),
                    ),
                    if (showDoctorName) ...[
                      SizedBox(height: 9),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.72),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.26),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _HealthInsuranceShieldLogo(),
                              SizedBox(width: 7),
                              Text(
                                'الدكتور أحمد بك أبو الحسب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderMetricCard(
                  label: 'waiting',
                  value: waitingCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetricCard(
                  label: 'follow up',
                  value: followUpCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetricCard(
                  label: 'addmission',
                  value: admissionCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  const _EcgPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.5;
    final unit = size.width / 12;
    final path = Path()..moveTo(0, y);
    for (var i = 0; i < 12; i += 4) {
      final x = i * unit;
      path
        ..lineTo(x + unit * 0.9, y)
        ..lineTo(x + unit * 1.2, y - size.height * 0.18)
        ..lineTo(x + unit * 1.5, y + size.height * 0.12)
        ..lineTo(x + unit * 1.85, y - size.height * 0.95)
        ..lineTo(x + unit * 2.2, y + size.height * 0.6)
        ..lineTo(x + unit * 2.5, y)
        ..lineTo(x + unit * 3.1, y - size.height * 0.16)
        ..lineTo(x + unit * 3.5, y)
        ..lineTo(x + unit * 4, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter oldDelegate) => oldDelegate.color != color;
}

class _ModernDoctorCard extends StatefulWidget {
  const _ModernDoctorCard({
    this.badge = 'استشاري جراحة أطفال',
    required this.name,
    required this.colors,
    required this.accent,
    required this.waitingCount,
    required this.followUpCount,
    required this.admissionCount,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String badge;
  final String name;
  final List<Color> colors;
  final Color accent;
  final int waitingCount;
  final int followUpCount;
  final int admissionCount;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<_ModernDoctorCard> createState() => _ModernDoctorCardState();
}

class _ModernDoctorCardState extends State<_ModernDoctorCard> {
  static const _waitingColor = Color(0xFFFFC145);
  static const _followUpColor = Color(0xFF22D3EE);
  static const _admissionColor = Color(0xFF34D399);

  bool _hovered = false;
  bool _pressed = false;

  String get _initial {
    final cleaned = widget.name
        .replaceAll(RegExp(r'^(أ\.\s*)?د\.?\s*'), '')
        .trim();
    return cleaned.isEmpty ? '؟' : String.fromCharCode(cleaned.runes.first);
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.7),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _caseloadBar(int total) {
    Widget segment(int value, Color color) => Expanded(
      flex: value,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 8),
          ],
        ),
      ),
    );

    return SizedBox(
      height: 8,
      child: total == 0
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
            )
          : Row(
              children: [
                if (widget.waitingCount > 0)
                  segment(widget.waitingCount, _waitingColor),
                if (widget.followUpCount > 0)
                  segment(widget.followUpCount, _followUpColor),
                if (widget.admissionCount > 0)
                  segment(widget.admissionCount, _admissionColor),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.colors.first;
    final glow = widget.colors.last;
    final total =
        widget.waitingCount + widget.followUpCount + widget.admissionCount;
    final dark = Color.lerp(base, const Color(0xFF020617), 0.62)!;
    final darker = Color.lerp(base, const Color(0xFF020617), 0.86)!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovered ? 1.015 : 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [dark, darker],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              border: Border.all(
                color: glow.withValues(alpha: _hovered ? 0.8 : 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: _hovered ? 0.5 : 0.28),
                  blurRadius: _hovered ? 34 : 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: -60,
                    end: -50,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            glow.withValues(alpha: 0.55),
                            glow.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: -30,
                    start: -30,
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  Positioned.fill(
                    top: 70,
                    bottom: 130,
                    child: CustomPaint(
                      painter: _EcgPainter(glow.withValues(alpha: 0.28)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    _waitingColor,
                                    glow,
                                    _followUpColor,
                                    _admissionColor,
                                    _waitingColor,
                                  ],
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: darker,
                                ),
                                child: Text(
                                  _initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      widget.badge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              'إجمالي الحالات',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              total.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _caseloadBar(total),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _stat('انتظار', widget.waitingCount, _waitingColor),
                            _stat(
                              'متابعة',
                              widget.followUpCount,
                              _followUpColor,
                            ),
                            _stat(
                              'حجز',
                              widget.admissionCount,
                              _admissionColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: _hovered
                                  ? [glow, widget.colors.first]
                                  : [
                                      Colors.white.withValues(alpha: 0.14),
                                      Colors.white.withValues(alpha: 0.06),
                                    ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'فتح قائمة الطبيب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onEdit != null || widget.onDelete != null)
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: PopupMenuButton<String>(
                        tooltip: 'إدارة القائمة',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') widget.onEdit?.call();
                          if (value == 'delete') widget.onDelete?.call();
                        },
                        itemBuilder: (_) => [
                          if (widget.onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('تعديل البطاقة'),
                            ),
                          if (widget.onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('حذف القائمة'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorProfileCard extends StatefulWidget {
  const _DoctorProfileCard({
    required this.name,
    required this.colors,
    required this.accent,
    required this.waitingCount,
    required this.followUpCount,
    required this.admissionCount,
    required this.onTap,
  });

  final String name;
  final List<Color> colors;
  final Color accent;
  final int waitingCount;
  final int followUpCount;
  final int admissionCount;
  final VoidCallback onTap;

  @override
  State<_DoctorProfileCard> createState() => _DoctorProfileCardState();
}

class _DoctorProfileCardState extends State<_DoctorProfileCard> {
  bool _pressed = false;

  Widget _statRing(String label, int value, int total, IconData icon) {
    final accent = widget.accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 4,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  SizedBox.expand(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: total == 0 ? 0 : value / total,
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, _) =>
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            strokeCap: StrokeCap.round,
                            color: accent,
                          ),
                    ),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final base = Color.lerp(widget.colors.first, Colors.black, 0.45)!;
    final glow = widget.colors.last;
    final total =
        widget.waitingCount + widget.followUpCount + widget.admissionCount;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - value)),
          child: child,
        ),
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 140),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                colors: [base, widget.colors.first, glow],
                stops: const [0, 0.55, 1],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HeartbeatPainter(color: accent),
                    ),
                  ),
                  Positioned(
                    top: -40,
                    left: -36,
                    child: Icon(
                      Icons.add_rounded,
                      size: 190,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    right: -50,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.35),
                            accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [accent, Colors.white, glow, accent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.55),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Colors.white, accent],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Icon(
                                  Icons.health_and_safety_rounded,
                                  size: 38,
                                  color: base,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 13,
                                            color: accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'استشاري جراحة الأطفال',
                                            style: TextStyle(
                                              color: accent,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x14000000),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFFFD54F),
                                        width: 1.4,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x66FFD54F),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(
                                            color: Color(0x66000000),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _statRing(
                              'الانتظار',
                              widget.waitingCount,
                              total,
                              Icons.hourglass_bottom_rounded,
                            ),
                            const SizedBox(width: 8),
                            _statRing(
                              'المتابعة',
                              widget.followUpCount,
                              total,
                              Icons.event_repeat_rounded,
                            ),
                            const SizedBox(width: 8),
                            _statRing(
                              'الحجز',
                              widget.admissionCount,
                              total,
                              Icons.bed_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [Colors.white, accent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'دخول إلى صفحة الطبيب',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: base,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_back_rounded,
                                color: base,
                                size: 20,
                              ),
                            ],
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
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  const _HeartbeatPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.5;
    final unit = size.width / 12;
    final path = Path()..moveTo(0, y);
    path
      ..lineTo(unit * 3, y)
      ..lineTo(unit * 3.6, y - 14)
      ..lineTo(unit * 4.2, y + 12)
      ..lineTo(unit * 5, y - 58)
      ..lineTo(unit * 5.8, y + 46)
      ..lineTo(unit * 6.5, y)
      ..lineTo(unit * 7.4, y - 12)
      ..lineTo(unit * 8, y)
      ..lineTo(size.width, y);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) =>
      oldDelegate.color != color;
}
