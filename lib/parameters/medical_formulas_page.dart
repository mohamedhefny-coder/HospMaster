import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hospmaster/auth/account_button.dart';
import 'package:hospmaster/parameters/clinical_scores.dart';
import 'package:hospmaster/surgery/surgery_department_page.dart'
    show PediatricParametersSection;

const _navy = Color(0xFF172B4D);
const _purple = Color(0xFF7A4CB3);

class _Field {
  const _Field(
    this.key,
    this.ar,
    this.en, {
    this.unit = '',
    this.isSex = false,
  });

  final String key;
  final String ar;
  final String en;
  final String unit;
  final bool isSex;
}

class _Formula {
  const _Formula({
    required this.arTitle,
    required this.enTitle,
    required this.expression,
    required this.icon,
    required this.fields,
    required this.compute,
    this.source =
        'Standard clinical equation; verify the current local guideline.',
  });

  final String arTitle;
  final String enTitle;
  final String expression;
  final IconData icon;
  final List<_Field> fields;
  final String? Function(Map<String, double> v, bool female, bool ar) compute;
  final String source;
}

String _n(double value, [int digits = 1]) => value.toStringAsFixed(digits);

/// Holliday-Segar maintenance fluid in mL/day (100/50/20 mL/kg).
double _maintenancePerDay(double kg) {
  if (kg <= 10) return kg * 100;
  if (kg <= 20) return 1000 + (kg - 10) * 50;
  return 1500 + (kg - 20) * 20;
}

