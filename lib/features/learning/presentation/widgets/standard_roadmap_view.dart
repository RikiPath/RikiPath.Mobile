import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/sakura_learning_journey_map.dart';

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
    this.showStandard = true,
    this.hasPendingPreview = false,
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
  final bool showStandard;
  final bool hasPendingPreview;
  final Future<void> Function(int day, {required bool complete})? onUpdateAiDay;
  final int? updatingAiDay;
  final String? aiDayError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progressFraction = roadmap.totalLessons == 0
        ? 0.0
        : (roadmap.completedLessons / roadmap.totalLessons).clamp(0.0, 1.0);
    final progressPercent = (progressFraction * 100).round();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey<String>('standard_roadmap_success_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          0,
          AppSpacing.space4,
          AppSpacing.space4,
        ),
        children: [
          // 1. Premium Summary Card
          if (showStandard)
            RikiCard(
              key: const ValueKey<String>('standard_roadmap_summary'),
              backgroundColor: AppColors.cardWarmWhite,
              borderColor: AppColors.borderSubtlePink,
              boxShadow: AppShadows.sakuraSubtle,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.standardRoadmapTitle,
                          style: AppTypography.sectionTitle.copyWith(
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        '$progressPercent%',
                        style: AppTypography.pageTitle.copyWith(
                          color: SakuraJourneyColors.primarySakura,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: SakuraJourneyColors.primarySakura,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'JLPT ${roadmap.currentStudyLevelName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (roadmap.targetJlptLevelName case final target?)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: SakuraJourneyColors.softPink,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${l10n.onboardingTargetJlptTitle}: $target',
                            style: const TextStyle(
                              color: SakuraJourneyColors.primarySakuraDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.standardRoadmapProgress(
                            roadmap.completedLessons,
                            roadmap.totalLessons,
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.learnerTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        '${roadmap.completedLessons}/${roadmap.totalLessons}',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 8,
                      backgroundColor: SakuraJourneyColors.lavender,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        SakuraJourneyColors.primarySakura,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showStandard) const SizedBox(height: AppSpacing.space2),

          // 2. Empty State or Gamified Journey Map
          if (showStandard && roadmap.lessons.isEmpty)
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
          else if (showStandard) ...[
            SakuraLearningJourneyMap(
              lessons: roadmap.lessons,
              currentStudyLevelName: roadmap.currentStudyLevelName,
              targetJlptLevelName: roadmap.targetJlptLevelName,
              nextLessonId: roadmap.nextLessonId,
              onOpenLesson: onOpenLesson,
            ),
          ],
          if (showStandard) const SizedBox(height: AppSpacing.space3),

          // 3. AI Personalized Path Section (preserved)
          _AiPathSection(
            canGenerate: canGenerateAiPath,
            hasCompletedPlacement: hasCompletedPlacement,
            isLoading: isGeneratingAiPath,
            error: aiPathError,
            path: aiPath,
            hasPendingPreview: hasPendingPreview,
            onGenerate: onGenerateAiPath,
            onUpdateDay: onUpdateAiDay,
            onOpenLesson: onOpenLesson,
            updatingDay: updatingAiDay,
            dayError: aiDayError,
          ),
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
    required this.hasPendingPreview,
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
  final bool hasPendingPreview;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              if (value.status != LearningPathStatus.draft &&
                  value.dailySchedules.isNotEmpty) ...[
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
                  hasPendingPreview || path?.status == LearningPathStatus.draft
                      ? 'Xem bản xem trước'
                      : path == null
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
