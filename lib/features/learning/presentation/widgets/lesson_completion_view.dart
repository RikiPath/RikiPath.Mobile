import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_shared_widgets.dart';

class LessonCompletionView extends StatelessWidget {
  const LessonCompletionView({
    required this.lesson,
    required this.onNextLesson,
    required this.onBackToRoadmap,
    super.key,
  });

  final Lesson lesson;
  final VoidCallback? onNextLesson;
  final VoidCallback onBackToRoadmap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('lesson_completion_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        RikiCard(
          borderColor: AppColors.successBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.successBackground,
                    foregroundColor: AppColors.success,
                    child: Icon(Icons.check_circle_outline, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xuất sắc hoàn thành',
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Chúc mừng bạn đã hoàn thành!',
                          style: AppTypography.sectionTitle.copyWith(
                            color: AppColors.learnerTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'BÀI ${lesson.lessonNumber}',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                lesson.title,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                lesson.focus,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              LessonMetadataWrap(lesson: lesson),
              const SizedBox(height: AppSpacing.space4),
              LessonProgressMeter(
                progress: lesson.progress,
                completedColor: true,
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.warningBackground,
                  border: Border.all(color: AppColors.warningBorder),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.skillGrammar,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        'Chuỗi học tập: ${lesson.streakDays} ngày liên tiếp',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.learnerTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '+${lesson.completionXp} XP',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.learnerTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        RikiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.space3,
                runSpacing: AppSpacing.space1,
                children: [
                  Text(
                    'Nội dung bạn đã nắm vững',
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.learnerTextPrimary,
                    ),
                  ),
                  Text(
                    '${lesson.masteryItems.length}/${lesson.masteryItems.length} mục',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              for (
                var index = 0;
                index < lesson.masteryItems.length;
                index++
              ) ...[
                _MasteryItem(item: lesson.masteryItems[index]),
                if (index != lesson.masteryItems.length - 1)
                  const SizedBox(height: AppSpacing.space2),
              ],
            ],
          ),
        ),
        if (lesson.nextLesson != null) ...[
          const SizedBox(height: AppSpacing.space4),
          _NextLessonCard(nextLesson: lesson.nextLesson!),
          const SizedBox(height: AppSpacing.space4),
          RikiPrimaryButton(
            key: const ValueKey<String>('lesson_next_button'),
            label: 'Học bài tiếp theo (Bài ${lesson.nextLesson!.lessonNumber})',
            trailingIcon: Icons.arrow_forward,
            onPressed: onNextLesson,
          ),
        ],
        const SizedBox(height: AppSpacing.space2),
        RikiTextButton(
          key: const ValueKey<String>('lesson_back_roadmap_button'),
          label: 'Quay lại Lộ trình học ${lesson.level.label}',
          leadingIcon: Icons.arrow_back,
          onPressed: onBackToRoadmap,
        ),
      ],
    );
  }
}

class _MasteryItem extends StatelessWidget {
  const _MasteryItem({required this.item});

  final LessonMasteryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.successBackground,
            foregroundColor: AppColors.success,
            child: Icon(Icons.check, size: 14),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.description,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
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

class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.nextLesson});

  final LessonLink nextLesson;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      boxShadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bài học tiếp theo trong lộ trình',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.brandTint,
                foregroundColor: AppColors.brandPrimary,
                child: Text(
                  '${nextLesson.lessonNumber}',
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nextLesson.title, style: AppTypography.cardTitle),
                    Text(
                      nextLesson.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    Text(
                      '~${nextLesson.durationMinutes} phút • '
                      '${nextLesson.level.label}',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
