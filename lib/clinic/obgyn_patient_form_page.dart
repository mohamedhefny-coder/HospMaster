import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _rose = Color(0xFFD6457F);
const _roseDark = Color(0xFF9B2C62);
const _ink = Color(0xFF172B4D);
const _muted = Color(0xFF718096);

class ClinicPatient {
  const ClinicPatient({
    required this.name,
    this.age = '',
    this.phone = '',
    this.bloodGroup = '',
    this.visitType = '',
    this.complaint = '',
    this.gravida = 0,
    this.para = 0,
    this.abortions = 0,
    this.pregnant = false,
    this.lmp,
    this.bp = '',
    this.weight = '',
    this.hemoglobin = '',
    this.history = const [],
    this.notes = '',
  });

  final String name;
  final String age;
  final String phone;
  final String bloodGroup;
  final String visitType;
  final String complaint;
  final int gravida;
  final int para;
  final int abortions;
  final bool pregnant;
  final DateTime? lmp;
  final String bp;
  final String weight;
  final String hemoglobin;
  final List<String> history;
  final String notes;

  DateTime? get edd => lmp?.add(const Duration(days: 280));

  /// Gestational age as (weeks, days) counted from the last menstrual period.
  (int, int)? gestationalAge([DateTime? now]) {
    final start = lmp;
    if (!pregnant || start == null) return null;
    final days = (now ?? DateTime.now()).difference(start).inDays;
    if (days < 0) return null;
    return (days ~/ 7, days % 7);
  }
}

