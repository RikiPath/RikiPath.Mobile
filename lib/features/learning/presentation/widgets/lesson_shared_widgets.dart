import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

class LessonMetadataWrap extends StatelessWidget {
  const LessonMetadataWrap({required this.lesson, super.key});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        JlptBadge(lesson.level),
        _MetadataPill(label: lesson.category),
        _MetadataPill(
          label: '${lesson.durationMinutes} phút',
          icon: Icons.schedule_outlined,
        ),
      ],
    );
  }
}

class LessonProgressMeter extends StatelessWidget {
  const LessonProgressMeter({
    required this.progress,
    this.completedColor = false,
    super.key,
  });

  final LessonProgress progress;
  final bool completedColor;

  @override
  Widget build(BuildContext context) {
    final color = completedColor ? AppColors.success : AppColors.brandPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.space3,
          runSpacing: AppSpacing.space1,
          children: [
            Text(
              'Tiến độ bài học',
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              progress.isCompleted
                  ? '100% HOÀN THÀNH'
                  : '${progress.progressPercent}% • Đang học',
              key: const ValueKey<String>('lesson_progress_value'),
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 9,
            color: color,
            backgroundColor: AppColors.learnerSurfaceLow,
            semanticsLabel:
                'Tiến độ bài học ${progress.progressPercent} phần trăm',
          ),
        ),
      ],
    );
  }
}

class LessonVocabularyTile extends StatelessWidget {
  const LessonVocabularyTile({required this.item, super.key});

  final LessonVocabularyItem item;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      boxShadow: const <BoxShadow>[],
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brandTint,
            foregroundColor: AppColors.brandPrimary,
            child: Icon(Icons.volume_up_outlined, size: 20),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reading,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.word,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.learnerTextPrimary,
                  ),
                ),
                Text(
                  item.meaning,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.learnerSurfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isSaved
                      ? Icons.bookmark_added_outlined
                      : Icons.bookmark_add_outlined,
                  size: 16,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  item.isSaved ? 'Đã lưu' : 'Sổ từ',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatLessonTime(int seconds) {
  final duration = Duration(seconds: seconds.clamp(0, 359999).toInt());
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final remainingSeconds = duration.inSeconds
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$remainingSeconds';
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.learnerSurfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            label,
            style: AppTypography.badgeText.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
