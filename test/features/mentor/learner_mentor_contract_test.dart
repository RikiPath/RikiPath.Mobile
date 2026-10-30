import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/data/api_learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_booking_detail_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_bookings_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_meetings_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_purchase_status_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

import '../../support/test_auth_session.dart';

void main() {
  test('booking status microcopy distinguishes learner and mentor', () {
    final l10n = AppLocalizationsVi();
    expect(l10n.learnerMentorStatusAssigned, 'Chờ Mentor xác nhận');
    expect(l10n.mentorStatusAssigned, 'Chờ xác nhận');
    expect(l10n.mentorStatusAccepted, 'Đã xác nhận');
  });

  group('Learner Mentor Meeting routes and role gates', () {
    test('exposes stable learner meeting routes with positive IDs', () {
      expect(AppRoutes.learnerMentorMeetings, '/mentor-meetings');
      expect(
        AppRoutes.learnerMentorAvailability(4),
        '/mentor-meetings/plans/4/availability',
      );
      expect(AppRoutes.learnerMentorBookings, '/mentor-meetings/bookings');
      expect(
        AppRoutes.learnerMentorBookingDetail(7),
        '/mentor-meetings/bookings/7',
      );
      expect(
        AppRoutes.learnerMentorPurchaseStatus(9),
        '/mentor-meetings/purchases/9',
      );
      expect(() => AppRoutes.learnerMentorAvailability(0), throwsArgumentError);
    });

    test('learner route is reachable only by an authenticated Learner', () {
      expect(
        authRouteRedirect(
          authState: AuthSessionState.authenticated,
          role: BackendUserRole.learner,
          matchedLocation: AppRoutes.learnerMentorMeetings,
        ),
        isNull,
      );
      expect(
        authRouteRedirect(
          authState: AuthSessionState.authenticated,
          role: BackendUserRole.mentor,
          matchedLocation: AppRoutes.learnerMentorMeetings,
        ),
        AppRoutes.mentor,
      );
      expect(
        authRouteRedirect(
          authState: AuthSessionState.unauthenticated,
          role: null,
          matchedLocation: AppRoutes.learnerMentorMeetings,
        ),
        AppRoutes.login,
      );
    });
  });

  group('Learner Mentor Meeting DTO and repository contract', () {
    test('mentor metadata absent from Backend remains unknown', () {
      const mentor = BookableMentor(id: 42, name: 'QA Mentor');
      expect(mentor.jlptLevels, isEmpty);
      expect(mentor.headline, isNull);
      expect(mentor.bio, isNull);
      expect(mentor.teachingMethod, isNull);
    });
    test('plans map only exact Backend response fields', () async {
      final client = _RecordingApiClient({
        'GET ${LearnerMentorApiPaths.plans}': _envelope([
          {
            'id': 3,
            'name': 'Starter',
            'description': 'One-to-one guidance',
            'durationDays': 30,
            'price': 125000.0,
            'meetingSessionCount': 2,
            'features': [
              {'id': 8, 'name': 'Roadmap review', 'description': null},
            ],
          },
        ]),
      });

      final plans = await ApiLearnerMentorRepository(client).loadPlans();

      expect(plans.single.id, 3);
      expect(plans.single.price, 125000);
      expect(plans.single.meetingSessionCount, 2);
      expect(plans.single.features.single.name, 'Roadmap review');
      expect(client.calls.single.path, LearnerMentorApiPaths.plans);
    });

    test(
      'availability serializes a UTC range and optional mentor filter',
      () async {
        final client = _RecordingApiClient({
          'GET ${LearnerMentorApiPaths.availability}': _envelope([
            {
              'id': 12,
              'mentorId': 5,
              'mentorName': 'Sato Haru',
              'startTime': '2026-10-12T02:00:00Z',
              'endTime': '2026-10-12T03:00:00Z',
              'isBooked': false,
            },
          ]),
        });
        final from = DateTime.parse('2026-10-10T09:00:00+07:00');
        final to = DateTime.parse('2026-10-20T09:00:00+07:00');

        final slots = await ApiLearnerMentorRepository(
          client,
        ).loadAvailability(from: from, to: to, mentorId: 5);

        expect(slots.single.id, 12);
        expect(slots.single.mentorId, 5);
        expect(client.calls.single.queryParameters, {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
          'mentorId': 5,
        });
      },
    );

    test('purchase request uses the exact verified JSON fields', () async {
      final client = _RecordingApiClient({
        'POST ${LearnerMentorApiPaths.purchase}': _envelope(
          _purchaseJson(subscriptionId: 21, bookingId: 34),
        ),
      });

      final purchase = await ApiLearnerMentorRepository(
        client,
      ).purchase(subscriptionPlanId: 3);

      expect(client.calls.single.data, {'subscriptionPlanId': 3});
      expect(purchase.subscriptionId, 21);
      expect(purchase.bookingId, 34);
      expect(purchase.safeCheckoutUri?.scheme, 'https');
    });

    test('included booking request uses only mentorAvailabilityId', () async {
      final path = LearnerMentorApiPaths.subscriptionBookings(21);
      final client = _RecordingApiClient({
        'POST $path': _envelope(_bookingJson(id: 44)),
      });

      final booking = await ApiLearnerMentorRepository(
        client,
      ).bookIncludedSession(subscriptionId: 21, mentorAvailabilityId: 15);

      expect(client.calls.single.path, path);
      expect(client.calls.single.data, {'mentorAvailabilityId': 15});
      expect(booking.id, 44);
    });

    test('booking and purchase status map nullable fields safely', () async {
      final client = _RecordingApiClient({
        'GET ${LearnerMentorApiPaths.bookings}': _envelope([
          _bookingJson(id: 44),
        ]),
        'GET ${LearnerMentorApiPaths.purchaseStatus(21)}': _envelope({
          'subscriptionId': 21,
          'planName': 'Starter',
          'paymentStatus': 'Paid',
          'isCheckoutExpired': false,
          'amountPaid': 125000,
          'paymentExpiresAt': null,
          'meetingSessionsIncluded': 2,
          'meetingSessionsUsed': 1,
          'bookings': [_bookingJson(id: 44)],
        }),
      });
      final repository = ApiLearnerMentorRepository(client);

      final bookings = await repository.loadBookings();
      final status = await repository.loadPurchaseStatus(21);

      expect(bookings.single.status, MentorMeetingStatus.accepted);
      expect(status.paymentStatus, MentorPaymentStatus.paid);
      expect(status.remainingSessions, 1);
      expect(status.bookings.single.id, 44);
    });

    test('response envelope and required identifiers remain strict', () {
      expect(
        () => readLearnerMentorResultList(const {'result': []}),
        throwsFormatException,
      );
      expect(
        () => LearnerMentorBookingDto.fromJson({..._bookingJson(id: 0)}),
        throwsFormatException,
      );
      expect(
        () => MentorMeetingPlanDto.fromJson({
          'id': 1,
          'name': 'Plan',
          'durationDays': 1,
          'price': 'free',
          'meetingSessionCount': 1,
          'features': const [],
        }),
        throwsFormatException,
      );
    });

    test('join and checkout URLs reject unsafe schemes and relatives', () {
      expect(safeExternalHttpUri('https://meet.example.com/room'), isNotNull);
      expect(safeExternalHttpUri('http://pay.example.com/order'), isNotNull);
      expect(safeExternalHttpUri('javascript:alert(1)'), isNull);
      expect(safeExternalHttpUri('file:///tmp/a'), isNull);
      expect(safeExternalHttpUri('/relative'), isNull);
      expect(safeExternalHttpUri(''), isNull);
      expect(safeExternalHttpUri(null), isNull);
    });

    test('unknown Backend enum values fail closed to unknown', () {
      expect(
        MentorPaymentStatus.fromApiValue('paid'),
        MentorPaymentStatus.unknown,
      );
      expect(
        LearnerMentorBookingDto.fromJson({
          ..._bookingJson(id: 4),
          'status': 'NewBackendStatus',
        }).toDomain().status,
        MentorMeetingStatus.unknown,
      );
    });
  });

  group('Learner Mentor Meeting controllers', () {
    test('plans retry transitions from error to success', () async {
      final repository = _TestLearnerMentorRepository(
        planResults: [
          const NetworkError(),
          [_plan()],
        ],
      );
      final container = ProviderContainer(
        overrides: [
          learnerMentorRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(learnerMentorPlansControllerProvider.future),
        throwsA(isA<NetworkError>()),
      );
      await container
          .read(learnerMentorPlansControllerProvider.notifier)
          .retry();

      expect(
        container
            .read(learnerMentorPlansControllerProvider)
            .requireValue
            .single
            .id,
        1,
      );
    });

    test('purchase controller exposes loading then success', () async {
      final completer = Completer<MentorMeetingPurchase>();
      final repository = _TestLearnerMentorRepository(
        purchaseResults: [completer.future],
      );
      final container = ProviderContainer(
        overrides: [
          learnerMentorRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        learnerMentorMutationControllerProvider.notifier,
      );

      final request = controller.purchase(
        subscriptionPlanId: 1,
        mentorAvailabilityId: 2,
      );
      expect(
        container.read(learnerMentorMutationControllerProvider).isLoading,
        isTrue,
      );
      completer.complete(_purchase());

      expect((await request)?.subscriptionId, 21);
      expect(
        container
            .read(learnerMentorMutationControllerProvider)
            .purchase
            ?.bookingId,
        34,
      );
    });

    test(
      'purchase controller retains 409/422 failures without success',
      () async {
        for (final error in const <ApiError>[
          ConflictError(),
          ValidationError(statusCode: 422),
        ]) {
          final repository = _TestLearnerMentorRepository(
            purchaseResults: [error],
          );
          final container = ProviderContainer(
            overrides: [
              learnerMentorRepositoryProvider.overrideWithValue(repository),
            ],
          );
          final result = await container
              .read(learnerMentorMutationControllerProvider.notifier)
              .purchase(subscriptionPlanId: 1, mentorAvailabilityId: 2);

          expect(result, isNull);
          expect(
            container.read(learnerMentorMutationControllerProvider).error,
            same(error),
          );
          container.dispose();
        }
      },
    );

    test('double-tap purchase protection sends one request', () async {
      final completer = Completer<MentorMeetingPurchase>();
      final repository = _TestLearnerMentorRepository(
        purchaseResults: [completer.future],
      );
      final container = ProviderContainer(
        overrides: [
          learnerMentorRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        learnerMentorMutationControllerProvider.notifier,
      );

      final first = controller.purchase(
        subscriptionPlanId: 1,
        mentorAvailabilityId: 2,
      );
      final second = await controller.purchase(
        subscriptionPlanId: 1,
        mentorAvailabilityId: 2,
      );
      expect(second, isNull);
      expect(repository.purchaseCalls, 1);
      completer.complete(_purchase());
      await first;
    });

    test('double-tap included booking protection sends one request', () async {
      final completer = Completer<LearnerMentorBooking>();
      final repository = _TestLearnerMentorRepository(
        bookingMutationResults: [completer.future],
      );
      final container = ProviderContainer(
        overrides: [
          learnerMentorRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        learnerMentorMutationControllerProvider.notifier,
      );

      final first = controller.bookIncludedSession(
        subscriptionId: 21,
        mentorAvailabilityId: 2,
      );
      final second = await controller.bookIncludedSession(
        subscriptionId: 21,
        mentorAvailabilityId: 2,
      );
      expect(second, isNull);
      expect(repository.bookingMutationCalls, 1);
      completer.complete(_booking());
      await first;
    });

    test(
      'purchase status polling stops requesting after a settled state',
      () async {
        final repository = _TestLearnerMentorRepository(
          purchaseStatusResults: [
            _purchaseStatus(MentorPaymentStatus.pending),
            _purchaseStatus(MentorPaymentStatus.paid),
          ],
        );
        final container = ProviderContainer(
          overrides: [
            learnerMentorRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        final provider = learnerMentorPurchaseStatusControllerProvider(21);

        expect((await container.read(provider.future)).isSettled, isFalse);
        await container.read(provider.notifier).poll();
        expect(container.read(provider).requireValue.isSettled, isTrue);
        await container.read(provider.notifier).poll();
        expect(repository.purchaseStatusCalls, 2);
      },
    );
  });

  group('Learner Mentor Meeting presentation', () {
    testWidgets('plans render success and empty states', (tester) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorMeetingsScreen(),
        repository: _TestLearnerMentorRepository(
          planResults: [
            [_plan()],
          ],
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('learner_mentor_plan_1')),
        findsOneWidget,
      );

      await _pumpLearnerMentor(
        tester,
        const LearnerMentorMeetingsScreen(),
        repository: _TestLearnerMentorRepository(
          planResults: const [<MentorMeetingPlan>[]],
        ),
      );
      expect(
        find.byKey(const Key('learner_mentor_plans_empty')),
        findsOneWidget,
      );
    });

    testWidgets('plan error is visible and retryable', (tester) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorMeetingsScreen(),
        repository: _TestLearnerMentorRepository(
          planResults: [const NetworkError()],
        ),
      );
      expect(
        find.byKey(const Key('learner_mentor_plans_error')),
        findsOneWidget,
      );
    });

    testWidgets('401 booking response stays an error state', (tester) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorBookingsScreen(),
        repository: _TestLearnerMentorRepository(
          bookingResults: [const UnauthorizedError()],
        ),
      );

      expect(
        find.byKey(const Key('learner_mentor_bookings_error')),
        findsOneWidget,
      );
      expect(find.byType(LearnerMentorBookingDetailScreen), findsNothing);
    });

    testWidgets('availability supports date and real slot selection', (
      tester,
    ) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorAvailabilityScreen(planId: 1),
        repository: _TestLearnerMentorRepository(
          availabilityResults: [
            [_slot(id: 12)],
          ],
        ),
      );

      final slot = find.byKey(const ValueKey<String>('learner_mentor_slot_12'));
      expect(slot, findsOneWidget);
      await tester.tap(slot);
      await tester.pump();
      expect(
        find.byKey(const Key('learner_mentor_selected_slot_card')),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('learner_mentor_purchase_button')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('bookings render empty, success, and error states', (
      tester,
    ) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorBookingsScreen(),
        repository: _TestLearnerMentorRepository(
          bookingResults: const [<LearnerMentorBooking>[]],
        ),
      );
      expect(
        find.byKey(const Key('learner_mentor_bookings_empty')),
        findsOneWidget,
      );

      await _pumpLearnerMentor(
        tester,
        const LearnerMentorBookingsScreen(),
        repository: _TestLearnerMentorRepository(
          bookingResults: [
            [_booking()],
          ],
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('learner_mentor_booking_44')),
        findsOneWidget,
      );

      await _pumpLearnerMentor(
        tester,
        const LearnerMentorBookingsScreen(),
        repository: _TestLearnerMentorRepository(
          bookingResults: [const ForbiddenError()],
        ),
      );
      expect(
        find.byKey(const Key('learner_mentor_bookings_error')),
        findsOneWidget,
      );
    });

    testWidgets('consultation detail exposes safe join without technical IDs', (
      tester,
    ) async {
      final launcher = _RecordingMeetingLinkLauncher();
      await _pumpLearnerMentorRouter(
        tester,
        repository: _TestLearnerMentorRepository(
          bookingResults: [
            [
              _booking(
                link:
                    'https://meet.example.com/meeting-room/'
                    '123e4567-e89b-42d3-a456-426614174000',
                roomId: '123e4567-e89b-42d3-a456-426614174000',
              ),
            ],
          ],
        ),
        launcher: launcher,
      );

      expect(
        find.byKey(const Key('learner_mentor_booking_detail_content')),
        findsOneWidget,
      );
      expect(find.text('Chi tiết buổi học'), findsOneWidget);
      expect(find.text('Vào phòng học'), findsOneWidget);
      expect(find.text('Mã lịch hẹn'), findsNothing);
      expect(find.text('44'), findsNothing);
      expect(
        find.byKey(const Key('learner_mentor_purchase_status_button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('learner_mentor_join_button')));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byKey(const Key('native_meeting_room_screen')),
        MeetingNativeRollout.isEnabled ? findsOneWidget : findsNothing,
      );
      expect(
        launcher.opened,
        MeetingNativeRollout.isEnabled
            ? isEmpty
            : <Uri>[
                Uri.parse(
                  'https://meet.example.com/meeting-room/'
                  '123e4567-e89b-42d3-a456-426614174000',
                ),
              ],
      );
    });

    testWidgets('invalid join URL is not offered', (tester) async {
      final launcher = _RecordingMeetingLinkLauncher();
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorBookingDetailScreen(bookingId: 44),
        repository: _TestLearnerMentorRepository(
          bookingResults: [
            [_booking(link: 'javascript:alert(1)')],
          ],
        ),
        launcher: launcher,
      );

      expect(
        find.byKey(const Key('learner_mentor_join_unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('learner_mentor_join_button')), findsNothing);
      expect(launcher.opened, isEmpty);
    });

    testWidgets('Japanese consultation wording hides technical IDs', (
      tester,
    ) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorBookingDetailScreen(bookingId: 44),
        repository: _TestLearnerMentorRepository(
          bookingResults: [
            [
              _booking(
                link:
                    'https://meet.example.com/meeting-room/'
                    '123e4567-e89b-42d3-a456-426614174000',
                roomId: '123e4567-e89b-42d3-a456-426614174000',
              ),
            ],
          ],
        ),
        locale: const Locale('ja'),
      );

      expect(find.text('相談の詳細'), findsOneWidget);
      expect(find.text('相談に参加'), findsOneWidget);
      expect(find.text('予約ID'), findsNothing);
      expect(find.text('44'), findsNothing);
    });

    testWidgets('purchase status shows authoritative paid state', (
      tester,
    ) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorPurchaseStatusScreen(subscriptionId: 21),
        repository: _TestLearnerMentorRepository(
          purchaseStatusResults: [_purchaseStatus(MentorPaymentStatus.paid)],
        ),
      );

      expect(
        find.byKey(const Key('learner_mentor_purchase_status_content')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('learner_mentor_sessions_usage')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('QA pending payment is clearly demo-only and has no checkout action', (
      tester,
    ) async {
      expect(
        _purchaseStatus(MentorPaymentStatus.pending, isQaSimulated: true)
            .isQaSimulated,
        isTrue,
      );
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorPurchaseStatusScreen(subscriptionId: 21),
        repository: _TestLearnerMentorRepository(
          purchaseStatusResults: [
            _purchaseStatus(MentorPaymentStatus.pending, isQaSimulated: true),
          ],
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('learner_mentor_qa_payment_demo')),
        250,
      );
      expect(find.byKey(const Key('learner_mentor_qa_payment_demo')), findsOneWidget);
      expect(find.text('CHẾ ĐỘ DEMO — KHÔNG CHUYỂN TIỀN'), findsOneWidget);
      expect(find.byKey(const Key('learner_mentor_open_checkout_button')), findsNothing);
    });

    testWidgets('learner routes resolve without entering Mentor shell', (
      tester,
    ) async {
      final session = createTestAuthSession(role: BackendUserRole.learner);
      final router = createAppRouter(
        authSession: session,
        initialLocation: AppRoutes.learnerMentorBookings,
      );
      addTearDown(session.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionControllerProvider.overrideWithValue(session),
            learnerMentorRepositoryProvider.overrideWithValue(
              _TestLearnerMentorRepository(
                bookingResults: const [<LearnerMentorBooking>[]],
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LearnerMentorBookingsScreen), findsOneWidget);
      expect(find.text('Mentor Home'), findsNothing);
    });

    testWidgets('learner meeting UI remains overflow-free at 320px', (
      tester,
    ) async {
      await _pumpLearnerMentor(
        tester,
        const LearnerMentorMeetingsScreen(),
        repository: _TestLearnerMentorRepository(
          planResults: [
            [
              _plan(
                name: 'A long consultation package name that must wrap safely',
              ),
            ],
          ],
        ),
        size: const Size(320, 720),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('LearnerBookingIntent persistence and restoration', () {
    test(
      'LearnerBookingIntent roundtrip serializes and restores correctly',
      () {
        final slot = _slot(id: 15);
        final intent = LearnerBookingIntent(
          planId: 2,
          subscriptionId: 991,
          mentorAvailabilityId: 15,
          slot: slot,
          question: 'Muốn học luyện đề N3',
        );

        final json = intent.toJson();
        expect(json['planId'], 2);
        expect(json['subscriptionId'], 991);
        expect(json['mentorAvailabilityId'], 15);
        expect(json['question'], 'Muốn học luyện đề N3');
        expect(json['slot'], isA<Map<String, dynamic>>());

        final restored = LearnerBookingIntent.fromJson(json);
        expect(restored.planId, intent.planId);
        expect(restored.subscriptionId, intent.subscriptionId);
        expect(restored.mentorAvailabilityId, intent.mentorAvailabilityId);
        expect(restored.question, intent.question);
        expect(restored.slot?.id, slot.id);
        expect(restored.slot?.mentorName, slot.mentorName);
        expect(restored.slot?.startTime.rawValue, slot.startTime.rawValue);
      },
    );

    test('LearnerBookingIntent handles null slot and optional fields', () {
      const intent = LearnerBookingIntent(planId: 1, subscriptionId: 55);

      final json = intent.toJson();
      expect(json.containsKey('slot'), isFalse);
      expect(json['planId'], 1);
      expect(json['subscriptionId'], 55);

      final restored = LearnerBookingIntent.fromJson(json);
      expect(restored.planId, 1);
      expect(restored.subscriptionId, 55);
      expect(restored.slot, isNull);
      expect(restored.question, isNull);
    });
  });
}

Map<String, Object?> _envelope(Object? result) => {
  'statusCode': 200,
  'isSuccess': true,
  'errorMessage': null,
  'errors': null,
  'result': result,
};

Map<String, Object?> _bookingJson({required int id}) => {
  'id': id,
  'userSubscriptionId': 21,
  'mentorAvailabilityId': 12,
  'mentorId': 5,
  'mentorName': 'Sato Haru',
  'learnerId': null,
  'learnerName': null,
  'status': 'Accepted',
  'paymentStatus': 'Paid',
  'scheduledAt': '2026-10-12T02:00:00Z',
  'meetingLink': 'https://meet.example.com/room-$id',
  'roomId': null,
};

Map<String, Object?> _purchaseJson({
  required int subscriptionId,
  int? bookingId,
}) => {
  'subscriptionId': subscriptionId,
  'bookingId': bookingId,
  'orderCode': 123456789,
  'planName': 'Starter',
  'meetingSessionCount': 2,
  'features': const <Object?>[],
  'amount': 125000,
  'checkoutUrl': 'https://pay.example.com/order-21',
  'paymentLinkId': 'pay-21',
  'qrCode': 'qr-value',
  'paymentExpiresAt': '2026-10-12T03:00:00Z',
};

MentorMeetingPlan _plan({String name = 'Starter'}) => MentorMeetingPlan(
  id: 1,
  name: name,
  durationDays: 30,
  price: 125000,
  meetingSessionCount: 2,
  features: const [MentorMeetingFeature(id: 8, name: 'Roadmap review')],
);

LearnerMentorAvailability _slot({required int id}) => LearnerMentorAvailability(
  id: id,
  mentorId: 5,
  mentorName: 'Sato Haru',
  startTime: MentorTimestamp.parse('2026-10-12T02:00:00Z'),
  endTime: MentorTimestamp.parse('2026-10-12T03:00:00Z'),
  isBooked: false,
);

LearnerMentorBooking _booking({String? link, String? roomId}) =>
    LearnerMentorBooking(
      id: 44,
      userSubscriptionId: 21,
      mentorAvailabilityId: 12,
      mentorId: 5,
      mentorName: 'Sato Haru',
      status: MentorMeetingStatus.accepted,
      paymentStatus: MentorPaymentStatus.paid,
      scheduledAt: MentorTimestamp.parse('2026-10-12T02:00:00Z'),
      meetingLink: link,
      roomId: roomId,
    );

MentorMeetingPurchase _purchase() => MentorMeetingPurchase(
  subscriptionId: 21,
  bookingId: 34,
  orderCode: 123456789,
  planName: 'Starter',
  meetingSessionCount: 2,
  features: const [],
  amount: 125000,
  checkoutUrl: 'https://pay.example.com/order-21',
  paymentLinkId: 'pay-21',
  qrCode: 'qr-value',
);

MentorMeetingPurchaseStatus _purchaseStatus(
  MentorPaymentStatus status, {
  bool isQaSimulated = false,
}) =>
    MentorMeetingPurchaseStatus(
      subscriptionId: 21,
      planName: 'Starter',
      paymentStatus: status,
      isCheckoutExpired: false,
      amountPaid: status == MentorPaymentStatus.paid ? 125000 : 0,
      meetingSessionsIncluded: 2,
      meetingSessionsUsed: 1,
      bookings: [_booking()],
      isQaSimulated: isQaSimulated,
    );

Future<void> _pumpLearnerMentor(
  WidgetTester tester,
  Widget child, {
  required LearnerMentorRepository repository,
  MentorMeetingLinkLauncher? launcher,
  Size size = const Size(390, 844),
  Locale locale = const Locale('vi'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final session = createTestAuthSession(role: BackendUserRole.learner);
  addTearDown(session.dispose);

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        learnerMentorRepositoryProvider.overrideWithValue(repository),
        if (launcher != null)
          mentorMeetingLinkLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _pumpLearnerMentorRouter(
  WidgetTester tester, {
  required LearnerMentorRepository repository,
  MentorMeetingLinkLauncher? launcher,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final session = createTestAuthSession(role: BackendUserRole.learner);
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.learnerMentorBookingDetail(44),
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
        learnerMentorRepositoryProvider.overrideWithValue(repository),
        if (launcher != null)
          mentorMeetingLinkLauncherProvider.overrideWithValue(launcher),
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
}

class _RecordedCall {
  const _RecordedCall({
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
  });

  final String method;
  final String path;
  final Object? data;
  final Map<String, dynamic>? queryParameters;
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.responses) : super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> responses;
  final List<_RecordedCall> calls = [];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add(
      _RecordedCall(
        method: 'GET',
        path: path,
        queryParameters: queryParameters,
      ),
    );
    return _response<T>('GET $path', path);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add(_RecordedCall(method: 'POST', path: path, data: data));
    return _response<T>('POST $path', path);
  }

  Response<T> _response<T>(String key, String path) {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responses[key] as T,
    );
  }
}

class _TestLearnerMentorRepository implements LearnerMentorRepository {
  _TestLearnerMentorRepository({
    this.planResults = const [<MentorMeetingPlan>[]],
    this.availabilityResults = const [<LearnerMentorAvailability>[]],
    this.purchaseResults = const [],
    this.bookingMutationResults = const [],
    this.bookingResults = const [<LearnerMentorBooking>[]],
    this.purchaseStatusResults = const [],
  });

  final List<Object> planResults;
  final List<Object> availabilityResults;
  final List<Object> purchaseResults;
  final List<Object> bookingMutationResults;
  final List<Object> bookingResults;
  final List<Object> purchaseStatusResults;
  int planCalls = 0;
  int availabilityCalls = 0;
  int purchaseCalls = 0;
  int bookingMutationCalls = 0;
  int bookingCalls = 0;
  int purchaseStatusCalls = 0;

  @override
  Future<List<MentorMeetingPlan>> loadPlans() =>
      _next(planResults, planCalls++);

  @override
  Future<List<BookableMentor>> loadMentors() async => const <BookableMentor>[];

  @override
  Future<List<LearnerMentorAvailability>> loadAvailability({
    required DateTime from,
    required DateTime to,
    int? mentorId,
  }) => _next(availabilityResults, availabilityCalls++);

  @override
  Future<MentorMeetingPurchase> purchase({
    required int subscriptionPlanId,
    int? mentorAvailabilityId,
    String? idempotencyKey,
  }) => _next(purchaseResults, purchaseCalls++);

  @override
  Future<LearnerMentorBooking> bookIncludedSession({
    required int subscriptionId,
    required int mentorAvailabilityId,
    String? question,
  }) => _next(bookingMutationResults, bookingMutationCalls++);

  @override
  Future<List<LearnerMentorBooking>> loadBookings() =>
      _next(bookingResults, bookingCalls++);

  @override
  Future<MentorMeetingPurchaseStatus> loadPurchaseStatus(int subscriptionId) =>
      _next(purchaseStatusResults, purchaseStatusCalls++);

  @override
  Future<MentorMeetingPurchaseStatus> syncPurchaseStatus(int subscriptionId) =>
      _next(purchaseStatusResults, purchaseStatusCalls++);

  Future<T> _next<T>(List<Object> results, int callIndex) async {
    if (results.isEmpty) throw StateError('Unexpected repository call.');
    final result = results[callIndex.clamp(0, results.length - 1)];
    if (result is Exception) throw result;
    if (result is Future<T>) return result;
    return result as T;
  }
}

class _RecordingMeetingLinkLauncher implements MentorMeetingLinkLauncher {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
