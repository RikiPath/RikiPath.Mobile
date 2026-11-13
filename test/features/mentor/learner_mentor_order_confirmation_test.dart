import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_order_confirmation_sheet.dart';

class _MockConfirmationRepo implements LearnerMentorRepository {
  final List<String> submittedOperationKeys = [];
  final List<String?> submittedJlptLevels = [];
  final List<({DateTime from, DateTime to, String? level})>
  availabilityQueries = [];
  bool simulateUnknownBookingResult = false;
  int bookingReconciliationCalls = 0;

  @override
  Future<List<LearnerMentorAvailability>> loadAvailability({
    required DateTime from,
    required DateTime to,
    int? mentorId,
    String? jlptLevel,
  }) async {
    availabilityQueries.add((from: from, to: to, level: jlptLevel));
    return [
      LearnerMentorAvailability(
        id: 201,
        mentorId: 1,
        mentorName: 'Sensei Tanaka',
        startTime: MentorTimestamp.parse('2026-11-20T09:00:00Z'),
        endTime: MentorTimestamp.parse('2026-11-20T10:30:00Z'),
        isBooked: false,
      ),
    ];
  }

  @override
  Future<LearnerMentorBooking> bookWithCredit({
    required int slotId,
    required String operationKey,
    String? notes,
    String? jlptLevel,
  }) async {
    submittedOperationKeys.add(operationKey);
    submittedJlptLevels.add(jlptLevel);
    if (simulateUnknownBookingResult) {
      throw StateError('network timeout after booking commit');
    }
    return LearnerMentorBooking(
      id: 888,
      userSubscriptionId: 10,
      status: MentorMeetingStatus.accepted,
      mentorId: 1,
      mentorName: 'Sensei Tanaka',
      mentorAvailabilityId: slotId,
      scheduledAt: MentorTimestamp.parse('2026-11-20T09:00:00Z'),
      jlptLevel: jlptLevel,
    );
  }

  @override
  Future<List<LearnerMentorBooking>> loadBookings() async {
    bookingReconciliationCalls++;
    return [
      LearnerMentorBooking(
        id: 888,
        userSubscriptionId: 10,
        status: MentorMeetingStatus.accepted,
        mentorId: 1,
        mentorName: 'Sensei Tanaka',
        mentorAvailabilityId: 201,
        scheduledAt: MentorTimestamp.parse('2026-11-20T09:00:00Z'),
        jlptLevel: 'N2',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCreditController extends LearnerCreditBalanceController {
  _MockCreditController(this.preset);
  final LearnerCreditBalance preset;

  @override
  Future<LearnerCreditBalance> build() async => preset;
}

void main() {
  late _MockConfirmationRepo mockRepo;

  setUp(() {
    mockRepo = _MockConfirmationRepo();
  });

  final testSlot = LearnerMentorAvailability(
    id: 201,
    mentorId: 1,
    mentorName: 'Sensei Tanaka',
    startTime: MentorTimestamp.parse('2026-11-20T09:00:00Z'),
    endTime: MentorTimestamp.parse('2026-11-20T10:30:00Z'),
    isBooked: false,
  );

  final testCreditBalance = LearnerCreditBalance(
    balance: 4,
    availableBalance: 4,
    pendingHoldCount: 0,
    activeGrants: [
      LearnerCreditGrant(
        grantId: 1,
        userSubscriptionId: 10,
        jlptLevel: 'N3',
        availableQuantity: 2,
      ),
      LearnerCreditGrant(
        grantId: 2,
        userSubscriptionId: 10,
        jlptLevel: 'N2',
        availableQuantity: 2,
      ),
    ],
  );

  testWidgets(
    'Confirmation sheet renders JLPT selection chips when multiple grants exist and plan level is null',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learnerMentorRepositoryProvider.overrideWithValue(mockRepo),
            learnerCreditBalanceControllerProvider.overrideWith(
              () => _MockCreditController(testCreditBalance),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LearnerMentorOrderConfirmationSheet(
                planId: 1,
                slot: testSlot,
                plan: null, // No fixed level
                subscriptionId: 10,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify prompt and chips
      expect(
        find.text('Chọn trình độ JLPT cho buổi hẹn (N5 - N2):'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('jlpt_chip_N3')), findsOneWidget);
      expect(find.byKey(const Key('jlpt_chip_N2')), findsOneWidget);

      // Select N3 chip
      await tester.tap(find.byKey(const Key('jlpt_chip_N3')));
      await tester.pumpAndSettle();

      // Confirm booking
      await tester.tap(
        find.byKey(const Key('learner_mentor_confirm_submit_button')),
      );
      await tester.pumpAndSettle();

      // Verify submission recorded with N3
      expect(mockRepo.submittedJlptLevels, contains('N3'));
      expect(mockRepo.submittedOperationKeys.length, 1);
      expect(mockRepo.submittedOperationKeys.first, startsWith('booking_'));
    },
  );

  testWidgets('Calendar level remains fixed and booking rechecks that day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerMentorRepositoryProvider.overrideWithValue(mockRepo),
          learnerCreditBalanceControllerProvider.overrideWith(
            () => _MockCreditController(testCreditBalance),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LearnerMentorOrderConfirmationSheet(
              slot: testSlot,
              requestedJlptLevel: 'N2',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('jlpt_chip_N3')), findsNothing);
    await tester.tap(
      find.byKey(const Key('learner_mentor_confirm_submit_button')),
    );
    await tester.pumpAndSettle();

    expect(mockRepo.submittedJlptLevels, ['N2']);
    expect(mockRepo.availabilityQueries.single.level, 'N2');
    expect(
      mockRepo.availabilityQueries.single.from,
      DateTime(2026, 11, 20).toUtc(),
    );
    expect(
      mockRepo.availabilityQueries.single.to,
      DateTime(2026, 11, 21).toUtc(),
    );
  });

  testWidgets(
    'Credit at another JLPT level is not treated as a matching ticket',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learnerMentorRepositoryProvider.overrideWithValue(mockRepo),
            learnerCreditBalanceControllerProvider.overrideWith(
              () => _MockCreditController(testCreditBalance),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LearnerMentorOrderConfirmationSheet(
                slot: testSlot,
                planId: 42,
                plan: const MentorMeetingPlan(
                  id: 42,
                  name: 'Gói N5',
                  durationDays: 30,
                  price: 1000,
                  meetingSessionCount: 1,
                  features: [],
                  jlptLevel: 'N5',
                ),
                requestedJlptLevel: 'N5',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gói N5'), findsOneWidget);
      expect(find.textContaining('PayOS'), findsWidgets);
      expect(mockRepo.submittedOperationKeys, isEmpty);
    },
  );

  testWidgets('Unknown booking response reconciles the learner booking list', (
    tester,
  ) async {
    mockRepo.simulateUnknownBookingResult = true;
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerMentorRepositoryProvider.overrideWithValue(mockRepo),
          learnerCreditBalanceControllerProvider.overrideWith(
            () => _MockCreditController(testCreditBalance),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LearnerMentorOrderConfirmationSheet(
              slot: testSlot,
              requestedJlptLevel: 'N2',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('learner_mentor_confirm_submit_button')),
    );
    await tester.pumpAndSettle();

    expect(mockRepo.submittedOperationKeys, hasLength(1));
    expect(mockRepo.bookingReconciliationCalls, 1);
  });
}
