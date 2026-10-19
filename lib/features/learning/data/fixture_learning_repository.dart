import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

/// Visual-development data based on the approved C9 Stitch references.
///
/// This repository never calls the API. The backend currently has no JLPT
/// roadmap, lesson-list, or learning-summary contract.
class FixtureLearningRepository implements LearningRepository {
  const FixtureLearningRepository();

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) {
    return Future<LearningSnapshot>.value(snapshot);
  }

  static const LearningSnapshot snapshot = LearningSnapshot(
    initials: 'MA',
    jlptTarget: JlptLevel.n4,
    streakDays: 12,
    hasUnreadNotifications: true,
    examDateLabel: '12/2024',
    overallProgress: 0.58,
    completedLessons: 18,
    totalLessons: 30,
    completedChapters: 1,
    totalChapters: 3,
    metrics: <LearningMetric>[
      LearningMetric(label: 'TỪ VỰNG', current: 420, total: 700),
      LearningMetric(label: 'KANJI', current: 112, total: 180),
      LearningMetric(label: 'NGỮ PHÁP', current: 18, total: 30),
    ],
    currentLesson: CurrentLessonSummary(
      routeId: FixtureLessonRepository.lesson19RouteId,
      chapterNumber: 2,
      lessonNumber: 19,
      title: 'Thể quá khứ & Liệt kê hành động',
      category: 'Ngữ pháp',
      pattern: '〜たり〜たりする',
      durationMinutes: 28,
      progress: 0.40,
    ),
    sections: <LearningSectionSummary>[
      LearningSectionSummary(
        kind: LearningSectionKind.roadmap,
        title: 'Lộ trình',
        subtitle: '3 chương học',
        status: '58% xong',
      ),
      LearningSectionSummary(
        kind: LearningSectionKind.lessons,
        title: 'Bài học',
        subtitle: '30 bài N4',
        status: '18/30 bài',
      ),
      LearningSectionSummary(
        kind: LearningSectionKind.library,
        title: 'Thư viện',
        subtitle: 'Ngữ pháp & Từ',
        status: 'Đầy đủ',
      ),
    ],
    chapters: <RoadmapChapter>[
      RoadmapChapter(
        number: 1,
        firstLesson: 1,
        lastLesson: 10,
        title: 'Nền tảng & Giao tiếp cơ bản',
        description:
            'Củng cố trợ từ, động từ nhóm I-II-III và các mẫu câu diễn đạt '
            'nguyện vọng 〜たい.',
        status: RoadmapChapterStatus.completed,
        completedLessons: 10,
        totalLessons: 10,
        skills: <ChapterSkillSummary>[
          ChapterSkillSummary(
            category: LearningSkillCategory.vocabulary,
            detail: '✓ 250 từ',
            status: ChapterSkillStatus.completed,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.kanji,
            detail: '✓ 60 chữ',
            status: ChapterSkillStatus.completed,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.grammar,
            detail: '✓ 10/10',
            status: ChapterSkillStatus.completed,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.reading,
            detail: '✓ 8/8 bài',
            status: ChapterSkillStatus.completed,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.listening,
            detail: '✓ 8/8 bài',
            status: ChapterSkillStatus.completed,
          ),
        ],
      ),
      RoadmapChapter(
        number: 2,
        firstLesson: 11,
        lastLesson: 20,
        title: 'Mẫu câu Trung cấp & Điều kiện',
        description:
            'Trọng tâm các thể: Thể điều kiện 〜ば, thể bị động, sai khiến '
            'và liệt kê hành động 〜たり.',
        status: RoadmapChapterStatus.current,
        completedLessons: 8,
        totalLessons: 10,
        skills: <ChapterSkillSummary>[
          ChapterSkillSummary(
            category: LearningSkillCategory.vocabulary,
            detail: '✓ Hoàn thành (170 từ)',
            status: ChapterSkillStatus.completed,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.kanji,
            detail: '✓ Hoàn thành (52 chữ)',
            status: ChapterSkillStatus.completed,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.grammar,
            detail: '60% (6/10 mẫu)',
            status: ChapterSkillStatus.inProgress,
            progress: 0.60,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.reading,
            detail: '20% (1/5 bài)',
            status: ChapterSkillStatus.inProgress,
            progress: 0.20,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.listening,
            detail: 'Chưa học',
            status: ChapterSkillStatus.notStarted,
          ),
        ],
      ),
      RoadmapChapter(
        number: 3,
        firstLesson: 21,
        lastLesson: 30,
        title: 'Kính ngữ & Luyện đề Nước rút',
        description:
            'Tôn kính ngữ (Sonkeigo), Khiêm nhường ngữ (Kenjougo) và 5 đề '
            'thi thử chuẩn cấu trúc JLPT N4.',
        status: RoadmapChapterStatus.locked,
        completedLessons: 0,
        totalLessons: 10,
        lockedReason: 'Mở khóa sau khi hoàn thành Chương 2',
        skills: <ChapterSkillSummary>[
          ChapterSkillSummary(
            category: LearningSkillCategory.vocabulary,
            detail: '280 từ',
            status: ChapterSkillStatus.locked,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.kanji,
            detail: '68 chữ',
            status: ChapterSkillStatus.locked,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.grammar,
            detail: '10 bài',
            status: ChapterSkillStatus.locked,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.reading,
            detail: '11 bài',
            status: ChapterSkillStatus.locked,
          ),
          ChapterSkillSummary(
            category: LearningSkillCategory.listening,
            detail: '8 bài',
            status: ChapterSkillStatus.locked,
          ),
        ],
      ),
    ],
    skillProgress: <LearningSkillProgress>[
      LearningSkillProgress(
        category: LearningSkillCategory.vocabulary,
        current: 420,
        total: 700,
        unit: 'từ',
      ),
      LearningSkillProgress(
        category: LearningSkillCategory.kanji,
        current: 112,
        total: 180,
        unit: 'chữ',
      ),
      LearningSkillProgress(
        category: LearningSkillCategory.grammar,
        current: 18,
        total: 30,
        unit: 'bài',
      ),
      LearningSkillProgress(
        category: LearningSkillCategory.reading,
        current: 12,
        total: 24,
        unit: 'bài',
      ),
      LearningSkillProgress(
        category: LearningSkillCategory.listening,
        current: 10,
        total: 22,
        unit: 'bài',
      ),
    ],
  );
}
