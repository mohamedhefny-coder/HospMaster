import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hospmaster/main.dart';
import 'package:hospmaster/surgery/oncology_surgery_page.dart';
import 'package:hospmaster/surgery/patient_follow_up_sheet_page.dart';
import 'package:hospmaster/surgery/patient_repository.dart';

Future<void> pumpDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const HospMasterApp());
  await tester.tap(find.text('Guest Mode'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows guest and subscriber mode cards on launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HospMasterApp());

    expect(find.text('Guest Mode'), findsOneWidget);
    expect(find.text('Subscriber Mode'), findsOneWidget);
  });

  testWidgets('shows the HospMaster dashboard', (WidgetTester tester) async {
    await pumpDashboard(tester);

    expect(find.text('صباح الخير، د. أحمد'), findsNothing);
    expect(find.text('إليك ملخص العمل اليوم'), findsNothing);
    expect(find.text('مركز التحكم الإداري'), findsOneWidget);
  });

  testWidgets(
    'general surgery active booking shows only the add patient action',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PatientFollowUpSheetPage(
            repository: DemoSurgeryPatientRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إضافة مريض'), findsOneWidget);
      expect(find.text('ابحث باسم المريض أو رقم الملف'), findsNothing);
      expect(find.text('المرضى الحاليون'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);

      await tester.tap(find.text('إضافة مريض'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientDetailsPage), findsOneWidget);
    },
  );

  testWidgets('a diagnosis added in the patient form shows in later forms', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> openForm() async {
      await tester.pumpWidget(
        MaterialApp(
          home: PatientDetailsPage(
            isNew: true,
            repository: DemoSurgeryPatientRepository(),
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
      await tester.pumpAndSettle();
    }

    await openForm();
    await tester.tap(find.text('التشخيص'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة عنصر جديد').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Rare diagnosis X');
    await tester.tap(find.text('إضافة').last);
    await tester.pumpAndSettle();

    expect(find.text('Rare diagnosis X'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await openForm();
    await tester.tap(find.text('التشخيص'));
    await tester.pumpAndSettle();
    expect(find.text('Rare diagnosis X'), findsOneWidget);
  });

  testWidgets('adds an obstetrics patient from the clinic manager', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpDashboard(tester);
    await tester.tap(find.text('إدارة العيادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عيادة النسا والتوليد'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add patient'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ ملف المريضة'));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Salma Ali');
    await tester.tap(find.text('حفظ ملف المريضة'));
    await tester.pumpAndSettle();

    expect(find.text('Salma Ali'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds a pediatric patient from the clinic manager', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpDashboard(tester);
    await tester.tap(find.text('إدارة العيادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عيادة الأطفال'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add patient'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Yassin Omar');
    await tester.tap(find.text('حفظ ملف الطفل'));
    await tester.pumpAndSettle();

    expect(find.text('Yassin Omar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a create account button that opens the auth page', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('إنشاء حساب'), findsWidgets);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
  });

  testWidgets('requires Supabase configuration for surgery waiting lists', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('إدارة المستشفى'));
    await tester.pumpAndSettle();
    expect(find.text('إدارة الأقسام'), findsOneWidget);
    expect(find.text('Waiting Lists'), findsOneWidget);
    await tester.ensureVisible(find.text('إدارة الأقسام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إدارة الأقسام'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting Lists'), findsNothing);
    await tester.ensureVisible(find.text('الجراحة العامة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الجراحة العامة'));
    await tester.pumpAndSettle();

    expect(find.text('إعداد Supabase مطلوب'), findsOneWidget);
  });

  testWidgets('shows pediatric surgery under waiting lists', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('إدارة المستشفى'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Waiting Lists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waiting Lists'));
    await tester.pumpAndSettle();

    expect(find.text('جراحة الأطفال'), findsOneWidget);
    expect(find.text('الجراحة العامة'), findsNothing);
  });

  testWidgets('requires Supabase configuration for oncology surgery', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('إدارة المستشفى'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('إدارة الأقسام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إدارة الأقسام'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('جراحة الأورام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جراحة الأورام'));
    await tester.pumpAndSettle();

    expect(find.text('إعداد Supabase مطلوب'), findsOneWidget);
  });

  testWidgets('saves an oncology patient and shows the patient profile', (
    WidgetTester tester,
  ) async {
    final repository = _FakePatientRepository();
    await tester.pumpWidget(
      MaterialApp(home: OncologySurgeryPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد مرضى بعد'), findsOneWidget);

    await tester.tap(find.byTooltip('إضافة مريض').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'اسم المريض'),
      'مريض تجريبي',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'أمر الطبيب'),
      'NPO after midnight',
    );
    expect(find.text('بيانات المريض'), findsOneWidget);
    await tester.ensureVisible(find.text('حفظ المريض'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ المريض'));
    await tester.pumpAndSettle();

    expect(repository.saved, hasLength(1));
    expect(
      repository.saved.single.doctorOrders.single.text,
      'NPO after midnight',
    );
    expect(find.text('مريض تجريبي'), findsOneWidget);

    await tester.tap(find.text('مريض تجريبي'));
    await tester.pumpAndSettle();

    expect(find.text('الملف السريري'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Doctor orders'), 300);
    expect(find.text('Doctor orders'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('NPO after midnight'), 300);
    expect(find.text('NPO after midnight'), findsOneWidget);
  });
}

class _FakePatientRepository extends SurgeryPatientRepository {
  final List<PatientRecord> saved = [];

  @override
  Future<List<PatientRecord>> fetchPatients(String department) async =>
      saved.where((patient) => patient.department == department).toList();

  @override
  Future<PatientRecord> savePatient(PatientRecord patient) async {
    final stored = PatientRecord.fromJson({
      ...patient.toJson(),
      'id': patient.id ?? 'patient-${saved.length + 1}',
    });
    saved
      ..removeWhere((item) => item.id == stored.id)
      ..insert(0, stored);
    return stored;
  }

  @override
  Future<void> removeFiles(List<String> paths) async {}
}
