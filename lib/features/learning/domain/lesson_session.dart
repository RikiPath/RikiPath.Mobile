import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

enum LessonStage { detail, video, article, completed }

enum LessonContentTab { content, notes, vocabulary }

enum LessonVideoStatus {
  initial,
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

@immutable
class LessonSession {
  const LessonSession({
    required this.lesson,
    this.stage = LessonStage.detail,
    this.videoStatus = LessonVideoStatus.initial,
    this.selectedTab = LessonContentTab.content,
    this.videoErrorMessage,
  });

  final Lesson lesson;
  final LessonStage stage;
  final LessonVideoStatus videoStatus;
  final LessonContentTab selectedTab;
  final String? videoErrorMessage;

  int get videoProgressPercent {
    if (lesson.durationSeconds <= 0) {
      return 0;
    }
    return (lesson.progress.resumePositionSeconds *
            100 /
            lesson.durationSeconds)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  LessonSession copyWith({
    Lesson? lesson,
    LessonStage? stage,
    LessonVideoStatus? videoStatus,
    LessonContentTab? selectedTab,
    String? videoErrorMessage,
    bool clearVideoError = false,
  }) {
    return LessonSession(
      lesson: lesson ?? this.lesson,
      stage: stage ?? this.stage,
      videoStatus: videoStatus ?? this.videoStatus,
      selectedTab: selectedTab ?? this.selectedTab,
      videoErrorMessage: clearVideoError
          ? null
          : videoErrorMessage ?? this.videoErrorMessage,
    );
  }
}
