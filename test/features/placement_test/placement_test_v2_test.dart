import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/onboarding/application/learner_startup_controller.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_draft_store.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_dtos.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/placement_test/presentation/placement_test_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';
import '../../support/test_json_preference_store.dart';

void main() {
  group('v2 DTO and error contracts', () {
    test(
      'maps exact status, active snapshot, and nullable active response',
      () {
        final status = readPlacementTestStatus(<String, Object?>{
          'statusCode': 200,
          'isSuccess': true,
          'result': <String, Object?>{
            'attemptType': 'placement',
            'hasActiveAttempt': true,
            'activeAttemptId': 81,
            'activeAttemptExpiresAt': '2026-10-27T02:30:00Z',
            'hasCompletedPlacementTest': true,
            'latestCompletedAttemptId': 72,
            'latestSubmittedAt': '2026-10-26T02:00:00Z',
            'latestScorePercent': 80,
            'assessedJlptLevelId': 2,
            'assessedJlptLevelName': 'N4',
            'recommendedTargetJlptLevelId': 3,
            'recommendedTargetJlptLevelName': 'N3',
            'targetJlptLevelId': null,
            'targetJlptLevelName': null,
            'dailyStudyMinutes': 45,
            'targetExamDate': null,
            'isReadyForLearningPath': false,
          },
        });
        expect(status.attemptType, 'placement');
        expect(status.hasActiveAttempt, isTrue);
        expect(status.activeAttemptId, 81);
        expect(status.latestCompletedAttemptId, 72);

        final active = readActivePlacementTest(<String, Object?>{
          'statusCode': 200,
          'isSuccess': true,
          'result': _activeSnapshotJson,
        });
        expect(active?.attemptType, 'placement');
        expect(active?.status, 'inProgress');
        expect(active?.isResumed, isTrue);
        expect(active?.expiresAt, DateTime.utc(2026, 10, 27, 2, 30));
        expect(active?.serverNow, DateTime.utc(2026, 10, 27, 2, 20));

        expect(
          readActivePlacementTest(<String, Object?>{
            'statusCode': 200,
            'isSuccess': true,
            'result': null,
          }),
          isNull,
        );
      },
    );

    test('keeps compatible v1 success field aliases', () {
      final status = readPlacementTestStatus(<String, Object?>{
        'isSuccess': true,
        'result': <String, Object?>{
          'attemptType': 'placement',
          'hasCompletedPlacementTest': true,
          'latestAttemptId': 14,
        },
      });
      expect(status.latestCompletedAttemptId, 14);
      expect(status.attemptType, 'placement');

      final start = readStartPlacementTest(<String, Object?>{
        'isSuccess': true,
        'result': <String, Object?>{
          ..._activeSnapshotJson,
          'status': null,
          'isResumed': null,
          'expiresAt': null,
          'serverNow': '2026-10-27T02:20:00Z',
        },
      });
      expect(start.attemptType, 'placement');
      expect(start.status, 'inProgress');
      expect(start.isResumed, isFalse);
      expect(start.expiresAt, start.startedAt.add(const Duration(minutes: 15)));
    });

    test('rejects missing v2 attempt type and server clock', () {
      expect(
        () => readPlacementTestStatus(<String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{'hasCompletedPlacementTest': false},
        }),
        throwsFormatException,
      );
      final attemptWithoutType = Map<String, Object?>.of(_activeSnapshotJson)
        ..remove('attemptType');
      expect(
        () => readStartPlacementTest(<String, Object?>{
          'isSuccess': true,
          'result': attemptWithoutType,
        }),
        throwsFormatException,
      );
      expect(
        () => readStartPlacementTest(<String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{
            ..._activeSnapshotJson,
            'serverNow': null,
          },
        }),
        throwsFormatException,
      );
    });

    test('preserves stable error code and retryable fields', () {
      final error = const ApiErrorMapper().fromEnvelopeFailure(
        <String, Object?>{
          'statusCode': 409,
          'isSuccess': false,
          'errorMessage': 'Question bank is not ready.',
          'errorCode': 'PLACEMENT_BANK_NOT_READY',
          'retryable': true,
          'errors': <Object?>['N3 has too few questions.'],
        },
        httpStatusCode: 409,
      );

      expect(error, isA<ConflictError>());
      expect(error?.errorCode, 'PLACEMENT_BANK_NOT_READY');
      expect(error?.retryable, isTrue);
      expect(error?.details, <String>['N3 has too few questions.']);
    });
  });

  group('learner-scoped draft persistence and restore', () {
    test(
      'isolates keys by learner and stores only allowed draft fields',
      () async {
        final preferences = TestJsonPreferenceStore();
        final store = PlacementTestDraftStore(preferences);
        await store.save(
          PlacementTestDraft(
            schemaVersion: 1,
            userId: 42,
            attemptId: 81,
            currentQuestionIndex: 1,
            selectedOptionIdsByQuestionId: const <int, int>{501: 5012},
            updatedAt: DateTime.utc(2026, 10, 27),
          ),
        );

        expect(await store.load(userId: 7, attemptId: 81), isNull);
        final restored = await store.load(userId: 42, attemptId: 81);
        expect(restored?.selectedOptionIdsByQuestionId, <int, int>{501: 5012});
        final raw = preferences.values['placement_draft_v1:42:81']!;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        expect(
          json.keys,
          unorderedEquals(<String>[
            'schemaVersion',
            'userId',
            'attemptId',
            'currentQuestionIndex',
            'selectedOptionIdsByQuestionId',
            'updatedAt',
          ]),
        );
        expect(raw, isNot(contains('questions')));
        expect(raw, isNot(contains('correctOption')));
        expect(raw, isNot(contains('token')));
      },
    );

    test(
      'restores after restart/re-login only for the matching learner',
      () async {
        final preferences = TestJsonPreferenceStore();
        final draftStore = PlacementTestDraftStore(preferences);
        await draftStore.save(
          PlacementTestDraft(
            schemaVersion: 1,
            userId: 42,
            attemptId: 81,
            currentQuestionIndex: 1,
            selectedOptionIdsByQuestionId: const <int, int>{401: 4011},
            updatedAt: DateTime.utc(2026, 10, 27),
          ),
        );
        final repository = _PlacementRepository(
          status: _activeStatus,
          activeAttempt: _activeAttempt(),
        );

        final first = _container(
          placement: repository,
          preferences: preferences,
          userId: 42,
        );
        expect(
          (await first.container.read(
            placementTestControllerProvider.future,
          )).attempt?.answers,
          <int, int>{401: 4011},
        );

        first.session.markAuthenticated(
          userId: 77,
          role: BackendUserRole.learner,
        );
        final switchedUser = await first.container.read(
          placementTestControllerProvider.future,
        );
        expect(switchedUser.attempt?.answers, isEmpty);
        first.dispose();

        final relogin = _container(
          placement: repository,
          preferences: preferences,
          userId: 42,
        );
        final restored = await relogin.container.read(
          placementTestControllerProvider.future,
        );
        expect(restored.attempt?.currentQuestionIndex, 1);
        expect(restored.attempt?.answers, <int, int>{401: 4011});
        relogin.dispose();

        final otherLearner = _container(
          placement: repository,
          preferences: preferences,
          userId: 77,
        );
        final isolated = await otherLearner.container.read(
          placementTestControllerProvider.future,
        );
        expect(isolated.attempt?.answers, isEmpty);
        otherLearner.dispose();
      },
    );

    test('clears only the matching corrupt or stale draft', () async {
      final preferences = TestJsonPreferenceStore(
        initialValues: <String, String>{
          'placement_draft_v1:42:81': jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'userId': 7,
            'attemptId': 81,
            'currentQuestionIndex': 0,
            'selectedOptionIdsByQuestionId': <String, int>{},
            'updatedAt': '2026-10-27T00:00:00Z',
          }),
          'placement_draft_v1:42:99': 'keep-other-attempt',
        },
      );
      final store = PlacementTestDraftStore(preferences);

      expect(await store.load(userId: 42, attemptId: 81), isNull);
      expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
      expect(
        preferences.values['placement_draft_v1:42:99'],
        'keep-other-attempt',
      );
    });
  });

  group('authoritative recovery and submission', () {
    test(
      'uses server remaining duration plus monotonic elapsed time',
      () async {
        var elapsed = Duration.zero;
        final preferences = TestJsonPreferenceStore();
        await PlacementTestDraftStore(preferences).save(_draft());
        await preferences.write(
          PlacementTestDraftStore.keyFor(userId: 42, attemptId: 99),
          'keep-other-attempt',
        );
        final repository = _PlacementRepository(
          status: _activeStatus,
          activeAttempt: _activeAttempt(
            serverNow: DateTime.utc(2026, 10, 27, 2, 20),
            expiresAt: DateTime.utc(2026, 10, 27, 2, 21),
          ),
        );
        final scope = _container(
          placement: repository,
          preferences: preferences,
          elapsed: () => elapsed,
        );
        final initial = await scope.container.read(
          placementTestControllerProvider.future,
        );
        expect(initial.remainingAtElapsed(elapsed), const Duration(minutes: 1));

        elapsed = const Duration(seconds: 61);
        scope.container
            .read(placementTestControllerProvider.notifier)
            .expireIfNeeded();
        final expired = scope.container
            .read(placementTestControllerProvider)
            .requireValue;
        expect(expired.attempt, isNull);
        expect(expired.actionIssue, PlacementTestActionIssue.expired);
        expect(repository.submitCalls, 0);
        await Future<void>.delayed(Duration.zero);
        expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
        expect(
          preferences.values['placement_draft_v1:42:99'],
          'keep-other-attempt',
        );
        scope.dispose();
      },
    );

    test('recovers an unapplied canonical completed result by ID', () async {
      final repository = _PlacementRepository(
        status: _completedStatus,
        result: _completedResult,
      );
      final scope = _container(placement: repository);

      final state = await scope.container.read(
        placementTestControllerProvider.future,
      );

      expect(state.result?.attemptId, 81);
      expect(repository.resultCalls, 1);
      expect(repository.lastResultAttemptId, 81);
      scope.dispose();
    });

    test('routes authenticated startup to a restored active attempt', () async {
      final profile = _ProfileRepository();
      final scope = _container(
        placement: _PlacementRepository(
          status: _activeStatus,
          activeAttempt: _activeAttempt(),
        ),
        profile: profile,
      );

      final destination = await scope.container.read(
        learnerStartupDestinationProvider.future,
      );

      expect(destination, LearnerStartupDestination.placementTest);
      expect(profile.loadCalls, 0);
      scope.dispose();
    });

    testWidgets('clock is shown only while an active attempt is displayed', (
      tester,
    ) async {
      var elapsed = Duration.zero;
      final scope = _container(
        placement: _PlacementRepository(
          status: _activeStatus,
          activeAttempt: _activeAttempt(),
          result: _completedResult,
        ),
        elapsed: () => elapsed,
      );
      addTearDown(scope.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope.container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PlacementTestScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('placement_test_timer_badge')),
        findsOneWidget,
      );
      elapsed = const Duration(seconds: 2);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('09:58'), findsOneWidget);

      await scope.container
          .read(placementTestControllerProvider.notifier)
          .submit();
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('placement_test_result_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('placement_test_timer_badge')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.byKey(const ValueKey<String>('placement_test_result_view')),
        findsOneWidget,
      );
    });

    test(
      'recovers canonical result after an uncertain duplicate submit',
      () async {
        final repository = _PlacementRepository(
          status: _activeStatus,
          activeAttempt: _activeAttempt(),
          result: _completedResult,
          submitOutcomes: <Object>[const NetworkError()],
        );
        final scope = _container(placement: repository);
        await scope.container.read(placementTestControllerProvider.future);

        final outcome = await scope.container
            .read(placementTestControllerProvider.notifier)
            .submit();

        expect(outcome, PlacementTestSubmitOutcome.recoveredCompleted);
        expect(repository.submitCalls, 1);
        expect(repository.resultCalls, 1);
        expect(
          scope.container.read(placementTestControllerProvider).value?.result,
          same(_completedResult),
        );
        scope.dispose();
      },
    );

    test(
      'classifies bank and invalid-answer failures by stable code',
      () async {
        final bankRepository = _PlacementRepository(
          status: const PlacementTestStatus(hasCompletedPlacementTest: false),
          startOutcomes: <Object>[
            const ConflictError(
              errorCode: 'PLACEMENT_BANK_NOT_READY',
              retryable: true,
            ),
          ],
        );
        final bankScope = _container(placement: bankRepository);
        await bankScope.container.read(placementTestControllerProvider.future);
        await bankScope.container
            .read(placementTestControllerProvider.notifier)
            .startTest();
        expect(
          bankScope.container
              .read(placementTestControllerProvider)
              .value
              ?.actionIssue,
          PlacementTestActionIssue.bankNotReady,
        );
        bankScope.dispose();

        final answerRepository = _PlacementRepository(
          status: _activeStatus,
          activeAttempt: _activeAttempt(),
          submitOutcomes: <Object>[
            const ValidationError(
              errorCode: 'PLACEMENT_ANSWER_INVALID',
              retryable: false,
            ),
          ],
        );
        final answerScope = _container(placement: answerRepository);
        await answerScope.container.read(
          placementTestControllerProvider.future,
        );
        await answerScope.container
            .read(placementTestControllerProvider.notifier)
            .submit();
        final answerState = answerScope.container
            .read(placementTestControllerProvider)
            .requireValue;
        expect(answerState.actionIssue, PlacementTestActionIssue.invalidAnswer);
        expect(answerState.actionRetryable, isFalse);
        answerScope.dispose();

        final notCompletedScope = _container(
          placement: _PlacementRepository(
            status: _activeStatus,
            activeAttempt: _activeAttempt(),
            submitOutcomes: <Object>[
              const ConflictError(
                errorCode: 'PLACEMENT_ATTEMPT_NOT_READY',
                retryable: true,
              ),
            ],
          ),
        );
        await notCompletedScope.container.read(
          placementTestControllerProvider.future,
        );
        await notCompletedScope.container
            .read(placementTestControllerProvider.notifier)
            .submit();
        expect(
          notCompletedScope.container
              .read(placementTestControllerProvider)
              .value
              ?.actionIssue,
          PlacementTestActionIssue.notCompleted,
        );
        notCompletedScope.dispose();

        final notFoundScope = _container(
          placement: _PlacementRepository(
            status: _activeStatus,
            activeAttempt: _activeAttempt(),
            submitOutcomes: <Object>[
              const NotFoundError(
                errorCode: 'PLACEMENT_ATTEMPT_NOT_FOUND',
                retryable: false,
              ),
            ],
          ),
        );
        await notFoundScope.container.read(
          placementTestControllerProvider.future,
        );
        await notFoundScope.container
            .read(placementTestControllerProvider.notifier)
            .submit();
        final notFoundState = notFoundScope.container
            .read(placementTestControllerProvider)
            .requireValue;
        expect(notFoundState.actionIssue, PlacementTestActionIssue.notFound);
        expect(notFoundState.attempt, isNull);
        notFoundScope.dispose();
      },
    );

    test(
      'owned attempt 404 clears only that learner and attempt draft',
      () async {
        final preferences = TestJsonPreferenceStore();
        await PlacementTestDraftStore(preferences).save(_draft());
        await preferences.write(
          PlacementTestDraftStore.keyFor(userId: 42, attemptId: 99),
          'keep-other-attempt',
        );
        final scope = _container(
          placement: _PlacementRepository(
            status: _activeStatus,
            activeAttempt: _activeAttempt(),
            submitOutcomes: <Object>[
              const NotFoundError(
                errorCode: 'PLACEMENT_ATTEMPT_NOT_FOUND',
                retryable: false,
              ),
            ],
          ),
          preferences: preferences,
        );
        await scope.container.read(placementTestControllerProvider.future);

        await scope.container
            .read(placementTestControllerProvider.notifier)
            .submit();

        expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
        expect(
          preferences.values['placement_draft_v1:42:99'],
          'keep-other-attempt',
        );
        scope.dispose();
      },
    );

    test(
      'owned active-attempt 404 during restore clears only its draft',
      () async {
        final preferences = TestJsonPreferenceStore();
        await PlacementTestDraftStore(preferences).save(_draft());
        await preferences.write(
          PlacementTestDraftStore.keyFor(userId: 42, attemptId: 99),
          'keep-other-attempt',
        );
        final scope = _container(
          placement: _PlacementRepository(
            status: _activeStatus,
            activeAttemptFailure: const NotFoundError(
              errorCode: 'PLACEMENT_ATTEMPT_NOT_FOUND',
              retryable: false,
            ),
          ),
          preferences: preferences,
        );

        final restored = await scope.container.read(
          placementTestControllerProvider.future,
        );

        expect(restored.attempt, isNull);
        expect(restored.status.hasActiveAttempt, isFalse);
        expect(restored.actionIssue, PlacementTestActionIssue.notFound);
        expect(restored.actionRetryable, isFalse);
        expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
        expect(
          preferences.values['placement_draft_v1:42:99'],
          'keep-other-attempt',
        );
        scope.dispose();
      },
    );

    test(
      '409 duplicate submit recovers the canonical result by attempt ID',
      () async {
        final repository = _PlacementRepository(
          status: _activeStatus,
          activeAttempt: _activeAttempt(),
          result: _completedResult,
          submitOutcomes: <Object>[const ConflictError()],
        );
        final scope = _container(placement: repository);
        await scope.container.read(placementTestControllerProvider.future);

        final outcome = await scope.container
            .read(placementTestControllerProvider.notifier)
            .submit();

        expect(outcome, PlacementTestSubmitOutcome.recoveredCompleted);
        expect(repository.submitCalls, 1);
        expect(repository.resultCalls, 1);
        expect(repository.lastResultAttemptId, 81);
        expect(
          scope.container.read(placementTestControllerProvider).value?.result,
          same(_completedResult),
        );
        scope.dispose();
      },
    );
  });

  group('recommendation transition', () {
    test(
      'restart after completed path without exam date returns home and clears draft',
      () async {
        final preferences = TestJsonPreferenceStore();
        await PlacementTestDraftStore(preferences).save(_draft());
        final appliedStatus = PlacementTestStatus(
          hasCompletedPlacementTest: true,
          latestCompletedAttemptId: 81,
          latestSubmittedAt: DateTime.utc(2026, 10, 27, 2, 25),
          recommendedTargetJlptLevelId: 309,
          recommendedTargetJlptLevelName: 'N3',
          targetJlptLevelId: 309,
          targetJlptLevelName: 'N3',
          dailyStudyMinutes: 45,
          isReadyForLearningPath: true,
        );
        final placement = _PlacementRepository(
          status: appliedStatus,
          result: _completedResult,
        );
        final learning = _LearningPathRepository(
          latestOutcomes: <Object?>[_latestPath],
        );
        final scope = _container(
          placement: placement,
          preferences: preferences,
          learning: learning,
          profile: _ProfileRepository(targetId: 309),
        );

        final destination = await scope.container.read(
          learnerStartupDestinationProvider.future,
        );
        final restored = scope.container
            .read(placementTestControllerProvider)
            .requireValue;

        expect(destination, LearnerStartupDestination.home);
        expect(restored.result, isNull);
        expect(restored.hasAppliedCompletedResult, isTrue);
        expect(placement.resultCalls, 0);
        expect(learning.latestCalls, 1);
        expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
        scope.dispose();
      },
    );

    test(
      'Flow 1 target change prevents the older recommendation from hijacking startup',
      () async {
        final manualGoalStatus = PlacementTestStatus(
          hasCompletedPlacementTest: true,
          latestCompletedAttemptId: 81,
          latestSubmittedAt: DateTime.utc(2026, 10, 27, 2, 25),
          recommendedTargetJlptLevelId: 3,
          recommendedTargetJlptLevelName: 'N3',
          targetJlptLevelId: 204,
          targetJlptLevelName: 'N4',
          dailyStudyMinutes: 45,
          targetExamDate: DateTime.utc(2027, 7, 4),
        );
        final placement = _PlacementRepository(
          status: manualGoalStatus,
          result: _completedResult,
        );
        final learning = _LearningPathRepository();
        final profile = _ProfileRepository(
          targetId: 204,
          targetExamDate: DateTime.utc(2027, 7, 4),
        );
        final scope = _container(
          placement: placement,
          profile: profile,
          learning: learning,
        );

        final destination = await scope.container.read(
          learnerStartupDestinationProvider.future,
        );
        final restored = scope.container
            .read(placementTestControllerProvider)
            .requireValue;

        expect(destination, LearnerStartupDestination.home);
        expect(restored.result, isNull);
        expect(restored.hasAppliedCompletedResult, isTrue);
        expect(placement.resultCalls, 0);
        expect(learning.latestCalls, 0);
        expect(profile.loadCalls, 1);
        scope.dispose();
      },
    );

    test(
      'dismissed completed result stays ignored after restart and startup',
      () async {
        final preferences = TestJsonPreferenceStore();
        await PlacementTestDraftStore(preferences).save(_draft());
        final first = _container(
          placement: _PlacementRepository(
            status: _completedStatus,
            result: _completedResult,
          ),
          preferences: preferences,
        );
        final firstState = await first.container.read(
          placementTestControllerProvider.future,
        );
        expect(firstState.result, same(_completedResult));
        await first.container
            .read(placementTestControllerProvider.notifier)
            .dismissResult();
        expect(preferences.values, contains('placement_dismissed_v1:42'));
        expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
        first.dispose();

        final restartedRepository = _PlacementRepository(
          status: _completedStatus.copyWith(
            targetJlptLevelId: 309,
            targetJlptLevelName: 'N3',
            isReadyForLearningPath: true,
          ),
          result: _completedResult,
        );
        final learning = _LearningPathRepository();
        final restarted = _container(
          placement: restartedRepository,
          preferences: preferences,
          profile: _ProfileRepository(targetId: 309),
          learning: learning,
        );

        final destination = await restarted.container.read(
          learnerStartupDestinationProvider.future,
        );

        expect(destination, LearnerStartupDestination.home);
        expect(
          restarted.container
              .read(placementTestControllerProvider)
              .value
              ?.result,
          isNull,
        );
        expect(restartedRepository.resultCalls, 0);
        expect(learning.latestCalls, 0);
        restarted.dispose();
      },
    );

    test(
      'latest-path network failure routes startup to a recoverable retry screen',
      () async {
        final readyStatus = PlacementTestStatus(
          hasCompletedPlacementTest: true,
          latestCompletedAttemptId: 81,
          latestSubmittedAt: DateTime.utc(2026, 10, 27, 2, 25),
          recommendedTargetJlptLevelId: 3,
          recommendedTargetJlptLevelName: 'N3',
          targetJlptLevelId: 3,
          targetJlptLevelName: 'N3',
          dailyStudyMinutes: 45,
          isReadyForLearningPath: true,
        );
        final learning = _LearningPathRepository(
          latestOutcomes: <Object?>[const NetworkError(), _latestPath],
        );
        final scope = _container(
          placement: _PlacementRepository(status: readyStatus),
          learning: learning,
        );

        final destination = await scope.container.read(
          learnerStartupDestinationProvider.future,
        );
        final failedState = scope.container
            .read(placementTestControllerProvider)
            .requireValue;

        expect(destination, LearnerStartupDestination.placementTest);
        expect(failedState.shouldRetryResultRecovery, isTrue);
        expect(
          failedState.actionIssue,
          PlacementTestActionIssue.networkUncertain,
        );
        await scope.container
            .read(placementTestControllerProvider.notifier)
            .refreshStatus();

        final recovered = scope.container
            .read(placementTestControllerProvider)
            .requireValue;
        expect(recovered.shouldRetryResultRecovery, isFalse);
        expect(recovered.hasAppliedCompletedResult, isTrue);
        expect(learning.latestCalls, 2);
        scope.dispose();
      },
    );

    testWidgets('latest-path startup failure exposes and completes retry', (
      tester,
    ) async {
      final readyStatus = PlacementTestStatus(
        hasCompletedPlacementTest: true,
        latestCompletedAttemptId: 81,
        latestSubmittedAt: DateTime.utc(2026, 10, 27, 2, 25),
        recommendedTargetJlptLevelId: 3,
        recommendedTargetJlptLevelName: 'N3',
        targetJlptLevelId: 3,
        targetJlptLevelName: 'N3',
        dailyStudyMinutes: 45,
        isReadyForLearningPath: true,
      );
      final scope = _container(
        placement: _PlacementRepository(status: readyStatus),
        learning: _LearningPathRepository(
          latestOutcomes: <Object?>[const NetworkError(), _latestPath],
        ),
      );
      addTearDown(scope.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope.container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PlacementTestScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('placement_test_intro_view')),
        findsOneWidget,
      );
      expect(find.text('Thử khôi phục kết quả'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('placement_test_start_button')),
      );
      await tester.pumpAndSettle();

      expect(
        scope.container
            .read(placementTestControllerProvider)
            .requireValue
            .shouldRetryResultRecovery,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey<String>('placement_test_intro_view')),
        findsOneWidget,
      );
    });

    test(
      'missing exam date preserves Placement result and does not generate AI path',
      () async {
        final profile = _ProfileRepository();
        final learning = _LearningPathRepository();
        final scope = _container(
          placement: _PlacementRepository(
            status: const PlacementTestStatus(
              hasCompletedPlacementTest: true,
              latestCompletedAttemptId: 81,
              recommendedTargetJlptLevelId: 3,
              recommendedTargetJlptLevelName: 'N3',
              dailyStudyMinutes: 45,
            ),
            result: _completedResult,
          ),
          profile: profile,
          learning: learning,
        );
        await scope.container.read(placementTestControllerProvider.future);

        final applied = await scope.container
            .read(placementTestControllerProvider.notifier)
            .applyRecommendation();
        final state = scope.container
            .read(placementTestControllerProvider)
            .requireValue;

        expect(applied, isFalse);
        expect(state.result?.attemptId, 81);
        expect(state.actionIssue, PlacementTestActionIssue.examDateRequired);
        expect(profile.goalCalls, 0);
        expect(learning.generateCalls, 0);
        scope.dispose();
      },
    );

    test(
      'saved exam date resumes the retained Placement recommendation',
      () async {
        final initialStatus = PlacementTestStatus(
          hasCompletedPlacementTest: true,
          latestCompletedAttemptId: 81,
          recommendedTargetJlptLevelId: 3,
          recommendedTargetJlptLevelName: 'N3',
          dailyStudyMinutes: 45,
        );
        final placement = _PlacementRepository(
          status: initialStatus,
          result: _completedResult,
        );
        final learning = _LearningPathRepository(
          latestOutcomes: <Object?>[_latestPath],
        );
        final scope = _container(
          placement: placement,
          profile: _ProfileRepository(targetExamDate: DateTime.utc(2027, 7, 4)),
          learning: learning,
        );
        await scope.container.read(placementTestControllerProvider.future);
        final controller = scope.container.read(
          placementTestControllerProvider.notifier,
        );

        expect(await controller.applyRecommendation(), isFalse);
        placement.status = initialStatus.copyWith(
          targetExamDate: DateTime.utc(2027, 7, 4),
        );
        expect(await controller.applyRecommendation(), isTrue);
        expect(learning.generateCalls, 1);
        expect(
          scope.container
              .read(placementTestControllerProvider)
              .requireValue
              .result,
          same(_completedResult),
        );
        scope.dispose();
      },
    );

    test(
      'exam date alone does not claim an AI path was already applied',
      () async {
        final status = _completedStatus.copyWith(
          targetJlptLevelId: 3,
          targetJlptLevelName: 'N3',
          isReadyForLearningPath: true,
        );
        final placement = _PlacementRepository(
          status: status,
          result: _completedResult,
        );
        final learning = _LearningPathRepository(
          latestOutcomes: <Object?>[null],
        );
        final scope = _container(placement: placement, learning: learning);

        final restored = await scope.container.read(
          placementTestControllerProvider.future,
        );

        expect(restored.result, same(_completedResult));
        expect(restored.hasAppliedCompletedResult, isFalse);
        scope.dispose();
      },
    );

    test(
      'recommended target preserves the server current study level',
      () async {
        final lessons = _RecordingLearningRepository();
        final scope = _container(
          placement: _PlacementRepository(
            status: _completedStatus,
            result: _completedResult,
          ),
          learning: _LearningPathRepository(
            latestOutcomes: <Object?>[_latestPath],
          ),
          lessons: lessons,
        );
        await scope.container.read(learningControllerProvider.future);
        await scope.container.read(placementTestControllerProvider.future);

        final applied = await scope.container
            .read(placementTestControllerProvider.notifier)
            .applyRecommendation();
        final journey = await scope.container.read(
          learnerJourneyControllerProvider.future,
        );
        final learning = await scope.container.read(
          learningControllerProvider.future,
        );

        expect(applied, isTrue);
        expect(journey.selectedLevelId, 101);
        expect(journey.selectedLevel, JlptLevel.n5);
        expect(journey.dailyStudyMinutes, 45);
        expect(lessons.loadedLevelIds.last, 101);
        expect(learning.jlptTarget, JlptLevel.n5);
        scope.dispose();
      },
    );

    test(
      'applies goal, generates, refreshes, then clears matching draft',
      () async {
        final preferences = TestJsonPreferenceStore();
        final store = PlacementTestDraftStore(preferences);
        await store.save(_draft());
        final profile = _ProfileRepository();
        final learning = _LearningPathRepository(
          latestOutcomes: <Object?>[_latestPath],
        );
        final scope = _container(
          placement: _PlacementRepository(
            status: _completedStatus,
            result: _completedResult,
          ),
          preferences: preferences,
          profile: profile,
          learning: learning,
        );
        await scope.container.read(placementTestControllerProvider.future);

        final applied = await scope.container
            .read(placementTestControllerProvider.notifier)
            .applyRecommendation();

        expect(applied, isTrue);
        expect(profile.goalCalls, 1);
        expect(profile.lastTargetLevelId, 3);
        expect(learning.generateCalls, 1);
        expect(learning.latestCalls, 1);
        expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
        expect(
          scope.container
              .read(placementTestControllerProvider)
              .value
              ?.recommendationApplied,
          isTrue,
        );
        scope.dispose();
      },
    );

    test(
      'keeps draft on partial failure and retries without regenerating',
      () async {
        final preferences = TestJsonPreferenceStore();
        final store = PlacementTestDraftStore(preferences);
        await store.save(_draft());
        final profile = _ProfileRepository();
        final learning = _LearningPathRepository(
          latestOutcomes: <Object?>[const NetworkError(), _latestPath],
        );
        final scope = _container(
          placement: _PlacementRepository(
            status: _completedStatus,
            result: _completedResult,
          ),
          preferences: preferences,
          profile: profile,
          learning: learning,
        );
        await scope.container.read(placementTestControllerProvider.future);
        final controller = scope.container.read(
          placementTestControllerProvider.notifier,
        );

        expect(await controller.applyRecommendation(), isFalse);
        expect(preferences.values, contains('placement_draft_v1:42:81'));
        expect(await controller.applyRecommendation(), isTrue);

        expect(profile.goalCalls, 1);
        expect(learning.generateCalls, 1);
        expect(learning.latestCalls, 2);
        expect(preferences.values, isNot(contains('placement_draft_v1:42:81')));
        scope.dispose();
      },
    );
  });

  testWidgets('renders image failure and explicit accessible audio fallback', (
    tester,
  ) async {
    final attempt = _activeAttempt(
      imageUrl: 'https://invalid.example.test/question.png',
      audioUrl: 'https://invalid.example.test/question.mp3',
    );
    final scope = _container(
      placement: _PlacementRepository(
        status: _activeStatus,
        activeAttempt: attempt,
      ),
    );
    addTearDown(scope.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope.container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlacementTestScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('placement_audio_unavailable')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Âm thanh câu hỏi hiện không được hỗ trợ hoặc không khả dụng',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('placement_question_image_unavailable_501'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders Placement Test chrome in the selected locale', (
    tester,
  ) async {
    final scope = _container(
      placement: _PlacementRepository(
        status: const PlacementTestStatus(hasCompletedPlacementTest: false),
      ),
    );
    addTearDown(scope.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope.container,
        child: MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: const PlacementTestScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JLPTレベル診断'), findsOneWidget);
    expect(find.text('入門レベルチェック'), findsOneWidget);
    expect(find.text('Kiểm tra trình độ đầu vào'), findsNothing);
  });
}

const _activeSnapshotJson = <String, Object?>{
  'attemptId': 81,
  'attemptType': 'placement',
  'status': 'inProgress',
  'isResumed': true,
  'startedAt': '2026-10-27T02:15:00Z',
  'expiresAt': '2026-10-27T02:30:00Z',
  'serverNow': '2026-10-27T02:20:00Z',
  'timeLimitMinutes': 15,
  'totalQuestions': 1,
  'questions': <Object?>[
    <String, Object?>{
      'questionId': 501,
      'mockTestId': 5,
      'mockTestSectionId': 50,
      'sectionTitle': 'N5',
      'sectionOrder': 1,
      'jlptLevelId': 1,
      'jlptLevelName': 'N5',
      'order': 1,
      'content': 'Question',
      'audioUrl': null,
      'imageUrl': null,
      'options': <Object?>[
        <String, Object?>{'optionId': 5011, 'content': 'A', 'order': 1},
        <String, Object?>{'optionId': 5012, 'content': 'B', 'order': 2},
      ],
    },
  ],
};

final _activeStatus = PlacementTestStatus(
  hasActiveAttempt: true,
  activeAttemptId: 81,
  activeAttemptExpiresAt: DateTime.utc(2026, 10, 27, 2, 30),
  hasCompletedPlacementTest: false,
);

final _completedStatus = PlacementTestStatus(
  hasCompletedPlacementTest: true,
  latestCompletedAttemptId: 81,
  latestSubmittedAt: DateTime.utc(2026, 10, 27, 2, 25),
  latestScorePercent: 75,
  assessedJlptLevelId: 2,
  assessedJlptLevelName: 'N4',
  recommendedTargetJlptLevelId: 3,
  recommendedTargetJlptLevelName: 'N3',
  dailyStudyMinutes: 45,
  targetExamDate: DateTime.utc(2027, 7, 4),
);

PlacementTestAttempt _activeAttempt({
  DateTime? serverNow,
  DateTime? expiresAt,
  String? imageUrl,
  String? audioUrl,
}) {
  return PlacementTestAttempt(
    id: 81,
    isResumed: true,
    startedAt: DateTime.utc(2026, 10, 27, 2, 15),
    serverNow: serverNow ?? DateTime.utc(2026, 10, 27, 2, 20),
    expiresAt: expiresAt ?? DateTime.utc(2026, 10, 27, 2, 30),
    timeLimitMinutes: 15,
    totalQuestions: 2,
    questions: <PlacementTestQuestion>[
      PlacementTestQuestion(
        id: 501,
        mockTestId: 5,
        mockTestSectionId: 50,
        sectionTitle: 'N5',
        sectionOrder: 1,
        jlptLevelId: 1,
        jlptLevelName: 'N5',
        order: 1,
        content: 'Question 1',
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        options: const <PlacementTestOption>[
          PlacementTestOption(id: 5011, content: 'A', order: 1),
          PlacementTestOption(id: 5012, content: 'B', order: 2),
        ],
      ),
      const PlacementTestQuestion(
        id: 401,
        mockTestId: 4,
        mockTestSectionId: 40,
        sectionTitle: 'N4',
        sectionOrder: 1,
        jlptLevelId: 2,
        jlptLevelName: 'N4',
        order: 2,
        content: 'Question 2',
        options: <PlacementTestOption>[
          PlacementTestOption(id: 4011, content: 'A', order: 1),
          PlacementTestOption(id: 4012, content: 'B', order: 2),
        ],
      ),
    ],
  );
}

final _completedResult = PlacementTestResult(
  attemptId: 81,
  status: MockTestAttemptStatus.completed,
  startedAt: DateTime.utc(2026, 10, 27, 2, 15),
  submittedAt: DateTime.utc(2026, 10, 27, 2, 25),
  totalScore: 75,
  correctCount: 3,
  totalQuestions: 4,
  assessedJlptLevelId: 2,
  assessedJlptLevelName: 'N4',
  recommendedTargetJlptLevelId: 3,
  recommendedTargetJlptLevelName: 'N3',
  wrongQuestionIds: const <int>[401],
  levelBreakdowns: const <PlacementLevelBreakdown>[],
  sections: const <PlacementSectionResult>[],
);

final _latestPath = RecommendedLearningPath(
  userId: 42,
  generatedAt: DateTime.utc(2026, 10, 27, 2, 26),
  summary: 'Path',
  strengths: const <String>[],
  weaknesses: const <String>[],
  feasibility: 'Ready',
  isExamDateRealistic: true,
  recommendedStudyDays: 10,
  focusTopics: const <String>[],
  dailySchedules: const <RecommendedLearningDay>[],
);

PlacementTestDraft _draft() => PlacementTestDraft(
  schemaVersion: 1,
  userId: 42,
  attemptId: 81,
  currentQuestionIndex: 0,
  selectedOptionIdsByQuestionId: const <int, int>{501: 5011},
  updatedAt: DateTime.utc(2026, 10, 27),
);

class _TestScope {
  const _TestScope(this.container, this.session);

  final ProviderContainer container;
  final AuthSessionController session;

  void dispose() {
    container.dispose();
    session.dispose();
  }
}

_TestScope _container({
  required _PlacementRepository placement,
  TestJsonPreferenceStore? preferences,
  int userId = 42,
  Duration Function()? elapsed,
  _ProfileRepository? profile,
  _LearningPathRepository? learning,
  LearningRepository? lessons,
}) {
  final session = createTestAuthSession(userId: userId);
  final container = ProviderContainer(
    overrides: [
      authSessionControllerProvider.overrideWithValue(session),
      jlptCatalogRepositoryProvider.overrideWithValue(
        TestJlptCatalogRepository(),
      ),
      jsonPreferenceStoreProvider.overrideWithValue(
        preferences ?? TestJsonPreferenceStore(),
      ),
      placementTestRepositoryProvider.overrideWithValue(placement),
      placementTestElapsedProvider.overrideWithValue(
        elapsed ?? () => Duration.zero,
      ),
      userProfileRepositoryProvider.overrideWithValue(
        profile ?? _ProfileRepository(),
      ),
      learningPathRepositoryProvider.overrideWithValue(
        learning ?? _LearningPathRepository(),
      ),
      if (lessons != null)
        learningRepositoryProvider.overrideWithValue(lessons),
    ],
  );
  return _TestScope(container, session);
}

class _PlacementRepository implements PlacementTestRepository {
  _PlacementRepository({
    required this.status,
    this.activeAttempt,
    this.activeAttemptFailure,
    this.result,
    List<Object>? startOutcomes,
    List<Object>? submitOutcomes,
  }) : startOutcomes = <Object>[...?startOutcomes],
       submitOutcomes = <Object>[...?submitOutcomes];

  PlacementTestStatus status;
  final PlacementTestAttempt? activeAttempt;
  final Object? activeAttemptFailure;
  final PlacementTestResult? result;
  final List<Object> startOutcomes;
  final List<Object> submitOutcomes;
  int submitCalls = 0;
  int resultCalls = 0;
  int? lastResultAttemptId;

  @override
  Future<PlacementTestStatus> loadStatus() async => status;

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async {
    if (activeAttemptFailure != null) throw activeAttemptFailure!;
    return activeAttempt;
  }

  @override
  Future<PlacementTestResult> loadResult(int attemptId) async {
    resultCalls++;
    lastResultAttemptId = attemptId;
    return result ?? (throw StateError('No result configured.'));
  }

  @override
  Future<PlacementTestAttempt> start() async {
    if (startOutcomes.isNotEmpty) {
      final outcome = startOutcomes.removeAt(0);
      if (outcome is Exception) throw outcome;
      return outcome as PlacementTestAttempt;
    }
    return activeAttempt ?? (throw StateError('No attempt configured.'));
  }

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) async {
    submitCalls++;
    if (submitOutcomes.isNotEmpty) {
      final outcome = submitOutcomes.removeAt(0);
      if (outcome is Exception) throw outcome;
      return outcome as PlacementTestResult;
    }
    return result ?? (throw StateError('No result configured.'));
  }
}

class _ProfileRepository implements UserProfileRepository {
  _ProfileRepository({this.targetId, this.targetExamDate});

  final int? targetId;
  final DateTime? targetExamDate;

  int loadCalls = 0;
  int goalCalls = 0;
  int? lastTargetLevelId;

  UserProfile _profile({int? targetId, int dailyMinutes = 45}) => UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetId,
    targetJlptLevelName: switch (targetId) {
      null => null,
      204 => 'N4',
      _ => 'N3',
    },
    currentStudyLevelId: 101,
    currentStudyLevelName: 'N5',
    dailyStudyMinutes: dailyMinutes,
    targetExamDate: targetExamDate,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> loadProfile() async {
    loadCalls++;
    return _profile(targetId: targetId);
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    goalCalls++;
    lastTargetLevelId = targetJlptLevelId;
    return _profile(
      targetId: targetJlptLevelId,
      dailyMinutes: dailyStudyMinutes,
    );
  }

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) =>
      throw UnimplementedError();
}

