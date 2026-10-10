import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/data/api_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_home_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meeting_detail_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meetings_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';

void main() {
  group('role and routing', () {
    test('1. exposes the dedicated Mentor route family', () {
      expect(AppRoutes.mentor, '/mentor');
      expect(AppRoutes.mentorAvailability, '/mentor/availability');
      expect(AppRoutes.mentorMeetings, '/mentor/meetings');
      expect(AppRoutes.mentorMeetingDetail(42), '/mentor/meetings/42');
      expect(() => AppRoutes.mentorMeetingDetail(0), throwsArgumentError);
    });

    test('2. authenticated Mentor leaves login for Mentor Home', () {
      expect(
        authRouteRedirect(
          authState: AuthSessionState.authenticated,
          role: BackendUserRole.mentor,
          matchedLocation: AppRoutes.login,
        ),
        AppRoutes.mentor,
      );
    });

    test('3. Learner cannot enter the Mentor route family', () {
      expect(
        authRouteRedirect(
          authState: AuthSessionState.authenticated,
          role: BackendUserRole.learner,
          matchedLocation: AppRoutes.mentorMeetings,
        ),
        AppRoutes.home,
      );
    });

    test('4. Mentor cannot enter the Learner shell', () {
      expect(
        authRouteRedirect(
          authState: AuthSessionState.authenticated,
          role: BackendUserRole.mentor,
          matchedLocation: AppRoutes.home,
        ),
        AppRoutes.mentor,
      );
    });

    test(
      '5. unsupported and unknown roles never fall back to mobile roles',
      () {
        for (final role in <BackendUserRole?>[
          BackendUserRole.contentAuthor,
          BackendUserRole.admin,
          null,
        ]) {
          expect(
            authRouteRedirect(
              authState: AuthSessionState.authenticated,
              role: role,
              matchedLocation: AppRoutes.home,
            ),
            AppRoutes.unsupportedRole,
          );
        }
      },
    );

    test('6. nested Mentor routes are stable and cannot redirect-loop', () {
      for (final location in <String>[
        AppRoutes.mentor,
        AppRoutes.mentorAvailability,
        AppRoutes.mentorMeetings,
        AppRoutes.mentorMeetingDetail(9),
      ]) {
        expect(
          authRouteRedirect(
            authState: AuthSessionState.authenticated,
            role: BackendUserRole.mentor,
            matchedLocation: location,
          ),
          isNull,
        );
      }
    });
  });

  group('verified Mentor contract', () {
    test('7. uses only the verified read endpoints', () {
      expect(MentorApiPaths.availability, '/api/mentor/availability');
      expect(MentorApiPaths.meetings, '/api/mentor/meetings');
    });

    test('8. availability maps exact fields from the live envelope', () async {
      final client = _RecordingApiClient(<String, Object?>{
        'GET ${MentorApiPaths.availability}': _envelope([
          {
            'id': 31,
            'startTime': '2026-10-03T09:00:00+07:00',
            'endTime': '2026-10-03T10:00:00+07:00',
            'isBooked': false,
          },
        ]),
      });

      final result = await ApiMentorRepository(client).loadAvailability();

      expect(client.calls, ['GET ${MentorApiPaths.availability}']);
      expect(result, hasLength(1));
      expect(result.single.id, 31);
      expect(result.single.isBooked, isFalse);
      expect(result.single.startTime.rawValue, '2026-10-03T09:00:00+07:00');
    });

    test('9. availability rejects missing or fabricated identifiers', () {
      expect(
        () => MentorAvailabilityDto.fromJson({
          'availabilityId': 31,
          'startTime': '2026-10-03T09:00:00',
          'endTime': '2026-10-03T10:00:00',
          'isBooked': false,
        }),
        throwsFormatException,
      );
      expect(
        () => MentorAvailabilityDto.fromJson({
          'id': 0,
          'startTime': '2026-10-03T09:00:00',
          'endTime': '2026-10-03T10:00:00',
          'isBooked': false,
        }),
        throwsFormatException,
      );
    });

    test(
      '10. meetings map exact verified nullable fields and status',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'GET ${MentorApiPaths.meetings}': _envelope([
            {
              'id': 81,
              'learnerName': 'Minh Anh',
              'scheduledAt': '2026-10-04T14:30:00Z',
              'status': 'Accepted',
              'meetingLink': 'https://meet.example.com/room-81',
            },
          ]),
        });

        final result = await ApiMentorRepository(client).loadMeetings();

        expect(client.calls, ['GET ${MentorApiPaths.meetings}']);
        expect(result.single.id, 81);
        expect(result.single.learnerName, 'Minh Anh');
        expect(result.single.status, MentorMeetingStatus.accepted);
        expect(result.single.safeMeetingUri.toString(), contains('room-81'));
      },
    );

    test(
      '11. meetings preserve only returned records and identifiers',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'GET ${MentorApiPaths.meetings}': _envelope([
            {
              'id': 901,
              'learnerName': null,
              'scheduledAt': null,
              'status': 'Assigned',
              'meetingLink': null,
            },
            {
              'id': 907,
              'learnerName': 'A',
              'scheduledAt': null,
              'status': 'Completed',
              'meetingLink': null,
            },
          ]),
        });

        final result = await ApiMentorRepository(client).loadMeetings();

        expect(result.map((meeting) => meeting.id), [901, 907]);
        expect(result.first.learnerName, isNull);
        expect(result.first.scheduledAt, isNull);
      },
    );

    test('12. Mentor response envelope is strict', () {
      expect(() => readMentorResultList(const []), throwsFormatException);
      expect(
        () => readMentorResultList(const {'data': []}),
        throwsFormatException,
      );
      expect(
        () => readMentorResultList(const {
          'result': [7],
        }),
        throwsFormatException,
      );
    });

    test('13. enum literals are exact and Consultant is not a role alias', () {
      expect(
        MentorMeetingStatus.fromApiValue('Accepted'),
        MentorMeetingStatus.accepted,
      );
      expect(
        MentorMeetingStatus.fromApiValue('accepted'),
        MentorMeetingStatus.unknown,
      );
      expect(BackendUserRole.fromApiValue('Mentor'), BackendUserRole.mentor);
      expect(BackendUserRole.fromApiValue('Consultant'), isNull);
    });

    test('14. offset-aware timestamps use device-local display conversion', () {
      final timestamp = MentorTimestamp.parse('2026-10-03T09:00:00+07:00');
      expect(timestamp.hasExplicitOffset, isTrue);
      expect(timestamp.displayValue, timestamp.value.toLocal());
    });

    test(
      '15. offset-less timestamps preserve server wall-clock components',
      () {
        final timestamp = MentorTimestamp.parse('2026-10-03T09:30:00');
        expect(timestamp.hasExplicitOffset, isFalse);
        expect(timestamp.displayValue.year, 2026);
        expect(timestamp.displayValue.month, 10);
        expect(timestamp.displayValue.day, 3);
        expect(timestamp.displayValue.hour, 9);
        expect(timestamp.displayValue.minute, 30);
      },
    );

    test('16. join URLs allow only returned absolute HTTP(S) values', () {
      expect(
        _meeting(link: 'https://meet.example.com/a').safeMeetingUri,
        isNotNull,
      );
      expect(
        _meeting(link: 'http://meet.example.com/a').safeMeetingUri,
        isNotNull,
      );
      expect(_meeting(link: 'javascript:alert(1)').safeMeetingUri, isNull);
      expect(_meeting(link: '/relative-room').safeMeetingUri, isNull);
      expect(_meeting(link: 'not a url').safeMeetingUri, isNull);
      expect(_meeting().safeMeetingUri, isNull);
    });

    test(
      '17. repository reads never call mutation verbs or send fixture IDs',
      () async {
        final client = _RecordingApiClient(<String, Object?>{
          'GET ${MentorApiPaths.availability}': _envelope(const []),
          'GET ${MentorApiPaths.meetings}': _envelope(const []),
        });
        final repository = ApiMentorRepository(client);

        await repository.loadAvailability();
        await repository.loadMeetings();

        expect(client.calls, [
          'GET ${MentorApiPaths.availability}',
          'GET ${MentorApiPaths.meetings}',
        ]);
        expect(client.postCalls, 0);
        expect(client.deleteCalls, 0);
        expect(client.queryParameters, everyElement(isNull));
      },
    );
  });

  group('Mentor Home', () {
    testWidgets('18. loads live availability and meeting summaries', (
      tester,
    ) async {
      final repository = _TestMentorRepository(
        availabilityResults: [
          [_slot(id: 1)],
        ],
        meetingResults: [
          [_meeting(id: 8, learnerName: 'Yuki')],
        ],
      );

      await _pumpMentor(
        tester,
        const MentorHomeScreen(),
        repository: repository,
      );

      expect(
        find.byKey(const Key('mentor_home_availability_summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mentor_home_meetings_summary')),
        findsOneWidget,
      );
      expect(find.textContaining('Yuki'), findsOneWidget);
      expect(repository.availabilityCalls, 1);
      expect(repository.meetingCalls, 1);
    });

    testWidgets('19. availability failure does not destroy Meetings', (
      tester,
    ) async {
      final repository = _TestMentorRepository(
        availabilityResults: [StateError('availability failed')],
        meetingResults: [
          [_meeting(id: 8, learnerName: 'Yuki')],
        ],
      );

      await _pumpMentor(
        tester,
        const MentorHomeScreen(),
        repository: repository,
      );

      expect(
        find.byKey(const Key('mentor_home_availability_error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mentor_home_meetings_summary')),
        findsOneWidget,
      );
    });

    testWidgets('20. meetings failure does not destroy Availability', (
      tester,
    ) async {
      final repository = _TestMentorRepository(
        availabilityResults: [
          [_slot(id: 1)],
        ],
        meetingResults: [StateError('meetings failed')],
      );

      await _pumpMentor(
        tester,
        const MentorHomeScreen(),
        repository: repository,
      );

      expect(
        find.byKey(const Key('mentor_home_availability_summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mentor_home_meetings_error')),
        findsOneWidget,
      );
    });

    testWidgets('21. empty Home data renders safely', (tester) async {
      final repository = _TestMentorRepository.empty();

      await _pumpMentor(
        tester,
        const MentorHomeScreen(),
        repository: repository,
      );

      expect(
        find.byKey(const Key('mentor_home_availability_summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mentor_home_meetings_summary')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('availability presentation', () {
    testWidgets('22. renders a stable loading state', (tester) async {
      final pending = Completer<List<MentorAvailabilitySlot>>();
      final repository = _TestMentorRepository(
        availabilityResults: [pending.future],
        meetingResults: const [[]],
      );

      await _pumpMentor(
        tester,
        const MentorAvailabilityScreen(),
        repository: repository,
        settle: false,
      );

      expect(
        find.byKey(const Key('mentor_availability_loading')),
        findsOneWidget,
      );
      pending.complete(const []);
    });

    testWidgets('23. displays mapped slots without raw IDs', (tester) async {
      final repository = _TestMentorRepository(
        availabilityResults: [
          [_slot(id: 321), _slot(id: 654, booked: true)],
        ],
        meetingResults: const [[]],
      );

      await _pumpMentor(
        tester,
        const MentorAvailabilityScreen(),
        repository: repository,
      );

      expect(find.byKey(const Key('mentor_availability_0')), findsOneWidget);
      expect(find.byKey(const Key('mentor_availability_1')), findsOneWidget);
      expect(find.text('321'), findsNothing);
      expect(find.text('654'), findsNothing);
    });

    testWidgets('24. displays the availability empty state', (tester) async {
      await _pumpMentor(
        tester,
        const MentorAvailabilityScreen(),
        repository: _TestMentorRepository.empty(),
      );

      expect(
        find.byKey(const Key('mentor_availability_empty')),
        findsOneWidget,
      );
    });

    testWidgets('25. displays a retryable availability error', (tester) async {
      final repository = _TestMentorRepository(
        availabilityResults: [StateError('offline')],
        meetingResults: const [[]],
      );

      await _pumpMentor(
        tester,
        const MentorAvailabilityScreen(),
        repository: repository,
      );

      expect(
        find.byKey(const Key('mentor_availability_error')),
        findsOneWidget,
      );
    });

    test('26. refresh updates the shared availability state', () async {
      final repository = _TestMentorRepository(
        availabilityResults: [
          const <MentorAvailabilitySlot>[],
          [_slot(id: 77)],
        ],
        meetingResults: const [[]],
      );
      final container = ProviderContainer(
        overrides: [mentorRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(mentorAvailabilityControllerProvider.future),
        isEmpty,
      );
      await container
          .read(mentorAvailabilityControllerProvider.notifier)
          .retry();

      expect(
        container
            .read(mentorAvailabilityControllerProvider)
            .requireValue
            .single
            .id,
        77,
      );
      expect(repository.availabilityCalls, 2);
    });
  });

  group('meetings presentation', () {
    testWidgets('27. renders a stable loading state', (tester) async {
      final pending = Completer<List<MentorMeetingSummary>>();
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [pending.future],
      );

      await _pumpMentor(
        tester,
        const MentorMeetingsScreen(),
        repository: repository,
        settle: false,
      );

      expect(find.byKey(const Key('mentor_meetings_loading')), findsOneWidget);
      pending.complete(const []);
    });

    testWidgets('28. displays only meetings returned for this Mentor', (
      tester,
    ) async {
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [
          [
            _meeting(id: 44, learnerName: 'Hana'),
            _meeting(id: 55, learnerName: 'Ken'),
          ],
        ],
      );

      await _pumpMentor(
        tester,
        const MentorMeetingsScreen(),
        repository: repository,
      );

      expect(
        find.byKey(const ValueKey<String>('mentor_meeting_44')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mentor_meeting_55')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mentor_meeting_0')),
        findsNothing,
      );
      expect(find.text('Hana'), findsOneWidget);
      expect(find.text('Ken'), findsOneWidget);
      expect(find.text('Lịch tư vấn của tôi'), findsWidgets);
      expect(find.text('Meeting của tôi'), findsNothing);
    });

    testWidgets('29. displays the meetings empty state', (tester) async {
      await _pumpMentor(
        tester,
        const MentorMeetingsScreen(),
        repository: _TestMentorRepository.empty(),
      );

      expect(find.byKey(const Key('mentor_meetings_empty')), findsOneWidget);
    });

    testWidgets('30. displays a retryable meetings error', (tester) async {
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [StateError('offline')],
      );

      await _pumpMentor(
        tester,
        const MentorMeetingsScreen(),
        repository: repository,
      );

      expect(find.byKey(const Key('mentor_meetings_error')), findsOneWidget);
    });
  });

  group('meeting detail and safety', () {
    testWidgets('31. a meeting detail route opens by the returned Backend ID', (
      tester,
    ) async {
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [
          [_meeting(id: 73, learnerName: 'Sora')],
        ],
      );

      await _pumpMentorRouter(
        tester,
        initialLocation: AppRoutes.mentorMeetingDetail(73),
        repository: repository,
      );

      expect(find.byType(MentorMeetingDetailScreen), findsOneWidget);
      expect(
        find.byKey(const Key('mentor_meeting_detail_content')),
        findsOneWidget,
      );
      expect(find.text('Sora'), findsWidgets);
      expect(find.text('73'), findsNothing);
    });

    testWidgets('32. missing meeting detail fails safely', (tester) async {
      await _pumpMentorRouter(
        tester,
        initialLocation: AppRoutes.mentorMeetingDetail(999),
        repository: _TestMentorRepository.empty(),
      );

      expect(
        find.byKey(const Key('mentor_meeting_detail_missing')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('33. a missing meeting link leaves Join unavailable', (
      tester,
    ) async {
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [
          [_meeting(id: 73, learnerName: 'Sora')],
        ],
      );

      await _pumpMentorRouter(
        tester,
        initialLocation: AppRoutes.mentorMeetingDetail(73),
        repository: repository,
      );

      expect(
        find.byKey(const Key('mentor_meeting_link_unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mentor_join_meeting_button')), findsNothing);
    });

    testWidgets('34. Join opens exactly the safe URL returned by Backend', (
      tester,
    ) async {
      final launcher = _RecordingMeetingLinkLauncher();
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [
          [
            _meeting(
              id: 73,
              learnerName: 'Sora',
              link: 'https://meet.example.com/backend-room-73',
            ),
          ],
        ],
      );

      await _pumpMentorRouter(
        tester,
        initialLocation: AppRoutes.mentorMeetingDetail(73),
        repository: repository,
        launcher: launcher,
      );
      await tester.tap(find.byKey(const Key('mentor_join_meeting_button')));
      await tester.pump();

      expect(launcher.opened, [
        Uri.parse('https://meet.example.com/backend-room-73'),
      ]);
    });

    testWidgets('35. malformed link is never offered to the launcher', (
      tester,
    ) async {
      final launcher = _RecordingMeetingLinkLauncher();
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [
          [_meeting(id: 73, link: 'room-73')],
        ],
      );

      await _pumpMentorRouter(
        tester,
        initialLocation: AppRoutes.mentorMeetingDetail(73),
        repository: repository,
        launcher: launcher,
      );

      expect(
        find.byKey(const Key('mentor_meeting_link_unavailable')),
        findsOneWidget,
      );
      expect(launcher.opened, isEmpty);
    });

    testWidgets(
      '36. 403 renders an error without clearing the Mentor session',
      (tester) async {
        final session = createTestAuthSession(role: BackendUserRole.mentor);
        final repository = _TestMentorRepository(
          availabilityResults: const [[]],
          meetingResults: [const ForbiddenError()],
        );

        await _pumpMentor(
          tester,
          const MentorMeetingsScreen(),
          repository: repository,
          session: session,
        );

        expect(find.byKey(const Key('mentor_meetings_error')), findsOneWidget);
        expect(session.value, AuthSessionState.authenticated);
        expect(session.currentRole, BackendUserRole.mentor);
      },
    );

    testWidgets('37. Mentor logout clears the session', (tester) async {
      final session = createTestAuthSession(role: BackendUserRole.mentor);

      await _pumpMentor(
        tester,
        const MentorHomeScreen(),
        repository: _TestMentorRepository.empty(),
        session: session,
      );
      await tester.tap(find.byKey(const Key('mentor_logout_button')));
      await tester.pumpAndSettle();

      expect(session.value, AuthSessionState.unauthenticated);
      expect(session.currentRole, isNull);
    });

    testWidgets('38. cards remain overflow-free at 320px', (tester) async {
      final repository = _TestMentorRepository(
        availabilityResults: const [[]],
        meetingResults: [
          [
            _meeting(
              id: 12,
              learnerName:
                  'A very long learner display name that must wrap safely',
              link: 'https://meet.example.com/12',
            ),
          ],
        ],
      );

      await _pumpMentor(
        tester,
        const MentorMeetingsScreen(),
        repository: repository,
        size: const Size(320, 720),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('39. Japanese localization is available for Mentor screens', (
      tester,
    ) async {
      await _pumpMentor(
        tester,
        const MentorAvailabilityScreen(),
        repository: _TestMentorRepository.empty(),
        locale: const Locale('ja'),
      );

      expect(find.text('自分の空き時間'), findsWidgets);
      expect(find.text('閲覧のみ'), findsOneWidget);

      await _pumpMentor(
        tester,
        const MentorMeetingsScreen(),
        repository: _TestMentorRepository.empty(),
        locale: const Locale('ja'),
      );

      expect(find.text('自分の相談予定'), findsWidgets);
      expect(find.text('相談予定はまだありません。'), findsOneWidget);
      expect(find.textContaining('ミーティング'), findsNothing);
    });

    test(
      '40. shared invalidation refreshes both independent read models',
      () async {
        final repository = _TestMentorRepository(
          availabilityResults: [
            const <MentorAvailabilitySlot>[],
            [_slot(id: 22)],
          ],
          meetingResults: [
            const <MentorMeetingSummary>[],
            [_meeting(id: 33)],
          ],
        );
        final container = ProviderContainer(
          overrides: [mentorRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await Future.wait([
          container.read(mentorAvailabilityControllerProvider.future),
          container.read(mentorMeetingsControllerProvider.future),
        ]);
        await Future.wait([
          container.refresh(mentorAvailabilityControllerProvider.future),
          container.refresh(mentorMeetingsControllerProvider.future),
        ]);

        expect(
          container
              .read(mentorAvailabilityControllerProvider)
              .requireValue
              .single
              .id,
          22,
        );
        expect(
          container
              .read(mentorMeetingsControllerProvider)
              .requireValue
              .single
              .id,
          33,
        );
      },
    );
  });
}

Map<String, Object?> _envelope(List<Object?> result) => {'result': result};

MentorAvailabilitySlot _slot({required int id, bool booked = false}) {
  return MentorAvailabilitySlot(
    id: id,
    startTime: MentorTimestamp.parse('2026-10-03T09:00:00+07:00'),
    endTime: MentorTimestamp.parse('2026-10-03T10:00:00+07:00'),
    isBooked: booked,
  );
}

MentorMeetingSummary _meeting({int id = 1, String? learnerName, String? link}) {
  return MentorMeetingSummary(
    id: id,
    learnerName: learnerName,
    scheduledAt: MentorTimestamp.parse('2026-10-04T14:30:00+07:00'),
    status: MentorMeetingStatus.accepted,
    meetingLink: link,
  );
}

Future<void> _pumpMentor(
  WidgetTester tester,
  Widget child, {
  required MentorRepository repository,
  AuthSessionController? session,
  MentorMeetingLinkLauncher? launcher,
  Size size = const Size(390, 844),
  Locale locale = const Locale('vi'),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final effectiveSession =
      session ?? createTestAuthSession(role: BackendUserRole.mentor);
  if (session == null) addTearDown(effectiveSession.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionControllerProvider.overrideWithValue(effectiveSession),
        mentorRepositoryProvider.overrideWithValue(repository),
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
  if (settle) await tester.pumpAndSettle();
}

Future<GoRouter> _pumpMentorRouter(
  WidgetTester tester, {
  required String initialLocation,
  required MentorRepository repository,
  MentorMeetingLinkLauncher? launcher,
}) async {
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
        authSessionControllerProvider.overrideWithValue(session),
        mentorRepositoryProvider.overrideWithValue(repository),
        if (launcher != null)
          mentorMeetingLinkLauncherProvider.overrideWithValue(launcher),
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
  return router;
}

class _TestMentorRepository implements MentorRepository {
  _TestMentorRepository({
    required this.availabilityResults,
    required this.meetingResults,
  });

  factory _TestMentorRepository.empty() => _TestMentorRepository(
    availabilityResults: const [<MentorAvailabilitySlot>[]],
    meetingResults: const [<MentorMeetingSummary>[]],
  );

  final List<Object> availabilityResults;
  final List<Object> meetingResults;
  int availabilityCalls = 0;
  int meetingCalls = 0;

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() {
    final result =
        availabilityResults[availabilityCalls.clamp(
          0,
          availabilityResults.length - 1,
        )];
    availabilityCalls++;
    return _resolve<List<MentorAvailabilitySlot>>(result);
  }

  @override
  Future<List<MentorMeetingSummary>> loadMeetings() {
    final result =
        meetingResults[meetingCalls.clamp(0, meetingResults.length - 1)];
    meetingCalls++;
    return _resolve<List<MentorMeetingSummary>>(result);
  }

  Future<T> _resolve<T>(Object result) async {
    if (result is Exception) throw result;
    if (result is Future<T>) return result;
    return result as T;
  }
}

class _RecordingMeetingLinkLauncher implements MentorMeetingLinkLauncher {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.responses) : super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> responses;
  final List<String> calls = <String>[];
  final List<Map<String, dynamic>?> queryParameters = <Map<String, dynamic>?>[];
  int postCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final key = 'GET $path';
    calls.add(key);
    this.queryParameters.add(queryParameters);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responses[key] as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    postCalls++;
    throw StateError('Mentor read repository must not call POST.');
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    deleteCalls++;
    throw StateError('Mentor read repository must not call DELETE.');
  }
}
