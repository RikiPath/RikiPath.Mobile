import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/meeting/application/upcoming_meeting_provider.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_home_section.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

void main() {
  test(
    'upcoming selection picks next paid active cohort session',
    () {
      final now = DateTime.utc(2026, 10, 10, 8);
      LearnerStudyCourseDetail course({
        required int id,
        required DateTime scheduledAt,
        String status = 'Active',
        String paymentStatus = 'Paid',
        String sessionStatus = 'Scheduled',
        String? meetingUrl = 'https://meet.example.com/room',
      }) => LearnerStudyCourseDetail(
        id: id,
        name: 'JLPT N3',
        planId: 1,
        cohortId: 10 + id,
        sessionType: 'Group',
        level: 'N3',
        mentorId: 5,
        mentorName: 'Sensei Aoi',
        durationMonths: 2,
        sessionsPerWeek: 3,
        totalSessions: 30,
        sessionMinutes: 90,
        amount: 2000000,
        paymentStatus: paymentStatus,
        status: status,
        startsAt: scheduledAt,
        endsAt: scheduledAt.add(const Duration(days: 70)),
        completedAt: null,
        eligibility: const CourseEligibilitySummary(
          canClaim: false,
          passedOnTimeHomework: 0,
          requiredHomework: 0,
          absentSessions: 0,
          countedSessions: 0,
          reasons: [],
        ),
        sessions: [
          CourseSessionItem(
            id: id * 10,
            number: 1,
            attempt: 1,
            scheduledAt: scheduledAt,
            status: sessionStatus,
            meetingUrl: meetingUrl,
          ),
        ],
        requests: const [],
      );

      final result = selectUpcomingCohortMeeting([
        course(id: 1, scheduledAt: DateTime.utc(2026, 10, 9, 8)),
        course(
          id: 2,
          scheduledAt: DateTime.utc(2026, 10, 11, 8),
          paymentStatus: 'Pending',
        ),
        course(
          id: 3,
          scheduledAt: DateTime.utc(2026, 10, 12, 8),
          status: 'Cancelled',
        ),
        course(id: 4, scheduledAt: DateTime.utc(2026, 10, 11, 9)),
      ], now: now);

      expect(result?.bookingId, 4);
    },
  );

  testWidgets('Home shows generic Meeting shortcut without an upcoming room', (
    tester,
  ) async {
    var opened = 0;
    await _pumpSection(
      tester,
      const AsyncData<UpcomingMeeting?>(null),
      onOpenMeeting: () => opened += 1,
    );

    final card = find.byKey(
      const ValueKey<String>('home_meeting_fallback_card'),
    );
    expect(card, findsOneWidget);
    expect(find.text('Tham gia bằng mã phòng hoặc liên kết.'), findsOneWidget);
    await tester.tap(card);

    expect(opened, 1);
  });

  testWidgets('Home shows real upcoming consultation actions', (tester) async {
    int? openedDetail;
    Uri? joinedUri;
    final meeting = UpcomingMeeting(
      bookingId: 17,
      scheduledAt: MentorTimestamp.parse('2026-10-12T09:30:00+07:00'),
      meetingUri: Uri.parse('https://meet.example.com/room-17'),
      status: MentorMeetingStatus.assigned,
      mentorName: 'Mentor One',
    );
    await _pumpSection(
      tester,
      AsyncData<UpcomingMeeting?>(meeting),
      onOpenDetail: (value) => openedDetail = value,
      onJoin: (value) => joinedUri = value,
    );

    expect(
      find.byKey(const ValueKey<String>('home_upcoming_meeting_card')),
      findsOneWidget,
    );
    expect(find.text('Mentor One'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('home_meeting_detail_button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('home_meeting_join_button')),
    );
    expect(openedDetail, 17);
    expect(joinedUri, Uri.parse('https://meet.example.com/room-17'));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  AsyncValue<UpcomingMeeting?> state, {
  VoidCallback? onOpenMeeting,
  ValueChanged<int>? onOpenDetail,
  ValueChanged<Uri>? onJoin,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MeetingHomeSection(
            state: state,
            onOpenMeeting: onOpenMeeting ?? () {},
            onOpenDetail: onOpenDetail ?? (_) {},
            onJoin: onJoin ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
