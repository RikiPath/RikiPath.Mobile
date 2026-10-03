import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/data/persistent_learner_journey_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/persistent_demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

import '../../support/test_json_preference_store.dart';

void main() {
  const n4Lesson19 = FixtureLessonRepository.lesson19RouteId;
  const n4Lesson20 = FixtureLessonRepository.lesson20RouteId;
  final completedAt = DateTime.utc(2026, 10, 2, 8);

  LessonProgress completed({DateTime? at}) => LessonProgress(
    progressPercent: 100,
    resumePositionSeconds: 1680,
    isCompleted: true,
    completedAt: at ?? completedAt,
  );

  test('1. Selected N5 persists and restores', () async {
    final store = TestJsonPreferenceStore();
    final first = _container(store);
    await first.read(learnerJourneyControllerProvider.future);
    await first
        .read(learnerJourneyControllerProvider.notifier)
        .selectLevel(JlptLevel.n5);
    first.dispose();

    final restored = _container(store);
    addTearDown(restored.dispose);
    expect(
      (await restored.read(
        learnerJourneyControllerProvider.future,
      )).selectedLevel,
      JlptLevel.n5,
    );
  });

  test('2. Selected N4 and N3 do not reuse N5 progress', () async {
    final store = TestJsonPreferenceStore();
    final container = _container(store);
    addTearDown(container.dispose);
    final controller = container.read(
      learnerJourneyControllerProvider.notifier,
    );
    await container.read(learnerJourneyControllerProvider.future);
    await controller.selectLevel(JlptLevel.n5);
    final n5Lesson = FixtureLessonRepository.lesson19RouteIdFor(JlptLevel.n5);
    await controller.recordLessonProgress(n5Lesson, completed());

    for (final level in <JlptLevel>[JlptLevel.n4, JlptLevel.n3]) {
      await controller.selectLevel(level);
      final snapshot = await container.read(learningControllerProvider.future);
      expect(snapshot.jlptTarget, level);
      expect(
        snapshot.currentLesson.routeId,
        FixtureLessonRepository.lesson19RouteIdFor(level),
      );
      expect(
        (await container.read(
          learnerJourneyControllerProvider.future,
        )).isLessonCompleted(FixtureLessonRepository.lesson19RouteIdFor(level)),
        isFalse,
      );
    }
  });

  test('3. Lesson completion persists', () async {
    final store = TestJsonPreferenceStore();
    final repository = PersistentLearnerJourneyRepository(store);
    await repository.save(
      LearnerJourneyState(
        lessonProgress: <String, LessonProgress>{n4Lesson19: completed()},
      ),
    );

    final restored = await repository.load();
    expect(restored.isLessonCompleted(n4Lesson19), isTrue);
    expect(restored.progressFor(n4Lesson19)?.completedAt, completedAt);
  });

  test(
    '4. Completed lesson remains completed after controller reconstruction',
    () async {
      final store = TestJsonPreferenceStore();
      final first = _container(store);
      await first.read(learnerJourneyControllerProvider.future);
      await first
          .read(learnerJourneyControllerProvider.notifier)
          .recordLessonProgress(n4Lesson19, completed());
      first.dispose();

      final restored = _container(store);
      addTearDown(restored.dispose);
      final journey = await restored.read(
        learnerJourneyControllerProvider.future,
      );
      expect(journey.isLessonCompleted(n4Lesson19), isTrue);
      final lesson = await restored.read(
        lessonControllerProvider(n4Lesson19).future,
      );
      expect(lesson.stage, LessonStage.completed);
    },
  );

  test('5. Completing a lesson unlocks the correct next lesson', () async {
    final container = _container(TestJsonPreferenceStore());
    addTearDown(container.dispose);
    await container.read(lessonControllerProvider(n4Lesson19).future);
    await container
        .read(lessonControllerProvider(n4Lesson19).notifier)
        .completeLesson();
    await container.pump();

    final next = await container.read(
      lessonControllerProvider(n4Lesson20).future,
    );
    expect(next.lesson.availability, LessonAvailability.available);
    expect(FixtureLessonRepository.nextRouteIdFor(n4Lesson19), n4Lesson20);
  });

  test('6. Unlock state survives restore', () async {
    final store = TestJsonPreferenceStore();
    final first = _container(store);
    await first.read(learnerJourneyControllerProvider.future);
    await first
        .read(learnerJourneyControllerProvider.notifier)
        .recordLessonProgress(n4Lesson19, completed());
    first.dispose();

    final restored = _container(store);
    addTearDown(restored.dispose);
    final next = await restored.read(
      lessonControllerProvider(n4Lesson20).future,
    );
    expect(next.lesson.availability, LessonAvailability.available);
    expect(next.lesson.prerequisite, isNull);
  });

  test('7. Completing the same lesson twice is idempotent locally', () async {
    final store = TestJsonPreferenceStore();
    final container = _container(store);
    addTearDown(container.dispose);
    await container.read(learnerJourneyControllerProvider.future);
    final controller = container.read(
      learnerJourneyControllerProvider.notifier,
    );
    await controller.recordLessonProgress(n4Lesson19, completed());
    final writesAfterFirst = store.writeCount;
    await controller.recordLessonProgress(
      n4Lesson19,
      completed(at: completedAt.add(const Duration(hours: 1))),
    );

    final journey = await container.read(
      learnerJourneyControllerProvider.future,
    );
    expect(journey.lessonProgress, hasLength(1));
    expect(journey.progressFor(n4Lesson19)?.completedAt, completedAt);
    expect(store.writeCount, writesAfterFirst);
  });

  test('8. Next Lesson derives from roadmap ordering', () async {
    final ordered = FixtureLessonRepository.orderedRouteIdsFor(JlptLevel.n5);
    expect(ordered, hasLength(greaterThan(1)));
    expect(FixtureLessonRepository.nextRouteIdFor(ordered.first), ordered[1]);
    final lesson = await const FixtureLessonRepository().loadLesson(
      ordered.first,
    );
    expect(lesson.nextLesson?.routeId, ordered[1]);
  });

  test('9. Final lesson has correct completion behavior', () async {
    final container = _container(TestJsonPreferenceStore());
    addTearDown(container.dispose);
    await container.read(learnerJourneyControllerProvider.future);
    final journey = container.read(learnerJourneyControllerProvider.notifier);
    await journey.recordLessonProgress(n4Lesson19, completed());
    await journey.recordLessonProgress(
      n4Lesson20,
      completed(at: completedAt.add(const Duration(hours: 1))),
    );

    final finalLesson = await container.read(
      lessonControllerProvider(n4Lesson20).future,
    );
    final snapshot = await container.read(learningControllerProvider.future);
    expect(finalLesson.stage, LessonStage.completed);
    expect(finalLesson.lesson.nextLesson, isNull);
    expect(FixtureLessonRepository.nextRouteIdFor(n4Lesson20), isNull);
    expect(snapshot.currentLesson.routeId, n4Lesson20);
  });

  test('10. Fixture bookmark persists', () async {
    final store = TestJsonPreferenceStore();
    final first = PersistentDemoNotebookRepository(store);
    await first.saveEntry(_fixtureDraft);

    final restored = PersistentDemoNotebookRepository(store);
    final entries = await restored.loadEntries();
    expect(entries, hasLength(1));
    expect(entries.single.vocabularyRouteKey, _fixtureDraft.stableKey);
    expect(entries.single.remoteNoteEntryId, isNull);
  });

  test('11. Duplicate fixture bookmark is prevented', () async {
    final repository = PersistentDemoNotebookRepository(
      TestJsonPreferenceStore(),
    );
    final first = await repository.saveEntry(_fixtureDraft);
    final duplicate = await repository.saveEntry(_fixtureDraft);

    expect(await repository.loadEntries(), hasLength(1));
    expect(duplicate.routeKey, first.routeKey);
  });

  test('12. Fixture bookmark restore never calls live Notebook API', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureDraft);
    final live = _RecordingNotebookRepository();
    final container = _container(store, notebookRepository: live);
    addTearDown(container.dispose);

    final restored = await container.read(
      demoNotebookControllerProvider.future,
    );
    expect(restored.entries, hasLength(1));
    expect(live.totalCalls, 0);
  });

  test('13. Live bookmark path remains unchanged', () async {
    final live = _RecordingNotebookRepository();
    final container = _container(
      TestJsonPreferenceStore(),
      notebookRepository: live,
    );
    addTearDown(container.dispose);
    final repository = container.read(notebookRepositoryProvider);

    await repository.bookmarkVocabulary(
      vocabulary: const NotebookVocabularyDraft(
        routeKey: 'live-vocabulary-41',
        remoteId: 41,
        term: '経験',
        reading: 'けいけん',
        meaning: 'Kinh nghiệm',
        jlptLevel: 'N4',
      ),
      collection: live.collection,
    );
    expect(live.bookmarkCalls, 1);
    expect(live.lastVocabularyRemoteId, 41);
  });

  test('14. Local bookmarks display if live Notebook loading fails', () async {
    final store = TestJsonPreferenceStore();
    await PersistentDemoNotebookRepository(store).saveEntry(_fixtureDraft);
    final live = _RecordingNotebookRepository(failLoads: true);
    final container = _container(store, notebookRepository: live);
    addTearDown(container.dispose);

    final notebook = await container.read(notebookControllerProvider.future);
    expect(notebook.collections.first.source, NotebookDataSource.fixture);
    expect(notebook.entries.single.term, _fixtureDraft.term);
    expect(notebook.mutationError, isNotNull);
  });

  test('15. Fixture IDs never reach live mutation repository', () async {
    final live = _RecordingNotebookRepository();
    final container = _container(
      TestJsonPreferenceStore(),
      notebookRepository: live,
    );
    addTearDown(container.dispose);
    await container.read(lessonControllerProvider(n4Lesson19).future);

    await container
        .read(lessonControllerProvider(n4Lesson19).notifier)
        .toggleFixtureVocabulary(0);
    expect(live.bookmarkCalls, 0);
    expect(live.removeCalls, 0);
  });

  test('16. Guessed JLPT IDs are never posted', () async {
    final store = TestJsonPreferenceStore();
    final container = _container(store);
    addTearDown(container.dispose);
    await container.read(learnerJourneyControllerProvider.future);
    await container
        .read(learnerJourneyControllerProvider.notifier)
        .selectLevel(JlptLevel.n5);

    final encoded =
        store.values[PersistentLearnerJourneyRepository.storageKey]!;
    expect(encoded, contains('"selectedLevel":"n5"'));
    expect(encoded, isNot(contains('jlptGoalId')));
    expect(encoded, isNot(contains('remoteId')));
  });

  test(
    '17. Learning state remains correct after navigation away and back',
    () async {
      final store = TestJsonPreferenceStore();
      final container = _container(store);
      addTearDown(container.dispose);
      await container.read(learnerJourneyControllerProvider.future);
      final journey = container.read(learnerJourneyControllerProvider.notifier);
      await journey.selectLevel(JlptLevel.n3);
      final first = FixtureLessonRepository.lesson19RouteIdFor(JlptLevel.n3);
      await journey.recordLessonProgress(first, completed());
      final before = await container.read(learningControllerProvider.future);

      container.invalidate(learningControllerProvider);
      container.invalidate(lessonControllerProvider(first));
      final after = await container.read(learningControllerProvider.future);
      expect(after.jlptTarget, before.jlptTarget);
      expect(after.currentLesson.routeId, before.currentLesson.routeId);
      expect(after.completedLessons, before.completedLessons);
    },
  );

  test('18. Restore failure falls back safely', () async {
    final store = TestJsonPreferenceStore(failReads: true);
    final live = _RecordingNotebookRepository();
    final container = _container(store, notebookRepository: live);
    addTearDown(container.dispose);

    final journey = await container.read(
      learnerJourneyControllerProvider.future,
    );
    final demo = await container.read(demoNotebookControllerProvider.future);
    final notebook = await container.read(notebookControllerProvider.future);
    expect(journey.selectedLevel, JlptLevel.n4);
    expect(journey.persistenceStatus, LocalPersistenceStatus.unavailable);
    expect(demo.entries, isEmpty);
    expect(demo.persistenceStatus, LocalPersistenceStatus.unavailable);
    expect(notebook.collections, hasLength(1));
    expect(notebook.collections.single.source, NotebookDataSource.remote);
  });
}

