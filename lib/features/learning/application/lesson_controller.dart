import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/data/lesson_media_driver.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';

typedef LessonMediaDriverFactory = LessonMediaDriver Function();

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => const FixtureLessonRepository(),
);

final lessonMediaDriverFactoryProvider = Provider<LessonMediaDriverFactory>(
  (ref) => FixtureLessonMediaDriver.new,
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
    final lesson = await ref
        .watch(lessonRepositoryProvider)
        .loadLesson(lessonId);
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
  }

  Future<void> completeLesson() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final progress = await _repository.updatePlaybackPosition(
      routeId: lessonId,
      positionSeconds: current.lesson.durationSeconds,
      durationSeconds: current.lesson.durationSeconds,
    );
    state = AsyncData(
      current.copyWith(
        lesson: current.lesson.copyWith(progress: progress),
        stage: LessonStage.completed,
        videoStatus: LessonVideoStatus.completed,
        clearVideoError: true,
      ),
    );
  }
}
