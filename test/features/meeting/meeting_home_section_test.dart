import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/meeting/application/upcoming_meeting_provider.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_home_section.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

void main() {
  test(
    'upcoming selection requires a paid assigned/accepted future booking',
    () {
      final now = DateTime(2026, 10, 10, 8);
      LearnerMentorBooking booking({
        required int id,
        required String scheduledAt,
        MentorMeetingStatus status = MentorMeetingStatus.assigned,
        MentorPaymentStatus paymentStatus = MentorPaymentStatus.paid,
        String? link = 'https://meet.example.com/room',
      }) => LearnerMentorBooking(
        id: id,
        userSubscriptionId: 1,
        status: status,
        paymentStatus: paymentStatus,
        scheduledAt: MentorTimestamp.parse(scheduledAt),
        meetingLink: link,
      );

      final result = selectUpcomingMeeting([
        booking(id: 1, scheduledAt: '2026-10-09T08:00:00'),
        booking(
          id: 2,
          scheduledAt: '2026-10-11T08:00:00',
          paymentStatus: MentorPaymentStatus.pending,
        ),
        booking(
          id: 3,
          scheduledAt: '2026-10-12T08:00:00',
          status: MentorMeetingStatus.cancelled,
        ),
        booking(id: 4, scheduledAt: '2026-10-11T09:00:00'),
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
