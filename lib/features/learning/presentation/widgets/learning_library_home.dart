import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_card.dart';
import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/sakura_library_hero_banner.dart';

/// Trang Thư viện chỉ điều hướng; dữ liệu bài học tải trong màn danh mục riêng.
///
/// Bố cục và hình học được đồng bộ chuẩn theo Practice Home:
/// - Banner trải ngang toàn bộ chiều rộng màn hình.
/// - Chiều cao compact 3:1.
/// - Các menu card nằm trong lề ngang chuẩn `AppSpacing.space4` (16dp).
/// - Mỗi chức năng sử dụng một 3D icon ngữ cảnh riêng biệt, không trùng lặp.
class LearningLibraryHome extends StatelessWidget {
  const LearningLibraryHome({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('learning_resource_library'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: AppSpacing.space8),
    children: [
      const SakuraLibraryHeroBanner(),
      const SizedBox(height: AppSpacing.space4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Column(
          children: [
            _LibraryEntryCard(
              key: const ValueKey('library_lessons_card'),
              icon: Sakura3DIconType.lesson,
              title: 'Bài học tiếng Nhật',
              description: 'Khám phá bài học theo trình độ JLPT.',
              onTap: () => context.push(AppRoutes.lessonCatalog),
            ),
            const SizedBox(height: AppSpacing.space3),
            _LibraryEntryCard(
              key: const ValueKey('library_vocabulary_card'),
              icon: Sakura3DIconType.vocabulary,
              title: 'Từ vựng',
              description: 'Khám phá và ghi nhớ từ mới.',
              onTap: () => context.push(AppRoutes.vocabulary),
            ),
            const SizedBox(height: AppSpacing.space3),
            _LibraryEntryCard(
              key: const ValueKey('library_kanji_card'),
              icon: Sakura3DIconType.kanji,
              title: 'Kanji',
              description: 'Khám phá chữ Hán và cách viết.',
              onTap: () => context.push(AppRoutes.kanji),
            ),
            const SizedBox(height: AppSpacing.space3),
            _LibraryEntryCard(
              key: const ValueKey('library_grammar_card'),
              icon: Sakura3DIconType.grammar,
              title: 'Ngữ pháp',
              description: 'Nắm vững các cấu trúc tiếng Nhật.',
              onTap: () => context.push(AppRoutes.grammar),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LibraryEntryCard extends StatelessWidget {
  const _LibraryEntryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final Sakura3DIconType icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RikiCard(
    onTap: onTap,
    backgroundColor: AppColors.cardWarmWhite,
    borderColor: AppColors.cardBorderMuted,
    boxShadow: AppShadows.sakuraSubtle,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.space4,
      vertical: AppSpacing.space3,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Sakura3DIcon(type: icon, size: 52),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.learnerTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ],
    ),
  );
}
