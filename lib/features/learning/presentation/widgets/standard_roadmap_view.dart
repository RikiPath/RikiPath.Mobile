import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';

class StandardRoadmapView extends StatelessWidget {
  const StandardRoadmapView({
    required this.roadmap,
    required this.onOpenLesson,
    required this.onRefresh,
    required this.canGenerateAiPath,
    required this.hasCompletedPlacement,
    required this.isGeneratingAiPath,
    required this.aiPathError,
    required this.aiPath,
    required this.onGenerateAiPath,
    this.onUpdateAiDay,
    this.updatingAiDay,
    this.aiDayError,
    super.key,
  });

  final StandardRoadmap roadmap;
  final ValueChanged<String> onOpenLesson;
  final Future<void> Function() onRefresh;
  final bool canGenerateAiPath;
  final bool hasCompletedPlacement;
  final bool isGeneratingAiPath;
  final String? aiPathError;
  final RecommendedLearningPath? aiPath;
  final VoidCallback onGenerateAiPath;
  final Future<void> Function(int day, {required bool complete})? onUpdateAiDay;
  final int? updatingAiDay;
  final String? aiDayError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey<String>('standard_roadmap_success_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: [
          RikiCard(
            key: const ValueKey<String>('standard_roadmap_summary'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.standardRoadmapTitle,
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    Chip(label: Text(roadmap.currentStudyLevelName)),
                    if (roadmap.targetJlptLevelName case final target?)
                      Chip(
                        label: Text(
                          '${l10n.onboardingTargetJlptTitle}: $target',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  l10n.standardRoadmapProgress(
                    roadmap.completedLessons,
                    roadmap.totalLessons,
                  ),
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.space2),
                LinearProgressIndicator(
                  value: roadmap.totalLessons == 0
                      ? 0
                      : roadmap.completedLessons / roadmap.totalLessons,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(l10n.standardRoadmapTitle, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space3),
          if (roadmap.lessons.isEmpty)
            RikiCard(
              key: const ValueKey<String>('standard_roadmap_empty'),
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.learningLessonsEmptyMessage,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  RikiPrimaryButton(
                    key: const ValueKey<String>(
                      'standard_roadmap_change_goal_button',
                    ),
                    label: 'Đổi mục tiêu JLPT',
                    leadingIcon: Icons.flag_outlined,
                    onPressed: () => context.push(AppRoutes.profileJlptGoal),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  RikiSecondaryButton(
                    key: const ValueKey<String>(
                      'standard_roadmap_placement_test_button',
                    ),
                    label: 'Đánh giá đầu vào',
                    leadingIcon: Icons.quiz_outlined,
                    onPressed: () => context.push(AppRoutes.placementTest),
                  ),
                ],
              ),
            )
          else
            for (var index = 0; index < roadmap.lessons.length; index++) ...[
              _StandardLessonCard(
                lesson: roadmap.lessons[index],
                isNext: roadmap.lessons[index].lessonId == roadmap.nextLessonId,
                onTap: () =>
                    onOpenLesson(roadmap.lessons[index].lessonId.toString()),
              ),
              if (index < roadmap.lessons.length - 1)
                const SizedBox(height: AppSpacing.space3),
            ],
          const SizedBox(height: AppSpacing.space5),
          _AiPathSection(
            canGenerate: canGenerateAiPath,
            hasCompletedPlacement: hasCompletedPlacement,
            isLoading: isGeneratingAiPath,
            error: aiPathError,
            path: aiPath,
            onGenerate: onGenerateAiPath,
            onUpdateDay: onUpdateAiDay,
            onOpenLesson: onOpenLesson,
            updatingDay: updatingAiDay,
            dayError: aiDayError,
          ),
          const SizedBox(height: AppSpacing.space4),
          SakuraEducationalBanner(
            tag: l10n.roadmapEduBannerTag,
            title: l10n.roadmapEduBannerTitle,
            message: l10n.roadmapEduBannerMessage,
            mascotPose: SakuraMascotPose.studying,
          ),
        ],
      ),
    );
  }
}

class _StandardLessonCard extends StatelessWidget {
  const _StandardLessonCard({
    required this.lesson,
    required this.isNext,
    required this.onTap,
  });

