import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/home/domain/home_repository.dart';

/// Visual-development data matching the approved new-learner Home reference.
///
/// This repository does not call the API and must not be treated as live data.
class FixtureHomeRepository implements HomeRepository {
  const FixtureHomeRepository();

  @override
  Future<HomeDashboard> loadDashboard() {
    return Future<HomeDashboard>.value(dashboard);
  }

  static const HomeDashboard dashboard = HomeDashboard(
    learnerName: 'Minh Anh',
    initials: 'MA',
    jlptTarget: JlptLevel.n4,
    streakDays: 1,
    hasUnreadNotifications: true,
    journeyStatus: 'Hành trình mới',
    goalStatus: 'Bắt đầu hành trình hôm nay',
    firstLesson: HomeLessonSummary(
      eyebrow: 'Bắt đầu hành trình',
      badge: 'Bài 1: Khởi động',
      title: 'Tổng quan JLPT N4 & Phương pháp học',
      description:
          'Làm quen cấu trúc đề thi N4, thang điểm, và thiết lập thói quen học 30 phút mỗi ngày.',
      completedParts: 0,
      totalParts: 5,
    ),
    roadmap: HomeRoadmapSummary(
      title: 'Lộ trình học tập cá nhân hóa',
      subtitle: 'Chương trình chuẩn từ N5 lên N4 chia theo từng chặng',
      description:
          'Bao gồm đầy đủ các cấu phần: Từ vựng cốt lõi, '
          'Ngữ pháp chuyên sâu, Đọc hiểu Dokkai và Luyện nghe Choukai.',
      stageCount: 4,
    ),
    setup: HomeSetupSummary(
      completedCount: 2,
      totalCount: 3,
      items: <HomeSetupItem>[
        HomeSetupItem(
          title: 'Đã chọn mục tiêu N4',
          description: 'Cấp độ mục tiêu đã sẵn sàng',
          isComplete: true,
        ),
        HomeSetupItem(
          title: 'Đã chọn thời gian học',
          description: '30 phút / ngày',
          isComplete: true,
        ),
        HomeSetupItem(
          title: 'Bài học đầu tiên đang chờ',
          description: 'Hoàn thành bài khởi động để mở khóa SRS',
          isComplete: false,
          actionLabel: 'Học ngay',
        ),
      ],
    ),
    tools: <HomeToolSummary>[
      HomeToolSummary(
        title: 'Sổ từ & SRS',
        description:
            'Lặp lại ngắt quãng khoa học giúp ghi nhớ từ vựng lâu bền.',
        destination: HomeToolDestination.notebook,
      ),
      HomeToolSummary(
        title: 'Luyện thi thử',
        description: 'Luyện theo dạng đề JLPT chuẩn từng kỹ năng ngữ cảnh.',
        destination: HomeToolDestination.practice,
      ),
    ],
  );
}