final List<_Formula> _formulas = [
  _Formula(
    arTitle: 'مؤشر كتلة الجسم (BMI)',
    enTitle: 'Body Mass Index (BMI)',
    expression: 'BMI = weight(kg) / height(m)²',
    icon: Icons.monitor_weight_outlined,
    fields: const [
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('h', 'الطول', 'Height', unit: 'cm'),
    ],
    compute: (v, female, ar) {
      final w = v['w'], h = v['h'];
      if (w == null || h == null || w <= 0 || h <= 0) return null;
      final bmi = w / math.pow(h / 100, 2);
      final category = bmi < 18.5
          ? (ar ? 'نحافة' : 'Underweight')
          : bmi < 25
          ? (ar ? 'وزن طبيعي' : 'Normal')
          : bmi < 30
          ? (ar ? 'وزن زائد' : 'Overweight')
          : (ar ? 'سمنة' : 'Obese');
      return 'BMI = ${_n(bmi)} kg/m²  ($category)';
    },
  ),
  _Formula(
    arTitle: 'مساحة سطح الجسم (BSA)',
    enTitle: 'Body Surface Area (BSA)',
    expression: 'BSA = √(height(cm) × weight(kg) / 3600)  [Mosteller]',
    icon: Icons.accessibility_new_outlined,
    fields: const [
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('h', 'الطول', 'Height', unit: 'cm'),
    ],
    compute: (v, female, ar) {
      final w = v['w'], h = v['h'];
      if (w == null || h == null || w <= 0 || h <= 0) return null;
      return 'BSA = ${_n(math.sqrt(h * w / 3600), 2)} m²';
    },
  ),
  _Formula(
    arTitle: 'الوزن المثالي (Devine)',
    enTitle: 'Ideal Body Weight (Devine)',
    expression:
        'Male: 50 + 2.3 × (in > 60)   |   Female: 45.5 + 2.3 × (in > 60)',
    icon: Icons.scale_outlined,
    fields: const [
      _Field('sex', 'الجنس', 'Sex', isSex: true),
      _Field('h', 'الطول', 'Height', unit: 'cm'),
    ],
    compute: (v, female, ar) {
      final h = v['h'];
      if (h == null || h <= 0) return null;
      final inches = h / 2.54;
      final ibw = (female ? 45.5 : 50) + 2.3 * math.max(inches - 60, 0);
      return 'IBW = ${_n(ibw)} kg';
    },
  ),
  _Formula(
    arTitle: 'ضغط الدم الشرياني المتوسط (MAP)',
    enTitle: 'Mean Arterial Pressure (MAP)',
    expression: 'MAP = (SBP + 2 × DBP) / 3',
    icon: Icons.favorite_border,
    fields: const [
      _Field('sbp', 'الانقباضي', 'Systolic', unit: 'mmHg'),
      _Field('dbp', 'الانبساطي', 'Diastolic', unit: 'mmHg'),
    ],
    compute: (v, female, ar) {
      final s = v['sbp'], d = v['dbp'];
      if (s == null || d == null || s <= 0 || d <= 0) return null;
      return 'MAP = ${_n((s + 2 * d) / 3)} mmHg';
    },
  ),
  _Formula(
    arTitle: 'تصفية الكرياتينين (Cockcroft-Gault)',
    enTitle: 'Creatinine Clearance (Cockcroft-Gault)',
    expression: 'CrCl = (140 − age) × weight / (72 × SCr)  (× 0.85 if female)',
    icon: Icons.water_drop_outlined,
    fields: const [
      _Field('sex', 'الجنس', 'Sex', isSex: true),
      _Field('age', 'العمر', 'Age', unit: 'years'),
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('scr', 'الكرياتينين', 'Serum creatinine', unit: 'mg/dL'),
    ],
    compute: (v, female, ar) {
      final age = v['age'], w = v['w'], scr = v['scr'];
      if (age == null || w == null || scr == null) return null;
      if (age <= 0 || w <= 0 || scr <= 0) return null;
      final crcl = (140 - age) * w / (72 * scr) * (female ? 0.85 : 1);
      return 'CrCl = ${_n(crcl)} mL/min';
    },
  ),
  _Formula(
    arTitle: 'معدل الترشيح الكبيبي (eGFR CKD-EPI 2021)',
    enTitle: 'eGFR (CKD-EPI 2021)',
    expression:
        '142 × min(SCr/κ,1)^α × max(SCr/κ,1)^−1.200 × 0.9938^age × 1.012 (female)',
    icon: Icons.bloodtype_outlined,
    fields: const [
      _Field('sex', 'الجنس', 'Sex', isSex: true),
      _Field('age', 'العمر', 'Age', unit: 'years'),
      _Field('scr', 'الكرياتينين', 'Serum creatinine', unit: 'mg/dL'),
    ],
    compute: (v, female, ar) {
      final age = v['age'], scr = v['scr'];
      if (age == null || scr == null || age <= 0 || scr <= 0) return null;
      final k = female ? 0.7 : 0.9;
      final a = female ? -0.241 : -0.302;
      final ratio = scr / k;
      final egfr =
          142.0 *
          math.pow(math.min(ratio, 1), a) *
          math.pow(math.max(ratio, 1), -1.200) *
          math.pow(0.9938, age) *
          (female ? 1.012 : 1);
      return 'eGFR = ${_n(egfr.toDouble())} mL/min/1.73m²';
    },
  ),
  _Formula(
    arTitle: 'الكالسيوم المصحح',
    enTitle: 'Corrected Calcium',
    expression: 'Ca corrected = Ca + 0.8 × (4.0 − albumin)',
    icon: Icons.science_outlined,
    fields: const [
      _Field('ca', 'الكالسيوم', 'Calcium', unit: 'mg/dL'),
      _Field('alb', 'الألبومين', 'Albumin', unit: 'g/dL'),
    ],
    compute: (v, female, ar) {
      final ca = v['ca'], alb = v['alb'];
      if (ca == null || alb == null || ca <= 0 || alb <= 0) return null;
      return 'Ca = ${_n(ca + 0.8 * (4 - alb), 2)} mg/dL';
    },
  ),
  _Formula(
    arTitle: 'فجوة الأنيون (Anion Gap)',
    enTitle: 'Anion Gap',
    expression: 'AG = Na⁺ − (Cl⁻ + HCO₃⁻)',
    icon: Icons.biotech_outlined,
    fields: const [
      _Field('na', 'الصوديوم', 'Sodium', unit: 'mEq/L'),
      _Field('cl', 'الكلوريد', 'Chloride', unit: 'mEq/L'),
      _Field('hco3', 'البيكربونات', 'Bicarbonate', unit: 'mEq/L'),
    ],
    compute: (v, female, ar) {
      final na = v['na'], cl = v['cl'], hco3 = v['hco3'];
      if (na == null || cl == null || hco3 == null) return null;
      return 'AG = ${_n(na - (cl + hco3))} mEq/L';
    },
  ),
  _Formula(
    arTitle: 'معدل تنقيط المحلول الوريدي',
    enTitle: 'IV Drip Rate',
    expression: 'gtt/min = volume(mL) × drop factor(gtt/mL) / time(min)',
    icon: Icons.opacity_outlined,
    fields: const [
      _Field('vol', 'الحجم', 'Volume', unit: 'mL'),
      _Field('df', 'معامل القطرة', 'Drop factor', unit: 'gtt/mL'),
      _Field('t', 'المدة', 'Time', unit: 'min'),
    ],
    compute: (v, female, ar) {
      final vol = v['vol'], df = v['df'], t = v['t'];
      if (vol == null || df == null || t == null) return null;
      if (vol <= 0 || df <= 0 || t <= 0) return null;
      return '${_n(vol * df / t)} gtt/min  |  ${_n(vol / (t / 60))} mL/h';
    },
  ),
  _Formula(
    arTitle: 'جرعة الدواء حسب الوزن',
    enTitle: 'Weight-based Dose',
    expression: 'Dose(mg) = dose(mg/kg) × weight(kg)',
    icon: Icons.medication_outlined,
    fields: const [
      _Field('dose', 'الجرعة', 'Dose', unit: 'mg/kg'),
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
    ],
    compute: (v, female, ar) {
      final dose = v['dose'], w = v['w'];
      if (dose == null || w == null || dose <= 0 || w <= 0) return null;
      return 'Dose = ${_n(dose * w, 2)} mg';
    },
  ),
  _Formula(
    arTitle: 'السوائل اليومية للأطفال (4-2-1)',
    enTitle: 'Maintenance Fluids (4-2-1)',
    expression: '4 mL/kg (first 10 kg) + 2 mL/kg (next 10 kg) + 1 mL/kg (rest)',
    icon: Icons.child_care_outlined,
    fields: const [_Field('w', 'الوزن', 'Weight', unit: 'kg')],
    compute: (v, female, ar) {
      final w = v['w'];
      if (w == null || w <= 0) return null;
      final double rate =
          4 * math.min(w, 10.0) +
          2 * math.min(math.max(w - 10, 0.0), 10.0) +
          math.max(w - 20, 0.0);
      return '${_n(rate)} mL/h  |  ${_n(rate * 24, 0)} mL/24h';
    },
  ),
  _Formula(
    arTitle: 'QT المصحح (Bazett)',
    enTitle: 'Corrected QT (Bazett)',
    expression: 'QTc = QT / √RR      RR = 60 / HR',
    icon: Icons.monitor_heart_outlined,
    fields: const [
      _Field('qt', 'QT', 'QT interval', unit: 'ms'),
      _Field('hr', 'النبض', 'Heart rate', unit: 'bpm'),
    ],
    compute: (v, female, ar) {
      final qt = v['qt'], hr = v['hr'];
      if (qt == null || hr == null || qt <= 0 || hr <= 0) return null;
      return 'QTc = ${_n(qt / math.sqrt(60 / hr), 0)} ms';
    },
  ),
  _Formula(
    arTitle: 'ضغط النبض (Pulse Pressure)',
    enTitle: 'Pulse Pressure',
    expression: 'PP = SBP − DBP',
    icon: Icons.favorite_outline,
    source: 'AHA/ACC blood-pressure assessment principles.',
    fields: const [
      _Field('sbp', 'الانقباضي', 'Systolic', unit: 'mmHg'),
      _Field('dbp', 'الانبساطي', 'Diastolic', unit: 'mmHg'),
    ],
    compute: (v, female, ar) {
      final sbp = v['sbp'], dbp = v['dbp'];
      if (sbp == null || dbp == null || sbp <= 0 || dbp <= 0) return null;
      return 'PP = ${_n(sbp - dbp)} mmHg';
    },
  ),
  _Formula(
    arTitle: 'مؤشر الصدمة',
    enTitle: 'Shock Index',
    expression: 'SI = heart rate / systolic blood pressure',
    icon: Icons.monitor_heart_outlined,
    source:
        'Allgöwer and Burri, Schweizerische Medizinische Wochenschrift (1967).',
    fields: const [
      _Field('hr', 'النبض', 'Heart rate', unit: 'bpm'),
      _Field('sbp', 'الضغط الانقباضي', 'Systolic BP', unit: 'mmHg'),
    ],
    compute: (v, female, ar) {
      final hr = v['hr'], sbp = v['sbp'];
      if (hr == null || sbp == null || hr <= 0 || sbp <= 0) return null;
      return 'SI = ${_n(hr / sbp, 2)}';
    },
  ),
  _Formula(
    arTitle: 'الصوديوم المصحح لفرط سكر الدم',
    enTitle: 'Corrected Sodium for Hyperglycemia',
    expression: 'Na corrected = Na measured + 1.6 × ((glucose − 100) / 100)',
    icon: Icons.water_drop_outlined,
    source: 'Hillier et al., American Journal of Medicine (1999).',
    fields: const [
      _Field('na', 'الصوديوم المقاس', 'Measured sodium', unit: 'mEq/L'),
      _Field('glucose', 'الجلوكوز', 'Glucose', unit: 'mg/dL'),
    ],
    compute: (v, female, ar) {
      final na = v['na'], glucose = v['glucose'];
      if (na == null || glucose == null || na <= 0 || glucose <= 0) return null;
      return 'Na corrected = ${_n(na + 1.6 * ((glucose - 100) / 100), 1)} mEq/L';
    },
  ),
  _Formula(
    arTitle: 'الأسمولالية المحسوبة',
    enTitle: 'Calculated Serum Osmolality',
    expression: '2 × Na + glucose/18 + BUN/2.8',
    icon: Icons.science_outlined,
    source:
        'Clinical chemistry standard calculation; SI units must be converted.',
    fields: const [
      _Field('na', 'الصوديوم', 'Sodium', unit: 'mEq/L'),
      _Field('glucose', 'الجلوكوز', 'Glucose', unit: 'mg/dL'),
      _Field('bun', 'اليوريا (BUN)', 'BUN', unit: 'mg/dL'),
    ],
    compute: (v, female, ar) {
      final na = v['na'], glucose = v['glucose'], bun = v['bun'];
      if (na == null ||
          glucose == null ||
          bun == null ||
          na <= 0 ||
          glucose < 0 ||
          bun < 0) {
        return null;
      }
      return 'Osm = ${_n(2 * na + glucose / 18 + bun / 2.8)} mOsm/kg';
    },
  ),
  _Formula(
    arTitle: 'فجوة الأسمولالية',
    enTitle: 'Osmolal Gap',
    expression: 'Gap = measured osmolality − calculated osmolality',
    icon: Icons.science_outlined,
    source: 'Standard toxicology and clinical chemistry calculation.',
    fields: const [
      _Field(
        'measured',
        'الأسمولالية المقاسة',
        'Measured osmolality',
        unit: 'mOsm/kg',
      ),
      _Field('na', 'الصوديوم', 'Sodium', unit: 'mEq/L'),
      _Field('glucose', 'الجلوكوز', 'Glucose', unit: 'mg/dL'),
      _Field('bun', 'اليوريا (BUN)', 'BUN', unit: 'mg/dL'),
    ],
    compute: (v, female, ar) {
      final measured = v['measured'];
      final na = v['na'], glucose = v['glucose'], bun = v['bun'];
      if (measured == null ||
          na == null ||
          glucose == null ||
          bun == null ||
          measured <= 0 ||
          na <= 0 ||
          glucose < 0 ||
          bun < 0) {
        return null;
      }
      final calculated = 2 * na + glucose / 18 + bun / 2.8;
      return 'Gap = ${_n(measured - calculated)} mOsm/kg';
    },
  ),
  _Formula(
    arTitle: 'جرعة حسب الوزن ثم حجم المحلول',
    enTitle: 'Weight-based Dose to Volume',
    expression:
        'dose(mg) = mg/kg × kg; volume(mL) = dose(mg) / concentration(mg/mL)',
    icon: Icons.medication_outlined,
    source:
        'Medication-safety calculation; use only the prescribed dose and verified concentration.',
    fields: const [
      _Field('dose', 'الجرعة الموصوفة', 'Prescribed dose', unit: 'mg/kg'),
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('conc', 'التركيز', 'Concentration', unit: 'mg/mL'),
    ],
    compute: (v, female, ar) {
      final dose = v['dose'], w = v['w'], conc = v['conc'];
      if (dose == null ||
          w == null ||
          conc == null ||
          dose <= 0 ||
          w <= 0 ||
          conc <= 0) {
        return null;
      }
      final total = dose * w;
      return 'Dose = ${_n(total, 2)} mg  |  Volume = ${_n(total / conc, 2)} mL';
    },
  ),
  _Formula(
    arTitle: 'حجم الجرعة الفموية (أقراص/مل)',
    enTitle: 'Oral Dose Volume or Tablet Count',
    expression:
        'volume = prescribed dose / liquid strength; tablets = prescribed dose / tablet strength',
    icon: Icons.medication_liquid_outlined,
    source:
        'Medication-safety calculation; confirm formulation and maximum dose.',
    fields: const [
      _Field('dose', 'الجرعة المطلوبة', 'Required dose', unit: 'mg'),
      _Field(
        'strength',
        'قوة القرص أو السائل',
        'Strength',
        unit: 'mg per tablet or mg/mL',
      ),
    ],
    compute: (v, female, ar) {
      final dose = v['dose'], strength = v['strength'];
      if (dose == null || strength == null || dose <= 0 || strength <= 0) {
        return null;
      }
      return 'Tablets or mL = ${_n(dose / strength, 2)}';
    },
  ),
  _Formula(
    arTitle: 'معدل التسريب الوريدي من جرعة/وزن/زمن',
    enTitle: 'IV Infusion Rate from Dose',
    expression: 'mL/h = dose(mcg/kg/min) × kg × 60 / concentration(mcg/mL)',
    icon: Icons.bloodtype_outlined,
    source:
        'Critical-care infusion conversion; verify pump concentration and units independently.',
    fields: const [
      _Field('dose', 'معدل الجرعة', 'Dose rate', unit: 'mcg/kg/min'),
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('conc', 'التركيز', 'Concentration', unit: 'mcg/mL'),
    ],
    compute: (v, female, ar) {
      final dose = v['dose'], w = v['w'], conc = v['conc'];
      if (dose == null ||
          w == null ||
          conc == null ||
          dose <= 0 ||
          w <= 0 ||
          conc <= 0) {
        return null;
      }
      return 'Rate = ${_n(dose * w * 60 / conc, 2)} mL/h';
    },
  ),
  _Formula(
    arTitle: 'تحويل الوحدات في التسريب الوريدي',
    enTitle: 'Units/kg/hour Infusion Rate',
    expression:
        'units/h = units/kg/h × kg; mL/h = units/h / concentration(units/mL)',
    icon: Icons.speed_outlined,
    source:
        'Medication-safety calculation; common for heparin and insulin protocols.',
    fields: const [
      _Field('dose', 'معدل الجرعة', 'Dose rate', unit: 'units/kg/h'),
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('conc', 'التركيز', 'Concentration', unit: 'units/mL'),
    ],
    compute: (v, female, ar) {
      final dose = v['dose'], w = v['w'], conc = v['conc'];
      if (dose == null ||
          w == null ||
          conc == null ||
          dose <= 0 ||
          w <= 0 ||
          conc <= 0) {
        return null;
      }
      final unitsPerHour = dose * w;
      return '${_n(unitsPerHour, 2)} units/h  |  ${_n(unitsPerHour / conc, 2)} mL/h';
    },
  ),
  _Formula(
    arTitle: 'جرعة حسب مساحة سطح الجسم',
    enTitle: 'Body Surface Area Dose',
    expression: 'dose(mg) = dose(mg/m²) × BSA(m²)',
    icon: Icons.medical_services_outlined,
    source: 'Mosteller BSA (1987); use the protocol-specific dose and limits.',
    fields: const [
      _Field('dose', 'الجرعة', 'Prescribed dose', unit: 'mg/m²'),
      _Field('bsa', 'مساحة سطح الجسم', 'BSA', unit: 'm²'),
    ],
    compute: (v, female, ar) {
      final dose = v['dose'], bsa = v['bsa'];
      if (dose == null || bsa == null || dose <= 0 || bsa <= 0) return null;
      return 'Dose = ${_n(dose * bsa, 2)} mg';
    },
  ),
  _Formula(
    arTitle: 'الجرعة مع حد أقصى',
    enTitle: 'Weight-based Dose with Maximum',
    expression: 'final dose = min(mg/kg × kg, maximum single dose)',
    icon: Icons.verified_outlined,
    source:
        'Medication-safety calculation; the maximum must come from the approved protocol.',
    fields: const [
      _Field('dose', 'الجرعة', 'Prescribed dose', unit: 'mg/kg'),
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('max', 'الحد الأقصى', 'Maximum dose', unit: 'mg'),
    ],
    compute: (v, female, ar) {
      final dose = v['dose'], w = v['w'], max = v['max'];
      if (dose == null ||
          w == null ||
          max == null ||
          dose <= 0 ||
          w <= 0 ||
          max <= 0) {
        return null;
      }
      final calculated = dose * w;
      final finalDose = math.min(calculated, max);
      return 'Calculated = ${_n(calculated, 2)} mg  |  Final = ${_n(finalDose, 2)} mg';
    },
  ),
  _Formula(
    arTitle: 'السوائل اليومية أثناء الصيام (Holliday-Segar)',
    enTitle: 'Daily Maintenance Fluids While Fasting (Holliday-Segar)',
    expression:
        '≤10 kg: 100 mL/kg  |  10-20 kg: +50 mL/kg  |  >20 kg: +20 mL/kg',
    icon: Icons.water_drop_outlined,
    source:
        'Holliday & Segar (1957). Not for neonates in the first days of life; adjust for fever, renal/cardiac disease and the local protocol.',
    fields: const [_Field('w', 'الوزن', 'Weight', unit: 'kg')],
    compute: (v, female, ar) {
      final w = v['w'];
      if (w == null || w <= 0) return null;
      final day = _maintenancePerDay(w);
      return 'Maintenance = ${_n(day, 0)} mL/24 h  |  ${_n(day / 24)} mL/h  |  ${_n(day / w)} mL/kg/day';
    },
  ),
  _Formula(
    arTitle: 'عجز السوائل قبل العملية (فترة الصيام)',
    enTitle: 'Preoperative Fasting Fluid Deficit',
    expression: 'deficit = hourly maintenance (4-2-1) × fasting hours',
    icon: Icons.hourglass_bottom_outlined,
    source:
        'Common anesthesia practice: replace 50% of the deficit in the first hour and 25% in each of the next two hours, using an isotonic fluid. Follow the local protocol.',
    fields: const [
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field('h', 'ساعات الصيام', 'Fasting hours', unit: 'h'),
    ],
    compute: (v, female, ar) {
      final w = v['w'], h = v['h'];
      if (w == null || h == null || w <= 0 || h <= 0) return null;
      final perHour = _maintenancePerDay(w) / 24;
      final deficit = perHour * h;
      return 'Maintenance = ${_n(perHour)} mL/h  |  Deficit = ${_n(deficit, 0)} mL\n'
          '1st hour = ${_n(deficit * 0.5, 0)} mL  |  2nd hour = ${_n(deficit * 0.25, 0)} mL  |  3rd hour = ${_n(deficit * 0.25, 0)} mL';
    },
  ),
  _Formula(
    arTitle: 'السوائل بعد العملية أثناء الصيام (24 ساعة)',
    enTitle: 'Postoperative Fluids While Fasting (24 h)',
    expression: 'total = maintenance (Holliday-Segar) + ongoing losses',
    icon: Icons.local_hospital_outlined,
    source:
        'Add measured losses (NG tube, drains, stoma, vomiting) as replacement, usually with an isotonic fluid. Reassess volume status and electrolytes daily.',
    fields: const [
      _Field('w', 'الوزن', 'Weight', unit: 'kg'),
      _Field(
        'loss',
        'الفقد المستمر (اختياري)',
        'Ongoing losses (optional)',
        unit: 'mL/24 h',
      ),
    ],
    compute: (v, female, ar) {
      final w = v['w'];
      if (w == null || w <= 0) return null;
      final loss = math.max(v['loss'] ?? 0.0, 0.0);
      final maintenance = _maintenancePerDay(w);
      final total = maintenance + loss;
      return 'Maintenance = ${_n(maintenance, 0)} mL  |  Losses = ${_n(loss, 0)} mL\n'
          'Total = ${_n(total, 0)} mL/24 h  |  ${_n(total / 24)} mL/h';
    },
  ),
];