class _RecordingLearningRepository implements LearningRepository {
  final List<int> loadedLevelIds = <int>[];

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) async {
    loadedLevelIds.add(certificateLevelId);
    return LearningSnapshot(
      initials: 'L',
      jlptTarget: switch (certificateLevelId) {
        101 => JlptLevel.n5,
        204 => JlptLevel.n4,
        _ => JlptLevel.n3,
      },
      streakDays: 0,
      hasUnreadNotifications: false,
      examDateLabel: '',
      overallProgress: 0,
      completedLessons: 0,
      totalLessons: 0,
      completedChapters: 0,
      totalChapters: 0,
      metrics: const <LearningMetric>[],
      currentLesson: const CurrentLessonSummary(
        routeId: 'lesson',
        chapterNumber: 1,
        lessonNumber: 1,
        title: 'Lesson',
        category: 'Grammar',
        pattern: 'Pattern',
        durationMinutes: 10,
        progress: 0,
      ),
      sections: const <LearningSectionSummary>[],
      chapters: const <RoadmapChapter>[],
      skillProgress: const <LearningSkillProgress>[],
      certificateLevelId: certificateLevelId,
    );
  }
}

class _LearningPathRepository implements LearningPathRepository {
  _LearningPathRepository({
    List<Object>? generateOutcomes,
    List<Object?>? latestOutcomes,
  }) : generateOutcomes = <Object>[...?generateOutcomes],
       latestOutcomes = <Object?>[...?latestOutcomes];

  final List<Object> generateOutcomes;
  final List<Object?> latestOutcomes;
  int generateCalls = 0;
  int latestCalls = 0;

  @override
  Future<RecommendedLearningPath> generate() async {
    generateCalls++;
    if (generateOutcomes.isEmpty) return _latestPath;
    final outcome = generateOutcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    return outcome as RecommendedLearningPath;
  }

  @override
  Future<RecommendedLearningPath?> loadLatest() async {
    latestCalls++;
    if (latestOutcomes.isEmpty) return null;
    final outcome = latestOutcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    return outcome as RecommendedLearningPath?;
  }
}