  final StandardRoadmapLesson lesson;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RikiCard(
      key: ValueKey<String>('standard_lesson_${lesson.lessonId}'),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            lesson.isCompleted ? Icons.check_circle : Icons.menu_book,
            color: lesson.isCompleted
                ? AppColors.success
                : AppColors.brandPrimary,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNext) ...[
                  Text(
                    l10n.standardRoadmapNextLesson,
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                ],
                Text(lesson.title, style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  lesson.isCompleted
                      ? l10n.completedLessonsLabel
                      : '${lesson.progressPercent}%',
                  style: AppTypography.metadata,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _AiPathSection extends StatelessWidget {
  const _AiPathSection({
    required this.canGenerate,
    required this.hasCompletedPlacement,
    required this.isLoading,
    required this.error,
    required this.path,
    required this.onGenerate,
    this.onUpdateDay,
    this.onOpenLesson,
    this.updatingDay,
    this.dayError,
  });

  final bool canGenerate;
  final bool hasCompletedPlacement;
  final bool isLoading;
  final String? error;
  final RecommendedLearningPath? path;
  final VoidCallback onGenerate;
  final Future<void> Function(int day, {required bool complete})? onUpdateDay;
  final ValueChanged<String>? onOpenLesson;
  final int? updatingDay;
  final String? dayError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RikiCard(
      key: const ValueKey<String>('ai_personalized_path_section'),
      borderColor: AppColors.brandBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.aiPersonalizedPathTitle, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space2),
          if (isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.space2),
            Text(l10n.generatingLearningPath),
          ] else if (!canGenerate && path == null)
            Text(
              error ??
                  (hasCompletedPlacement
                      ? l10n.aiLearningGoalRequired
                      : l10n.aiPlacementRequired),
              style: AppTypography.bodySmall.copyWith(
                color: error == null
                    ? AppColors.textSecondary
                    : AppColors.error,
              ),
            )
          else ...[
            if (path case final value?) ...[
              Text(value.summary, style: AppTypography.bodySmall),
              if (value.focusTopics.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    for (final topic in value.focusTopics)
                      Chip(label: Text(topic)),
                  ],
                ),
              ],
              if (value.dailySchedules.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                for (final day in value.dailySchedules) ...[
                  const Divider(),
                  Text(
                    'Ngày ${day.day}: ${day.title}',
                    style: AppTypography.cardTitle,
                  ),
                  Text(day.focus, style: AppTypography.bodySmall),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    day.isCompleted == true
                        ? 'Đã hoàn thành'
                        : day.isStarted == true
                        ? 'Đang học'
                        : day.canStart == true
                        ? 'Có thể bắt đầu'
                        : 'Chưa mở',
                    style: AppTypography.metadata,
                  ),
                  for (final lesson in day.lessons)
                    TextButton.icon(
                      key: ValueKey<String>(
                        'ai_day_${day.day}_lesson_${lesson.lessonId}',
                      ),
                      onPressed:
                          day.isStarted == true || day.isCompleted == true
                          ? () => onOpenLesson?.call(lesson.routeId)
                          : null,
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(lesson.title),
                    ),
                  if (day.canStart == true && day.isStarted != true)
                    OutlinedButton(
                      key: ValueKey<String>('ai_day_${day.day}_start'),
                      onPressed: updatingDay == null && onUpdateDay != null
                          ? () => onUpdateDay!(day.day, complete: false)
                          : null,
                      child: const Text('Bắt đầu ngày học'),
                    ),
                  if (day.canStart == true &&
                      day.isStarted == true &&
                      day.isCompleted != true)
                    OutlinedButton(
                      key: ValueKey<String>('ai_day_${day.day}_complete'),
                      onPressed: updatingDay == null && onUpdateDay != null
                          ? () => onUpdateDay!(day.day, complete: true)
                          : null,
                      child: const Text('Hoàn thành ngày học'),
                    ),
                  if (updatingDay == day.day) const LinearProgressIndicator(),
                ],
              ],
              if (dayError case final message?) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              if (!canGenerate) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  error ??
                      (hasCompletedPlacement
                          ? l10n.aiLearningGoalRequired
                          : l10n.aiPlacementRequired),
                  style: AppTypography.bodySmall.copyWith(
                    color: error == null
                        ? AppColors.textSecondary
                        : AppColors.error,
                  ),
                ),
              ],
            ] else
              Text(
                error ?? l10n.learningPathRequirements,
                style: AppTypography.bodySmall.copyWith(
                  color: error == null
                      ? AppColors.textSecondary
                      : AppColors.error,
                ),
              ),
            if (canGenerate) ...[
              const SizedBox(height: AppSpacing.space3),
              FilledButton.icon(
                key: const ValueKey<String>('ai_learning_path_generate_button'),
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  path == null
                      ? l10n.generateLearningPath
                      : l10n.regenerateLearningPath,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
