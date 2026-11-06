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

  @override
  Future<List<LearnerMentorAvailability>> loadAvailability({
    required DateTime from,
    required DateTime to,
    int? mentorId,
  }) async {
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

  testWidgets('Confirmation sheet renders JLPT selection chips when multiple grants exist and plan level is null', (tester) async {
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
    expect(find.text('Chọn trình độ JLPT cho buổi hẹn (N5 - N2):'), findsOneWidget);
    expect(find.byKey(const Key('jlpt_chip_N3')), findsOneWidget);
    expect(find.byKey(const Key('jlpt_chip_N2')), findsOneWidget);

    // Select N3 chip
    await tester.tap(find.byKey(const Key('jlpt_chip_N3')));
    await tester.pumpAndSettle();

    // Confirm booking
    await tester.tap(find.byKey(const Key('learner_mentor_confirm_submit_button')));
    await tester.pumpAndSettle();

    // Verify submission recorded with N3
    expect(mockRepo.submittedJlptLevels, contains('N3'));
    expect(mockRepo.submittedOperationKeys.length, 1);
    expect(mockRepo.submittedOperationKeys.first, startsWith('booking_'));
  });
}
