import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_chat_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_kpi_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_schedule_v3_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_chat_dtos.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_chat_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_dtos.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_schedule_v3_dtos.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_schedule_v3_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_chat.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_schedule_v3.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_attendance_kpi_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_chat_screens.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_disputes_screens.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_edit_profile_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meeting_detail_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meetings_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_profile_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_reviews_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_session_prep_screen.dart';
import 'package:rikipath_mobile/features/notifications/application/push_notification_service.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_auth_session.dart';

// 1x1 transparent PNG bytes so Image.memory decodes cleanly in widget tests.
final Uint8List _valid1x1PngBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Mentor Full Parity DTOs', () {
    test('MentorBookingDetailDto & AttendanceRecordDto parse full fields', () {
      final detail = MentorBookingDetailDto.fromJson({
        'id': 88,
        'userSubscriptionId': 12,
        'creditGrantId': 4,
        'mentorAvailabilityId': 31,
        'mentorId': 5,
        'mentorName': 'Tanaka Sensei',
        'learnerId': 99,
        'learnerName': 'Minh Anh',
        'jlptLevel': 'N3',
        'status': 'Accepted',
        'paymentStatus': 'Paid',
        'scheduledAt': '2026-11-20T12:00:00Z',
        'endsAt': '2026-11-20T13:30:00Z',
        'createdAt': '2026-11-14T08:00:00Z',
        'meetingLink': 'https://meet.rikipath.local/rooms/r-88',
        'roomId': 'r-88',
        'question': 'Em hay nhầm ~ようにする với ~ことにする ạ.',
      });

      expect(detail.id, 88);
      expect(detail.jlptLevel, 'N3');
      expect(detail.question, contains('ようにする'));
      expect(detail.roomId, 'r-88');
      expect(detail.status, MentorMeetingStatus.accepted);

      final attendance = MentorAttendanceRecordDto.fromJson({
        'id': 7,
        'mentorBookingId': 88,
        'roomId': 'r-88',
        'userId': 99,
        'participantName': 'Minh Anh',
        'role': 'Learner',
        'status': 4,
        'reconnectionCount': 2,
        'totalDurationSeconds': 5100,
        'isOnline': false,
        'firstJoinedAtUtc': '2026-11-20T12:01:00Z',
      });

      expect(attendance.status, MentorAttendanceStatus.completed);
      expect(attendance.reconnectionCount, 2);
      expect(attendance.totalDurationSeconds, 5100);
      expect(attendance.participantName, 'Minh Anh');
    });

    test('MentorRatingSummaryDto & MentorReviewDto parse breakdown & reply', () {
      final summary = MentorRatingSummaryDto.fromJson({
        'mentorId': 5,
        'totalReviews': 10,
        'averageRating': 4.8,
        'ratingBreakdown': {'5': 8, '4': 2, '3': 0, '2': 0, '1': 0},
        'positiveRatePercent': 100.0,
      });

      expect(summary.totalReviews, 10);
      expect(summary.averageRating, 4.8);
      expect(summary.ratingBreakdown[5], 8);
      expect(summary.positiveRatePercent, 100.0);

      final review = MentorReviewDto.fromJson({
        'id': 201,
        'mentorBookingId': 88,
        'mentorId': 5,
        'mentorName': 'Tanaka Sensei',
        'learnerId': 99,
        'learnerName': 'Yuki',
        'rating': 5,
        'comment': 'Giải thích cực kỳ dễ hiểu!',
        'isPublic': true,
        'moderationStatus': 2,
        'mentorReply': null,
        'createdAtUtc': '2026-11-14T10:00:00Z',
      });

      expect(review.id, 201);
      expect(review.moderationStatus, MentorReviewModerationStatus.approved);
      expect(review.hasReply, isFalse);
    });

    test('MentorDisputeDto & MentorDisputeDetailDto parse evidence & history', () {
      final detail = MentorDisputeDetailDto.fromJson({
        'dispute': {
          'id': 301,
          'mentorBookingId': 88,
          'learnerId': 99,
          'learnerName': 'Quang Huy',
          'mentorId': 5,
          'mentorName': 'Tanaka Sensei',
          'category': 3,
          'status': 3,
          'reason': 'Âm thanh bị gián đoạn 10 phút đầu.',
          'evidenceUrls': 'https://cdn.rikipath.local/evidence-1.png',
          'creditRefunded': false,
          'createdAtUtc': '2026-11-14T11:00:00Z',
        },
        'bookingStatus': 'Completed',
        'attendanceTotalDurationSeconds': 4800,
        'attendanceReconnectionCount': 1,
        'attendanceFirstJoinedAtUtc': '2026-11-14T09:00:00Z',
        'isCancelled': false,
        'creditAlreadyRefunded': false,
        'histories': [
          {
            'id': 1,
            'action': 'Submitted',
            'previousStatus': null,
            'newStatus': 1,
            'actorId': 99,
            'actorRole': 'Learner',
            'notes': 'Created by learner',
            'createdAtUtc': '2026-11-14T11:00:00Z',
          },
        ],
      });

      expect(detail.dispute.category, MentorDisputeCategory.mediaRoomIssue);
      expect(detail.dispute.status, MentorDisputeStatus.awaitingResponse);
      expect(detail.dispute.canSubmitResponse, isTrue);
      expect(detail.attendanceTotalDurationSeconds, 4800);
      expect(detail.histories, hasLength(1));
      expect(detail.histories.first.actorRole, 'Learner');

      final jsonListEvidence = MentorDisputeDto.fromJson({
        'id': 302,
        'mentorBookingId': 89,
        'learnerId': 99,
        'learnerName': 'Quang Huy',
        'mentorId': 5,
        'mentorName': 'Tanaka Sensei',
        'category': 3,
        'status': 3,
        'reason': 'Evidence JSON array test',
        'evidenceUrls':
            '["https://cdn.rikipath.local/evidence-1.png","https://cdn.rikipath.local/evidence-2.png"]',
        'creditRefunded': false,
        'createdAtUtc': '2026-11-14T11:00:00Z',
        'updatedAtUtc': '2026-11-14T11:00:00Z',
      });
      expect(jsonListEvidence.evidenceUrlList, [
        'https://cdn.rikipath.local/evidence-1.png',
        'https://cdn.rikipath.local/evidence-2.png',
      ]);
    });

    test('MentorScheduleV3Dto parses schedule, serializes PUT & parses preview/publish', () {
      final schedule = MentorScheduleV3Dto.fromJson({
        'scheduleId': 15,
        'mentorId': 5,
        'mentorName': 'Tanaka Sensei',
        'policyVersion': 3,
        'timeZoneId': 'Asia/Ho_Chi_Minh',
        'autoPublish': true,
        'effectiveFrom': '2026-11-15',
        'generatedThrough': '2026-11-29',
        'createdAtUtc': '2026-11-01T00:00:00Z',
        'rules': [
          {
            'id': 71,
            'scheduleId': 15,
            'weekday': 1,
            'weekdayName': 'Monday',
            'daypartCode': 'Evening',
            'localStart': '18:00',
            'localEnd': '22:00',
            'effectiveFrom': '2026-11-15',
          },
        ],
      });

      expect(schedule.scheduleId, 15);
      expect(schedule.rules.single.daypart, MentorDaypart.evening);

      final updateMap = MentorScheduleV3Dto.updateToJson(
        UpdateMentorScheduleV3Request(
          timeZoneId: 'Asia/Ho_Chi_Minh',
          autoPublish: true,
          effectiveFrom: DateTime.utc(2026, 11, 15),
          rules: [
            MentorScheduleRuleDraft(
              weekday: 3,
              daypart: MentorDaypart.morning,
              localStart: '07:00',
              localEnd: '11:00',
              effectiveFrom: DateTime.utc(2026, 11, 15),
            ),
          ],
        ),
      );

      expect(updateMap['timeZoneId'], 'Asia/Ho_Chi_Minh');
      expect(updateMap['autoPublish'], isTrue);
      expect(updateMap['effectiveFrom'], '2026-11-15');
      expect((updateMap['rules'] as List).single['daypartCode'], 'Morning');

      final preview = MentorScheduleV3Dto.previewFromJson({
        'totalCandidateSlots': 4,
        'existingSlotsCount': 1,
        'newSlotsCount': 3,
        'conflictSlotsCount': 0,
        'startDate': '2026-11-15',
        'endDate': '2026-11-21',
        'slots': [
          {
            'localDate': '2026-11-16',
            'daypartCode': 'Evening',
            'startUtc': '2026-11-16T11:00:00Z',
            'endUtc': '2026-11-16T12:30:00Z',
            'localStart': '18:00',
            'localEnd': '19:30',
            'generationKey': 'gen-1',
            'isExisting': false,
            'hasConflict': false,
          },
        ],
      });

      expect(preview.newSlotsCount, 3);
      expect(preview.slots.single.localStart, '18:00');

      final publish = MentorScheduleV3Dto.publishFromJson({
        'createdCount': 3,
        'skippedExistingCount': 1,
        'totalSlotsProcessed': 4,
        'generatedThrough': '2026-11-29',
        'publishedSlots': const [],
      });

      expect(publish.createdCount, 3);
      expect(publish.totalSlotsProcessed, 4);
    });

    test('MentorChatThreadDto & MentorChatMessageDto parse threads and messages', () {
      final thread = MentorChatThreadDto.fromJson({
        'bookingId': 88,
        'learnerId': 99,
        'learnerName': 'Linh Chi',
        'mentorId': 5,
        'mentorName': 'Tanaka Sensei',
        'scheduledAt': '2026-11-20T12:00:00Z',
        'endsAt': '2026-11-20T13:30:00Z',
        'bookingStatus': 'Accepted',
        'canSendMessages': true,
        'unreadCount': 2,
        'lastMessage': {
          'id': 501,
          'bookingId': 88,
          'senderUserId': 99,
          'senderName': 'Linh Chi',
          'senderRole': 'Learner',
          'text': 'Em chào sensei ạ!',
          'sentAt': '2026-11-14T13:00:00Z',
        },
      });

      expect(thread.bookingId, 88);
      expect(thread.unreadCount, 2);
      expect(thread.lastMessage?.text, 'Em chào sensei ạ!');
      expect(thread.canSendMessages, isTrue);
    });
  });

  group('Mentor Notification Deep Link Resolution', () {
    final service = PushNotificationService(apiClient: _NoopPushApiClient());

    test('resolves dispute, review, chat and meeting links for Mentor role', () {
      final disputePayload = PushNotificationPayload.fromMap({
        'data': {'screen': 'mentor_disputes', 'disputeId': '42'},
      });
      expect(
        service.resolveDeepLink(disputePayload, role: 'Mentor'),
        '/mentor/disputes/42',
      );

      final chatPayload = PushNotificationPayload.fromMap({
        'data': {'linkUrl': '/mentor/chat/88'},
      });
      expect(
        service.resolveDeepLink(chatPayload, role: 'Mentor'),
        '/mentor/chat/88',
      );

      final reviewPayload = PushNotificationPayload.fromMap({
        'data': {'linkUrl': '/mentor/reviews'},
      });
      expect(
        service.resolveDeepLink(reviewPayload, role: 'Mentor'),
        '/mentor/reviews',
      );

      final meetingPayload = PushNotificationPayload.fromMap({
        'data': {'screen': 'booking_detail', 'bookingId': '88'},
      });
      expect(
        service.resolveDeepLink(meetingPayload, role: 'Mentor'),
        '/mentor/meetings/88',
      );
    });
  });

  group('Mentor Shell 5-Tab Navigation & Screen Parity', () {
    testWidgets('MentorShell switches across all 5 tabs cleanly', (tester) async {
      final router = await _pumpMentorRouter(
        tester,
        initialLocation: AppRoutes.mentor,
      );

      expect(find.byKey(const Key('mentor_home_screen')), findsOneWidget);
      expect(find.byKey(const Key('mentor_bottom_navigation_bar')), findsOneWidget);
      expect(find.byKey(const Key('mentor_home_next_session_card')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('mentor_home_next_session_card')),
          matching: find.text('Chi tiết'),
        ),
        findsOneWidget,
      );

      // Navigate tabs via bottom nav bar labels
      await tester.tap(find.text('Lịch dạy'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mentor_calendar_screen')), findsOneWidget);

      await tester.tap(find.text('Buổi tư vấn'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mentor_meetings_screen')), findsOneWidget);

      await tester.tap(find.text('Lịch trống'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mentor_availability_screen')), findsOneWidget);

      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mentor_profile_screen')), findsOneWidget);

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.mentorProfile);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorMeetingsScreen supports search, filters, cancelled API notice & sort', (tester) async {
      await _pumpWidget(
        tester,
        const MentorMeetingsScreen(),
      );

      expect(find.byKey(const Key('mentor_meetings_search_input')), findsOneWidget);
      expect(find.textContaining('Yuki'), findsOneWidget);
      expect(find.textContaining('Minh Anh'), findsOneWidget);

      // Search filters cards
      await tester.enterText(
        find.byKey(const Key('mentor_meetings_search_input')),
        'Yuki',
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Yuki'),
        findsOneWidget,
      );
      expect(find.textContaining('Minh Anh'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('mentor_meetings_search_input')),
        '',
      );
      await tester.pumpAndSettle();

      // Switch to Cancelled chip -> displays Backend gap API notice banner
      await tester.ensureVisible(find.textContaining('Đã hủy'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Đã hủy'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Lưu ý: Danh sách hiện tại chỉ hiển thị các buổi tư vấn đang hoạt động'),
        findsOneWidget,
      );

      // Switch back to All & toggle sort
      await tester.ensureVisible(find.textContaining('Tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Tất cả'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sắp xếp: Giờ hẹn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sắp xếp: Giờ hẹn'));
      await tester.pumpAndSettle();
      expect(find.text('Sắp xếp: Mới nhất'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorMeetingDetailScreen renders detail, question, attendance, eligibility & no literal placeholders', (tester) async {
      await _pumpWidget(
        tester,
        const MentorMeetingDetailScreen(meetingId: 88),
      );

      expect(find.textContaining('Minh Anh'), findsWidgets);
      expect(find.textContaining('N3'), findsWidgets);
      await tester.scrollUntilVisible(
        find.textContaining('Em hay nhầm ~ようにする'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Em hay nhầm ~ようにする'), findsOneWidget);
      // Verify no broken template literals remain
      expect(find.textContaining(r'${'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorReviewsScreen filters unreplied reviews & submits reply modal', (tester) async {
      final repo = _FakeMentorRepository();
      final opsRepo = _FakeMentorOperationsRepository();
      await _pumpWidget(
        tester,
        const MentorReviewsScreen(),
        mentorRepo: repo,
        opsRepo: opsRepo,
      );

      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('Yuki'), findsOneWidget);
      expect(find.textContaining('Kenji'), findsOneWidget);

      // Filter to unreplied reviews only
      await tester.tap(find.text('Đánh giá chờ reply'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Yuki'), findsOneWidget);
      expect(find.textContaining('Kenji'), findsNothing);

      // Open reply sheet & submit
      await tester.tap(find.text('Phản hồi đánh giá'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        'Cảm ơn Yuki, chúc bạn ôn N3 thật tốt!',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi phản hồi'));
      await tester.pumpAndSettle();

      expect(repo.replyReviewCalls, 1);
      expect(repo.lastReviewReply, 'Cảm ơn Yuki, chúc bạn ôn N3 thật tốt!');
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorDisputesScreen & MentorDisputeDetailScreen render evidence and submit response', (tester) async {
      final repo = _FakeMentorRepository();
      await _pumpWidget(
        tester,
        const MentorDisputesScreen(),
        mentorRepo: repo,
      );

      expect(find.textContaining('Quang Huy'), findsOneWidget);
      expect(find.textContaining('Buổi tư vấn #88'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Now test detail screen & submit one-time response
      await _pumpWidget(
        tester,
        const MentorDisputeDetailScreen(disputeId: 301),
        mentorRepo: repo,
      );

      expect(find.textContaining('Âm thanh bị gián đoạn'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Reconnects: 1'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Reconnects: 1'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byType(TextField),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byType(TextField),
        'Sensei đã vào đúng giờ và nhắn lại phòng ngay sau đó.',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Gửi giải trình'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Gửi giải trình'));
      await tester.pumpAndSettle();

      expect(repo.respondDisputeCalls, 1);
      expect(repo.lastDisputeResponse, contains('Sensei đã vào đúng giờ'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorChatThreadsScreen & MentorChatRoomScreen handle read-only and active send', (tester) async {
      final chatRepo = _FakeMentorChatRepository();
      final fakeRealtime = _FakeMentorChatRealtimeClient();

      await _pumpWidget(
        tester,
        const MentorChatThreadsScreen(),
        chatRepo: chatRepo,
        chatRealtimeClient: fakeRealtime,
      );

      expect(find.text('Linh Chi'), findsOneWidget);
      expect(find.text('Em chào sensei ạ!'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Closed booking shows read-only banner and disabled composer
      await _pumpWidget(
        tester,
        const MentorChatRoomScreen(bookingId: 89),
        chatRepo: chatRepo,
        chatRealtimeClient: fakeRealtime,
      );
      expect(
        find.textContaining('chế độ chỉ đọc'),
        findsOneWidget,
      );

      // Active booking allows sending message via SignalR
      await _pumpWidget(
        tester,
        const MentorChatRoomScreen(bookingId: 88),
        chatRepo: chatRepo,
        chatRealtimeClient: fakeRealtime,
      );
      expect(find.text('Em chào sensei ạ!'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        'Hẹn gặp em lúc 19:00 nhé!',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(fakeRealtime.sentMessages, contains('Hẹn gặp em lúc 19:00 nhé!'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorAvailabilityScreen unapproved mentor sees Policy v3 approval notice', (tester) async {
      await _pumpWidget(
        tester,
        const MentorAvailabilityScreen(),
        mentorRepo: _FakeMentorRepository(
          profile: const MentorProfileData(
            mentorId: 5,
            email: 'mentor@rikipath.local',
            verificationStatus: 'Pending',
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('mentor_schedule_v3_card')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('mentor_schedule_v3_card')), findsOneWidget);
      expect(
        find.byKey(const Key('mentor_schedule_v3_approval_notice')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorAvailabilityScreen approved mentor opens Policy v3 slot popup menu', (tester) async {
      await _pumpWidget(
        tester,
        const MentorAvailabilityScreen(),
        mentorRepo: _FakeMentorRepository(
          profile: const MentorProfileData(
            mentorId: 5,
            email: 'mentor@rikipath.local',
            verificationStatus: 'Approved',
            isBookable: true,
          ),
        ),
      );
      expect(
        find.byKey(const Key('mentor_schedule_v3_approval_notice')),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('mentor_slot_actions_501')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('mentor_slot_actions_501')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mentor_slot_delete_501')), findsNothing);
      expect(find.byKey(const Key('mentor_slot_disable_501')), findsNothing);
      expect(find.byKey(const Key('mentor_slot_cancel_501')), findsOneWidget);
      expect(find.byKey(const Key('mentor_slot_change_501')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorProfileScreen home & MentorEditProfileScreen lock banners, certificate viewer & operational links', (tester) async {
      await _pumpWidget(
        tester,
        const MentorProfileScreen(),
        mentorRepo: _FakeMentorRepository(
          profile: const MentorProfileData(
            mentorId: 5,
            email: 'mentor@rikipath.local',
            verificationStatus: 'Approved',
            isBookable: true,
            jlptLevel: 'N2',
            hasVerificationDocument: true,
            verificationDocumentUrl: '/documents/cert.png',
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('mentor_profile_edit_action')), findsOneWidget);
      expect(find.byKey(const Key('mentor_profile_verification_status_action')), findsOneWidget);
      expect(find.byKey(const Key('mentor_profile_chat_action')), findsOneWidget);
      expect(find.byKey(const Key('mentor_profile_reviews_action')), findsOneWidget);
      expect(find.byKey(const Key('mentor_profile_disputes_action')), findsOneWidget);
      expect(find.byKey(const Key('mentor_profile_prep_action')), findsOneWidget);

      await _pumpWidget(
        tester,
        const MentorEditProfileScreen(),
        mentorRepo: _FakeMentorRepository(
          profile: const MentorProfileData(
            mentorId: 5,
            email: 'mentor@rikipath.local',
            verificationStatus: 'Pending',
            jlptLevel: 'N2',
          ),
        ),
      );
      expect(
        find.byKey(const Key('mentor_profile_account_readonly_banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mentor_profile_pending_lock_banner')),
        findsOneWidget,
      );

      // Approved mentor sees approved lock banner + can open uploaded certificate viewer
      await _pumpWidget(
        tester,
        const MentorEditProfileScreen(),
        mentorRepo: _FakeMentorRepository(
          profile: const MentorProfileData(
            mentorId: 5,
            email: 'mentor@rikipath.local',
            verificationStatus: 'Approved',
            isBookable: true,
            jlptLevel: 'N2',
            hasVerificationDocument: true,
            verificationDocumentUrl: '/documents/cert.png',
          ),
        ),
      );
      expect(
        find.byKey(const Key('mentor_profile_approved_lock_banner')),
        findsOneWidget,
      );

      final viewDocFinder = find.byKey(
        const Key('mentor_view_verification_document_button'),
      );
      await tester.ensureVisible(viewDocFinder);
      await tester.pumpAndSettle();
      await tester.tap(viewDocFinder);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorAttendanceKpiScreen renders KPI stats, period toggle & zero payroll/VND text', (tester) async {
      final kpiRepo = _FakeMentorKpiRepository();

      await _pumpWidget(
        tester,
        const MentorAttendanceKpiScreen(),
        kpiRepo: kpiRepo,
      );

      expect(
        find.byKey(const Key('mentor_attendance_kpi_screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('kpi_assigned_sessions')), findsOneWidget);
      expect(find.byKey(const Key('kpi_completed_sessions')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('2026-10'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('2026-10'), findsOneWidget);
      expect(find.textContaining('₫'), findsNothing);

      await tester.ensureVisible(find.text('Tuần'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tuần'));
      await tester.pumpAndSettle();
      expect(find.textContaining('W45'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MentorSessionPrepScreen renders checklist, question, room status & server-notes banner', (tester) async {
      await _pumpWidget(
        tester,
        const MentorSessionPrepScreen(bookingId: 88),
      );

      expect(
        find.textContaining('Em hay nhầm ~ようにする'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Phòng đã sẵn sàng truy cập'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining('Hiện chưa hỗ trợ lưu ghi chú chuẩn bị trực tuyến'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Hiện chưa hỗ trợ lưu ghi chú chuẩn bị trực tuyến'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    test(
      'ApiMentorOperationsRepository.checkRoomAccess maps HTTP 403 ForbiddenError to non-ready status',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 403,
                    data: {
                      'isSuccess': false,
                      'statusCode': 403,
                      'errorMessage':
                          'Bạn không có quyền tham gia phòng tư vấn này hoặc thời gian chưa hợp lệ.',
                    },
                  ),
                ),
              );
            },
          ),
        );
        final repo = ApiMentorOperationsRepository(
          ApiClient(dio, const ApiErrorMapper()),
        );

        final status = await repo.checkRoomAccess('room-990103');
        expect(status.roomId, 'room-990103');
        expect(status.canAccess, isFalse);
        expect(status.isRoomReady, isFalse);
        expect(
          status.reason,
          'Bạn không có quyền tham gia phòng tư vấn này hoặc thời gian chưa hợp lệ.',
        );
      },
    );

    test(
      'mentorRoomAccessProvider disables Riverpod auto-retry and resolves immediately on error',
      () async {
        final session = createTestAuthSession(role: BackendUserRole.mentor);
        addTearDown(session.dispose);

        var attempts = 0;
        final container = ProviderContainer(
          overrides: [
            authSessionControllerProvider.overrideWithValue(session),
            mentorOperationsRepositoryProvider.overrideWithValue(
              _FakeMentorOperationsRepository(
                onCheckRoomAccess: (_) async {
                  attempts++;
                  throw StateError('transient failure');
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(mentorRoomAccessProvider('r-88').future),
          throwsStateError,
        );
        expect(attempts, 1);
        final asyncValue = container.read(mentorRoomAccessProvider('r-88'));
        expect(asyncValue.isLoading, isFalse);
        expect(asyncValue.hasError, isTrue);
      },
    );

    testWidgets(
      'MentorSessionPrepScreen displays not-ready room notice immediately without infinite spinner',
      (tester) async {
        const forbiddenReason =
            'Bạn không có quyền tham gia phòng tư vấn này hoặc thời gian chưa hợp lệ.';
        await _pumpWidget(
          tester,
          const MentorSessionPrepScreen(bookingId: 88),
          opsRepo: _FakeMentorOperationsRepository(
            onCheckRoomAccess: (roomId) async => MentorRoomAccessStatus(
              roomId: roomId,
              canAccess: false,
              isRoomReady: false,
              reason: forbiddenReason,
            ),
          ),
        );

        expect(find.textContaining(forbiddenReason), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Future<void> _pumpWidget(
  WidgetTester tester,
  Widget child, {
  _FakeMentorRepository? mentorRepo,
  _FakeMentorOperationsRepository? opsRepo,
  _FakeMentorScheduleV3Repository? scheduleV3Repo,
  _FakeMentorChatRepository? chatRepo,
  _FakeMentorChatRealtimeClient? chatRealtimeClient,
  _FakeMentorKpiRepository? kpiRepo,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession(role: BackendUserRole.mentor);
  addTearDown(session.dispose);

  final effectiveRealtime =
      chatRealtimeClient ?? _FakeMentorChatRealtimeClient();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        mentorRepositoryProvider.overrideWithValue(
          mentorRepo ?? _FakeMentorRepository(),
        ),
        mentorOperationsRepositoryProvider.overrideWithValue(
          opsRepo ?? _FakeMentorOperationsRepository(),
        ),
        mentorScheduleV3RepositoryProvider.overrideWithValue(
          scheduleV3Repo ?? _FakeMentorScheduleV3Repository(),
        ),
        mentorChatRepositoryProvider.overrideWithValue(
          chatRepo ?? _FakeMentorChatRepository(),
        ),
        mentorChatRealtimeClientFactoryProvider.overrideWithValue(
          () => effectiveRealtime,
        ),
        mentorKpiRepositoryProvider.overrideWithValue(
          kpiRepo ?? _FakeMentorKpiRepository(),
        ),
        mentorMeetingLinkLauncherProvider.overrideWithValue(
          _NoopMeetingLinkLauncher(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<GoRouter> _pumpMentorRouter(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession(role: BackendUserRole.mentor);
  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(const {
            'APP_ENV': 'development',
            'API_PROFILE': 'local-emulator',
          }),
        ),
        authSessionControllerProvider.overrideWithValue(session),
        mentorRepositoryProvider.overrideWithValue(_FakeMentorRepository()),
        mentorOperationsRepositoryProvider.overrideWithValue(
          _FakeMentorOperationsRepository(),
        ),
        mentorScheduleV3RepositoryProvider.overrideWithValue(
          _FakeMentorScheduleV3Repository(),
        ),
        mentorChatRepositoryProvider.overrideWithValue(
          _FakeMentorChatRepository(),
        ),
        mentorChatRealtimeClientFactoryProvider.overrideWithValue(
          _FakeMentorChatRealtimeClient.new,
        ),
        mentorKpiRepositoryProvider.overrideWithValue(
          _FakeMentorKpiRepository(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _NoopPushApiClient extends ApiClient {
  _NoopPushApiClient() : super(Dio(), const ApiErrorMapper());
}

class _NoopMeetingLinkLauncher implements MentorMeetingLinkLauncher {
  @override
  Future<bool> open(Uri uri) async => true;
}

class _FakeMentorRepository implements MentorRepository {
  _FakeMentorRepository({MentorProfileData? profile})
    : _profile =
          profile ??
          const MentorProfileData(
            mentorId: 5,
            email: 'mentor@rikipath.local',
            firstName: 'Tanaka',
            lastName: 'Sensei',
            jlptLevel: 'N2',
            verificationStatus: 'Approved',
            isBookable: true,
            hasVerificationDocument: true,
          );

  final MentorProfileData _profile;
  int replyReviewCalls = 0;
  String? lastReviewReply;
  int respondDisputeCalls = 0;
  String? lastDisputeResponse;

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async => [
    MentorAvailabilitySlot(
      id: 501,
      startTime: MentorTimestamp.parse('2026-11-20T18:00:00+07:00'),
      endTime: MentorTimestamp.parse('2026-11-20T19:30:00+07:00'),
      isBooked: false,
      isApproved: true,
    ),
  ];

  @override
  Future<List<MentorMeetingSummary>> loadMeetings() async => [
    MentorMeetingSummary(
      id: 88,
      learnerName: 'Minh Anh',
      scheduledAt: MentorTimestamp.parse('2026-11-20T19:00:00+07:00'),
      status: MentorMeetingStatus.accepted,
      jlptLevel: 'N3',
      roomId: 'r-88',
      meetingLink: 'https://meet.rikipath.local/rooms/r-88',
    ),
    MentorMeetingSummary(
      id: 89,
      learnerName: 'Yuki',
      scheduledAt: MentorTimestamp.parse('2026-11-10T10:00:00+07:00'),
      status: MentorMeetingStatus.completed,
      jlptLevel: 'N4',
      roomId: 'r-89',
    ),
  ];

  @override
  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(
    DateTime weekStart,
  ) async => const [];

  @override
  Future<bool> cancelMeeting(int bookingId, String reason) async => true;

  @override
  Future<bool> replyReview(int reviewId, String reply) async {
    replyReviewCalls++;
    lastReviewReply = reply;
    return true;
  }

  @override
  Future<bool> respondDispute(int disputeId, String responseText) async {
    respondDisputeCalls++;
    lastDisputeResponse = responseText;
    return true;
  }

  @override
  Future<MentorProfileData> loadProfile() async => _profile;

  @override
  Future<MentorProfileData> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  }) async => _profile;

  @override
  Future<MentorProfileData> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  }) async => _profile;

  @override
  Future<MentorProfileData> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  }) async => _profile;
}

class _FakeMentorOperationsRepository implements MentorOperationsRepository {
  _FakeMentorOperationsRepository({this.onCheckRoomAccess});

  final Future<MentorRoomAccessStatus> Function(String roomId)?
  onCheckRoomAccess;

  @override
  Future<MentorBookingDetail> loadBookingDetail(int bookingId) async =>
      MentorBookingDetail(
        id: bookingId,
        userSubscriptionId: 12,
        mentorId: 5,
        mentorName: 'Tanaka Sensei',
        learnerId: 99,
        learnerName: 'Minh Anh',
        jlptLevel: 'N3',
        status: MentorMeetingStatus.accepted,
        scheduledAt: MentorTimestamp.parse('2026-11-20T19:00:00+07:00'),
        endsAt: MentorTimestamp.parse('2026-11-20T20:30:00+07:00'),
        roomId: 'r-88',
        meetingLink: 'https://meet.rikipath.local/rooms/r-88',
        question: 'Em hay nhầm ~ようにする với ~ことにする ạ.',
      );

  @override
  Future<MentorCancellationEligibility> checkCancellationEligibility(
    int bookingId,
  ) async => const MentorCancellationEligibility(
    bookingId: 88,
    canCancel: true,
    canReschedule: false,
    eligibleForFullRefund: true,
    hoursUntilStart: 48.0,
    tier: 'Early',
    message: 'Còn trên 24h trước buổi tư vấn.',
  );

  @override
  Future<List<MentorAttendanceRecord>> loadBookingAttendance(
    int bookingId,
  ) async => [
    MentorAttendanceRecord(
      id: 1,
      mentorBookingId: bookingId,
      roomId: 'r-88',
      userId: 99,
      participantName: 'Minh Anh',
      role: 'Learner',
      status: MentorAttendanceStatus.joined,
      reconnectionCount: 0,
      totalDurationSeconds: 1800,
      isOnline: true,
      firstJoinedAtUtc: MentorTimestamp.parse('2026-11-20T12:00:00Z'),
    ),
  ];

  @override
  Future<MentorRoomAccessStatus> checkRoomAccess(String roomId) async {
    if (onCheckRoomAccess != null) {
      return onCheckRoomAccess!(roomId);
    }
    return MentorRoomAccessStatus(
      roomId: roomId,
      canAccess: true,
      isRoomReady: true,
    );
  }

  @override
  Future<MentorVerificationDocumentData> loadVerificationDocument() async =>
      MentorVerificationDocumentData(
        bytes: _valid1x1PngBytes,
        contentType: 'image/png',
      );

  @override
  Future<MentorRatingSummary> loadRatingSummary(int mentorId) async =>
      const MentorRatingSummary(
        mentorId: 5,
        totalReviews: 10,
        averageRating: 4.8,
        ratingBreakdown: {5: 8, 4: 2, 3: 0, 2: 0, 1: 0},
        positiveRatePercent: 100.0,
      );

  @override
  Future<List<MentorReviewItem>> loadReviews(
    int mentorId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (page > 1) return const [];
    return [
      MentorReviewItem(
        id: 201,
        mentorBookingId: 89,
        mentorId: mentorId,
        mentorName: 'Tanaka Sensei',
        learnerId: 101,
        learnerName: 'Yuki',
        rating: 5,
        comment: 'Rất tận tâm!',
        isPublic: true,
        moderationStatus: MentorReviewModerationStatus.approved,
        createdAtUtc: MentorTimestamp.parse('2026-11-11T09:00:00Z'),
        updatedAtUtc: MentorTimestamp.parse('2026-11-11T09:00:00Z'),
      ),
      MentorReviewItem(
        id: 202,
        mentorBookingId: 87,
        mentorId: mentorId,
        mentorName: 'Tanaka Sensei',
        learnerId: 102,
        learnerName: 'Kenji',
        rating: 5,
        comment: 'Tuyệt vời.',
        isPublic: true,
        moderationStatus: MentorReviewModerationStatus.approved,
        mentorReply: 'Cảm ơn bạn rất nhiều!',
        mentorRepliedAtUtc: MentorTimestamp.parse('2026-11-10T10:00:00Z'),
        createdAtUtc: MentorTimestamp.parse('2026-11-09T09:00:00Z'),
        updatedAtUtc: MentorTimestamp.parse('2026-11-10T10:00:00Z'),
      ),
    ];
  }

  @override
  Future<List<MentorDisputeItem>> loadDisputes({
    int page = 1,
    int pageSize = 20,
  }) async => [
    MentorDisputeItem(
      id: 301,
      mentorBookingId: 88,
      learnerId: 99,
      learnerName: 'Quang Huy',
      mentorId: 5,
      mentorName: 'Tanaka Sensei',
      category: MentorDisputeCategory.mediaRoomIssue,
      status: MentorDisputeStatus.awaitingResponse,
      reason: 'Âm thanh bị gián đoạn 10 phút đầu.',
      evidenceUrls: 'https://cdn.rikipath.local/evidence-1.png',
      creditRefunded: false,
      createdAtUtc: MentorTimestamp.parse('2026-11-12T10:00:00Z'),
      updatedAtUtc: MentorTimestamp.parse('2026-11-12T10:00:00Z'),
    ),
  ];

  @override
  Future<MentorDisputeDetail> loadDisputeDetail(int disputeId) async =>
      MentorDisputeDetail(
        dispute: (await loadDisputes()).single,
        bookingScheduledAt: MentorTimestamp.parse('2026-11-11T10:00:00Z'),
        bookingStatus: MentorMeetingStatus.completed,
        attendanceTotalDurationSeconds: 4800,
        attendanceReconnectionCount: 1,
        attendanceFirstJoinedAtUtc: MentorTimestamp.parse(
          '2026-11-11T10:00:00Z',
        ),
        isCancelled: false,
        creditAlreadyRefunded: false,
        histories: [
          MentorDisputeHistoryEntry(
            id: 1,
            action: 'Opened',
            previousStatus: null,
            newStatus: MentorDisputeStatus.awaitingResponse,
            actorId: 99,
            actorRole: 'Learner',
            notes: 'Opened by learner',
            createdAtUtc: MentorTimestamp.parse('2026-11-12T10:00:00Z'),
          ),
        ],
      );
}

class _FakeMentorScheduleV3Repository implements MentorScheduleV3Repository {
  @override
  Future<MentorScheduleV3> loadSchedule() async => MentorScheduleV3(
    scheduleId: 15,
    mentorId: 5,
    mentorName: 'Tanaka Sensei',
    policyVersion: 3,
    timeZoneId: 'Asia/Ho_Chi_Minh',
    autoPublish: true,
    effectiveFrom: DateTime.utc(2026, 11, 15),
    generatedThrough: DateTime.utc(2026, 11, 29),
    createdAtUtc: MentorTimestamp.parse('2026-11-01T00:00:00Z'),
    rules: [
      MentorScheduleRule(
        id: 71,
        scheduleId: 15,
        weekday: 1,
        weekdayName: 'Monday',
        daypart: MentorDaypart.evening,
        localStart: '18:00',
        localEnd: '22:00',
        effectiveFrom: DateTime.utc(2026, 11, 15),
      ),
    ],
  );

  @override
  Future<MentorScheduleV3> updateSchedule(
    UpdateMentorScheduleV3Request request,
  ) async => loadSchedule();

  @override
  Future<MentorSlotPreviewResult> previewSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) async => MentorSlotPreviewResult(
    totalCandidateSlots: 2,
    existingSlotsCount: 1,
    newSlotsCount: 1,
    conflictSlotsCount: 0,
    startDate: startDate,
    endDate: endDate,
    slots: const [],
  );

  @override
  Future<MentorPublishSlotsResult> publishSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) async => MentorPublishSlotsResult(
    createdCount: 1,
    skippedExistingCount: 1,
    totalSlotsProcessed: 2,
    generatedThrough: endDate,
    publishedSlots: const [],
  );

  @override
  Future<void> deleteAvailability(int availabilityId) async {}

  @override
  Future<void> requestCancelAvailabilities(
    List<int> ids, {
    String? reason,
  }) async {}

  @override
  Future<void> requestSlotChange(int slotId, String reason) async {}
}

class _FakeMentorChatRepository implements MentorChatRepository {
  @override
  Future<List<MentorChatThread>> loadThreads() async => [
    await loadThread(88),
    await loadThread(89),
  ];

  @override
  Future<MentorChatThread> loadThread(int bookingId) async => MentorChatThread(
    bookingId: bookingId,
    learnerId: bookingId == 88 ? 99 : 101,
    learnerName: bookingId == 88 ? 'Linh Chi' : 'Yuki',
    mentorId: 5,
    mentorName: 'Tanaka Sensei',
    scheduledAt: MentorTimestamp.parse('2026-11-20T19:00:00+07:00'),
    bookingStatus: bookingId == 88 ? 'Accepted' : 'Completed',
    canSendMessages: bookingId == 88,
    unreadCount: bookingId == 88 ? 2 : 0,
    lastMessage: bookingId == 88
        ? MentorChatMessage(
            id: 501,
            bookingId: 88,
            senderUserId: 99,
            senderName: 'Linh Chi',
            senderRole: 'Learner',
            text: 'Em chào sensei ạ!',
            sentAt: MentorTimestamp.parse('2026-11-14T13:00:00Z'),
          )
        : null,
  );

  @override
  Future<List<MentorChatMessage>> loadMessages(
    int bookingId, {
    int? beforeMessageId,
    int pageSize = 50,
  }) async => bookingId == 88
      ? [
          MentorChatMessage(
            id: 501,
            bookingId: 88,
            senderUserId: 99,
            senderName: 'Linh Chi',
            senderRole: 'Learner',
            text: 'Em chào sensei ạ!',
            sentAt: MentorTimestamp.parse('2026-11-14T13:00:00Z'),
          ),
        ]
      : const [];

  @override
  Future<void> markRead(int bookingId) async {}
}

class _FakeMentorChatRealtimeClient implements MentorChatRealtimeClient {
  final _stateController =
      StreamController<MentorChatConnectionStatus>.broadcast();
  final _messageController = StreamController<MentorChatMessage>.broadcast();
  final _readController = StreamController<int>.broadcast();
  final List<String> sentMessages = <String>[];

  @override
  Stream<MentorChatConnectionStatus> get connectionStates =>
      _stateController.stream;

  @override
  Stream<MentorChatMessage> get incomingMessages => _messageController.stream;

  @override
  Stream<int> get readReceipts => _readController.stream;

  @override
  Future<void> connectAndJoin(int bookingId) async {
    _stateController.add(MentorChatConnectionStatus.connected);
  }

  @override
  Future<void> sendMessage(int bookingId, String text) async {
    sentMessages.add(text);
    _messageController.add(
      MentorChatMessage(
        id: 900 + sentMessages.length,
        bookingId: bookingId,
        senderUserId: 5,
        senderName: 'Tanaka Sensei',
        senderRole: 'Mentor',
        text: text,
        sentAt: MentorTimestamp.parse('2026-11-14T14:00:00Z'),
      ),
    );
  }

  @override
  Future<void> markRead(int bookingId) async {}

  @override
  Future<void> leave(int bookingId) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _messageController.close();
    await _readController.close();
  }
}

class _FakeMentorKpiRepository implements MentorKpiRepository {
  @override
  Future<MentorKpiSummary> loadSummary({
    String? fromDate,
    String? toDate,
  }) async =>
      MentorKpiSummary(
        mentorId: 5,
        mentorName: 'Tanaka Taro',
        fromDate: fromDate ?? '2026-09-01',
        toDate: toDate ?? '2026-11-16',
        teachingJlptLevels: const ['N2'],
        totalAssignedSessions: 4,
        assignedBookingsCount: 3,
        assignedCourseSessionsCount: 1,
        completedValidSessions: 3,
        confirmedTeachingMinutes: 240,
        scheduledCompletedMinutes: 270,
        weeklyBreakdown: const [
          MentorKpiPeriodItem(
            periodKey: 'W45 (02/11)',
            periodStart: '2026-11-02',
            periodEnd: '2026-11-08',
            totalAssignedSessions: 2,
            completedValidSessions: 2,
            confirmedTeachingMinutes: 150,
            scheduledCompletedMinutes: 180,
            cancelledSessionsCount: 0,
            missedOrNoShowSessionsCount: 0,
            upcomingOrIncompleteSessionsCount: 0,
            homeworkAssignedCount: 1,
            homeworkSubmittedCount: 1,
            homeworkGradedCount: 1,
            feedbackTurnaroundSampleCount: 1,
            reviewsCount: 1,
            disputesCount: 0,
          ),
        ],
        monthlyBreakdown: const [
          MentorKpiPeriodItem(
            periodKey: '2026-10',
            periodStart: '2026-10-01',
            periodEnd: '2026-10-31',
            totalAssignedSessions: 4,
            completedValidSessions: 3,
            confirmedTeachingMinutes: 240,
            scheduledCompletedMinutes: 270,
            cancelledSessionsCount: 1,
            missedOrNoShowSessionsCount: 0,
            upcomingOrIncompleteSessionsCount: 0,
            homeworkAssignedCount: 2,
            homeworkSubmittedCount: 1,
            homeworkGradedCount: 1,
            feedbackTurnaroundSampleCount: 1,
            reviewsCount: 2,
            disputesCount: 0,
          ),
        ],
      );
}
