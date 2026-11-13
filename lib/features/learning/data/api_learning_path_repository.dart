import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/data/learning_api_paths.dart';
import 'package:rikipath_mobile/features/learning/data/learning_path_dtos.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';

class ApiLearningPathRepository
    implements
        LearningPathRepository,
        LearningPathVersionRepository,
        LearningPathDayRepository {
  const ApiLearningPathRepository(this._client);

  final ApiClient _client;

  @override
  Future<RecommendedLearningPath?> loadLatest() async {
    final response = await _client.get<Object?>(LearningApiPaths.latestPath);
    try {
      final dto = readOptionalRecommendedLearningPath(response.data);
      return dto == null ? null : _map(dto);
    } on FormatException {
      throw const UnknownError(
        message:
            'The latest learning-path response did not match the contract.',
      );
    }
  }

  @override
  Future<RecommendedLearningPath> generate() async {
    final response = await _client.post<Object?>(
      LearningApiPaths.generatePath,
      data: const <String, Object?>{},
    );
    try {
      final dto = readRecommendedLearningPath(response.data);
      return _map(dto);
    } on FormatException {
      throw const UnknownError(
        message: 'The learning-path response did not match the contract.',
      );
    }
  }

  @override
  Future<RecommendedLearningPath?> loadActive() async {
    final response = await _client.get<Object?>(LearningApiPaths.activePath);
    try {
      final dto = readOptionalRecommendedLearningPath(response.data);
      final candidate = dto == null ? null : _map(dto);
      if (candidate?.status == LearningPathStatus.active) return candidate;

      // /active và /latest hiện dùng cùng service. Repository Backend hiện lọc
      // ACTIVE; nếu response lệch hợp đồng, đối chiếu lịch sử từ chính Backend.
      final history = await loadHistory();
      for (final path in history) {
        if (path.status == LearningPathStatus.active) return path;
      }
      return null;
    } on FormatException {
      throw const UnknownError(
        message:
            'The active learning-path response did not match the contract.',
      );
    }
  }

  @override
  Future<List<RecommendedLearningPath>> loadHistory() async {
    final response = await _client.get<Object?>(LearningApiPaths.pathHistory);
    try {
      return readLearningPathHistory(
        response.data,
      ).map(_map).toList(growable: false);
    } on FormatException {
      throw const UnknownError(
        message: 'The learning-path history did not match the contract.',
      );
    }
  }

  @override
  Future<RecommendedLearningPath> preview({
    required int startingJlptLevelId,
    int? targetJlptLevelId,
  }) async {
    final request = <String, Object?>{
      'startingJlptLevelId': startingJlptLevelId,
    };
    if (targetJlptLevelId != null) {
      request['targetJlptLevelId'] = targetJlptLevelId;
    }
    final response = await _client.post<Object?>(
      LearningApiPaths.previewPath,
      data: request,
    );
    return _readVersioned(response.data, LearningPathStatus.draft);
  }

  @override
  Future<RecommendedLearningPath> confirmPreview(int pathId) async {
    final response = await _client.post<Object?>(
      LearningApiPaths.confirmPreview(pathId),
    );
    final path = _readVersioned(response.data);
    if (path.status != LearningPathStatus.active &&
        path.status != LearningPathStatus.superseded) {
      throw const UnknownError(
        message:
            'The confirmed learning-path status did not match the contract.',
      );
    }
    return path;
  }

  @override
  Future<RecommendedLearningPath> cancelPreview(int pathId) async {
    final response = await _client.delete<Object?>(
      LearningApiPaths.cancelPreview(pathId),
    );
    return _readVersioned(response.data, LearningPathStatus.cancelled);
  }

  @override
  Future<RecommendedLearningPath> startDay(int day) async {
    final response = await _client.post<Object?>(
      LearningApiPaths.startActiveDay(day),
    );
    return _readVersioned(response.data, LearningPathStatus.active);
  }

  @override
  Future<RecommendedLearningPath> completeDay(int day) async {
    final response = await _client.post<Object?>(
      LearningApiPaths.completeActiveDay(day),
    );
    return _readVersioned(response.data, LearningPathStatus.active);
  }

  RecommendedLearningPath _readVersioned(
    Object? body, [
    LearningPathStatus? expectedStatus,
  ]) {
    try {
      final path = _map(readRecommendedLearningPath(body));
      if (path.pathId == null ||
          path.status == null ||
          (expectedStatus != null && path.status != expectedStatus)) {
        throw const FormatException(
          'Learning-path version metadata is invalid.',
        );
      }
      return path;
    } on FormatException {
      throw const UnknownError(
        message:
            'The learning-path version response did not match the contract.',
      );
    }
  }

  RecommendedLearningPath _map(RecommendedLearningPathDto dto) {
    final dailySchedules =
        dto.dailySchedules
            .map(
              (day) => RecommendedLearningDay(
                day: day.day,
                title: day.title,
                focus: day.focus,
                canStart: day.canStart,
                isStarted: day.isStarted,
                isCompleted: day.isCompleted,
                startedAt: day.startedAt,
                completedAt: day.completedAt,
                lessons: List<RecommendedLesson>.unmodifiable([
                  for (var index = 0; index < day.lessonIds.length; index++)
                    RecommendedLesson(
                      lessonId: day.lessonIds[index],
                      title: day.lessons[index],
                    ),
                ]),
              ),
            )
            .toList()
          ..sort((left, right) => left.day.compareTo(right.day));
    return RecommendedLearningPath(
      userId: dto.userId,
      generatedAt: dto.generatedAt,
      summary: dto.summary,
      strengths: List<String>.unmodifiable(dto.strengths),
      weaknesses: List<String>.unmodifiable(dto.weaknesses),
      feasibility: dto.feasibility,
      isExamDateRealistic: dto.isExamDateRealistic,
      recommendedStudyDays: dto.recommendedStudyDays,
      suggestedExamDate: dto.suggestedExamDate,
      focusTopics: List<String>.unmodifiable(dto.focusTopics),
      dailySchedules: List<RecommendedLearningDay>.unmodifiable(dailySchedules),
      pathId: dto.pathId,
      version: dto.version,
      status: switch (dto.status?.toUpperCase()) {
        'DRAFT' => LearningPathStatus.draft,
        'ACTIVE' => LearningPathStatus.active,
        'SUPERSEDED' => LearningPathStatus.superseded,
        'CANCELLED' => LearningPathStatus.cancelled,
        _ => null,
      },
      startingJlptLevelId: dto.startingJlptLevelId,
      targetJlptLevelId: dto.targetJlptLevelId,
      baseActivePathId: dto.baseActivePathId,
      previewExpiresAt: dto.previewExpiresAt,
      confirmedAt: dto.confirmedAt,
      horizon: dto.horizon,
      planDurationDays: dto.planDurationDays,
      targetExamDate: dto.targetExamDate,
      daysUntilExam: dto.daysUntilExam,
      hasTargetExamDate: dto.hasTargetExamDate,
    );
  }
}
