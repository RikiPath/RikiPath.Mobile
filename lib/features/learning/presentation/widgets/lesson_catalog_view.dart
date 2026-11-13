import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';

/// Bài học có sẵn không phụ thuộc Placement hoặc lộ trình AI.
class LessonCatalogView extends ConsumerWidget {
  const LessonCatalogView({
    required this.selectedLevelId,
    required this.onSelectLevel,
    required this.onSetStudyLevel,
    super.key,
  });

  final int? selectedLevelId;
  final ValueChanged<int> onSelectLevel;
  final ValueChanged<JlptLevelCatalogItem> onSetStudyLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(jlptCatalogControllerProvider);
    final profileLevelId = ref
        .watch(userProfileControllerProvider)
        .asData
        ?.value
        .profile
        .currentStudyLevelId;
    return catalogState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _CatalogState(
        message: 'Không thể tải các cấp độ JLPT.',
        onRetry: () => ref.invalidate(jlptCatalogControllerProvider),
      ),
      data: (levels) {
        final supported =
            levels
                .where((level) => level.level != JlptLevel.n1)
                .toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (supported.isEmpty) {
          return const _CatalogState(
            message: 'Hiện chưa có cấp độ N5–N2 để hiển thị.',
          );
        }
        final selected =
            supported
                .where((level) => level.id == selectedLevelId)
                .firstOrNull ??
            supported
                .where((level) => level.id == profileLevelId)
                .firstOrNull ??
            supported.first;
        final lessonsState = ref.watch(lessonCatalogProvider(selected.id));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(lessonCatalogProvider(selected.id));
            await ref.read(lessonCatalogProvider(selected.id).future);
          },
          child: ListView(
            key: const PageStorageKey('learning_lesson_catalog'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 132,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/learning/sakura_garden.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: Colors.white.withValues(alpha: 0.88),
                          child: Text(
                            'Khám phá bài học theo nhịp của bạn',
                            style: AppTypography.sectionTitle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Lọc bài học theo cấp độ JLPT',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final level in supported) ...[
                        ChoiceChip(
                          key: ValueKey(
                            'learning_level_${level.code.toLowerCase()}',
                          ),
                          label: Text(level.code),
                          selected: selected.id == level.id,
                          onSelected: (_) => onSelectLevel(level.id),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (profileLevelId != selected.id)
                OutlinedButton(
                  key: const ValueKey('learning_set_study_level'),
                  onPressed: () => onSetStudyLevel(selected),
                  child: Text('Đặt ${selected.code} làm cấp độ đang học'),
                ),
              lessonsState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    key: ValueKey('learning_catalog_loading'),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => _CatalogState(
                  message: 'Không thể tải bài học. Vui lòng kiểm tra kết nối.',
                  onRetry: () =>
                      ref.invalidate(lessonCatalogProvider(selected.id)),
                ),
                data: (snapshot) {
                  if (snapshot.certificateLevelId != null &&
                      snapshot.certificateLevelId != selected.id) {
                    return const _CatalogState(
                      message:
                          'Dữ liệu bài học không khớp cấp độ đã chọn. Vui lòng tải lại.',
                    );
                  }
                  if (snapshot.lessons.isEmpty) {
                    return const _CatalogState(
                      message: 'Cấp độ này hiện chưa có bài học được công bố.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${snapshot.lessons.length} bài học',
                        style: AppTypography.sectionTitle,
                      ),
                      const SizedBox(height: 10),
                      for (final lesson in snapshot.lessons) ...[
                        _LessonCard(lesson: lesson),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogState extends StatelessWidget {
  const _CatalogState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey('learning_catalog_state'),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});
  final LearningLessonSummary lesson;

  @override
  Widget build(BuildContext context) {
    final progress = lesson.progressPercent.clamp(0, 100);
    final status = lesson.isCompleted
        ? 'Đã hoàn thành'
        : progress > 0
        ? 'Đang học'
        : 'Chưa bắt đầu';
    return Card(
      key: ValueKey('catalog_lesson_${lesson.lessonId}'),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.lesson(lesson.routeId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Image.asset(
                _iconFor(lesson.languageSkillName),
                width: 54,
                height: 54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sectionTitle,
                    ),
                    if (lesson.description?.trim().isNotEmpty == true)
                      Text(
                        lesson.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: AppTypography.metadata.copyWith(
                        color: lesson.isCompleted
                            ? Colors.green.shade700
                            : AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Tiến độ $progress phần trăm',
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress / 100,
                        strokeWidth: 4,
                        backgroundColor: AppColors.brandTint,
                        color: lesson.isCompleted
                            ? Colors.green
                            : AppColors.brandPrimary,
                      ),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _iconFor(String skill) {
    final value = skill.toLowerCase();
    if (value.contains('kanji') || value.contains('hán')) {
      return 'assets/images/icons_3d/kanji_brush.webp';
    }
    if (value.contains('ngữ pháp') || value.contains('grammar')) {
      return 'assets/images/icons_3d/grammar_book.webp';
    }
    if (value.contains('từ vựng') || value.contains('vocabulary')) {
      return 'assets/images/icons_3d/vocabulary_book.webp';
    }
    return 'assets/images/icons_3d/lesson_book.webp';
  }
}
