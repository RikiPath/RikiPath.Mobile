import 'dart:math' as math;

import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/data/lesson_fixture_dto.dart';
import 'package:rikipath_mobile/features/learning/data/lesson_mapper.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_repository.dart';

/// C10 visual-development data built only from LEARNING_07 through
/// LEARNING_14. No backend endpoint is called by this repository.
class FixtureLessonRepository implements LessonRepository {
  const FixtureLessonRepository();

  static const String lesson19RouteId = 'fixture-n4-grammar-lesson-19';
  static const String lesson20RouteId = 'fixture-n4-grammar-lesson-20';

  static String lesson19RouteIdFor(JlptLevel level) =>
      _routeForLevel(lesson19RouteId, level);

  static String lesson20RouteIdFor(JlptLevel level) =>
      _routeForLevel(lesson20RouteId, level);

  static List<String> orderedRouteIdsFor(JlptLevel level) => List.unmodifiable(
    _lessons.map((lesson) => _routeForLevel(lesson.routeId, level)),
  );

  static String? nextRouteIdFor(String routeId) {
    final level = _levelFromRoute(routeId);
    final normalized = _routeForLevel(routeId, JlptLevel.n4);
    final index = _lessons.indexWhere((lesson) => lesson.routeId == normalized);
    if (index < 0 || index == _lessons.length - 1) return null;
    return _routeForLevel(_lessons[index + 1].routeId, level);
  }

  @override
  Future<Lesson> loadLesson(String routeId) async {
    final level = _levelFromRoute(routeId);
    final normalizedRouteId = _routeForLevel(routeId, JlptLevel.n4);
    final dto = _lessons
        .where((lesson) => lesson.routeId == normalizedRouteId)
        .firstOrNull;
    if (dto == null) {
      throw StateError('Không tìm thấy bài học trong dữ liệu mẫu.');
    }
    final lesson = LessonMapper.fromFixture(dto);
    final lessonIndex = _lessons.indexOf(dto);
    final nextDto = lessonIndex < _lessons.length - 1
        ? _lessons[lessonIndex + 1]
        : null;
    final prerequisite = lesson.prerequisite;
    return lesson.copyWith(
      routeId: routeId,
      level: level,
      nextLesson: nextDto == null
          ? null
          : LessonLink(
              routeId: _routeForLevel(nextDto.routeId, level),
              lessonNumber: nextDto.lessonNumber,
              title: nextDto.title,
              subtitle: nextDto.focus,
              durationMinutes: (nextDto.durationSeconds / 60).ceil(),
              level: level,
            ),
      prerequisite: prerequisite?.copyWith(
        routeId: _routeForLevel(prerequisite.routeId, level),
      ),
    );
  }

