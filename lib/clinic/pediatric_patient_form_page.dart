import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _sky = Color(0xFF1E88E5);
const _skyDark = Color(0xFF0F5FA8);
const _sun = Color(0xFFFFB020);
const _ink = Color(0xFF172B4D);
const _muted = Color(0xFF718096);
const _tint = Color(0xFFF0F7FE);
const _line = Color(0xFFCFE3F6);

class PediatricPatient {
  const PediatricPatient({
    required this.name,
    this.isBoy = true,
    this.birthDate,
    this.guardian = '',
    this.phone = '',
    this.reasons = const [],
    this.complaint = '',
    this.weight = '',
    this.height = '',
    this.headCircumference = '',
    this.temperature = '',
    this.birthType = '',
    this.preterm = false,
    this.birthWeight = '',
    this.feeding = '',
    this.vaccinated = true,
    this.history = const [],
    this.notes = '',
  });

  final String name;
  final bool isBoy;
  final DateTime? birthDate;
  final String guardian;
  final String phone;
  final List<String> reasons;
  final String complaint;
  final String weight;
  final String height;
  final String headCircumference;
  final String temperature;
  final String birthType;
  final bool preterm;
  final String birthWeight;
  final String feeding;
  final bool vaccinated;
  final List<String> history;
  final String notes;

