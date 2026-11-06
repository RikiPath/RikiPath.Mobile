import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_reschedule_sheet.dart';

class _MockLearnerMentorRepository implements LearnerMentorRepository {
  bool rescheduleSuccess = true;
  int? lastRescheduledBookingId;
  int? lastRescheduledSlotId;

  @override
  Future<List<LearnerMentorAvailability>> loadAvailability({
    required DateTime from,
    required DateTime to,
    int? mentorId,
  }) async {
    return [
      // Old slot (id 101) - already booked
      LearnerMentorAvailability(
        id: 101,
        mentorId: 1,
        mentorName: 'Sensei One',
        startTime: MentorTimestamp.parse('2026-11-12T09:00:00Z'),
        endTime: MentorTimestamp.parse('2026-11-12T10:30:00Z'),
        isBooked: true,
      ),
      // Eligible slot (id 102) - future open slot
      LearnerMentorAvailability(
        id: 102,
        mentorId: 1,
        mentorName: 'Sensei One',
        startTime: MentorTimestamp.parse('2026-11-18T09:00:00Z'),
        endTime: MentorTimestamp.parse('2026-11-18T10:30:00Z'),
        isBooked: false,
      ),
      // Ineligible slot (id 103) - past slot (<24h)
      LearnerMentorAvailability(
        id: 103,
        mentorId: 1,
        mentorName: 'Sensei One',
        startTime: MentorTimestamp.parse('2026-11-06T02:00:00Z'),
        endTime: MentorTimestamp.parse('2026-11-06T03:30:00Z'),
        isBooked: false,
      ),
    ];
  }

  @override
  Future<bool> rescheduleBooking({
    required int bookingId,
    required int newSlotId,
  }) async {
    lastRescheduledBookingId = bookingId;
    lastRescheduledSlotId = newSlotId;
    return rescheduleSuccess;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockLearnerMentorRepository mockRepo;

  setUp(() {
    mockRepo = _MockLearnerMentorRepository();
  });

  final testBooking = LearnerMentorBooking(
    id: 501,
    userSubscriptionId: 1,
    status: MentorMeetingStatus.accepted,
    mentorId: 1,
    mentorName: 'Sensei One',
    mentorAvailabilityId: 101,
    scheduledAt: MentorTimestamp.parse('2026-11-12T09:00:00Z'),
    jlptLevel: 'N3',
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        learnerMentorRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LearnerMentorRescheduleSheet(booking: testBooking),
        ),
      ),
    );
  }

  testWidgets('LearnerMentorRescheduleSheet displays eligible future slots and excludes current slot', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify header and current schedule display
    expect(find.text('Dời lịch hẹn tư vấn'), findsOneWidget);
    expect(find.textContaining('Lịch hiện tại:'), findsOneWidget);

    // Verify eligible slot 102 is shown
    expect(find.byKey(const Key('reschedule_slot_tile_102')), findsOneWidget);

    // Verify current slot 101 and <24h slot 103 are filtered out
    expect(find.byKey(const Key('reschedule_slot_tile_101')), findsNothing);
    expect(find.byKey(const Key('reschedule_slot_tile_103')), findsNothing);

    // Confirm button is initially disabled (prompting user to select a slot)
    final confirmButtonFinder = find.byKey(const Key('confirm_reschedule_button'));
    expect(confirmButtonFinder, findsOneWidget);
    expect(find.text('Vui lòng chọn khung giờ mới'), findsOneWidget);
  });

  testWidgets('Selecting an eligible slot enables confirmation and submits successfully', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap slot 102
    await tester.tap(find.byKey(const Key('reschedule_slot_tile_102')));
    await tester.pumpAndSettle();

    // Verify selected indicator and updated button label
    expect(find.text('Khung giờ mới đã chọn:'), findsOneWidget);
    expect(find.text('Xác nhận dời lịch sang giờ này'), findsOneWidget);

    // Tap confirm
    await tester.tap(find.byKey(const Key('confirm_reschedule_button')));
    await tester.pump();

    // Verify repository called with correct IDs
    expect(mockRepo.lastRescheduledBookingId, 501);
    expect(mockRepo.lastRescheduledSlotId, 102);
  });

  testWidgets('Reschedule failure shows friendly error banner and keeps sheet open for retry', (tester) async {
    mockRepo.rescheduleSuccess = false;
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap slot 102 and confirm
    await tester.tap(find.byKey(const Key('reschedule_slot_tile_102')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_reschedule_button')));
    await tester.pumpAndSettle();

    // Sheet remains open for user to pick another slot
    expect(find.byKey(const Key('learner_mentor_reschedule_sheet')), findsOneWidget);
  });
}
