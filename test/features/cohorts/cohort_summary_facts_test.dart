import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_summary_facts.dart';

StudyCohortSummary _cohort({
  required int id,
  required String intensity,
  required String label,
  required int perWeek,
  int seats = 2,
  bool open = true,
}) => StudyCohortSummary(
  id: id,
  planId: 1,
  name: 'Lớp $label',
  mentorId: 2,
  mentorName: 'Tanaka Sensei',
  startsAt: DateTime(2026, 12, 7, 19),
  endsAt: DateTime(2027, 2, 14, 20, 30),
  capacity: 4,
  enrolledCount: 4 - seats,
  seatsAvailable: seats,
  status: 'Published',
  level: 'N4',
  totalSessions: perWeek * 10,
  sessionMinutes: 90,
  price: 2500000,
  enrollmentClosesAtUtc: DateTime(2026, 12, 6),
  requiresEntitlement: false,
  hasApprovedEntitlement: false,
  entitlementReference: null,
  entitlementStatusMessage: null,
  myEnrollmentCourseId: null,
  myEnrollmentStatus: null,
  enrollmentOpen: open,
  sessions: const [],
  intensity: intensity,
  intensityLabel: label,
  sessionsPerWeek: perWeek,
  totalTeachingHours: perWeek * 15,
  schedulePattern: const [
    CohortSchedulePatternItem(
      weekday: 1,
      weekdayLabel: 'Thứ 2',
      localStart: '19:00',
      localEnd: '20:30',
    ),
  ],
);

Future<void> _pump(WidgetTester tester, StudyCohortSummary c) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CohortSummaryFacts(cohort: c)),
        ),
      ),
    );

void main() {
  for (final (intensity, label, perWeek) in [
    ('Light', 'Nhẹ', 2),
    ('Standard', 'Tiêu chuẩn', 3),
    ('Advanced', 'Nâng cao', 4),
  ]) {
    testWidgets('$perWeek buổi/tuần hiển thị cường độ $label không cần lọc', (
      tester,
    ) async {
      await _pump(
        tester,
        _cohort(
          id: perWeek,
          intensity: intensity,
          label: label,
          perWeek: perWeek,
        ),
      );
      expect(
        find.text('Cường độ: $label · $perWeek buổi/tuần'),
        findsOneWidget,
      );
      expect(find.textContaining('N4'), findsOneWidget);
      expect(find.textContaining('Tanaka Sensei'), findsOneWidget);
      expect(find.textContaining('Thứ 2 19:00–20:30'), findsOneWidget);
      expect(find.textContaining('90 phút/buổi'), findsOneWidget);
      expect(
        find.textContaining('${perWeek * 10} buổi · 10 tuần'),
        findsOneWidget,
      );
      expect(find.textContaining('2/4'), findsOneWidget);
      expect(find.textContaining('2.500.000'), findsOneWidget);
      expect(find.text('Còn chỗ'), findsOneWidget);
    });
  }

  testWidgets('trạng thái ghi danh tách biệt với cường độ', (tester) async {
    await _pump(
      tester,
      _cohort(
        id: 9,
        intensity: 'Advanced',
        label: 'Nâng cao',
        perWeek: 4,
        seats: 0,
      ),
    );
    expect(find.text('Cường độ: Nâng cao · 4 buổi/tuần'), findsOneWidget);
    expect(find.text('Đã đủ chỗ'), findsOneWidget);
    expect(
      cohortAvailabilityOf(
        _cohort(
          id: 1,
          intensity: 'Light',
          label: 'Nhẹ',
          perWeek: 2,
          open: false,
        ),
      ),
      CohortEnrollmentAvailability.upcoming,
    );
  });
}
