import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_kpi_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_kpi_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi_repository.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_attendance_kpi_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

class _FakeMentorKpiRepository implements MentorKpiRepository {
  String? lastFrom;
  String? lastTo;

  @override
  Future<MentorKpiSummary> loadSummary({
    String? fromDate,
    String? toDate,
  }) async {
    lastFrom = fromDate;
    lastTo = toDate;
    return MentorKpiSummary(
      mentorId: 5,
      mentorName: 'Tanaka Taro',
      fromDate: fromDate ?? '2026-09-01',
      toDate: toDate ?? '2026-11-16',
      teachingJlptLevels: const ['N3', 'N2'],
      totalAssignedSessions: 8,
      assignedBookingsCount: 5,
      assignedCourseSessionsCount: 3,
      completedValidSessions: 6,
      confirmedTeachingMinutes: 465,
      scheduledCompletedMinutes: 480,
      cancelledSessionsCount: 1,
      cancelledByMentorCount: 1,
      cancelledByLearnerCount: 0,
      missedOrNoShowSessionsCount: 0,
      upcomingOrIncompleteSessionsCount: 1,
      homeworkAssignedCount: 4,
      homeworkSubmittedCount: 3,
      homeworkGradedCount: 2,
      averageFeedbackTurnaroundMinutes: 95.0,
      feedbackTurnaroundSampleCount: 2,
      averageRating: 4.8,
      totalReviewsCount: 5,
      totalDisputesCount: 1,
      openDisputesCount: 0,
      resolvedRefundCount: 0,
      weeklyBreakdown: const [
        MentorKpiPeriodItem(
          periodKey: 'W46 (09/11)',
          periodStart: '2026-11-09',
          periodEnd: '2026-11-15',
          totalAssignedSessions: 3,
          completedValidSessions: 2,
          confirmedTeachingMinutes: 150,
          scheduledCompletedMinutes: 180,
          cancelledSessionsCount: 1,
          missedOrNoShowSessionsCount: 0,
          upcomingOrIncompleteSessionsCount: 0,
          homeworkAssignedCount: 2,
          homeworkSubmittedCount: 1,
          homeworkGradedCount: 1,
          averageFeedbackTurnaroundMinutes: 60.0,
          feedbackTurnaroundSampleCount: 1,
          reviewsCount: 2,
          averageRating: 5.0,
          disputesCount: 0,
        ),
      ],
      monthlyBreakdown: const [
        MentorKpiPeriodItem(
          periodKey: '2026-11',
          periodStart: '2026-11-01',
          periodEnd: '2026-11-30',
          totalAssignedSessions: 8,
          completedValidSessions: 6,
          confirmedTeachingMinutes: 465,
          scheduledCompletedMinutes: 480,
          cancelledSessionsCount: 1,
          missedOrNoShowSessionsCount: 0,
          upcomingOrIncompleteSessionsCount: 1,
          homeworkAssignedCount: 4,
          homeworkSubmittedCount: 3,
          homeworkGradedCount: 2,
          averageFeedbackTurnaroundMinutes: 95.0,
          feedbackTurnaroundSampleCount: 2,
          reviewsCount: 5,
          averageRating: 4.8,
          disputesCount: 1,
        ),
      ],
      recentSessions: [
        MentorKpiRecentSessionItem(
          sourceType: 'Booking1on1',
          bookingOrSessionId: 42,
          learnerName: 'Minh Nguyen',
          jlptLevel: 'N3',
          status: 'Completed',
          scheduledStartUtc: DateTime.utc(2026, 11, 14, 12, 0),
          scheduledMinutes: 90,
          observedMentorMinutes: 88,
          isValidCompleted: true,
        ),
      ],
    );
  }
}

void main() {
  test('parseMentorKpiSummary handles null turnaround and formats non-financial values', () {
    final dto = parseMentorKpiSummary(<String, Object?>{
      'mentorId': 5,
      'mentorName': 'Tanaka',
      'fromDate': '2026-10-01',
      'toDate': '2026-11-16',
      'teachingJlptLevels': ['N5', 'N3'],
      'totalAssignedSessions': 4,
      'completedValidSessions': 3,
      'confirmedTeachingMinutes': 195,
      'scheduledCompletedMinutes': 240,
      'averageFeedbackTurnaroundMinutes': null,
      'feedbackTurnaroundSampleCount': 0,
    });

    expect(dto.teachingJlptLevels, ['N5', 'N3']);
    expect(dto.averageFeedbackTurnaroundMinutes, isNull);
    expect(formatKpiTurnaround(dto.averageFeedbackTurnaroundMinutes), 'Chưa đủ dữ liệu');
    expect(formatKpiMinutes(dto.confirmedTeachingMinutes), '3g 15p');
    expect(formatKpiCompletionRate(dto.completedValidSessions, dto.totalAssignedSessions), '75%');
  });

  testWidgets('MentorAttendanceKpiScreen renders 8 KPI metrics, period switch & zero payroll/VND text', (tester) async {
    final repo = _FakeMentorKpiRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mentorKpiRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MentorAttendanceKpiScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mentor_attendance_kpi_screen')), findsOneWidget);
    expect(find.text('Chấm công & KPI'), findsOneWidget);
    expect(find.text('N3'), findsOneWidget);
    expect(find.text('N2'), findsOneWidget);
    expect(find.text('7g 45p'), findsOneWidget);
    expect(find.textContaining('4.8 ★'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('2026-11'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2026-11'), findsOneWidget);

    // Zero VND / payroll references
    expect(find.textContaining('₫'), findsNothing);
    expect(find.textContaining('Thu nhập'), findsNothing);

    await tester.ensureVisible(find.text('Tuần'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(find.text('W46 (09/11)'), findsOneWidget);
  });
}