const _fixtureDraft = NotebookFixtureDraft(
  stableKey: 'fixture-n4-grammar-lesson-19:vocabulary:0:経験',
  contentType: NotebookContentType.vocabulary,
  term: '経験',
  reading: 'けいけん',
  meaning: 'Kinh nghiệm',
  jlptLevel: 'N4',
);

ProviderContainer _container(
  TestJsonPreferenceStore store, {
  NotebookRepository? notebookRepository,
}) {
  return ProviderContainer(
    overrides: [
      jsonPreferenceStoreProvider.overrideWithValue(store),
      if (notebookRepository != null)
        notebookRepositoryProvider.overrideWithValue(notebookRepository),
    ],
  );
}

class _RecordingNotebookRepository implements NotebookRepository {
  _RecordingNotebookRepository({this.failLoads = false});

  final bool failLoads;
  int loadCollectionCalls = 0;
  int loadEntryCalls = 0;
  int bookmarkCalls = 0;
  int removeCalls = 0;
  int? lastVocabularyRemoteId;

  NotebookCollection get collection => NotebookCollection(
    routeKey: 'remote-list-1',
    remoteId: 1,
    name: 'Live list',
    entryCount: 0,
    createdAt: DateTime.utc(2026, 10, 1),
    source: NotebookDataSource.remote,
  );

  int get totalCalls =>
      loadCollectionCalls + loadEntryCalls + bookmarkCalls + removeCalls;

  @override
  Future<List<NotebookCollection>> loadCollections() async {
    loadCollectionCalls++;
    if (failLoads) throw StateError('Live load failed.');
    return <NotebookCollection>[collection];
  }

  @override
  Future<List<NotebookEntry>> loadEntries(NotebookCollection collection) async {
    loadEntryCalls++;
    return const <NotebookEntry>[];
  }

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required NotebookVocabularyDraft vocabulary,
    required NotebookCollection collection,
  }) async {
    bookmarkCalls++;
    lastVocabularyRemoteId = vocabulary.remoteId;
    return NotebookBookmark(
      noteEntryId: 2,
      collectionRouteKey: collection.routeKey,
      collectionName: collection.name,
    );
  }

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) async => collection;

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isVocabularySaved(String vocabularyRouteKey) async => false;

  @override
  Future<void> removeEntry(NotebookEntry entry) async {
    removeCalls++;
  }

  @override
  Stream<Set<String>> watchSavedVocabularyKeys() =>
      Stream<Set<String>>.value(const <String>{});
}
