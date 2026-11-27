import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hospmaster/auth/account_button.dart';
import 'package:image_picker/image_picker.dart';

import 'custom_field_options.dart';
import 'patient_record.dart';
import 'patient_repository.dart';

export 'patient_record.dart';

class PatientFollowUpSheetPage extends StatefulWidget {
  final SurgeryPatientRepository? repository;

  const PatientFollowUpSheetPage({super.key, this.repository});

  @override
  State<PatientFollowUpSheetPage> createState() =>
      _PatientFollowUpSheetPageState();
}

class _PatientFollowUpSheetPageState extends State<PatientFollowUpSheetPage> {
  late final SurgeryPatientRepository _repository =
      widget.repository ?? SurgeryPatientRepository();

  Future<void> _addPatient() async {
    final patient = await Navigator.of(context).push<PatientRecord>(
      MaterialPageRoute(
        builder: (_) => PatientDetailsPage(
          isNew: true,
          department: SurgeryDepartment.general,
          repository: _repository,
          patient: const PatientRecord(
            department: SurgeryDepartment.general,
            name: '',
            fileNumber: '',
            roomNumber: '',
            diagnosis: '',
            statusLabel: 'جديد',
            accentColor: Color(0xFF1E6FD9),
          ),
        ),
      ),
    );
    if (patient == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ المريض في قسم الجراحة العامة.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            title: const Text('قسم الجراحة العامة'),
            actions: const [AccountButton()],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TabBar(
                    isScrollable: false,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E6FD9), Color(0xFF22A38A)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF47607A),
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(18),
                    tabs: const [
                      Tab(text: 'حجز نشط'),
                      Tab(text: 'طوارئ'),
                      Tab(text: 'خروج'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      Center(
                        child: FilledButton.icon(
                          onPressed: _addPatient,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('إضافة مريض'),
                        ),
                      ),
                      _buildTabPlaceholder(
                        context,
                        title: 'الطوارئ',
                        description:
                            'يمكنك هنا لاحقًا تسجيل الحالات الحرجة، تقييم الوصول السريع، والإجراءات العاجلة داخل القسم.',
                        icon: Icons.emergency_outlined,
                      ),
                      _buildTabPlaceholder(
                        context,
                        title: 'الخروج',
                        description:
                            'يمكنك هنا لاحقًا تسجيل قرار الخروج، التعليمات النهائية، وموعد المراجعة بعد العملية.',
                        icon: Icons.logout_outlined,
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

  Widget _buildTabPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientDetailsPage extends StatefulWidget {
  final PatientRecord patient;
  final String department;
  final SurgeryPatientRepository? repository;

  /// When true the page works as an "add patient" form: it starts blank and
  /// saves a new record to Supabase. Otherwise it edits [patient].
  final bool isNew;

  const PatientDetailsPage({
    super.key,
    required this.patient,
    this.department = SurgeryDepartment.general,
    this.repository,
    this.isNew = false,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  static const List<String> _signOptions = [
    'Fever',
    'Tachycardia',
    'Bradycardia',
    'Tachypnea',
    'Hypotension',
    'Hypertension',
    'Pallor',
    'Jaundice',
    'Cyanosis',
    'Dehydration',
    'Edema',
    'Bleeding',
    'Discharge',
    'Abdominal distension',
    'Tenderness',
    'Rebound tenderness',
    'Guarding',
    'Rigidity',
    'Swelling',
    'Redness',
    'Warmth',
    'Wound gaping',
  ];
  static const List<String> _symptomOptions = [
    'Pain',
    'Abdominal pain',
    'Chest pain',
    'Headache',
    'Nausea',
    'Vomiting',
    'Dizziness',
    'Shortness of breath',
    'Cough',
    'Palpitations',
    'Fatigue',
    'Loss of appetite',
    'Constipation',
    'Diarrhea',
    'Dysuria',
    'Hematuria',
    'Back pain',
    'Wound pain',
    'Numbness',
    'Weakness',
    'Insomnia',
    'Itching',
  ];
  static const List<String> _pastHistoryOptions = [
    'DM',
    'HTN',
    'IHD',
    'Rheumatoid disease',
    'Bronchial asthma',
    'Chronic kidney disease',
    'Chronic liver disease',
    'Thyroid disease',
    'Epilepsy',
    'Tuberculosis',
  ];
  static const List<String> _operationHistoryOptions = [
    'Appendectomy',
    'Cholecystectomy',
    'Cesarean section',
    'Hernia repair',
    'Thyroid surgery',
    'Laparotomy',
    'Cardiac surgery',
    'Orthopedic surgery',
    'Neurosurgery',
    'No previous operations',
  ];
  static const List<String> _surgicalDiagnosisOptions = [
    'Acute appendicitis',
    'Inguinal hernia',
    'Intestinal obstruction',
    'Acute cholecystitis',
    'Cholelithiasis',
    'Peritonitis',
    'Hemorrhoids',
    'Anal fissure',
    'Pilonidal sinus',
    'Breast lump',
    'Thyroid nodule',
    'Varicose veins',
    'Diabetic foot',
    'Peripheral vascular disease',
    'Hydrocele',
    'Undescended testis',
    'Acute pancreatitis',
    'Peptic perforation',
    'Colorectal mass',
    'Postoperative wound infection',
    'التهاب زائدة حاد',
    'فتق أربي',
  ];
  static const List<_DrugCatalogEntry> _egyptianDrugCatalog = [
    _DrugCatalogEntry(
      tradeName: 'Cataflam',
      genericName: 'Diclofenac potassium',
      strength: '50 mg tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Voltaren',
      genericName: 'Diclofenac sodium',
      strength: '75 mg ampoule / gel',
    ),
    _DrugCatalogEntry(
      tradeName: 'Ketolac',
      genericName: 'Ketorolac',
      strength: '30 mg ampoule / 10 mg tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Perfalgan',
      genericName: 'Paracetamol',
      strength: '1 g infusion',
    ),
    _DrugCatalogEntry(
      tradeName: 'Panadol',
      genericName: 'Paracetamol',
      strength: '500 mg tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Augmentin',
      genericName: 'Amoxicillin + Clavulanic acid',
      strength: '1 g tablet / 1.2 g vial',
    ),
    _DrugCatalogEntry(
      tradeName: 'Unasyn',
      genericName: 'Ampicillin + Sulbactam',
      strength: '1.5 g vial',
    ),
    _DrugCatalogEntry(
      tradeName: 'Rocephin',
      genericName: 'Ceftriaxone',
      strength: '1 g vial',
    ),
    _DrugCatalogEntry(
      tradeName: 'Cefotax',
      genericName: 'Cefotaxime',
      strength: '1 g vial',
    ),
    _DrugCatalogEntry(
      tradeName: 'Flagyl',
      genericName: 'Metronidazole',
      strength: '500 mg infusion / tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Ciprocin',
      genericName: 'Ciprofloxacin',
      strength: '500 mg tablet / 200 mg infusion',
    ),
    _DrugCatalogEntry(
      tradeName: 'Tavanic',
      genericName: 'Levofloxacin',
      strength: '500 mg tablet / infusion',
    ),
    _DrugCatalogEntry(
      tradeName: 'Controloc',
      genericName: 'Pantoprazole',
      strength: '40 mg vial / tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Nexium',
      genericName: 'Esomeprazole',
      strength: '40 mg vial / tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Primperan',
      genericName: 'Metoclopramide',
      strength: '10 mg ampoule / tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Zofran',
      genericName: 'Ondansetron',
      strength: '4 mg ampoule / tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Clexane',
      genericName: 'Enoxaparin',
      strength: '40 mg prefilled syringe',
    ),
    _DrugCatalogEntry(
      tradeName: 'Lovenox',
      genericName: 'Enoxaparin',
      strength: '40 mg prefilled syringe',
    ),
    _DrugCatalogEntry(
      tradeName: 'Concor',
      genericName: 'Bisoprolol',
      strength: '5 mg tablet',
    ),
    _DrugCatalogEntry(
      tradeName: 'Amrizole',
      genericName: 'Metronidazole',
      strength: '500 mg tablet / suspension',
    ),
  ];
  static const List<String> _labOptions = [
    'CBC',
    'Hemoglobin',
    'TLC',
    'Platelets',
    'CRP',
    'ESR',
    'PT',
    'PTT',
    'INR',
    'RBS',
    'HbA1c',
    'Urea',
    'Creatinine',
    'Sodium',
    'Potassium',
    'ALT',
    'AST',
    'Total bilirubin',
    'Direct bilirubin',
    'Albumin',
    'Amylase',
    'Lipase',
    'ABG',
    'Urinalysis',
    'Stool analysis',
    'Blood culture',
    'Wound swab culture',
    'Cross match',
    'D-dimer',
    'Lactate',
  ];
  static const List<String> _imagingOptions = [
    'Chest X-ray',
    'Abdominal X-ray',
    'Pelvic X-ray',
    'Breast ultrasound',
    'Abdominal ultrasound',
    'Pelvic ultrasound',
    'Thyroid ultrasound',
    'Doppler study',
    'CT brain',
    'CT chest',
    'CT abdomen and pelvis',
    'CT angiography',
    'MRI brain',
    'MRI spine',
    'MRCP',
    'Echocardiography',
    'Mammography',
    'Endoscopy',
    'Colonoscopy',
  ];
  static const List<String> _consciousLevelOptions = [
    'fully conscious',
    'drowsy',
    'confused',
    'responds to voice',
    'responds to pain',
    'unconscious',
  ];
  static const List<String> _doctorOptions = [
    'د. عبد العظيم علي',
    'د. أحمد سعد',
    'د. يحيى محفوظ',
    'د. أحمد رمضان',
    'د. رمضان إبراهيم',
    'د. محمد رضا',
    'د. أحمد خيري',
    'د. نبيل عبد اللطيف',
    'د. محمد ابراهيم',
    'د. حسام صبحي',
    'د. محمد العليمي',
  ];

  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _residenceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _fileNumberController;
  late final TextEditingController _roomNumberController;
  late final TextEditingController _diagnosisController;
  final TextEditingController _lastOperativeDetailsController =
      TextEditingController();
  final TextEditingController _currentTreatmentController =
      TextEditingController();
  final TextEditingController _currentDoseController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _rrController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _doctorOrderController = TextEditingController();
  final List<VitalReading> _vitalReadings = [];
  final List<DoctorOrder> _doctorOrders = [];
  DateTime _vitalDate = DateTime.now();
  VitalShift _vitalShift = DateTime.now().hour < 12
      ? VitalShift.morning
      : VitalShift.evening;
  final List<String> _customSignOptions = [];
  final List<String> _customSymptomOptions = [];
  final List<String> _customPastHistoryOptions = [];
  final List<String> _customOperationHistoryOptions = [];
  final List<String> _customLabOptions = [];
  final List<String> _customImagingOptions = [];
  final List<String> _customDiagnosisOptions = [];
  final List<String> _customDoctorOptions = [];
  final List<String> _customConsciousLevelOptions = [];
  List<String> _selectedSigns = [];
  List<String> _selectedSymptoms = [];
  List<String> _selectedPastHistory = [];
  List<String> _selectedOperationHistory = [];
  final List<String> _selectedLabs = [];
  final List<String> _selectedImaging = [];
  final Map<String, TextEditingController> _labResultControllers = {};
  final Map<String, TextEditingController> _imagingResultControllers = {};
  final Map<String, Uint8List> _labImageBytes = {};
  final Map<String, String> _labImageNames = {};
  final Map<String, Uint8List> _imagingImageBytes = {};
  final Map<String, String> _imagingImageNames = {};
  late String _selectedDiagnosis;
  _DrugCatalogEntry? _selectedDrugEntry;
  String? _selectedLabToAdd;
  String? _selectedImagingToAdd;
  late String _selectedDoctor;
  String _selectedConsciousLevel = _consciousLevelOptions.first;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _photoPath;
  bool _photoChanged = false;
  bool _isSaving = false;
  final Map<String, String> _labImagePaths = {};
  final Map<String, String> _imagingImagePaths = {};
  late final SurgeryPatientRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SurgeryPatientRepository();
    final patient = widget.patient;
    _nameController = TextEditingController(text: patient.name);
    _residenceController = TextEditingController(text: patient.residence);
    _phoneController = TextEditingController(text: patient.phone);
    _fileNumberController = TextEditingController(text: patient.fileNumber);
    _roomNumberController = TextEditingController(text: patient.roomNumber);
    _diagnosisController = TextEditingController(text: patient.diagnosis);
    _selectedDiagnosis = patient.diagnosis;

    _selectedDoctor = patient.doctor.isNotEmpty
        ? patient.doctor
        : _doctorOptions.first;

    _lastOperativeDetailsController.text = patient.lastOperativeDetails;
    _currentTreatmentController.text = patient.currentTreatment;
    _currentDoseController.text = patient.currentDose;

    _selectedSigns = List.of(patient.signs);
    _selectedSymptoms = List.of(patient.symptoms);
    _selectedPastHistory = List.of(patient.pastHistory);
    _selectedOperationHistory = List.of(patient.operationHistory);
    _restoreCustomOptions(_selectedSigns, _signOptions, _customSignOptions);
    _restoreCustomOptions(
      _selectedSymptoms,
      _symptomOptions,
      _customSymptomOptions,
    );
    _restoreCustomOptions(
      _selectedPastHistory,
      _pastHistoryOptions,
      _customPastHistoryOptions,
    );
    _restoreCustomOptions(
      _selectedOperationHistory,
      _operationHistoryOptions,
      _customOperationHistoryOptions,
    );

    _vitalReadings.addAll(patient.vitalReadings);
    _doctorOrders.addAll(
      patient.doctorOrders.map(
        (order) => DoctorOrder(
          text: order.text,
          createdAt: order.createdAt,
          done: order.done,
        ),
      ),
    );

    for (final lab in patient.labs) {
      _selectedLabs.add(lab.name);
      _labResultControllers[lab.name] = TextEditingController(text: lab.result);
      _storeExistingAttachment(lab, _labImagePaths, _labImageNames);
    }
    for (final study in patient.imaging) {
      _selectedImaging.add(study.name);
      _imagingResultControllers[study.name] = TextEditingController(
        text: study.result,
      );
      _storeExistingAttachment(study, _imagingImagePaths, _imagingImageNames);
    }
    _restoreCustomOptions(_selectedLabs, _labOptions, _customLabOptions);
    _restoreCustomOptions(
      _selectedImaging,
      _imagingOptions,
      _customImagingOptions,
    );

    _photoPath = patient.photoPath;
    _selectedImageName = patient.photoName;
    if (_photoPath != null) {
      _loadExistingPhoto(_photoPath!);
    }

    _syncStoredOptions();
    CustomFieldOptions.instance.load().then((_) {
      if (!mounted) return;
      setState(_syncStoredOptions);
    });
  }

  /// Pulls items added earlier (by any patient form) into this form's lists.
  void _syncStoredOptions() {
    final store = CustomFieldOptions.instance;
    void merge(String field, List<String> base, List<String> custom) {
      for (final value in store.of(field)) {
        if (!base.contains(value) && !custom.contains(value)) {
          custom.add(value);
        }
      }
    }

    merge('sign', _signOptions, _customSignOptions);
    merge('symptom', _symptomOptions, _customSymptomOptions);
    merge('past_history', _pastHistoryOptions, _customPastHistoryOptions);
    merge(
      'operation_history',
      _operationHistoryOptions,
      _customOperationHistoryOptions,
    );
    merge('lab', _labOptions, _customLabOptions);
    merge('imaging', _imagingOptions, _customImagingOptions);
    merge('diagnosis', _surgicalDiagnosisOptions, _customDiagnosisOptions);
    merge('doctor', _doctorOptions, _customDoctorOptions);
    merge(
      'conscious_level',
      _consciousLevelOptions,
      _customConsciousLevelOptions,
    );
  }

  /// Keeps a newly added item in this form and saves it for later patients.
  void _rememberCustomOption(
    String field,
    List<String> customOptions,
    String option,
  ) {
    if (!customOptions.contains(option)) customOptions.add(option);
    CustomFieldOptions.instance.add(field, option);
  }

  List<String> _optionsWithCustom(
    List<String> base,
    List<String> custom, [
    String? current,
  ]) {
    return [
      if (current != null &&
          current.isNotEmpty &&
          !base.contains(current) &&
          !custom.contains(current))
        current,
      ...base,
      ...custom,
    ];
  }

  void _restoreCustomOptions(
    List<String> selected,
    List<String> baseOptions,
    List<String> customOptions,
  ) {
    for (final value in selected) {
      if (!baseOptions.contains(value) && !customOptions.contains(value)) {
        customOptions.add(value);
      }
    }
  }

  void _storeExistingAttachment(
    PatientTest test,
    Map<String, String> paths,
    Map<String, String> names,
  ) {
    if (test.imagePath != null) {
      paths[test.name] = test.imagePath!;
      names[test.name] = test.imageName ?? test.imagePath!.split('/').last;
    }
  }

  Future<void> _loadExistingPhoto(String path) async {
    try {
      final bytes = await _repository.downloadFile(path);
      if (!mounted || _photoPath != path) return;
      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      // The photo preview is optional; the stored path is kept regardless.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _residenceController.dispose();
    _phoneController.dispose();
    _fileNumberController.dispose();
    _roomNumberController.dispose();
    _diagnosisController.dispose();
    _lastOperativeDetailsController.dispose();
    _currentTreatmentController.dispose();
    _currentDoseController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    _rrController.dispose();
    _spo2Controller.dispose();
    _tempController.dispose();
    _doctorOrderController.dispose();
    for (final controller in _labResultControllers.values) {
      controller.dispose();
    }
    for (final controller in _imagingResultControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _savePatient() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل اسم المريض')),
      );
      return;
    }

    // Keep values the user typed but did not add to the daily logs yet.
    if (VitalReading(
      date: _vitalDate,
      shift: _vitalShift,
      bp: _bpController.text.trim(),
      hr: _hrController.text.trim(),
      rr: _rrController.text.trim(),
      spo2: _spo2Controller.text.trim(),
      temp: _tempController.text.trim(),
      consciousLevel: _selectedConsciousLevel,
    ).hasValues) {
      _addVitalReading();
    }
    if (_doctorOrderController.text.trim().isNotEmpty) {
      _addDoctorOrder();
    }

    setState(() => _isSaving = true);
    final uploadedPaths = <String>[];

    Future<PatientTest> buildTest({
      required String testName,
      required Map<String, TextEditingController> resultControllers,
      required Map<String, Uint8List> imageBytes,
      required Map<String, String> imageNames,
      required Map<String, String> imagePaths,
    }) async {
      final bytes = imageBytes[testName];
      if (bytes != null) {
        final path = await _repository.uploadFile(
          bytes,
          imageNames[testName] ?? '$testName.jpg',
        );
        uploadedPaths.add(path);
        imagePaths[testName] = path;
      }
      return PatientTest(
        name: testName,
        result: resultControllers[testName]?.text.trim() ?? '',
        imagePath: imagePaths[testName],
        imageName: imageNames[testName],
      );
    }

    try {
      var photoPath = _photoPath;
      if (_photoChanged && _selectedImageBytes != null) {
        photoPath = await _repository.uploadFile(
          _selectedImageBytes!,
          _selectedImageName ?? 'patient.jpg',
        );
        uploadedPaths.add(photoPath);
      }

      final labs = <PatientTest>[
        for (final lab in _selectedLabs)
          await buildTest(
            testName: lab,
            resultControllers: _labResultControllers,
            imageBytes: _labImageBytes,
            imageNames: _labImageNames,
            imagePaths: _labImagePaths,
          ),
      ];
      final imaging = <PatientTest>[
        for (final study in _selectedImaging)
          await buildTest(
            testName: study,
            resultControllers: _imagingResultControllers,
            imageBytes: _imagingImageBytes,
            imageNames: _imagingImageNames,
            imagePaths: _imagingImagePaths,
          ),
      ];

      final record = PatientRecord(
        id: widget.isNew ? null : widget.patient.id,
        department: widget.department,
        name: name,
        fileNumber: _fileNumberController.text.trim(),
        roomNumber: _roomNumberController.text.trim(),
        diagnosis: _selectedDiagnosis,
        statusLabel: widget.isNew ? 'جديد' : widget.patient.statusLabel,
        accentColor: SurgeryDepartment.accent(widget.department),
        doctor: _selectedDoctor,
        residence: _residenceController.text.trim(),
        phone: _phoneController.text.trim(),
        photoPath: photoPath,
        photoName: photoPath == null ? null : _selectedImageName,
        signs: _selectedSigns,
        symptoms: _selectedSymptoms,
        pastHistory: _selectedPastHistory,
        operationHistory: _selectedOperationHistory,
        vitalReadings: List.of(_vitalReadings),
        labs: labs,
        imaging: imaging,
        lastOperativeDetails: _lastOperativeDetailsController.text.trim(),
        currentTreatment: _currentTreatmentController.text.trim(),
        currentTreatmentDetail: _selectedDrugEntry == null
            ? ''
            : '${_selectedDrugEntry!.genericName} - ${_selectedDrugEntry!.strength}',
        currentDose: _currentDoseController.text.trim(),
        doctorOrders: List.of(_doctorOrders),
      );

      final saved = await _repository.savePatient(record);

      // Files that were replaced or removed while editing are no longer used.
      final keptPaths = saved.filePaths.toSet();
      await _repository.removeFiles([
        for (final path in widget.patient.filePaths)
          if (!keptPaths.contains(path)) path,
      ]);

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      await _repository.removeFiles(uploadedPaths);
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('فشل حفظ المريض: ${describeSupabaseError(error)}'),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = image.name;
      _photoChanged = true;
    });
  }

  Future<void> _showMultiSelectDialog({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
    List<String> customOptions = const [],
    ValueChanged<String>? onCustomOptionAdded,
  }) async {
    final tempSelection = List<String>.from(selectedValues);
    final tempCustomOptions = List<String>.from(customOptions);
    final newOptionController = TextEditingController();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allOptions = [...options, ...tempCustomOptions];

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newOptionController,
                              decoration: const InputDecoration(
                                labelText: 'إضافة عنصر جديد',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final newOption = newOptionController.text.trim();
                              if (newOption.isEmpty) {
                                return;
                              }
                              final alreadyExists = allOptions.any(
                                (option) =>
                                    option.toLowerCase() ==
                                    newOption.toLowerCase(),
                              );
                              if (alreadyExists) {
                                final existingOption = allOptions.firstWhere(
                                  (option) =>
                                      option.toLowerCase() ==
                                      newOption.toLowerCase(),
                                );
                                if (!tempSelection.contains(existingOption)) {
                                  tempSelection.add(existingOption);
                                }
                                newOptionController.clear();
                                return;
                              }

                              setDialogState(() {
                                tempCustomOptions.add(newOption);
                                tempSelection.add(newOption);
                                newOptionController.clear();
                              });
                            },
                            child: const Text('إضافة'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...allOptions.map(
                        (option) => CheckboxListTile(
                          value: tempSelection.contains(option),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(option),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked ?? false) {
                                if (!tempSelection.contains(option)) {
                                  tempSelection.add(option);
                                }
                              } else {
                                tempSelection.remove(option);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(tempSelection),
                  child: const Text('تم'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      for (final option in tempCustomOptions) {
        if (!customOptions.contains(option)) {
          onCustomOptionAdded?.call(option);
        }
      }
      onChanged(result);
    });
  }

  List<String> _mergeOptions(
    List<String> baseOptions,
    List<String> customOptions,
  ) {
    return [...baseOptions, ...customOptions];
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickVitalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vitalDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _vitalDate = picked;
    });
  }

  void _clearVitalInputs() {
    _bpController.clear();
    _hrController.clear();
    _rrController.clear();
    _spo2Controller.clear();
    _tempController.clear();
    _selectedConsciousLevel = _consciousLevelOptions.first;
  }

  void _addVitalReading() {
    final reading = VitalReading(
      date: DateTime(_vitalDate.year, _vitalDate.month, _vitalDate.day),
      shift: _vitalShift,
      bp: _bpController.text.trim(),
      hr: _hrController.text.trim(),
      rr: _rrController.text.trim(),
      spo2: _spo2Controller.text.trim(),
      temp: _tempController.text.trim(),
      consciousLevel: _selectedConsciousLevel,
    );

    if (!reading.hasValues) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل قيمة واحدة على الأقل للعلامات الحيوية'),
        ),
      );
      return;
    }

    setState(() {
      _vitalReadings.removeWhere(
        (item) => item.date == reading.date && item.shift == reading.shift,
      );
      _vitalReadings.add(reading);
      _vitalReadings.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.shift.index.compareTo(a.shift.index);
      });
      _clearVitalInputs();

      // Move to the next slot: morning -> evening -> next day's morning.
      if (_vitalShift == VitalShift.morning) {
        _vitalShift = VitalShift.evening;
      } else {
        _vitalShift = VitalShift.morning;
        _vitalDate = reading.date.add(const Duration(days: 1));
      }
    });
  }