  @override
  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    if (durationSeconds <= 0) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'Thời lượng video phải lớn hơn 0.',
      );
    }
    if (positionSeconds < 0) {
      throw ArgumentError.value(
        positionSeconds,
        'positionSeconds',
        'Vị trí phát không được âm.',
      );
    }

    final lesson = await loadLesson(routeId);
    final clampedPosition = math.min(positionSeconds, durationSeconds);
    final watchedPercent = (clampedPosition * 100 / durationSeconds)
        .round()
        .clamp(0, 100)
        .toInt();
    final progressPercent = math.max(
      lesson.progress.progressPercent,
      watchedPercent,
    );
    final isCompleted = progressPercent >= 95;

    return LessonProgress(
      progressPercent: progressPercent,
      resumePositionSeconds: clampedPosition,
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now().toUtc() : null,
    );
  }

  static const List<LessonFixtureDto> _lessons = [
    LessonFixtureDto(
      routeId: lesson19RouteId,
      title: 'Thể quá khứ & Liệt kê hành động',
      focus: '～たり～たりする',
      level: 'N4',
      category: 'Ngữ pháp',
      curriculum: 'Ngữ pháp Minna',
      chapterNumber: 2,
      lessonNumber: 19,
      durationSeconds: 1680,
      objective:
          'Sử dụng cấu trúc ～たり～たりする để liệt kê nhiều hành động '
          'hoặc trạng thái tiêu biểu một cách tự nhiên trong giao tiếp.',
      parts: [
        LessonPartFixtureDto(
          number: 1,
          title: 'Cấu trúc ngữ pháp',
          subtitle: 'Vた + り、Vた + りする',
          durationMinutes: 5,
          status: 'completed',
        ),
        LessonPartFixtureDto(
          number: 2,
          title: 'Cách sử dụng & Ngữ cảnh',
          subtitle: 'Hội thoại thực tế đời sống',
          durationMinutes: 8,
          status: 'current',
        ),
        LessonPartFixtureDto(
          number: 3,
          title: 'Các câu ví dụ thực tế & Phân tích',
          subtitle: 'Ví dụ hội thoại, phân tích câu',
          durationMinutes: 10,
          status: 'locked',
        ),
        LessonPartFixtureDto(
          number: 4,
          title: 'Những lưu ý quan trọng',
          subtitle: 'Tránh nhầm với ～て、～て',
          durationMinutes: 5,
          status: 'locked',
        ),
      ],
      vocabulary: [
        LessonVocabularyFixtureDto(
          word: '経験',
          reading: 'けいけん',
          meaning: 'Kinh nghiệm, trải nghiệm',
          isSaved: true,
        ),
        LessonVocabularyFixtureDto(
          word: '改善',
          reading: 'かいぜん',
          meaning: 'Cải thiện, tiến bộ',
          isSaved: false,
        ),
        LessonVocabularyFixtureDto(
          word: '週末',
          reading: 'しゅうまつ',
          meaning: 'Cuối tuần',
          isSaved: false,
        ),
        LessonVocabularyFixtureDto(
          word: '映画',
          reading: 'えいが',
          meaning: 'Phim ảnh, bộ phim',
          isSaved: false,
        ),
      ],
      detailVocabularyCount: 8,
      videoVocabularyCount: 12,
      relatedGrammar: [
        LessonRelatedGrammarFixtureDto(
          number: 12,
          title: 'Mẫu câu ～てから',
          description: 'Chỉ hành động kế tiếp trong thời gian',
        ),
        LessonRelatedGrammarFixtureDto(
          number: 23,
          title: 'Mẫu câu ～ながら',
          description: 'Chỉ hai hành động song song cùng diễn ra',
        ),
      ],
      article: LessonArticleFixtureDto(
        formulas: [
          'Vた + り、Vた + りする',
          'Aい (bỏ い) + かったり、Aい + かったりする',
          'Na / N + だったり、Na / N + だったりする',
        ],
        meaning: 'Làm những việc như là... và như là...',
        usageSteps: [
          'Động từ chia về thể quá khứ ngắn (thể Ta - た) rồi gắn trực tiếp với trợ từ り.',
          'Cuối câu kết thúc bằng する; chính động từ này quyết định thì, phủ định và kính ngữ.',
        ],
        examples: [
          LessonExampleFixtureDto(
            japanese: '休みの日は、掃除をしたり、洗濯をしたりします。',
            reading:
                'Yasumi no hi wa, souji o shitari, sentaku o shitari shimasu.',
            translation:
                'Vào ngày nghỉ, tôi thường dọn dẹp, giặt giũ và làm những việc khác.',
          ),
          LessonExampleFixtureDto(
            japanese: '昨日は雨が降ったり、晴れたりしました。',
            reading: 'Kinou wa ame ga futtari, haretari shimashita.',
            translation: 'Hôm qua trời lúc thì mưa, lúc thì nắng.',
          ),
        ],
        importantNotes: [
          'Thì của toàn bộ câu do trợ động từ する ở cuối câu quyết định.',
          'Khác với ～て、～て, cấu trúc ～たり～たり không yêu cầu thứ tự thời gian.',
        ],
      ),
      progress: LessonProgressFixtureDto(
        progressPercent: 40,
        resumePositionSeconds: 750,
        isCompleted: false,
      ),
      availability: 'available',
      noteCount: 3,
      streakDays: 12,
      detailXp: 25,
      completionXp: 30,
      masteryItems: [
        LessonMasteryFixtureDto(
          title: 'Video bài giảng lý thuyết',
          description: 'Thời lượng hoàn tất: 28:00 (100% thời gian)',
        ),
        LessonMasteryFixtureDto(
          title: 'Cấu trúc ngữ pháp & Cách dùng cốt lõi',
          description: 'Liệt kê hành động đại diện, không cần thứ tự thời gian',
        ),
        LessonMasteryFixtureDto(
          title: '4 câu ví dụ thực tế tiêu biểu',
          description: 'Phân biệt ～たり～たり với cấu trúc ～て、～て',
        ),
        LessonMasteryFixtureDto(
          title: 'Đã lưu từ mới vào Sổ từ cá nhân',
          description: '経験 • 改善 • 週末',
        ),
      ],
      nextLesson: LessonLinkFixtureDto(
        routeId: lesson20RouteId,
        lessonNumber: 20,
        title: 'Văn phong giao tiếp thân mật',
        subtitle: 'Thể thông thường (Futsuukei)',
        durationMinutes: 35,
        level: 'N4',
      ),
    ),
    LessonFixtureDto(
      routeId: lesson20RouteId,
      title: 'Văn phong giao tiếp thân mật',
      focus: '普通形',
      level: 'N4',
      category: 'Ngữ pháp',
      curriculum: 'Ngữ pháp Minna',
      chapterNumber: 2,
      lessonNumber: 20,
      durationSeconds: 2100,
      objective: 'Nội dung sẽ mở sau khi hoàn thành bài học tiên quyết.',
      parts: [
        LessonPartFixtureDto(
          number: 1,
          title: 'Video: Văn phong Futsukei (普通形)',
          subtitle: 'Giảng giải quy tắc & ngữ cảnh sử dụng',
          durationMinutes: 12,
          status: 'locked',
        ),
        LessonPartFixtureDto(
          number: 2,
          title: 'Cấu trúc chia động từ thể thông thường',
          subtitle: 'Bảng tóm tắt quy tắc & lưu ý',
          durationMinutes: 8,
          status: 'locked',
        ),
        LessonPartFixtureDto(
          number: 3,
          title: '15 từ vựng giao tiếp thực tế đời sống',
          subtitle: 'Có phát âm audio & thẻ nhớ Kanji',
          durationMinutes: 7,
          status: 'locked',
        ),
        LessonPartFixtureDto(
          number: 4,
          title: 'Luyện tập phản xạ đàm thoại',
          subtitle: '10 câu trắc nghiệm tương tác nhanh',
          durationMinutes: 8,
          status: 'locked',
        ),
      ],
      vocabulary: [],
      detailVocabularyCount: 15,
      videoVocabularyCount: 15,
      relatedGrammar: [],
      article: LessonArticleFixtureDto(
        formulas: [],
        meaning: '',
        usageSteps: [],
        examples: [],
        importantNotes: [],
      ),
      progress: LessonProgressFixtureDto(
        progressPercent: 0,
        resumePositionSeconds: 0,
        isCompleted: false,
      ),
      availability: 'locked',
      noteCount: 0,
      streakDays: 12,
      detailXp: 0,
      completionXp: 0,
      masteryItems: [],
      lockedReason:
          'Hoàn thành Bài 19 để mở khóa toàn bộ bài giảng, hội thoại thực tế và bài tập.',
      prerequisite: LessonPrerequisiteFixtureDto(
        routeId: lesson19RouteId,
        lessonNumber: 19,
        title: 'Thể quá khứ & Liệt kê hành động',
        focus: '～たり～たりする',
        progressPercent: 40,
        completedParts: 2,
        totalParts: 4,
        remainingMinutes: 15,
      ),
    ),
  ];

  static String _routeForLevel(String routeId, JlptLevel level) {
    return routeId.replaceFirst(
      RegExp(r'^fixture-n[345]-'),
      'fixture-${level.name}-',
    );
  }

  static JlptLevel _levelFromRoute(String routeId) {
    if (routeId.startsWith('fixture-n5-')) return JlptLevel.n5;
    if (routeId.startsWith('fixture-n3-')) return JlptLevel.n3;
    return JlptLevel.n4;
  }
}
