import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/data/api_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/data/lesson_media_driver.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

typedef LessonMediaDriverFactory = LessonMediaDriver Function();

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => ApiLessonRepository(ref.watch(apiClientProvider)),
);

final lessonMediaDriverFactoryProvider = Provider<LessonMediaDriverFactory>(
  (ref) => VideoPlayerLessonMediaDriver.new,
);

final lessonMediaDriverProvider = Provider.autoDispose
    .family<LessonMediaDriver, String>((ref, lessonId) {
      final driver = ref.watch(lessonMediaDriverFactoryProvider)();
      ref.onDispose(driver.dispose);
      return driver;
    });

final lessonControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LessonController, LessonSession, String>(
      (lessonId) => LessonController(lessonId),
    );

class LessonController extends AsyncNotifier<LessonSession> {
  LessonController(this.lessonId);

  final String lessonId;

  LessonRepository get _repository => ref.read(lessonRepositoryProvider);
  LessonMediaDriver get _mediaDriver =>
      ref.read(lessonMediaDriverProvider(lessonId));

  @override
  Future<LessonSession> build() async {
    final loadedLesson = await ref
        .watch(lessonRepositoryProvider)
        .loadLesson(lessonId);
    final journey = await ref.watch(learnerJourneyControllerProvider.future);
    final storedProgress = loadedLesson.remoteLessonId == null
        ? journey.progressFor(lessonId)
        : null;
    var lesson = storedProgress == null
        ? loadedLesson
        : loadedLesson.copyWith(progress: storedProgress);
    final prerequisite = lesson.prerequisite;
    if (lesson.availability == LessonAvailability.locked &&
        prerequisite != null &&
        journey.isLessonCompleted(prerequisite.routeId)) {
      lesson = lesson.copyWith(
        availability: LessonAvailability.available,
        parts: [
          for (var index = 0; index < lesson.parts.length; index++)
            LessonPart(
              number: lesson.parts[index].number,
              title: lesson.parts[index].title,
              subtitle: lesson.parts[index].subtitle,
              durationMinutes: lesson.parts[index].durationMinutes,
              status: index == 0
                  ? LessonPartStatus.current
                  : LessonPartStatus.locked,
            ),
        ],
        clearLockedReason: true,
        clearPrerequisite: true,
      );
    }
    if (lesson.remoteLessonId == null) {
      final demoNotebook = await ref.watch(
        demoNotebookControllerProvider.future,
      );
      lesson = lesson.copyWith(
        vocabulary: [
          for (var index = 0; index < lesson.vocabulary.length; index++)
            lesson.vocabulary[index].copyWith(
              isSaved: demoNotebook.entries.any(
                (entry) =>
                    entry.vocabularyRouteKey ==
                    _vocabularyStableKey(index, lesson),
              ),
            ),
        ],
        relatedGrammar: [
          for (var index = 0; index < lesson.relatedGrammar.length; index++)
            lesson.relatedGrammar[index].copyWith(
              isSaved: demoNotebook.entries.any(
                (entry) =>
                    entry.key ==
                    NotebookEntryKey.fixture(
                      contentType: NotebookContentType.grammar,
                      stableKey: _grammarStableKey(index, lesson),
                    ),
              ),
            ),
        ],
      );
    } else {
      lesson = await _withLiveSavedState(lesson);
      lesson = _withNextLiveLesson(lesson);
    }
    return LessonSession(
      lesson: lesson,
      stage: lesson.progress.isCompleted
          ? LessonStage.completed
          : LessonStage.detail,
      videoStatus: lesson.progress.isCompleted
          ? LessonVideoStatus.completed
          : LessonVideoStatus.initial,
    );
  }

  Future<void> retry() async {
    state = const AsyncLoading<LessonSession>();
    state = await AsyncValue.guard(build);
  }

