import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/data/learning_api_paths.dart';
import 'package:rikipath_mobile/features/learning/data/learning_dtos.dart';
import 'package:rikipath_mobile/features/learning/data/learning_mapper.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_repository.dart';

class ApiLessonRepository implements LessonRepository {
  const ApiLessonRepository(this._client);

  final ApiClient _client;

  @override
  Future<Lesson> loadLesson(String routeId) async {
    final id = _lessonId(routeId);
    final response = await _client.get<Object?>(LearningApiPaths.lesson(id));
    return _readLesson(response.data, expectedId: id);
  }

  @override
  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final id = _lessonId(routeId);
    final response = await _client.patch<Object?>(
      LearningApiPaths.playback(id),
      data: <String, Object?>{
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
      },
    );
    return _readProgress(response.data, expectedId: id);
  }

  @override
  Future<LessonProgress> completeLesson({required String routeId}) async {
    final id = _lessonId(routeId);
    final response = await _client.post<Object?>(LearningApiPaths.complete(id));
    return _readProgress(response.data, expectedId: id);
  }

  Lesson _readLesson(Object? body, {required int expectedId}) {
    try {
      final lesson = LearningMapper.lesson(readLessonDetail(body));
      if (lesson.remoteLessonId != expectedId) {
        throw const FormatException('Mismatched lesson ID.');
      }
      return lesson;
    } on FormatException {
      throw const UnknownError(
        message: 'The lesson detail response did not match the contract.',
      );
    }
  }

  LessonProgress _readProgress(Object? body, {required int expectedId}) {
    try {
      final dto = readLessonDetail(body);
      if (dto.lessonId != expectedId) {
        throw const FormatException('Mismatched lesson ID.');
      }
      return LearningMapper.progress(dto);
    } on FormatException {
      throw const UnknownError(
        message: 'The lesson progress response did not match the contract.',
      );
    }
  }

  int _lessonId(String routeId) {
    final id = int.tryParse(routeId);
    if (id == null || id <= 0 || '$id' != routeId) {
      throw ArgumentError.value(
        routeId,
        'routeId',
        'Expected a backend lesson ID.',
      );
    }
    return id;
  }
}