  /// Age as (years, months, days) calendar difference from [birthDate].
  (int, int, int)? age([DateTime? now]) {
    final b = birthDate;
    if (b == null) return null;
    final today = now ?? DateTime.now();
    var years = today.year - b.year;
    var months = today.month - b.month;
    var days = today.day - b.day;
    if (days < 0) {
      months--;
      days += DateTime(today.year, today.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years < 0) return null;
    return (years, months, days);
  }

  double? get bmi {
    final w = double.tryParse(weight);
    final h = double.tryParse(height);
    if (w == null || h == null || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }
}

/// Full-screen intake form for a new pediatric patient.
/// Pops with a [PediatricPatient] when saved.
class PediatricPatientFormPage extends StatefulWidget {
  const PediatricPatientFormPage({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  State<PediatricPatientFormPage> createState() =>
      _PediatricPatientFormPageState();
}

class _PediatricPatientFormPageState extends State<PediatricPatientFormPage> {
  static const _reasons = <(String, String)>[
    ('حرارة', 'Fever'),
    ('كحة', 'Cough'),
    ('قيء', 'Vomiting'),
    ('إسهال', 'Diarrhea'),
    ('طفح جلدي', 'Rash'),
    ('تطعيم', 'Vaccination'),
    ('متابعة نمو', 'Growth check'),
    ('أخرى', 'Other'),
  ];

  static const _history = <(String, String)>[
    ('حساسية صدر', 'Asthma'),
    ('حساسية طعام', 'Food allergy'),
    ('أنيميا', 'Anemia'),
    ('تشنجات', 'Seizures'),
    ('عيوب قلب', 'Heart defect'),
    ('سكر', 'Diabetes'),
    ('دخول مستشفى سابق', 'Previous admission'),
  ];

  static const _feeding = <(IconData, String, String)>[
    (Icons.favorite_rounded, 'طبيعية', 'Breast'),
    (Icons.local_drink_outlined, 'صناعية', 'Formula'),
    (Icons.blender_outlined, 'مختلطة', 'Mixed'),
    (Icons.rice_bowl_outlined, 'أكل عادي', 'Solid food'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _guardian = TextEditingController();
  final _phone = TextEditingController();
  final _complaint = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _head = TextEditingController();
  final _temp = TextEditingController();
  final _birthWeight = TextEditingController();
  final _notes = TextEditingController();

  bool _isBoy = true;
  DateTime? _birthDate;
  final Set<int> _selectedReasons = {};
  final Set<int> _selectedHistory = {};
  bool _cSection = false;
  bool _preterm = false;
  int _feedingIndex = 0;
  bool _vaccinated = true;

  bool get _ar => widget.isArabic;
  String tr(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    for (final c in [_weight, _height]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _guardian,
      _phone,
      _complaint,
      _weight,
      _height,
      _head,
      _temp,
      _birthWeight,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  PediatricPatient _build() => PediatricPatient(
    name: _name.text.trim(),
    isBoy: _isBoy,
    birthDate: _birthDate,
    guardian: _guardian.text.trim(),
    phone: _phone.text.trim(),
    reasons: [
      for (final i in _selectedReasons.toList()..sort()) _reasons[i].$2,
    ],
    complaint: _complaint.text.trim(),
    weight: _weight.text.trim(),
    height: _height.text.trim(),
    headCircumference: _head.text.trim(),
    temperature: _temp.text.trim(),
    birthType: _cSection ? 'C-section' : 'Normal',
    preterm: _preterm,
    birthWeight: _birthWeight.text.trim(),
    feeding: _feeding[_feedingIndex].$3,
    vaccinated: _vaccinated,
    history: [
      for (final i in _selectedHistory.toList()..sort()) _history[i].$2,
    ],
    notes: _notes.text.trim(),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('أدخل اسم الطفل', "Enter the child's name"))),
      );
      return;
    }
    Navigator.of(context).pop(_build());
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F9FF),
        appBar: AppBar(
          foregroundColor: Colors.white,
          elevation: 0,
          backgroundColor: _skyDark,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_skyDark, _sky],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
            ),
          ),
          title: const Text(
            'ملف طفل جديد  ·  New child',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        bottomNavigationBar: _saveBar(),
        body: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _hero(),
                  const SizedBox(height: 16),
                  _section(
                    Icons.child_care_rounded,
                    tr('بيانات الطفل', 'Child information'),
                    [
                      _field(
                        _name,
                        tr('اسم الطفل', "Child's name"),
                        Icons.badge_outlined,
                        required: true,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _genderTile(
                              true,
                              Icons.boy_rounded,
                              'ولد',
                              'Boy',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _genderTile(
                              false,
                              Icons.girl_rounded,
                              'بنت',
                              'Girl',
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: _decoration(
                            tr('تاريخ الميلاد', 'Date of birth'),
                            Icons.cake_outlined,
                          ),
                          child: Text(
                            _birthDate == null
                                ? tr('اختر التاريخ', 'Select date')
                                : _date(_birthDate!),
                            style: TextStyle(
                              color: _birthDate == null ? _muted : _ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _guardian,
                              tr('اسم ولي الأمر', 'Guardian name'),
                              Icons.family_restroom_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _phone,
                              tr('رقم الهاتف', 'Phone'),
                              Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _section(
                    Icons.sick_outlined,
                    tr('سبب الزيارة', 'Reason for visit'),
                    [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _reasons.length; i++)
                            _pill(
                              tr(_reasons[i].$1, _reasons[i].$2),
                              selected: _selectedReasons.contains(i),
                              onTap: () => setState(
                                () => _selectedReasons.contains(i)
                                    ? _selectedReasons.remove(i)
                                    : _selectedReasons.add(i),
                              ),
                            ),
                        ],
                      ),
                      _field(
                        _complaint,
                        tr('الشكوى بالتفصيل', 'Complaint details'),
                        Icons.notes_rounded,
                        lines: 2,
                      ),
                    ],
                  ),
                  _section(
                    Icons.straighten_rounded,
                    tr('القياسات والنمو', 'Measurements & growth'),
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _weight,
                              tr('الوزن (كجم)', 'Weight (kg)'),
                              Icons.monitor_weight_outlined,
                              decimal: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _height,
                              tr('الطول (سم)', 'Height (cm)'),
                              Icons.height_rounded,
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _head,
                              tr('محيط الرأس (سم)', 'Head circ. (cm)'),
                              Icons.face_rounded,
                              decimal: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _temp,
                              tr('الحرارة (°م)', 'Temp (°C)'),
                              Icons.thermostat_rounded,
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _section(
                    Icons.child_friendly_outlined,
                    tr('تاريخ الولادة والتغذية', 'Birth history & feeding'),
                    [
                      _switch(
                        tr('ولادة قيصرية', 'C-section delivery'),
                        _cSection,
                        (v) => setState(() => _cSection = v),
                      ),
                      _switch(
                        tr('ولادة مبكرة (خديج)', 'Born preterm'),
                        _preterm,
                        (v) => setState(() => _preterm = v),
                      ),
                      _field(
                        _birthWeight,
                        tr('وزن الولادة (كجم)', 'Birth weight (kg)'),
                        Icons.scale_outlined,
                        decimal: true,
                      ),
                      _caption(tr('نوع التغذية', 'Feeding type')),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < _feeding.length; i++)
                            _feedingTile(i),
                        ],
                      ),
                    ],
                  ),
                  _section(
                    Icons.vaccines_outlined,
                    tr(
                      'التطعيمات والتاريخ المرضي',
                      'Vaccines & medical history',
                    ),
                    [
                      _switch(
                        tr('التطعيمات مكتملة', 'Vaccinations up to date'),
                        _vaccinated,
                        (v) => setState(() => _vaccinated = v),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _history.length; i++)
                            _pill(
                              tr(_history[i].$1, _history[i].$2),
                              selected: _selectedHistory.contains(i),
                              onTap: () => setState(
                                () => _selectedHistory.contains(i)
                                    ? _selectedHistory.remove(i)
                                    : _selectedHistory.add(i),
                              ),
                            ),
                        ],
                      ),
                      _field(
                        _notes,
                        tr('ملاحظات إضافية', 'Additional notes'),
                        Icons.edit_note_rounded,
                        lines: 3,
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

  Widget _hero() {
    final preview = PediatricPatient(
      name: '',
      birthDate: _birthDate,
      weight: _weight.text,
      height: _height.text,
    );
    final age = preview.age();
    final bmi = preview.bmi;

    String ageText() {
      if (age == null) return tr('العمر: —', 'Age: —');
      final (y, m, d) = age;
      if (y > 0) {
        return tr('$y سنة و $m شهر', '${y}y ${m}m');
      }
      if (m > 0) return tr('$m شهر و $d يوم', '${m}m ${d}d');
      return tr('$d يوم', '${d}d');
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [_skyDark, _sky, Color(0xFF4FC3F7)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401E88E5),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -30,
            end: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sun.withValues(alpha: 0.85),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -40,
            start: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عيادة الأطفال',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Pediatrics Clinic',
                        style: TextStyle(
                          color: Color(0xFFE1F3FF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _heroChip(Icons.cake_outlined, ageText()),
                          if (bmi != null)
                            _heroChip(
                              Icons.speed_rounded,
                              'BMI ${bmi.toStringAsFixed(1)}',
                            ),
                        ],
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

  Widget _heroChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _section(IconData icon, String title, List<Widget> children) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: 12));
      spaced.add(children[i]);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCEBF9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F5FA8),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _sun.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFFE08A00), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...spaced,
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: _sky),
    filled: true,
    fillColor: _tint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _sky, width: 1.6),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int lines = 1,
    bool decimal = false,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : keyboard,
      minLines: lines,
      maxLines: lines,
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: _decoration(required ? '$label *' : label, icon),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? tr('هذا الحقل مطلوب', 'This field is required')
                : null
          : null,
    );
  }

  Widget _caption(String text) => Text(
    text,
    style: const TextStyle(
      color: _muted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeThumbColor: _sky,
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _pill(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _sky : _tint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _sky : _line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _skyDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderTile(bool boy, IconData icon, String ar, String en) {
    final selected = _isBoy == boy;
    final color = boy ? _sky : const Color(0xFFEC5B9A);
    return InkWell(
      onTap: () => setState(() => _isBoy = boy),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : _tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : _line, width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$ar · $en',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedingTile(int index) {
    final (icon, ar, en) = _feeding[index];
    final selected = _feedingIndex == index;
    return InkWell(
      onTap: () => setState(() => _feedingIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_skyDark, _sky])
              : null,
          color: selected ? null : _tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _sky : _line),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : _sky, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar,
                    style: TextStyle(
                      color: selected ? Colors.white : _ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    en,
                    style: TextStyle(
                      color: selected ? const Color(0xFFE1F3FF) : _muted,
                      fontSize: 10.5,
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

  Widget _saveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _skyDark,
                    side: const BorderSide(color: _line),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(tr('إلغاء', 'Cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [_skyDark, _sky]),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x551E88E5),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _save,
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                tr('حفظ ملف الطفل', 'Save child file'),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
