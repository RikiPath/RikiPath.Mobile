import 'dart:convert';

import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

class PersistentLearnerJourneyRepository implements LearnerJourneyRepository {
  PersistentLearnerJourneyRepository(this._store);

  static const storageKey = 'r3_learner_journey_v1';

  final JsonPreferenceStore _store;

  @override
  Future<LearnerJourneyState> load() async {
    final encoded = await _store.read(storageKey);
    if (encoded == null) return const LearnerJourneyState();

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Learner journey must be a JSON object.');
    }
    final levelName = decoded['selectedLevel'];
    final selectedLevelIdValue = decoded['selectedLevelId'];
    final selectedLevel = JlptLevel.values
        .where((level) => level.name == levelName)
        .firstOrNull;
    final encodedHasSelectedLevel = decoded['hasSelectedLevel'];
    final hasSelectedLevel = encodedHasSelectedLevel is bool
        ? encodedHasSelectedLevel
        : selectedLevel != null;
    final dailyStudyMinutes = decoded['dailyStudyMinutes'];
    final encodedProgress = decoded['lessonProgress'];
    if (selectedLevel == null ||
        (selectedLevelIdValue != null &&
            (selectedLevelIdValue is! int || selectedLevelIdValue <= 0)) ||
        dailyStudyMinutes is! int ||
        dailyStudyMinutes <= 0 ||
        encodedProgress is! Map<String, dynamic>) {
      throw const FormatException('Learner journey fields are invalid.');
    }

    final progress = <String, LessonProgress>{};
    for (final item in encodedProgress.entries) {
      if (item.value is! Map<String, dynamic>) {
        throw const FormatException('Lesson progress entry is invalid.');
      }
      progress[item.key] = _decodeProgress(item.value as Map<String, dynamic>);
    }
    return LearnerJourneyState(
      selectedLevel: selectedLevel,
      selectedLevelId: selectedLevelIdValue as int?,
      hasSelectedLevel: hasSelectedLevel,
      dailyStudyMinutes: dailyStudyMinutes,
      lessonProgress: progress,
    );
  }

  @override
  Future<void> save(LearnerJourneyState state) {
    final encoded = jsonEncode(<String, Object?>{
      'selectedLevel': state.selectedLevel.name,
      'selectedLevelId': state.selectedLevelId,
      'hasSelectedLevel': state.hasSelectedLevel,
      'dailyStudyMinutes': state.dailyStudyMinutes,
      'lessonProgress': <String, Object>{
        for (final item in state.lessonProgress.entries)
          item.key: <String, Object?>{
            'progressPercent': item.value.progressPercent,
            'resumePositionSeconds': item.value.resumePositionSeconds,
            'isCompleted': item.value.isCompleted,
            'completedAt': item.value.completedAt?.toUtc().toIso8601String(),
          },
      },
    });
    return _store.write(storageKey, encoded);
  }

  @override
  Future<void> reset() => _store.remove(storageKey);

  LessonProgress _decodeProgress(Map<String, dynamic> json) {
    final progressPercent = json['progressPercent'];
    final resumePositionSeconds = json['resumePositionSeconds'];
    final isCompleted = json['isCompleted'];
    final completedAtValue = json['completedAt'];
    if (progressPercent is! int ||
        resumePositionSeconds is! int ||
        isCompleted is! bool ||
        progressPercent < 0 ||
        progressPercent > 100 ||
        resumePositionSeconds < 0 ||
        (completedAtValue != null && completedAtValue is! String)) {
      throw const FormatException('Lesson progress fields are invalid.');
    }
    final completedAt = completedAtValue == null
        ? null
        : DateTime.tryParse(completedAtValue as String)?.toUtc();
    if (completedAtValue != null && completedAt == null) {
      throw const FormatException('Lesson completion date is invalid.');
    }
    return LessonProgress(
      progressPercent: progressPercent,
      resumePositionSeconds: resumePositionSeconds,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }
}
