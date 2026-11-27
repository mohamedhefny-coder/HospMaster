import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospmaster/auth/service_access.dart';
import 'package:hospmaster/main.dart';

ServiceAccessEntry entry(
  String service,
  AccessStatus status, {
  String? userId,
  String email = 'doc@example.com',
}) => ServiceAccessEntry(
  id: '$service-$email',
  userId: userId,
  email: email,
  service: HospService.fromKey(service),
  status: status,
);

void main() {
  group('ServiceAccess', () {
    test('only approved services of the signed-in user are allowed', () {
      final access = ServiceAccess.forUser(
        [
          entry('oncology_surgery', AccessStatus.approved, userId: 'u1'),
          entry('general_surgery', AccessStatus.pending, userId: 'u1'),
          entry('obgyn_clinic', AccessStatus.approved, email: 'other@x.com'),
        ],
        isAdmin: false,
        userId: 'u1',
        email: 'Doc@Example.com',
      );

      expect(access.approved, {HospService.oncologySurgery});
      expect(access.hasAccess, isTrue);
      expect(access.statuses[HospService.generalSurgery], AccessStatus.pending);
    });

    test('admin-added email rows apply before the user has a user id', () {
      final access = ServiceAccess.forUser(
        [entry('pediatric_surgery', AccessStatus.approved)],
        isAdmin: false,
        userId: 'u2',
        email: 'doc@example.com',
      );

      expect(access.approved, {HospService.pediatricSurgery});
    });

    test('pending or rejected rows give no access; admins get everything', () {
      final entries = [
        entry('general_surgery', AccessStatus.pending, userId: 'u1'),
        entry('obgyn_clinic', AccessStatus.rejected, userId: 'u1'),
      ];

      expect(
        ServiceAccess.forUser(
          entries,
          isAdmin: false,
          userId: 'u1',
          email: 'doc@example.com',
        ).hasAccess,
        isFalse,
      );
      expect(
        ServiceAccess.forUser(
          const [],
          isAdmin: true,
          userId: 'admin',
          email: 'a@x.com',
        ).approved,
        HospService.values.toSet(),
      );
    });
  });

  group('formatLastSeen', () {
    final now = DateTime.utc(2026, 11, 27, 12);

    test('shows relative time and a never-seen fallback', () {
      expect(formatLastSeen(null, false, now: now), 'Never seen');
      expect(
        formatLastSeen(
          now.subtract(const Duration(minutes: 5)),
          false,
          now: now,
        ),
        '5 min ago',
      );
      expect(
        formatLastSeen(now.subtract(const Duration(hours: 3)), true, now: now),
        'منذ 3 ساعة',
      );
    });
  });

  testWidgets('five quick taps on the logo open the protected admin panel', (
    tester,
  ) async {
    await tester.pumpWidget(const HospMasterApp());

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(Image));
    }
    await tester.pumpAndSettle();
    expect(find.text('لوحة تحكم المدير'), findsNothing);

    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    expect(find.text('لوحة تحكم المدير'), findsOneWidget);
    expect(find.text('المستخدمون والطلبات'), findsNothing);
  });

  testWidgets('dashboard shows only the approved services', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HospitalDashboard(services: {HospService.oncologySurgery}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إدارة العيادات'), findsNothing);

    await tester.tap(find.text('إدارة المستشفيات'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting Lists'), findsNothing);

    await tester.ensureVisible(find.text('إدارة الأقسام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إدارة الأقسام'));
    await tester.pumpAndSettle();

    expect(find.text('جراحة الأورام'), findsOneWidget);
    expect(find.text('الجراحة العامة'), findsNothing);
  });
}
