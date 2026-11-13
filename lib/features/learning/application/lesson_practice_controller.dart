import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/data/api_lesson_practice_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_practice.dart';

final lessonPracticeRepositoryProvider = Provider<LessonPracticeRepository>(
  (ref) => ApiLessonPracticeRepository(ref.watch(apiClientProvider)),
);

final lessonPracticeExercisesProvider = FutureProvider.autoDispose
    .family<List<LessonPracticeExercise>, int>((ref, lessonId) {
      return ref
          .watch(lessonPracticeRepositoryProvider)
          .loadForLesson(lessonId);
    });
