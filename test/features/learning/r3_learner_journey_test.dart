import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

import '../../support/test_json_preference_store.dart';

void main() {
  test(
    'fixture completion updates roadmap progress and unlocks next lesson',
    () async {
      final container = _container();
      addTearDown(container.dispose);

      final before = await container.read(learningControllerProvider.future);
      final lessonId = FixtureLessonRepository.lesson19RouteIdFor(JlptLevel.n4);
      await container.read(lessonControllerProvider(lessonId).future);

      await container
          .read(lessonControllerProvider(lessonId).notifier)
          .completeLesson();
      await container.pump();

      final after = await container.read(learningControllerProvider.future);
      expect(after.completedLessons, before.completedLessons + 1);
      expect(
        after.currentLesson.routeId,
        FixtureLessonRepository.lesson20RouteIdFor(JlptLevel.n4),
      );
      expect(
        (await container.read(
          learnerJourneyControllerProvider.future,
        )).isLessonCompleted(lessonId),
        isTrue,
      );

      final next = await container.read(
        lessonControllerProvider(after.currentLesson.routeId).future,
      );
      expect(next.lesson.availability.name, 'available');
    },
  );

  test(
    'fixture bookmark remains local and never touches live Notebook',
    () async {
      final liveNotebook = _RecordingNotebookRepository();
      final container = _container(notebookRepository: liveNotebook);
      addTearDown(container.dispose);

      final lessonId = FixtureLessonRepository.lesson19RouteId;
      await container.read(lessonControllerProvider(lessonId).future);
      await container
          .read(lessonControllerProvider(lessonId).notifier)
          .toggleFixtureVocabulary(0);

      final saved = await container.read(demoNotebookControllerProvider.future);
      expect(saved.entries, hasLength(1));
      expect(saved.entries.single.remoteNoteEntryId, isNull);
      expect(saved.entries.single.source, NotebookDataSource.fixture);
      expect(liveNotebook.calls, 0);
    },
  );

  test(
    'level and lesson state survive feature route/controller changes',
    () async {
      final container = _container();
      addTearDown(container.dispose);

      await container
          .read(learnerJourneyControllerProvider.notifier)
          .selectLevel(JlptLevel.n5);
      final lessonId = FixtureLessonRepository.lesson19RouteIdFor(JlptLevel.n5);
      await container.read(lessonControllerProvider(lessonId).future);
      await container
          .read(lessonControllerProvider(lessonId).notifier)
          .completeLesson();
      container.invalidate(learningControllerProvider);

      final restored = await container.read(learningControllerProvider.future);
      expect(restored.jlptTarget, JlptLevel.n5);
      expect(
        (await container.read(
          learnerJourneyControllerProvider.future,
        )).isLessonCompleted(lessonId),
        isTrue,
      );
    },
  );
}

ProviderContainer _container({NotebookRepository? notebookRepository}) {
  return ProviderContainer(
    overrides: [
      jsonPreferenceStoreProvider.overrideWithValue(TestJsonPreferenceStore()),
      if (notebookRepository != null)
        notebookRepositoryProvider.overrideWithValue(notebookRepository),
    ],
  );
}

class _RecordingNotebookRepository implements NotebookRepository {
  int calls = 0;

  Never _unexpected() {
    calls++;
    throw StateError('Fixture bookmark crossed into the live repository.');
  }

  @override
  Future<NotebookEntry> addManualEntry({
    required NotebookCollection collection,
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) async => _unexpected();

  @override
  Future<NotebookBookmark> bookmarkVocabulary({
    required NotebookVocabularyDraft vocabulary,
    required NotebookCollection collection,
  }) async => _unexpected();

  @override
  Future<NotebookCollection> createCollection({
    required String name,
    String? description,
  }) async => _unexpected();

  @override
  Future<bool> isVocabularySaved(String vocabularyRouteKey) async =>
      _unexpected();

  @override
  Future<List<NotebookCollection>> loadCollections() async => _unexpected();

  @override
  Future<List<NotebookEntry>> loadEntries(
    NotebookCollection collection,
  ) async => _unexpected();

  @override
  Future<void> removeEntry(NotebookEntry entry) async => _unexpected();

  @override
  Stream<Set<String>> watchSavedVocabularyKeys() => _unexpected();
}