class MedicalFormulasPage extends StatefulWidget {
  const MedicalFormulasPage({
    super.key,
    required this.isArabic,
    required this.role,
    required this.onLanguageChanged,
  });

  final bool isArabic;
  final String role;
  final ValueChanged<bool> onLanguageChanged;

  @override
  State<MedicalFormulasPage> createState() => _MedicalFormulasPageState();
}

class _MedicalFormulasPageState extends State<MedicalFormulasPage> {
  late bool _isArabic = widget.isArabic;
  String _search = '';

  String tr(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final items = _formulas.where((f) {
      if (query.isEmpty) return true;
      return f.arTitle.toLowerCase().contains(query) ||
          f.enTitle.toLowerCase().contains(query);
    }).toList();

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr('المعايير الطبية', 'Medical Parameters')),
            backgroundColor: Colors.white,
            foregroundColor: _navy,
            actions: [
              AccountButton(isArabic: _isArabic),
              Center(
                child: Text(
                  tr('العربية', 'English'),
                  style: const TextStyle(fontSize: 12, color: _purple),
                ),
              ),
              Switch(
                value: _isArabic,
                onChanged: (value) {
                  setState(() => _isArabic = value);
                  widget.onLanguageChanged(value);
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              labelColor: _purple,
              indicatorColor: _purple,
              tabs: [
                Tab(text: tr('المعادلات الطبية', 'Medical Formulas')),
                const Tab(text: 'parameters'),
                const Tab(text: 'scores'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _tabBody(_formulasTab(items)),
              _tabBody([PediatricParametersSection(isArabic: _isArabic)]),
              _tabBody([const ClinicalScoresSection()]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBody(List<Widget> children) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );

  List<Widget> _formulasTab(List<_Formula> items) => [
    TextField(
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: tr('ابحث عن معادلة...', 'Search formulas...'),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        tr(
          'للمساعدة السريرية فقط وليست وصفة علاجية. راجع التشخيص، العمر، الحساسية، وظائف الكلى والكبد، التركيز، الحد الأقصى، والبروتوكول المحلي قبل إعطاء أي دواء. الدور الحالي: ${widget.role}',
          'Clinical support only, not a prescription. Verify diagnosis, age, allergies, renal/hepatic function, concentration, maximum dose, and local protocol before giving any medicine. Active role: ${widget.role}',
        ),
        style: const TextStyle(
          color: Color(0xFF9B2C2C),
          fontSize: 12,
          height: 1.45,
        ),
      ),
    ),
    if (items.isEmpty)
      Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(tr('لا توجد نتائج', 'No results'))),
      ),
    for (final formula in items)
      _FormulaCard(
        key: ValueKey(formula.enTitle),
        formula: formula,
        isArabic: _isArabic,
      ),
  ];
}

class _FormulaCard extends StatefulWidget {
  const _FormulaCard({
    super.key,
    required this.formula,
    required this.isArabic,
  });

  final _Formula formula;
  final bool isArabic;

  @override
  State<_FormulaCard> createState() => _FormulaCardState();
}

class _FormulaCardState extends State<_FormulaCard> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.formula.fields.where((f) => !f.isSex))
      f.key: TextEditingController(),
  };
  bool _female = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    final formula = widget.formula;
    final values = <String, double>{};
    _controllers.forEach((key, controller) {
      final parsed = double.tryParse(
        controller.text.trim().replaceAll(',', '.'),
      );
      if (parsed != null) values[key] = parsed;
    });
    final result = formula.compute(values, _female, ar);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: _purple.withValues(alpha: 0.12),
            child: Icon(formula.icon, color: _purple),
          ),
          title: Text(
            ar ? formula.arTitle : formula.enTitle,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              formula.expression,
              style: const TextStyle(color: Color(0xFF718096), fontSize: 11),
            ),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final field in formula.fields)
                  SizedBox(
                    width: 200,
                    child: field.isSex
                        ? SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(ar ? 'ذكر' : 'Male'),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(ar ? 'أنثى' : 'Female'),
                              ),
                            ],
                            selected: {_female},
                            onSelectionChanged: (s) =>
                                setState(() => _female = s.first),
                          )
                        : TextField(
                            controller: _controllers[field.key],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: ar ? field.ar : field.en,
                              suffixText: field.unit,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  result ??
                      (ar
                          ? 'أدخل القيم لحساب النتيجة'
                          : 'Enter values to calculate'),
                  style: TextStyle(
                    color: result == null ? const Color(0xFF718096) : _purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ar ? 'المصدر' : 'Source'}: ${formula.source}',
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