  void _editVitalReading(VitalReading reading) {
    setState(() {
      _vitalReadings.remove(reading);
      _vitalDate = reading.date;
      _vitalShift = reading.shift;
      _bpController.text = reading.bp;
      _hrController.text = reading.hr;
      _rrController.text = reading.rr;
      _spo2Controller.text = reading.spo2;
      _tempController.text = reading.temp;
      _selectedConsciousLevel = reading.consciousLevel.isNotEmpty
          ? reading.consciousLevel
          : _consciousLevelOptions.first;
      if (!_consciousLevelOptions.contains(_selectedConsciousLevel) &&
          !_customConsciousLevelOptions.contains(_selectedConsciousLevel)) {
        _customConsciousLevelOptions.add(_selectedConsciousLevel);
      }
    });
  }

  void _addDoctorOrder() {
    final text = _doctorOrderController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _doctorOrders.insert(
        0,
        DoctorOrder(text: text, createdAt: DateTime.now()),
      );
      _doctorOrderController.clear();
    });
  }

  void _addLab(String labName) {
    if (_selectedLabs.contains(labName)) {
      return;
    }

    setState(() {
      _selectedLabs.add(labName);
      _labResultControllers.putIfAbsent(labName, TextEditingController.new);
      _selectedLabToAdd = null;
    });
  }

  void _removeLab(String labName) {
    final controller = _labResultControllers.remove(labName);
    controller?.dispose();

    setState(() {
      _selectedLabs.remove(labName);
      _labImageBytes.remove(labName);
      _labImageNames.remove(labName);
      _labImagePaths.remove(labName);
    });
  }

  void _addImaging(String imagingName) {
    if (_selectedImaging.contains(imagingName)) {
      return;
    }

    setState(() {
      _selectedImaging.add(imagingName);
      _imagingResultControllers.putIfAbsent(
        imagingName,
        TextEditingController.new,
      );
      _selectedImagingToAdd = null;
    });
  }

  void _removeImaging(String imagingName) {
    final controller = _imagingResultControllers.remove(imagingName);
    controller?.dispose();

    setState(() {
      _selectedImaging.remove(imagingName);
      _imagingImageBytes.remove(imagingName);
      _imagingImageNames.remove(imagingName);
      _imagingImagePaths.remove(imagingName);
    });
  }

  Future<void> _pickAttachmentImage({
    required String itemName,
    required Map<String, Uint8List> imageBytesStore,
    required Map<String, String> imageNameStore,
  }) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      imageBytesStore[itemName] = bytes;
      imageNameStore[itemName] = image.name;
    });
  }

  Iterable<_DrugCatalogEntry> _searchDrugOptions(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _egyptianDrugCatalog;
    }

    return _egyptianDrugCatalog.where(
      (drug) =>
          drug.tradeName.toLowerCase().contains(query) ||
          drug.genericName.toLowerCase().contains(query) ||
          drug.strength.toLowerCase().contains(query),
    );
  }

  void _syncSelectedDrugFromText(String value) {
    final normalizedValue = value.trim().toLowerCase();
    final matchedDrug = _egyptianDrugCatalog
        .cast<_DrugCatalogEntry?>()
        .firstWhere(
          (drug) => drug!.tradeName.toLowerCase() == normalizedValue,
          orElse: () => null,
        );

    if (_selectedDrugEntry == matchedDrug) {
      return;
    }

    setState(() {
      _selectedDrugEntry = matchedDrug;
    });
  }

  TextDirection _resolveTextDirection(
    String text, {
    TextDirection fallback = TextDirection.rtl,
  }) {
    for (final rune in text.runes) {
      if (_isArabicRune(rune)) {
        return TextDirection.rtl;
      }
      if (_isLatinRune(rune)) {
        return TextDirection.ltr;
      }
    }
    return fallback;
  }

  bool _isArabicRune(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  bool _isLatinRune(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A);
  }

  Widget _buildDrugSearchField(ThemeData theme) {
    return Autocomplete<_DrugCatalogEntry>(
      initialValue: TextEditingValue(text: _currentTreatmentController.text),
      displayStringForOption: (option) => option.tradeName,
      optionsBuilder: _searchDrugOptions,
      onSelected: (option) {
        _currentTreatmentController.text = option.tradeName;
        setState(() {
          _selectedDrugEntry = option;
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 260,
                minWidth: 280,
                maxWidth: 420,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option.tradeName),
                    subtitle: Text(
                      '${option.genericName} - ${option.strength}',
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onSubmitted) {
            if (textEditingController.text !=
                _currentTreatmentController.text) {
              textEditingController.value = TextEditingValue(
                text: _currentTreatmentController.text,
                selection: TextSelection.collapsed(
                  offset: _currentTreatmentController.text.length,
                ),
              );
            }

            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: textEditingController,
              builder: (context, value, child) {
                final textDirection = _resolveTextDirection(value.text);

                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  textDirection: textDirection,
                  textAlign: textDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  decoration: InputDecoration(
                    labelText: 'العلاج',
                    hintText: 'ابحث باسم الدواء التجاري أو العلمي',
                    filled: true,
                    fillColor: const Color(0xFFFDFEFF),
                    suffixIcon: const Icon(Icons.medication_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF0E4D92),
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (text) {
                    _currentTreatmentController.text = text;
                    _syncSelectedDrugFromText(text);
                  },
                );
              },
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnosisOptions = _optionsWithCustom(
      _surgicalDiagnosisOptions,
      _customDiagnosisOptions,
      _selectedDiagnosis,
    );
    final doctorChoices = _optionsWithCustom(
      _doctorOptions,
      _customDoctorOptions,
      _selectedDoctor,
    );
    final consciousLevelChoices = _optionsWithCustom(
      _consciousLevelOptions,
      _customConsciousLevelOptions,
    );
    final labOptions = _mergeOptions(_labOptions, _customLabOptions);
    final imagingOptions = _mergeOptions(
      _imagingOptions,
      _customImagingOptions,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(widget.isNew ? 'إضافة مريض' : widget.patient.name),
          actions: const [AccountButton()],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'بيانات المريض',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16324F),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 190,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFD),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFD9E1EA),
                                ),
                              ),
                              child: _selectedImageBytes == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 42,
                                          color: Color(0xFF5B6B7B),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'اضغط لإضافة صورة المريض',
                                          style: TextStyle(
                                            color: Color(0xFF5B6B7B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedImageName ?? 'لم يتم اختيار صورة بعد',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7B8C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PatientDetailsField(
                            controller: _fileNumberController,
                            label: 'رقم الملف',
                            fallbackDirection: TextDirection.ltr,
                          ),
                          const SizedBox(height: 10),
                          _PatientDetailsField(
                            controller: _roomNumberController,
                            label: 'رقم الغرفة',
                            fallbackDirection: TextDirection.ltr,
                          ),
                          const SizedBox(height: 10),
                          _PatientDropdownField(
                            label: 'الطبيب المعالج',
                            value: _selectedDoctor,
                            options: doctorChoices,
                            onAddOption: (option) => setState(() {
                              _rememberCustomOption(
                                'doctor',
                                _customDoctorOptions,
                                option,
                              );
                            }),
                            fillColor: const Color(0xFFF1FBF5),
                            borderColor: const Color(0xFF6FC08D),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedDoctor = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PatientDetailsField(
                        controller: _residenceController,
                        label: 'محل الإقامة',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PatientDetailsField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        keyboardType: TextInputType.phone,
                        fallbackDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PatientDetailsField(
                        controller: _nameController,
                        label: 'اسم المريض',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PatientDropdownField(
                        label: 'التشخيص',
                        value: _selectedDiagnosis.isEmpty
                            ? null
                            : _selectedDiagnosis,
                        options: diagnosisOptions,
                        onAddOption: (option) => setState(() {
                          _rememberCustomOption(
                            'diagnosis',
                            _customDiagnosisOptions,
                            option,
                          );
                        }),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedDiagnosis = value;
                            _diagnosisController.text = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E1EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'complaint',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر أكثر من علامة أو عرض حسب حالة المريض.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B6B7B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _PatientMultiSelectField(
                                label: 'Signs',
                                values: _selectedSigns,
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select signs',
                                  options: _signOptions,
                                  selectedValues: _selectedSigns,
                                  customOptions: _customSignOptions,
                                  onCustomOptionAdded: (option) {
                                    _rememberCustomOption(
                                      'sign',
                                      _customSignOptions,
                                      option,
                                    );
                                  },
                                  onChanged: (values) {
                                    _selectedSigns = values;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Color(0xFFD9E1EA),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PatientMultiSelectField(
                                label: 'Symptoms',
                                values: _selectedSymptoms,
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select symptoms',
                                  options: _symptomOptions,
                                  selectedValues: _selectedSymptoms,
                                  customOptions: _customSymptomOptions,
                                  onCustomOptionAdded: (option) {
                                    _rememberCustomOption(
                                      'symptom',
                                      _customSymptomOptions,
                                      option,
                                    );
                                  },
                                  onChanged: (values) {
                                    _selectedSymptoms = values;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'vital signs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16324F),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickVitalDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(_formatDate(_vitalDate)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SegmentedButton<VitalShift>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: VitalShift.morning,
                            icon: Icon(Icons.wb_sunny_outlined, size: 18),
                            label: Text('صباحًا'),
                          ),
                          ButtonSegment(
                            value: VitalShift.evening,
                            icon: Icon(Icons.nights_stay_outlined, size: 18),
                            label: Text('مساءً'),
                          ),
                        ],
                        selected: {_vitalShift},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _vitalShift = selection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PatientDetailsField(
                          controller: _bpController,
                          label: 'BP =',
                          fallbackDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PatientDetailsField(
                          controller: _hrController,
                          label: 'HR',
                          fallbackDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PatientDetailsField(
                          controller: _rrController,
                          label: 'RR',
                          fallbackDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PatientDetailsField(
                          controller: _spo2Controller,
                          label: 'SpO2',
                          fallbackDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PatientDetailsField(
                          controller: _tempController,
                          label: 'Temp.',
                          fallbackDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _PatientDropdownField(
                          label: 'Conscious level',
                          value: _selectedConsciousLevel,
                          options: consciousLevelChoices,
                          onAddOption: (option) => setState(() {
                            _rememberCustomOption(
                              'conscious_level',
                              _customConsciousLevelOptions,
                              option,
                            );
                          }),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedConsciousLevel = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _addVitalReading,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'تسجيل قراءة ${_vitalShift.label} - ${_formatDate(_vitalDate)}',
                  ),
                ),
                if (_vitalReadings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final reading in _vitalReadings)
                    _VitalReadingTile(
                      reading: reading,
                      dateLabel: _formatDate(reading.date),
                      onEdit: () => _editVitalReading(reading),
                      onDelete: () {
                        setState(() {
                          _vitalReadings.remove(reading);
                        });
                      },
                    ),
                ],
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E1EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'history',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر الأمراض المزمنة والتاريخ الجراحي للمريض.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B6B7B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _PatientMultiSelectField(
                                label: 'Past history',
                                values: _selectedPastHistory,
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select past history',
                                  options: _pastHistoryOptions,
                                  selectedValues: _selectedPastHistory,
                                  customOptions: _customPastHistoryOptions,
                                  onCustomOptionAdded: (option) {
                                    _rememberCustomOption(
                                      'past_history',
                                      _customPastHistoryOptions,
                                      option,
                                    );
                                  },
                                  onChanged: (values) {
                                    _selectedPastHistory = values;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Color(0xFFD9E1EA),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PatientMultiSelectField(
                                label: 'Operation history',
                                values: _selectedOperationHistory,
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select operation history',
                                  options: _operationHistoryOptions,
                                  selectedValues: _selectedOperationHistory,
                                  customOptions: _customOperationHistoryOptions,
                                  onCustomOptionAdded: (option) {
                                    _rememberCustomOption(
                                      'operation_history',
                                      _customOperationHistoryOptions,
                                      option,
                                    );
                                  },
                                  onChanged: (values) {
                                    _selectedOperationHistory = values;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E1EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'labs',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر التحليل ثم اكتب النتيجة يدويًا.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B6B7B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedLabToAdd,
                              isExpanded: true,
                              hint: const Text('اختر تحليلًا'),
                              items: labOptions
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option,
                                      child: Text(
                                        option,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                _addLab(value);
                              },
                              decoration: InputDecoration(
                                labelText: 'تحاليل معملية',
                                filled: true,
                                fillColor: const Color(0xFFFDFEFF),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E1EA),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E1EA),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0E4D92),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => _showMultiSelectDialog(
                              title: 'إضافة تحليل جديد',
                              options: const [],
                              selectedValues: const [],
                              customOptions: _customLabOptions,
                              onCustomOptionAdded: (option) {
                                _rememberCustomOption(
                                  'lab',
                                  _customLabOptions,
                                  option,
                                );
                              },
                              onChanged: (values) {
                                for (final value in values) {
                                  _addLab(value);
                                }
                              },
                            ),
                            child: const Text('إضافة تحليل'),
                          ),
                        ],
                      ),
                      if (_selectedLabs.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ..._selectedLabs.map(
                          (labName) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _PatientDetailsField(
                                        controller:
                                            _labResultControllers[labName]!,
                                        label: '$labName result',
                                        fallbackDirection: TextDirection.ltr,
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _pickAttachmentImage(
                                          itemName: labName,
                                          imageBytesStore: _labImageBytes,
                                          imageNameStore: _labImageNames,
                                        ),
                                        icon: const Icon(
                                          Icons.upload_file_outlined,
                                        ),
                                        label: Text(
                                          _labImageNames[labName] == null
                                              ? 'تحميل صورة التحليل'
                                              : 'تغيير صورة التحليل',
                                        ),
                                      ),
                                      if (_labImageNames[labName] != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _labImageNames[labName]!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF5B6B7B),
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF3FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      labName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF16324F),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeLab(labName),
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'حذف التحليل',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E1EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'imaging',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر الأشعة ثم اكتب التقرير أو ارفع الصورة.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B6B7B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedImagingToAdd,
                              isExpanded: true,
                              hint: const Text('اختر نوع الأشعة'),
                              items: imagingOptions
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option,
                                      child: Text(
                                        option,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                _addImaging(value);
                              },
                              decoration: InputDecoration(
                                labelText: 'فحوص الأشعة',
                                filled: true,
                                fillColor: const Color(0xFFFDFEFF),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E1EA),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E1EA),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0E4D92),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => _showMultiSelectDialog(
                              title: 'إضافة أشعة جديدة',
                              options: const [],
                              selectedValues: const [],
                              customOptions: _customImagingOptions,
                              onCustomOptionAdded: (option) {
                                _rememberCustomOption(
                                  'imaging',
                                  _customImagingOptions,
                                  option,
                                );
                              },
                              onChanged: (values) {
                                for (final value in values) {
                                  _addImaging(value);
                                }
                              },
                            ),
                            child: const Text('إضافة أشعة'),
                          ),
                        ],
                      ),
                      if (_selectedImaging.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ..._selectedImaging.map(
                          (imagingName) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _PatientDetailsField(
                                        controller:
                                            _imagingResultControllers[imagingName]!,
                                        label: '$imagingName report',
                                        fallbackDirection: TextDirection.ltr,
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _pickAttachmentImage(
                                          itemName: imagingName,
                                          imageBytesStore: _imagingImageBytes,
                                          imageNameStore: _imagingImageNames,
                                        ),
                                        icon: const Icon(
                                          Icons.upload_file_outlined,
                                        ),
                                        label: Text(
                                          _imagingImageNames[imagingName] ==
                                                  null
                                              ? 'تحميل صورة الأشعة'
                                              : 'تغيير صورة الأشعة',
                                        ),
                                      ),
                                      if (_imagingImageNames[imagingName] !=
                                          null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _imagingImageNames[imagingName]!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF5B6B7B),
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF3FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      imagingName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF16324F),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeImaging(imagingName),
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'حذف الأشعة',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E1EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'last operative details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PatientDetailsField(
                        controller: _lastOperativeDetailsController,
                        label: 'تفاصيل آخر عملية',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E1EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'العلاج الحالي',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildDrugSearchField(theme),
                                if (_selectedDrugEntry != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF3FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '${_selectedDrugEntry!.genericName} - ${_selectedDrugEntry!.strength}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF16324F),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _PatientDetailsField(
                              controller: _currentDoseController,
                              label: 'الجرعة',
                              fallbackDirection: TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E1EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'doctor orders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أضف أوامر الطبيب تباعًا، وسيتم تسجيل وقت كل أمر.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B6B7B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PatientDetailsField(
                              controller: _doctorOrderController,
                              label: 'أمر الطبيب',
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: _addDoctorOrder,
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة'),
                          ),
                        ],
                      ),
                      for (final order in _doctorOrders)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: order.done
                                ? const Color(0xFFF1FBF5)
                                : const Color(0xFFFDFEFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD9E1EA)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: order.done,
                                onChanged: (value) {
                                  setState(() {
                                    order.done = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.text,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration: order.done
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatDate(order.createdAt)} - ${_formatTime(order.createdAt)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF6B7B8C),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                onPressed: () {
                                  setState(() {
                                    _doctorOrders.remove(order);
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _savePatient,
                  style: FilledButton.styleFrom(
                    backgroundColor: SurgeryDepartment.accent(
                      widget.department,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'جارٍ الحفظ...'
                        : (widget.isNew ? 'حفظ المريض' : 'حفظ التعديلات'),
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

class _PatientDetailsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextDirection fallbackDirection;

  const _PatientDetailsField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.fallbackDirection = TextDirection.rtl,
  });

  TextDirection _resolveTextDirection(String text) {
    for (final rune in text.runes) {
      if (_isArabicRune(rune)) {
        return TextDirection.rtl;
      }
      if (_isLatinRune(rune)) {
        return TextDirection.ltr;
      }
    }
    return fallbackDirection;
  }

  bool _isArabicRune(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  bool _isLatinRune(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final textDirection = _resolveTextDirection(value.text);

        return TextField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: textDirection,
          textAlign: textDirection == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: const Color(0xFFFDFEFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0E4D92),
                width: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PatientDropdownField extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  /// When set, the list ends with an "add new item" entry; the typed item is
  /// passed here and then selected.
  final ValueChanged<String>? onAddOption;
  final Color? fillColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;

  const _PatientDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onAddOption,
    this.fillColor,
    this.borderColor,
    this.contentPadding,
    this.textStyle,
  });

  @override
  State<_PatientDropdownField> createState() => _PatientDropdownFieldState();
}

class _PatientDropdownFieldState extends State<_PatientDropdownField> {
  static const String _addNewValue = '\u0000add_new';

  // Bumped to rebuild the form field when it must drop the "add new" pick.
  int _generation = 0;

  List<String> get options => widget.options;
  TextStyle? get textStyle => widget.textStyle;

  Future<void> _handleChanged(String? selected) async {
    if (selected != _addNewValue) {
      widget.onChanged(selected);
      return;
    }
    final newOption = await _askForNewOption();
    if (!mounted) return;
    setState(() => _generation++);
    if (newOption == null) return;
    final existing = options.where(
      (option) => option.toLowerCase() == newOption.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      widget.onChanged(existing.first);
      return;
    }
    widget.onAddOption?.call(newOption);
    widget.onChanged(newOption);
  }

  Future<String?> _askForNewOption() {
    return showDialog<String>(
      context: context,
      builder: (_) => _NewOptionDialog(label: widget.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = widget.fillColor;
    final borderColor = widget.borderColor;
    final canAdd = widget.onAddOption != null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$_generation|${widget.value}|${options.length}'),
      initialValue: widget.value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: [
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ),
        if (canAdd)
          DropdownMenuItem<String>(
            value: _addNewValue,
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline, size: 18),
                const SizedBox(width: 6),
                Text(
                  'إضافة عنصر جديد',
                  style: (textStyle ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0E4D92),
                  ),
                ),
              ],
            ),
          ),
      ],
      selectedItemBuilder: (context) {
        return [
          ...options.map(
            (option) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ),
          if (canAdd) const SizedBox.shrink(),
        ];
      },
      onChanged: _handleChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        fillColor: fillColor ?? const Color(0xFFFDFEFF),
        isDense: true,
        contentPadding:
            widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor ?? const Color(0xFFD9E1EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor ?? const Color(0xFFD9E1EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: borderColor ?? const Color(0xFF0E4D92),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _NewOptionDialog extends StatefulWidget {
  final String label;

  const _NewOptionDialog({required this.label});

  @override
  State<_NewOptionDialog> createState() => _NewOptionDialogState();
}

class _NewOptionDialogState extends State<_NewOptionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('إضافة ${widget.label}'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'اسم العنصر الجديد',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _submit, child: const Text('إضافة')),
        ],
      ),
    );
  }
}

class _PatientMultiSelectField extends StatelessWidget {
  final String label;
  final List<String> values;
  final VoidCallback onTap;

  const _PatientMultiSelectField({
    required this.label,
    required this.values,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValues = values.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFDFEFF),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0E4D92), width: 1.4),
          ),
        ),
        child: hasValues
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .map(
                      (value) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF0E4D92),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )
            : Text(
                'لا يوجد اختيار',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7B8C),
                ),
              ),
      ),
    );
  }
}

class _VitalReadingTile extends StatelessWidget {
  final VitalReading reading;
  final String dateLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VitalReadingTile({
    required this.reading,
    required this.dateLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      if (reading.bp.isNotEmpty) 'BP ${reading.bp}',
      if (reading.hr.isNotEmpty) 'HR ${reading.hr}',
      if (reading.rr.isNotEmpty) 'RR ${reading.rr}',
      if (reading.spo2.isNotEmpty) 'SpO2 ${reading.spo2}',
      if (reading.temp.isNotEmpty) 'Temp ${reading.temp}',
      reading.consciousLevel,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: reading.shift == VitalShift.morning
            ? const Color(0xFFFFFBEA)
            : const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E1EA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateLabel - ${reading.shift.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16324F),
                  ),
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(values.join('   •   ')),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تعديل',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _DrugCatalogEntry {
  final String tradeName;
  final String genericName;
  final String strength;

  const _DrugCatalogEntry({
    required this.tradeName,
    required this.genericName,
    required this.strength,
  });
}