/// Full-screen intake form for a new Obstetrics & Gynecology patient.
/// Pops with a [ClinicPatient] when saved.
class ObgynPatientFormPage extends StatefulWidget {
  const ObgynPatientFormPage({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  State<ObgynPatientFormPage> createState() => _ObgynPatientFormPageState();
}

class _ObgynPatientFormPageState extends State<ObgynPatientFormPage> {
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const _visitTypes = <(IconData, String, String)>[
    (Icons.child_friendly_outlined, 'متابعة حمل', 'Antenatal'),
    (Icons.female_rounded, 'كشف نساء', 'Gynecology'),
    (Icons.baby_changing_station_outlined, 'ما بعد الولادة', 'Postnatal'),
    (Icons.favorite_border_rounded, 'تأخر إنجاب', 'Fertility'),
  ];

  static const _historyItems = <(String, String)>[
    ('سكر', 'Diabetes'),
    ('ضغط', 'Hypertension'),
    ('غدة درقية', 'Thyroid'),
    ('أنيميا', 'Anemia'),
    ('قلب', 'Heart disease'),
    ('ربو', 'Asthma'),
    ('حساسية', 'Allergy'),
    ('عملية سابقة', 'Previous surgery'),
    ('قيصرية سابقة', 'Previous C-section'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _complaint = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _weight = TextEditingController();
  final _hemoglobin = TextEditingController();
  final _notes = TextEditingController();

  String _bloodGroup = '';
  int _visit = 0;
  int _gravida = 0;
  int _para = 0;
  int _abortions = 0;
  bool _pregnant = false;
  DateTime? _lmp;
  final Set<int> _history = {};

  bool get _ar => widget.isArabic;
  String tr(String ar, String en) => _ar ? ar : en;

  @override
  void dispose() {
    for (final c in [
      _name,
      _age,
      _phone,
      _complaint,
      _systolic,
      _diastolic,
      _weight,
      _hemoglobin,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  ClinicPatient _build() => ClinicPatient(
    name: _name.text.trim(),
    age: _age.text.trim(),
    phone: _phone.text.trim(),
    bloodGroup: _bloodGroup,
    visitType: _visitTypes[_visit].$3,
    complaint: _complaint.text.trim(),
    gravida: _gravida,
    para: _para,
    abortions: _abortions,
    pregnant: _pregnant,
    lmp: _pregnant ? _lmp : null,
    bp: _systolic.text.isEmpty && _diastolic.text.isEmpty
        ? ''
        : '${_systolic.text.trim()}/${_diastolic.text.trim()}',
    weight: _weight.text.trim(),
    hemoglobin: _hemoglobin.text.trim(),
    history: [for (final i in _history.toList()..sort()) _historyItems[i].$2],
    notes: _notes.text.trim(),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('أدخل اسم المريضة', 'Enter patient name'))),
      );
      return;
    }
    Navigator.of(context).pop(_build());
  }

  Future<void> _pickLmp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp ?? now,
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
    );
    if (picked != null) setState(() => _lmp = picked);
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF5F8),
        appBar: AppBar(
          foregroundColor: Colors.white,
          elevation: 0,
          backgroundColor: _roseDark,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_roseDark, _rose],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
            ),
          ),
          title: const Text(
            'ملف مريضة جديدة  ·  New patient',
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
                    Icons.badge_outlined,
                    tr('البيانات الشخصية', 'Personal information'),
                    [
                      _field(
                        _name,
                        tr('اسم المريضة', 'Patient name'),
                        Icons.person_outline,
                        required: true,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _age,
                              tr('العمر', 'Age'),
                              Icons.cake_outlined,
                              keyboard: TextInputType.number,
                              maxLength: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _field(
                              _phone,
                              tr('رقم الهاتف', 'Phone number'),
                              Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      _caption(tr('فصيلة الدم', 'Blood group')),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in _bloodGroups)
                            _pill(
                              g,
                              selected: _bloodGroup == g,
                              onTap: () => setState(
                                () => _bloodGroup = _bloodGroup == g ? '' : g,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  _section(
                    Icons.event_note_outlined,
                    tr('سبب الزيارة', 'Reason for visit'),
                    [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < _visitTypes.length; i++)
                            _visitTile(i),
                        ],
                      ),
                      _field(
                        _complaint,
                        tr('الشكوى الرئيسية', 'Chief complaint'),
                        Icons.notes_rounded,
                        lines: 2,
                      ),
                    ],
                  ),
                  _section(
                    Icons.pregnant_woman_rounded,
                    tr('التاريخ التوليدي', 'Obstetric history'),
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _counter(
                              tr('حمل', 'Gravida'),
                              'G',
                              _gravida,
                              (v) => setState(() => _gravida = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _counter(
                              tr('ولادة', 'Para'),
                              'P',
                              _para,
                              (v) => setState(() => _para = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _counter(
                              tr('إجهاض', 'Abortion'),
                              'A',
                              _abortions,
                              (v) => setState(() => _abortions = v),
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _rose,
                        title: Text(
                          tr('حامل حالياً', 'Currently pregnant'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        value: _pregnant,
                        onChanged: (v) => setState(() => _pregnant = v),
                      ),
                      if (_pregnant)
                        InkWell(
                          onTap: _pickLmp,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: _decoration(
                              tr(
                                'تاريخ آخر دورة (LMP)',
                                'Last menstrual period (LMP)',
                              ),
                              Icons.calendar_month_outlined,
                            ),
                            child: Text(
                              _lmp == null
                                  ? tr('اختر التاريخ', 'Select date')
                                  : _date(_lmp!),
                              style: TextStyle(
                                color: _lmp == null ? _muted : _ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  _section(
                    Icons.monitor_heart_outlined,
                    tr('العلامات الحيوية', 'Vitals'),
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _systolic,
                              tr('الضغط الانقباضي', 'Systolic'),
                              Icons.arrow_upward_rounded,
                              keyboard: TextInputType.number,
                              maxLength: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _diastolic,
                              tr('الضغط الانبساطي', 'Diastolic'),
                              Icons.arrow_downward_rounded,
                              keyboard: TextInputType.number,
                              maxLength: 3,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _weight,
                              tr('الوزن (كجم)', 'Weight (kg)'),
                              Icons.monitor_weight_outlined,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              maxLength: 5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _hemoglobin,
                              tr('الهيموجلوبين', 'Hemoglobin'),
                              Icons.bloodtype_outlined,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              maxLength: 4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _section(
                    Icons.history_edu_outlined,
                    tr('التاريخ المرضي', 'Medical history'),
                    [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _historyItems.length; i++)
                            _pill(
                              tr(_historyItems[i].$1, _historyItems[i].$2),
                              selected: _history.contains(i),
                              onTap: () => setState(
                                () => _history.contains(i)
                                    ? _history.remove(i)
                                    : _history.add(i),
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
    final preview = _pregnant && _lmp != null
        ? ClinicPatient(name: '', pregnant: true, lmp: _lmp)
        : null;
    final age = preview?.gestationalAge();
    final edd = preview?.edd;
    String trimester() {
      final weeks = age?.$1 ?? 0;
      if (weeks < 14) return tr('الثلث الأول', '1st trimester');
      if (weeks < 28) return tr('الثلث الثاني', '2nd trimester');
      return tr('الثلث الثالث', '3rd trimester');
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_roseDark, _rose, Color(0xFFF08AB0)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40D6457F),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.pregnant_woman_rounded,
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
                  'عيادة النسا والتوليد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Obstetrics & Gynecology',
                  style: TextStyle(color: Color(0xFFFFE3EE), fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _heroChip(
                      Icons.timelapse_rounded,
                      age == null
                          ? tr('عمر الحمل: —', 'Gestation: —')
                          : tr(
                              '${age.$1} أسبوع + ${age.$2} يوم',
                              '${age.$1}w + ${age.$2}d',
                            ),
                    ),
                    _heroChip(
                      Icons.event_available_outlined,
                      edd == null
                          ? tr('الولادة المتوقعة: —', 'EDD: —')
                          : '${tr('الولادة المتوقعة', 'EDD')}: ${_date(edd)}',
                    ),
                    if (age != null)
                      _heroChip(Icons.layers_outlined, trimester()),
                  ],
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
      color: Colors.white.withValues(alpha: 0.2),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E1E9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F9B2C62),
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
                  color: _rose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _rose, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
    counterText: '',
    prefixIcon: Icon(icon, size: 20, color: _rose),
    filled: true,
    fillColor: const Color(0xFFFFF9FB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEBD3DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEBD3DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _rose, width: 1.6),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int lines = 1,
    int? maxLength,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      minLines: lines,
      maxLines: lines,
      maxLength: maxLength,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
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
          color: selected ? _rose : const Color(0xFFFFF1F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _rose : const Color(0xFFF3CCDB)),
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
                color: selected ? Colors.white : _roseDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visitTile(int index) {
    final (icon, ar, en) = _visitTypes[index];
    final selected = _visit == index;
    return InkWell(
      onTap: () => setState(() => _visit = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_roseDark, _rose])
              : null,
          color: selected ? null : const Color(0xFFFFF9FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _rose : const Color(0xFFEBD3DD)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : _rose, size: 22),
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
                      color: selected ? const Color(0xFFFFE3EE) : _muted,
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

  Widget _counter(
    String label,
    String letter,
    int value,
    ValueChanged<int> onChanged,
  ) {
    Widget button(IconData icon, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null ? const Color(0xFFF1E6EB) : _rose,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBD3DD)),
      ),
      child: Column(
        children: [
          Text(
            letter,
            style: const TextStyle(
              color: _rose,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              button(
                Icons.remove,
                value > 0 ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              button(Icons.add, value < 20 ? () => onChanged(value + 1) : null),
            ],
          ),
        ],
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
                    foregroundColor: _roseDark,
                    side: const BorderSide(color: Color(0xFFF3CCDB)),
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
                    gradient: const LinearGradient(colors: [_roseDark, _rose]),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55D6457F),
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
                                tr('حفظ ملف المريضة', 'Save patient file'),
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