  Future<void> openVideo() async {
    final current = state.value;
    if (current == null ||
        current.lesson.availability == LessonAvailability.locked) {
      return;
    }

    if (current.lesson.mediaSource.type == LessonMediaSourceType.none) {
      showArticle();
      return;
    }

    state = AsyncData(
      current.copyWith(
        stage: LessonStage.video,
        videoStatus: LessonVideoStatus.loading,
        clearVideoError: true,
      ),
    );

    try {
      await _mediaDriver.initialize(
        source: current.lesson.mediaSource,
        resumePosition: Duration(
          seconds: current.lesson.progress.resumePositionSeconds,
        ),
      );
      final mediaDurationSeconds =
          _mediaDriver.videoController?.value.duration.inSeconds ?? 0;
      if (mediaDurationSeconds > 0) {
        state = AsyncData(
          state.requireValue.copyWith(
            lesson: state.requireValue.lesson.copyWith(
              durationSeconds: mediaDurationSeconds,
            ),
          ),
        );
      }
      final ready = state.requireValue.copyWith(
        videoStatus: LessonVideoStatus.ready,
      );
      state = AsyncData(ready);
      await _mediaDriver.play();
      state = AsyncData(
        state.requireValue.copyWith(videoStatus: LessonVideoStatus.playing),
      );
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          videoStatus: LessonVideoStatus.error,
          videoErrorMessage: ref.read(appLocalizationsProvider).videoLoadFailed,
        ),
      );
    }
  }

  Future<void> togglePlayback() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    if (current.videoStatus == LessonVideoStatus.initial ||
        current.videoStatus == LessonVideoStatus.error) {
      await openVideo();
      return;
    }

    try {
      if (current.videoStatus == LessonVideoStatus.playing) {
        await _mediaDriver.pause();
        state = AsyncData(
          current.copyWith(videoStatus: LessonVideoStatus.paused),
        );
      } else {
        await _mediaDriver.play();
        state = AsyncData(
          current.copyWith(videoStatus: LessonVideoStatus.playing),
        );
      }
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          videoStatus: LessonVideoStatus.error,
          videoErrorMessage: ref.read(appLocalizationsProvider).videoLoadFailed,
        ),
      );
    }
  }

  void showArticle() {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        stage: LessonStage.article,
        selectedTab: LessonContentTab.content,
      ),
    );
  }

  void showVideo() {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(stage: LessonStage.video));
  }

  void showDetail() {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(stage: LessonStage.detail));
  }

  void selectTab(LessonContentTab tab) {
    final current = state.value;
    if (current == null || tab == LessonContentTab.notes) {
      return;
    }
    state = AsyncData(current.copyWith(selectedTab: tab));
  }

  Future<void> toggleFixtureVocabulary(int index) async {
    final current = state.value;
    if (current == null ||
        current.lesson.remoteLessonId != null ||
        index < 0 ||
        index >= current.lesson.vocabulary.length) {
      return;
    }
    final item = current.lesson.vocabulary[index];
    final isSaved = await ref
        .read(demoNotebookControllerProvider.notifier)
        .toggleEntry(
          NotebookFixtureDraft(
            stableKey: _vocabularyStableKey(index, current.lesson),
            contentType: NotebookContentType.vocabulary,
            term: item.word,
            reading: item.reading,
            meaning: item.meaning,
            jlptLevel: current.lesson.level.label,
          ),
        );
    final vocabulary = [...current.lesson.vocabulary];
    vocabulary[index] = item.copyWith(isSaved: isSaved);
    state = AsyncData(
      current.copyWith(lesson: current.lesson.copyWith(vocabulary: vocabulary)),
    );
  }

  Future<void> toggleFixtureGrammar(int index) async {
    final current = state.value;
    if (current == null ||
        current.lesson.remoteLessonId != null ||
        index < 0 ||
        index >= current.lesson.relatedGrammar.length) {
      return;
    }
    final item = current.lesson.relatedGrammar[index];
    final isSaved = await ref
        .read(demoNotebookControllerProvider.notifier)
        .toggleEntry(
          NotebookFixtureDraft(
            stableKey: _grammarStableKey(index, current.lesson),
            contentType: NotebookContentType.grammar,
            term: item.title,
            meaning: item.description,
            jlptLevel: current.lesson.level.label,
          ),
        );
    final grammar = [...current.lesson.relatedGrammar];
    grammar[index] = item.copyWith(isSaved: isSaved);
    state = AsyncData(
      current.copyWith(
        lesson: current.lesson.copyWith(relatedGrammar: grammar),
      ),
    );
  }

  Future<bool> saveLiveVocabulary(
    int index,
    NotebookCollection collection,
  ) async {
    final current = state.value;
    if (current == null ||
        current.lesson.remoteLessonId == null ||
        index < 0 ||
        index >= current.lesson.vocabulary.length) {
      return false;
    }
    final item = current.lesson.vocabulary[index];
    final id = item.vocabularyId;
    final repository = ref.read(notebookRepositoryProvider);
    if (id == null || id <= 0) return false;
    try {
      await repository.bookmarkVocabulary(
        vocabulary: NotebookVocabularyDraft(
          routeKey: 'remote-$id',
          remoteId: id,
          term: item.word,
          reading: item.reading,
          meaning: item.meaning,
          jlptLevel: current.lesson.level.label,
          exampleSentence: item.exampleSentence,
        ),
        collection: collection,
      );
      final vocabulary = [...current.lesson.vocabulary];
      vocabulary[index] = item.copyWith(isSaved: true);
      state = AsyncData(
        current.copyWith(
          lesson: current.lesson.copyWith(vocabulary: vocabulary),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveLiveKanji(int index, NotebookCollection collection) async {
    final current = state.value;
    if (current == null ||
        current.lesson.remoteLessonId == null ||
        index < 0 ||
        index >= current.lesson.kanji.length) {
      return false;
    }
    final item = current.lesson.kanji[index];
    final repository = ref.read(notebookRepositoryProvider);
    if (repository is! LessonNotebookRepository) return false;
    try {
      await (repository as LessonNotebookRepository).bookmarkKanji(
        kanji: NotebookKanjiDraft(
          remoteId: item.kanjiId,
          character: item.character,
          meaning: item.meaning,
          reading: item.onYomi ?? item.kunYomi,
        ),
        collection: collection,
      );
      final kanji = [...current.lesson.kanji];
      kanji[index] = item.copyWith(isSaved: true);
      state = AsyncData(
        current.copyWith(lesson: current.lesson.copyWith(kanji: kanji)),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveLiveGrammar(int index) async {
    final current = state.value;
    if (current == null ||
        current.lesson.remoteLessonId == null ||
        index < 0 ||
        index >= current.lesson.relatedGrammar.length) {
      return false;
    }
    final item = current.lesson.relatedGrammar[index];
    final id = item.grammarPatternId;
    final repository = ref.read(notebookRepositoryProvider);
    if (id == null || id <= 0 || repository is! LessonNotebookRepository) {
      return false;
    }
    try {
      await (repository as LessonNotebookRepository).bookmarkGrammar(id);
      final grammar = [...current.lesson.relatedGrammar];
      grammar[index] = item.copyWith(isSaved: true);
      state = AsyncData(
        current.copyWith(
          lesson: current.lesson.copyWith(relatedGrammar: grammar),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> savePlaybackPosition(int positionSeconds) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final progress = await _repository.updatePlaybackPosition(
      routeId: lessonId,
      positionSeconds: positionSeconds,
      durationSeconds: current.lesson.durationSeconds,
    );
    state = AsyncData(
      current.copyWith(lesson: current.lesson.copyWith(progress: progress)),
    );
    await ref
        .read(learnerJourneyControllerProvider.notifier)
        .recordLessonProgress(lessonId, progress);
  }

  Future<void> completeLesson() async {
    final current = state.value;
    if (current == null || current.isCompleting) {
      return;
    }
    state = AsyncData(
      current.copyWith(isCompleting: true, clearCompletionError: true),
    );
    try {
      final progress = await _repository.completeLesson(routeId: lessonId);
      final completed = state.requireValue.copyWith(
        lesson: current.lesson.copyWith(progress: progress),
        stage: LessonStage.completed,
        videoStatus: LessonVideoStatus.completed,
        isCompleting: false,
        clearVideoError: true,
        clearCompletionError: true,
      );
      state = AsyncData(completed);
      if (current.lesson.remoteLessonId == null) {
        await ref
            .read(learnerJourneyControllerProvider.notifier)
            .recordLessonProgress(lessonId, progress);
      } else {
        ref.invalidate(learningControllerProvider);
      }
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isCompleting: false,
          completionErrorMessage: ref
              .read(appLocalizationsProvider)
              .checkConnectionRetry,
        ),
      );
    }
  }

  Lesson _withNextLiveLesson(Lesson lesson) {
    final currentId = lesson.remoteLessonId;
    if (currentId == null) return lesson;

    final snapshot = ref.read(learningControllerProvider).value;
    final recommended = ref
        .watch(learningPathControllerProvider)
        .value
        ?.recommendationAfter(currentId);

    final nextId = recommended?.lessonId;
    final nextTitle = recommended?.title;

    if (nextId == null || nextId <= 0 || nextId == currentId) return lesson;
    final summary = snapshot?.lessons
        .where((item) => item.lessonId == nextId)
        .firstOrNull;
    return lesson.copyWith(
      nextLesson: LessonLink(
        routeId: '$nextId',
        lessonNumber: summary?.sortOrder ?? 0,
        title: nextTitle?.trim().isNotEmpty == true
            ? nextTitle!.trim()
            : summary?.title ?? '',
        subtitle: summary?.languageSkillName ?? '',
        durationMinutes: 0,
        level: lesson.level,
      ),
    );
  }

  Future<Lesson> _withLiveSavedState(Lesson lesson) async {
    try {
      final repository = ref.read(notebookRepositoryProvider);
      final collections = await repository.loadCollections();
      final entries = <NotebookEntry>[];
      for (final collection in collections.where((item) => item.isLive)) {
        entries.addAll(await repository.loadEntries(collection));
      }
      final vocabularyIds = entries
          .map((entry) => entry.sourceVocabularyId)
          .whereType<int>()
          .toSet();
      final kanjiIds = entries
          .map((entry) => entry.sourceKanjiId)
          .whereType<int>()
          .toSet();
      return lesson.copyWith(
        vocabulary: [
          for (final item in lesson.vocabulary)
            item.copyWith(
              isSaved:
                  item.vocabularyId != null &&
                  vocabularyIds.contains(item.vocabularyId),
            ),
        ],
        kanji: [
          for (final item in lesson.kanji)
            item.copyWith(isSaved: kanjiIds.contains(item.kanjiId)),
        ],
      );
    } catch (_) {
      // Notebook availability must not block opening an otherwise valid lesson.
      return lesson;
    }
  }

  String _vocabularyStableKey(int index, Lesson lesson) =>
      '${lesson.routeId}:vocabulary:$index:${lesson.vocabulary[index].word}';

  String _grammarStableKey(int index, Lesson lesson) =>
      '${lesson.routeId}:grammar:$index:${lesson.relatedGrammar[index].title}';
}
