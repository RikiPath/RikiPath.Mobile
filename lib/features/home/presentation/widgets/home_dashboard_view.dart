import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/meeting/domain/upcoming_meeting.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_home_section.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({
    required this.dashboardState,
    required this.journeyState,
    required this.learningState,
    required this.analyticsState,
    this.roadmapState,
    required this.practiceState,
    required this.dailyReviewState,
    required this.upcomingMeetingState,
    required this.onRefreshLive,
    required this.onRetryHome,
    required this.onRetryLearning,
    required this.onRetryAnalytics,
    required this.onRetryPractice,
    required this.onOpenLearning,
    required this.onOpenRoadmap,
    required this.onOpenNotebook,
    required this.onOpenPractice,
    required this.onOpenReview,
    required this.onOpenAnalytics,
    this.onOpenCalendarDate,
    required this.onOpenMeeting,
    required this.onOpenMeetingDetail,
    required this.onJoinMeeting,
    this.onOpenVocabulary,
    this.onOpenGrammar,
    this.onOpenWriting,
    super.key,
  });

  final AsyncValue<HomeDashboard> dashboardState;
  final AsyncValue<LearnerJourneyState> journeyState;
  final AsyncValue<LearningSnapshot> learningState;
  final AsyncValue<LearnerAnalytics> analyticsState;
  final AsyncValue<StandardRoadmap>? roadmapState;
  final AsyncValue<DemoPracticeState> practiceState;
  final AsyncValue<DailyReviewState> dailyReviewState;
  final AsyncValue<UpcomingMeeting?> upcomingMeetingState;
  final Future<void> Function() onRefreshLive;
  final VoidCallback onRetryHome;
  final VoidCallback onRetryLearning;
  final VoidCallback onRetryAnalytics;
  final VoidCallback onRetryPractice;
  final VoidCallback onOpenLearning;
  final VoidCallback onOpenRoadmap;
  final VoidCallback onOpenNotebook;
  final VoidCallback onOpenPractice;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenAnalytics;
  final ValueChanged<DateTime>? onOpenCalendarDate;
  final VoidCallback onOpenMeeting;
  final ValueChanged<int> onOpenMeetingDetail;
  final ValueChanged<Uri> onJoinMeeting;
  final VoidCallback? onOpenVocabulary;
  final VoidCallback? onOpenGrammar;
  final VoidCallback? onOpenWriting;

  @override
  Widget build(BuildContext context) {
    final currentLevel = learningState.value?.hasSelectedLevel == true
        ? learningState.value?.jlptTarget
        : (journeyState.value?.hasSelectedLevel == true
              ? journeyState.value?.selectedLevel
              : dashboardState.value?.jlptTarget);
    final targetLevelName = roadmapState?.value?.targetJlptLevelName;

    return RefreshIndicator(
      onRefresh: onRefreshLive,
      color: AppColors.brandPrimary,
      semanticsLabel: context.l10n.homeRefreshSemantics,
      child: ListView(
        key: const ValueKey<String>('home_success_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          0,
          AppSpacing.space3,
          0,
          AppSpacing.space8,
        ),
        children: [
          // 1. Welcoming personalized learner header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _GreetingSection(
              state: dashboardState,
              currentLevel: currentLevel,
              targetLevelName: targetLevelName,
              onRetry: onRetryHome,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // 2. Full-bleed Real-Time Sakura Hero Banner (touches left & right edges)
          SakuraHeroBanner(
            key: const ValueKey<String>('home_hero_banner'),
            onTap: onOpenLearning,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 3. Learning Analytics & streak/completion (2 equal-height cards)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _AnalyticsSection(
              state: analyticsState,
              roadmapState: roadmapState,
              onOpen: onOpenAnalytics,
              onOpenRoadmap: onOpenRoadmap,
              onOpenCalendarDate: onOpenCalendarDate,
              onRetry: onRetryAnalytics,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // 4. Quick feature category shortcuts (Học tập, Từ vựng, Ngữ pháp, Luyện nghe)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _QuickActionCategories(
              onOpenRoadmap: onOpenRoadmap,
              onOpenVocabulary: onOpenVocabulary ?? onOpenLearning,
              onOpenGrammar: onOpenGrammar ?? onOpenLearning,
              onOpenPractice: onOpenPractice,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // 5. Primary Continue Learning action (dominant study action)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _ContinueLearningSection(
              journeyState: journeyState,
              learningState: learningState,
              onOpenLearning: onOpenLearning,
              onRetry: onRetryLearning,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // 5b. Compact real learning-progress display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _LocalProgressSection(
              journeyState: journeyState,
              learningState: learningState,
              onOpenRoadmap: onOpenRoadmap,
              onRetry: onRetryLearning,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // 6. Study Categories (Bảng chữ cái, Ngữ pháp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _StudyCategoriesSection(
              onOpenWriting: onOpenWriting ?? onOpenPractice,
              onOpenGrammar: onOpenGrammar ?? onOpenLearning,
              onOpenRoadmap: onOpenRoadmap,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // 7. Practice & Daily Review
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _PracticeSections(
              state: practiceState,
              dailyReviewState: dailyReviewState,
              onOpenReview: onOpenReview,
              onOpenPractice: onOpenPractice,
              onRetry: onRetryPractice,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // 8. Meeting section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: MeetingHomeSection(
              state: upcomingMeetingState,
              onOpenMeeting: onOpenMeeting,
              onOpenDetail: onOpenMeetingDetail,
              onJoin: onJoinMeeting,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // 9. Notebook shortcut
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: _NotebookShortcut(onPressed: onOpenNotebook),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. Welcoming Greeting
// -----------------------------------------------------------------------------
class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.state,
    required this.onRetry,
    this.currentLevel,
    this.targetLevelName,
  });

  final AsyncValue<HomeDashboard> state;
  final VoidCallback onRetry;
  final JlptLevel? currentLevel;
  final String? targetLevelName;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RikiSkeleton(width: 210, height: 28),
          SizedBox(height: AppSpacing.space2),
          RikiSkeleton(width: 150, height: 16),
        ],
      ),
      error: (_, _) =>
          _CompactError(title: context.l10n.homeLoadFailed, onRetry: onRetry),
      data: (dashboard) {
        final target = targetLevelName?.trim();
        final current = currentLevel ?? dashboard.jlptTarget;
        final String subtitle;
        if (current != null &&
            target != null &&
            target.isNotEmpty &&
            target != current.label) {
          subtitle = context.l10n.homeGreetingCurrentAndTargetLevel(
            current.label,
            target,
          );
        } else if (current != null) {
          subtitle = context.l10n.homeGreetingLearningLevel(current.label);
        } else {
          subtitle = context.l10n.homeGreetingNoLevel;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.sakuraHeroGradient,
                borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
                border: Border.all(
                  color: AppColors.borderSubtlePink,
                  width: 1.5,
                ),
              ),
              child: const SakuraBlossomMark(size: 24),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dashboard.learnerName.trim().isNotEmpty
                        ? context.l10n.greetingName(dashboard.learnerName)
                        : context.l10n.greetingGeneric,
                    key: const ValueKey<String>('home_greeting'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.compactPageTitle.copyWith(
                      color: AppColors.learnerTextPrimary,
                      fontSize: 20,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.learnerTextSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Dominant Continue Learning Section
// -----------------------------------------------------------------------------
class _ContinueLearningSection extends StatelessWidget {
  const _ContinueLearningSection({
    required this.journeyState,
    required this.learningState,
    required this.onOpenLearning,
    required this.onRetry,
  });

  final AsyncValue<LearnerJourneyState> journeyState;
  final AsyncValue<LearningSnapshot> learningState;
  final VoidCallback onOpenLearning;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (journeyState.isLoading || learningState.isLoading) {
      return const _SectionSkeleton(key: ValueKey('home_learning_loading'));
    }
    if (journeyState.hasError || learningState.hasError) {
      return _CompactError(
        title: context.l10n.learningLoadFailed,
        onRetry: onRetry,
      );
    }

    final journey = journeyState.requireValue;
    if (!journey.hasSelectedLevel) {
      return _FeatureCard(
        key: const ValueKey<String>('home_choose_jlpt_card'),
        icon: Icons.flag_outlined,
        icon3d: Sakura3DIconType.achievement,
        title: context.l10n.homeChooseJlptTitle,
        description: context.l10n.homeChooseJlptDescription,
        actionLabel: context.l10n.homeChooseJlptAction,
        tone: AppFeatureTones.brand,
        onPressed: onOpenLearning,
      );
    }

    final snapshot = learningState.requireValue;
    if (!snapshot.hasCurrentLesson) {
      return _FeatureCard(
        key: const ValueKey<String>('home_view_roadmap_card'),
        icon: Icons.route_outlined,
        icon3d: Sakura3DIconType.roadmap,
        title: context.l10n.homeRoadmapProgressTitle,
        description: context.l10n.homeRoadmapProgressDescription,
        actionLabel: context.l10n.viewRoadmap,
        tone: AppFeatureTones.learning,
        onPressed: onOpenLearning,
      );
    }

    final lesson = snapshot.currentLesson;
    final lessonDisplayTitle = _formatLessonTitle(lesson);

    return RikiCard(
      key: const ValueKey<String>('home_continue_learning_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraCard,
      borderRadius: AppRadius.cardLarge,
      padding: const EdgeInsets.all(AppSpacing.space4),
      onTap: onOpenLearning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Sakura3DIcon(
                type: SakuraIconMapper.iconForLesson(
                  title: lessonDisplayTitle,
                  topic: lesson.category,
                  contentType: lesson.category,
                ),
                size: 46,
                fallbackColor: AppColors.pastelOrangeFg,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  lessonDisplayTitle,
                  key: const ValueKey<String>('home_current_lesson_title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              _LevelPill(label: snapshot.jlptTarget.label),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _ProgressBar(
                  value: lesson.progress,
                  tone: AppFeatureTones.learning,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${lesson.progressPercent}%',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          RikiPrimaryButton(
            key: const ValueKey<String>('home_continue_learning_button'),
            label: context.l10n.continueStudy,
            trailingIcon: Icons.arrow_forward,
            onPressed: onOpenLearning,
          ),
        ],
      ),
    );
  }

  static String _formatLessonTitle(CurrentLessonSummary lesson) {
    final trimmed = lesson.title.trim();
    if (trimmed.isEmpty) {
      return lesson.lessonNumber > 0 ? 'Bài ${lesson.lessonNumber}' : '';
    }
    final hasLessonPrefix =
        RegExp(
          r'^(?:bài\s*(?:học\s*)?|lesson\s*|第\s*)\d+',
          caseSensitive: false,
        ).hasMatch(trimmed) ||
        RegExp(
          r'^(?:bài\s*(?:học\s*)?|lesson\s*)[:\-\s]',
          caseSensitive: false,
        ).hasMatch(trimmed);

    if (hasLessonPrefix) {
      return trimmed;
    }
    if (lesson.lessonNumber > 0) {
      return 'Bài ${lesson.lessonNumber}: $trimmed';
    }
    return trimmed;
  }
}

// -----------------------------------------------------------------------------
// 3. Compact Real Learning Progress Display
// -----------------------------------------------------------------------------
class _LocalProgressSection extends StatelessWidget {
  const _LocalProgressSection({
    required this.journeyState,
    required this.learningState,
    required this.onOpenRoadmap,
    required this.onRetry,
  });

  final AsyncValue<LearnerJourneyState> journeyState;
  final AsyncValue<LearningSnapshot> learningState;
  final VoidCallback onOpenRoadmap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (journeyState.isLoading || learningState.isLoading) {
      return const _SectionSkeleton(key: ValueKey('home_progress_loading'));
    }
    if (journeyState.hasError || learningState.hasError) {
      return _CompactError(
        title: context.l10n.homeSectionUnavailable,
        onRetry: onRetry,
      );
    }

    final journey = journeyState.requireValue;
    if (!journey.hasSelectedLevel) return const SizedBox.shrink();

    final snapshot = learningState.requireValue;

    return RikiCard(
      key: const ValueKey<String>('home_local_progress_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraCard,
      borderRadius: AppRadius.cardLarge,
      padding: const EdgeInsets.all(AppSpacing.space4),
      onTap: onOpenRoadmap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SakuraProgressRing(
                progress: snapshot.overallProgress,
                size: 46,
                strokeWidth: 4.5,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.l10n.homeRoadmapProgressTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        _LevelPill(label: snapshot.jlptTarget.label),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.homeRoadmapProgressDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.metadata,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            context.l10n.homeRoadmapProgressValue(
              snapshot.completedLessons,
              snapshot.totalLessons,
              snapshot.overallPercent,
            ),
            key: const ValueKey<String>('home_local_progress_value'),
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.learnerTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          _ProgressBar(
            value: snapshot.overallProgress,
            tone: AppFeatureTones.learning,
          ),
          const SizedBox(height: AppSpacing.space2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey<String>('home_view_roadmap_button'),
              onPressed: onOpenRoadmap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(context.l10n.viewRoadmap),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Quick Action Categories (4 buttons)
// -----------------------------------------------------------------------------
class _QuickActionCategories extends StatelessWidget {
  const _QuickActionCategories({
    required this.onOpenRoadmap,
    required this.onOpenVocabulary,
    required this.onOpenGrammar,
    required this.onOpenPractice,
  });

  final VoidCallback onOpenRoadmap;
  final VoidCallback onOpenVocabulary;
  final VoidCallback onOpenGrammar;
  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SakuraCategoryShortcut(
            label: context.l10n.homeQuickStudy,
            icon: Icons.school_outlined,
            icon3d: Sakura3DIconType.roadmap,
            backgroundColor: AppColors.pastelGreenBg,
            foregroundColor: AppColors.pastelGreenFg,
            borderColor: AppColors.pastelGreenBorder,
            onTap: onOpenRoadmap,
          ),
        ),
        Expanded(
          child: SakuraCategoryShortcut(
            label: context.l10n.homeQuickVocabulary,
            icon: Icons.auto_stories_outlined,
            icon3d: Sakura3DIconType.vocabulary,
            backgroundColor: AppColors.pastelBlueBg,
            foregroundColor: AppColors.pastelBlueFg,
            borderColor: AppColors.pastelBlueBorder,
            onTap: onOpenVocabulary,
          ),
        ),
        Expanded(
          child: SakuraCategoryShortcut(
            label: context.l10n.homeQuickGrammar,
            icon: Icons.format_list_bulleted_outlined,
            icon3d: Sakura3DIconType.grammar,
            backgroundColor: AppColors.pastelOrangeBg,
            foregroundColor: AppColors.pastelOrangeFg,
            borderColor: AppColors.pastelOrangeBorder,
            onTap: onOpenGrammar,
          ),
        ),
        Expanded(
          child: SakuraCategoryShortcut(
            label: context.l10n.homeQuickListening,
            icon: Icons.headphones_outlined,
            icon3d: Sakura3DIconType.speech,
            backgroundColor: AppColors.pastelPurpleBg,
            foregroundColor: AppColors.pastelPurpleFg,
            borderColor: AppColors.pastelPurpleBorder,
            onTap: onOpenPractice,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 6. Study Categories Section (Bảng chữ cái, Ngữ pháp)
// -----------------------------------------------------------------------------
class _StudyCategoriesSection extends StatelessWidget {
  const _StudyCategoriesSection({
    required this.onOpenWriting,
    required this.onOpenGrammar,
    required this.onOpenRoadmap,
  });

  final VoidCallback onOpenWriting;
  final VoidCallback onOpenGrammar;
  final VoidCallback onOpenRoadmap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.homeLearningCategories,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            InkWell(
              onTap: onOpenRoadmap,
              borderRadius: BorderRadius.circular(AppRadius.compact),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  context.l10n.viewAll,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _CategoryShowcaseCard(
                glyph: 'あ',
                icon3d: Sakura3DIconType.kana,
                title: context.l10n.homeAlphabetShortcutTitle,
                subtitle: context.l10n.homeAlphabetShortcutSubtitle,
                glyphColor: AppColors.pastelBlueFg,
                glyphBgColor: AppColors.pastelBlueBg,
                onTap: onOpenWriting,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _CategoryShowcaseCard(
                icon: Icons.temple_buddhist_outlined,
                icon3d: Sakura3DIconType.grammar,
                title: context.l10n.homeGrammarShortcutTitle,
                subtitle: context.l10n.homeGrammarShortcutSubtitle,
                glyphColor: AppColors.brandPrimary,
                glyphBgColor: AppColors.brandTint,
                onTap: onOpenGrammar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryShowcaseCard extends StatelessWidget {
  const _CategoryShowcaseCard({
    required this.title,
    required this.subtitle,
    required this.glyphColor,
    required this.glyphBgColor,
    required this.onTap,
    this.glyph,
    this.icon,
    this.icon3d,
  });

  final String title;
  final String subtitle;
  final Color glyphColor;
  final Color glyphBgColor;
  final VoidCallback onTap;
  final String? glyph;
  final IconData? icon;
  final Sakura3DIconType? icon3d;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space4),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: null,
      boxShadow: AppShadows.sakuraCard,
      borderRadius: AppRadius.cardSmooth,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon3d != null)
            Sakura3DIcon(type: icon3d!, size: 46, fallbackColor: glyphColor)
          else
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: glyphBgColor,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: glyph != null
                  ? Text(
                      glyph!,
                      style: TextStyle(
                        color: glyphColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    )
                  : Icon(icon, color: glyphColor, size: 22),
            ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.metadata.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. Analytics Section
// -----------------------------------------------------------------------------
class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.state,
    required this.roadmapState,
    required this.onOpen,
    required this.onOpenRoadmap,
    required this.onOpenCalendarDate,
    required this.onRetry,
  });

  final AsyncValue<LearnerAnalytics> state;
  final AsyncValue<StandardRoadmap>? roadmapState;
  final VoidCallback onOpen;
  final VoidCallback onOpenRoadmap;
  final ValueChanged<DateTime>? onOpenCalendarDate;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          title: context.l10n.homeLiveProgressTitle,
          actionLabel: context.l10n.homeViewProgress,
          onAction: onOpen,
        ),
        const SizedBox(height: AppSpacing.space3),
        if (state.isLoading)
          const _SectionSkeleton(key: ValueKey('home_analytics_loading'))
        else if (state.hasError)
          _CompactError(
            key: const ValueKey<String>('home_analytics_error'),
            title: context.l10n.homeAnalyticsUnavailable,
            onRetry: onRetry,
          )
        else
          _AnalyticsSummary(
            data: state.requireValue,
            roadmapState: roadmapState,
            onOpenRoadmap: onOpenRoadmap,
            onOpenCalendarDate: onOpenCalendarDate,
          ),
      ],
    );
  }
}

class _AnalyticsSummary extends StatelessWidget {
  const _AnalyticsSummary({
    required this.data,
    required this.roadmapState,
    required this.onOpenRoadmap,
    required this.onOpenCalendarDate,
  });

  final LearnerAnalytics data;
  final AsyncValue<StandardRoadmap>? roadmapState;
  final VoidCallback onOpenRoadmap;
  final ValueChanged<DateTime>? onOpenCalendarDate;

  @override
  Widget build(BuildContext context) {
    final roadmap = roadmapState?.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) >= 22;
        final hasBothTiles =
            data.isAvailable(AnalyticsSection.streak) && roadmapState != null;
        final stacked =
            constraints.maxWidth < 320 || largeText || !hasBothTiles;

        final tiles = <Widget>[
          if (data.isAvailable(AnalyticsSection.streak))
            _StreakMetricTile(
              key: const ValueKey<String>('home_analytics_streak'),
              streakDays: data.streakDays,
              compact: !stacked,
              onDateSelected: onOpenCalendarDate,
            ),
          if (roadmapState != null)
            _CompletionMetricTile(
              key: const ValueKey<String>('home_analytics_completion'),
              completed: roadmap?.completedLessons,
              total: roadmap?.totalLessons,
              isLoading: roadmapState!.isLoading,
              isError: roadmapState!.hasError,
              onTap: onOpenRoadmap,
            ),
        ];

        final skillTile =
            data.isAvailable(AnalyticsSection.skills) && data.skills.isNotEmpty
            ? _MetricTile(
                key: const ValueKey<String>('home_analytics_skill'),
                icon: Icons.auto_graph_outlined,
                icon3d: Sakura3DIconType.kanji,
                tone: AppFeatureTones.learning,
                label: context.l10n.skillBreakdown,
                value: data.skills.first.skill,
              )
            : null;

        if (tiles.isEmpty && skillTile == null) {
          return RikiCard(
            boxShadow: const <BoxShadow>[],
            child: Text(context.l10n.analyticsEmpty),
          );
        }

        final primary = stacked
            ? Column(
                children: [
                  for (var index = 0; index < tiles.length; index++) ...[
                    tiles[index],
                    if (index < tiles.length - 1)
                      const SizedBox(height: AppSpacing.space2),
                  ],
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(child: tiles[1]),
                  ],
                ),
              );
        if (skillTile == null) return primary;
        if (tiles.isEmpty) return skillTile;
        return Column(
          children: [
            primary,
            const SizedBox(height: AppSpacing.space2),
            skillTile,
          ],
        );
      },
    );
  }
}

class _StreakMetricTile extends StatelessWidget {
  const _StreakMetricTile({
    required this.streakDays,
    required this.onDateSelected,
    this.compact = false,
    super.key,
  });

  final int streakDays;
  final ValueChanged<DateTime>? onDateSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: 10,
      ),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraSubtle,
      borderRadius: AppRadius.cardSmooth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const _IconTile(
                icon: Icons.local_fire_department_outlined,
                icon3d: Sakura3DIconType.streak,
                compact: true,
                tone: AppFeatureTones.streak,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.studyStreakLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.metadata.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      context.l10n.streakDaysValue(streakDays),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SakuraDayTracker(
            compact: true,
            onDateSelected: onDateSelected,
          ),
        ],
      ),
    );
  }
}

class _CompletionMetricTile extends StatelessWidget {
  const _CompletionMetricTile({
    required this.completed,
    required this.total,
    required this.isLoading,
    required this.isError,
    required this.onTap,
    super.key,
  });

  final int? completed;
  final int? total;
  final bool isLoading;
  final bool isError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = completed ?? 0;
    final scope = total ?? 0;
    final progress = scope <= 0 ? 0.0 : (count / scope).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return RikiCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: 10,
      ),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraSubtle,
      borderRadius: AppRadius.cardSmooth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const _IconTile(
                icon: Icons.task_alt_outlined,
                icon3d: Sakura3DIconType.achievement,
                compact: true,
                tone: AppFeatureTones.success,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.completedLessonsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.metadata.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isLoading || isError
                          ? '—'
                          : context.l10n.analyticsCompletedLessons(
                              count,
                              scope,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 260),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(5),
                  color: AppColors.brandPrimary,
                  backgroundColor: AppColors.surfaceMuted,
                  semanticsLabel: context.l10n.completedLessonsLabel,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ',
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.learnerTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isLoading || isError ? '—' : '$percent%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.badgeText.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeSections extends StatelessWidget {
  const _PracticeSections({
    required this.state,
    required this.dailyReviewState,
    required this.onOpenReview,
    required this.onOpenPractice,
    required this.onRetry,
  });

  final AsyncValue<DemoPracticeState> state;
  final AsyncValue<DailyReviewState> dailyReviewState;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenPractice;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const _SectionSkeleton(key: ValueKey('home_practice_loading'));
    }
    if (state.hasError) {
      return _CompactError(
        key: const ValueKey<String>('home_practice_error'),
        title: context.l10n.practiceLoadFailed,
        onRetry: onRetry,
      );
    }
    final dailyReview = dailyReviewState.value;
    final cards = <Widget>[
      SakuraNavigationCard(
        key: const ValueKey<String>('home_daily_review_card'),
        icon3d: Sakura3DIconType.flashcards,
        fallbackIcon: Icons.style_outlined,
        title: context.l10n.dailyReviewTitle,
        description: context.l10n.homeReviewDescription,
        badge:
            (dailyReview != null &&
                dailyReview.currentIndex > 0 &&
                !dailyReview.isComplete)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.borderSubtlePink,
                    width: 1,
                  ),
                ),
                child: Text(
                  context.l10n.homeResumeReview,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        onTap: onOpenReview,
      ),
      SakuraNavigationCard(
        key: const ValueKey<String>('home_start_practice_card'),
        icon3d: Sakura3DIconType.mockExam,
        fallbackIcon: Icons.quiz_outlined,
        title: context.l10n.homePracticeTitle,
        description: context.l10n.practiceJourneySubtitle,
        onTap: onOpenPractice,
      ),
    ];

    return Column(
      children: [
        cards.first,
        const SizedBox(height: AppSpacing.space3),
        cards.last,
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 9. Notebook Shortcut
// -----------------------------------------------------------------------------
class _NotebookShortcut extends StatelessWidget {
  const _NotebookShortcut({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SakuraNavigationCard(
      key: const ValueKey<String>('home_notebook_shortcut'),
      icon3d: Sakura3DIconType.notebook,
      fallbackIcon: Icons.bookmark_outline,
      title: context.l10n.homeNotebookShortcutTitle,
      description: context.l10n.homeNotebookShortcutDescription,
      onTap: onPressed,
    );
  }
}

// -----------------------------------------------------------------------------
// Helper primitives & cards
// -----------------------------------------------------------------------------
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.tone,
    required this.onPressed,
    this.icon3d,
    super.key,
  });

  final IconData icon;
  final Sakura3DIconType? icon3d;
  final String title;
  final String description;
  final String actionLabel;
  final RikiFeatureTone tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space4),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: null,
      boxShadow: AppShadows.sakuraCard,
      borderRadius: AppRadius.cardLarge,
      onTap: onPressed,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(icon: icon, icon3d: icon3d, compact: true, tone: tone),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.space1),
                    Text(description, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          );
          final action = TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(foregroundColor: tone.foreground),
            child: Text(actionLabel),
          );

          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: AppSpacing.space2),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: AppSpacing.space2),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.icon3d,
    super.key,
  });

  final IconData icon;
  final Sakura3DIconType? icon3d;
  final String label;
  final String value;
  final RikiFeatureTone tone;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      borderRadius: AppRadius.cardSmooth,
      child: Row(
        children: [
          _IconTile(icon: icon, icon3d: icon3d, compact: true, tone: tone),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.metadata,
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(16) >= 26) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.sectionTitle)),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _CompactError extends StatelessWidget {
  const _CompactError({required this.title, required this.onRetry, super.key});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RikiErrorBanner(
          title: title,
          message: context.l10n.checkConnectionRetry,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(context.l10n.retry),
          ),
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const RikiShimmer(
      child: RikiCard(
        boxShadow: <BoxShadow>[],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RikiSkeleton(width: 160, height: 20),
            SizedBox(height: AppSpacing.space3),
            RikiSkeleton(height: 16),
            SizedBox(height: AppSpacing.space2),
            RikiSkeleton(width: 220, height: 16),
            SizedBox(height: AppSpacing.space4),
            RikiSkeleton(height: 44),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    this.icon3d,
    this.compact = false,
    this.tone = AppFeatureTones.brand,
  });

  final IconData icon;
  final Sakura3DIconType? icon3d;
  final bool compact;
  final RikiFeatureTone tone;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 46.0;
    return RikiFeatureIcon(
      icon: icon,
      icon3d: icon3d,
      tone: tone,
      extent: size,
      iconSize: compact ? 19 : 22,
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.learnerPrimaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: AppColors.brandPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.tone});

  final double value;
  final RikiFeatureTone tone;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        color: tone.foreground,
        backgroundColor: tone.background,
      ),
    );
  }
}
