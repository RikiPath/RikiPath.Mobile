import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
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
  final VoidCallback onOpenMeeting;
  final ValueChanged<int> onOpenMeetingDetail;
  final ValueChanged<Uri> onJoinMeeting;
  final VoidCallback? onOpenVocabulary;
  final VoidCallback? onOpenGrammar;
  final VoidCallback? onOpenWriting;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefreshLive,
      color: AppColors.brandPrimary,
      semanticsLabel: context.l10n.homeRefreshSemantics,
      child: ListView(
        key: const ValueKey<String>('home_success_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: [
          // 1. Welcoming personalized learner header
          _GreetingSection(state: dashboardState, onRetry: onRetryHome),
          const SizedBox(height: AppSpacing.space4),

          // 2. Primary Continue Learning action (dominant study action)
          _ContinueLearningSection(
            journeyState: journeyState,
            learningState: learningState,
            onOpenLearning: onOpenLearning,
            onRetry: onRetryLearning,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 3. Compact real learning-progress display
          _LocalProgressSection(
            journeyState: journeyState,
            learningState: learningState,
            onOpenRoadmap: onOpenRoadmap,
            onRetry: onRetryLearning,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 4. Learning Analytics & streak/skill breakdown
          _AnalyticsSection(
            state: analyticsState,
            onOpen: onOpenAnalytics,
            onRetry: onRetryAnalytics,
          ),
          const SizedBox(height: AppSpacing.space5),

          // 5. Quick feature category shortcuts (Học tập, Từ vựng, Ngữ pháp, Luyện nghe)
          _QuickActionCategories(
            onOpenRoadmap: onOpenRoadmap,
            onOpenVocabulary: onOpenVocabulary ?? onOpenLearning,
            onOpenGrammar: onOpenGrammar ?? onOpenLearning,
            onOpenPractice: onOpenPractice,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 6. Daily encouragement Sakura banner
          SakuraMotivationBanner(
            title: context.l10n.homeDailyMotivation,
            subtitle: context.l10n.homeDailyMotivationSubtitle,
            onTap: onOpenLearning,
          ),
          const SizedBox(height: AppSpacing.space5),

          // 7. Study Categories (Bảng chữ cái, Ngữ pháp)
          _StudyCategoriesSection(
            onOpenWriting: onOpenWriting ?? onOpenPractice,
            onOpenGrammar: onOpenGrammar ?? onOpenLearning,
            onOpenRoadmap: onOpenRoadmap,
          ),
          const SizedBox(height: AppSpacing.space5),

          // 8. Practice & Daily Review
          _PracticeSections(
            state: practiceState,
            dailyReviewState: dailyReviewState,
            onOpenReview: onOpenReview,
            onOpenPractice: onOpenPractice,
            onRetry: onRetryPractice,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 9. Meeting section
          MeetingHomeSection(
            state: upcomingMeetingState,
            onOpenMeeting: onOpenMeeting,
            onOpenDetail: onOpenMeetingDetail,
            onJoin: onJoinMeeting,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 10. Notebook shortcut
          _NotebookShortcut(onPressed: onOpenNotebook),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. Welcoming Greeting
// -----------------------------------------------------------------------------
class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.state, required this.onRetry});

  final AsyncValue<HomeDashboard> state;
  final VoidCallback onRetry;

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
      data: (dashboard) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.sakuraHeroGradient,
              borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
              border: Border.all(color: AppColors.borderSubtlePink, width: 1.5),
            ),
            child: const SakuraBlossomMark(size: 24),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.greetingName(dashboard.learnerName),
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
                  context.l10n.practiceJourneySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                    fontSize: 12,
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
        title: context.l10n.homeRoadmapProgressTitle,
        description: context.l10n.homeRoadmapProgressDescription,
        actionLabel: context.l10n.viewRoadmap,
        tone: AppFeatureTones.learning,
        onPressed: onOpenLearning,
      );
    }

    final lesson = snapshot.currentLesson;

    return RikiCard(
      key: const ValueKey<String>('home_continue_learning_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraCard,
      borderRadius: AppRadius.cardLarge,
      padding: const EdgeInsets.all(AppSpacing.space5),
      onTap: onOpenLearning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.pastelOrangeBg,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: AppColors.pastelOrangeBorder,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.pastelOrangeFg,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  context.l10n.homeContinueLearningTitle,
                  style: AppTypography.sectionTitle,
                ),
              ),
              _LevelPill(label: snapshot.jlptTarget.label),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            lesson.title,
            key: const ValueKey<String>('home_current_lesson_title'),
            style: AppTypography.cardTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            lesson.durationMinutes > 0
                ? context.l10n.homeCurrentLessonMeta(
                    lesson.lessonNumber,
                    lesson.durationMinutes,
                  )
                : context.l10n.homeCurrentLessonLabel(lesson.lessonNumber),
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space4),
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
          const SizedBox(height: AppSpacing.space4),
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
  });

  final String title;
  final String subtitle;
  final Color glyphColor;
  final Color glyphBgColor;
  final VoidCallback onTap;
  final String? glyph;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space4),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraCard,
      borderRadius: AppRadius.cardSmooth,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
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
    required this.onOpen,
    required this.onRetry,
  });

  final AsyncValue<LearnerAnalytics> state;
  final VoidCallback onOpen;
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
          _AnalyticsSummary(data: state.requireValue),
      ],
    );
  }
}

class _AnalyticsSummary extends StatelessWidget {
  const _AnalyticsSummary({required this.data});

  final LearnerAnalytics data;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (data.isAvailable(AnalyticsSection.streak))
        _StreakMetricTile(
          key: const ValueKey<String>('home_analytics_streak'),
          streakDays: data.streakDays,
        ),
      if (data.isAvailable(AnalyticsSection.completion))
        _MetricTile(
          key: const ValueKey<String>('home_analytics_completion'),
          icon: Icons.task_alt_outlined,
          tone: AppFeatureTones.success,
          label: context.l10n.completedLessonsLabel,
          value: context.l10n.analyticsCompletedLessons(
            data.completedLessons,
            data.totalLessons,
          ),
        ),
      if (data.isAvailable(AnalyticsSection.skills) && data.skills.isNotEmpty)
        _MetricTile(
          key: const ValueKey<String>('home_analytics_skill'),
          icon: Icons.auto_graph_outlined,
          tone: AppFeatureTones.learning,
          label: context.l10n.skillBreakdown,
          value: data.skills.first.skill,
        ),
    ];

    if (tiles.isEmpty) {
      return RikiCard(
        boxShadow: const <BoxShadow>[],
        child: Text(context.l10n.analyticsEmpty),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 350 || tiles.length == 1) {
          return Column(
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                tiles[index],
                if (index < tiles.length - 1)
                  const SizedBox(height: AppSpacing.space2),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.space2) / 2,
                child: tile,
              ),
          ],
        );
      },
    );
  }
}

class _StreakMetricTile extends StatelessWidget {
  const _StreakMetricTile({required this.streakDays, super.key});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraSubtle,
      borderRadius: AppRadius.cardSmooth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(
                icon: Icons.local_fire_department_outlined,
                compact: true,
                tone: AppFeatureTones.review,
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
                      style: AppTypography.metadata,
                    ),
                    Text(
                      context.l10n.streakDaysValue(streakDays),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          SakuraDayTracker(streakDays: streakDays),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 8. Practice & Daily Review
// -----------------------------------------------------------------------------
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
    final reviewAction =
        dailyReview != null &&
            dailyReview.currentIndex > 0 &&
            !dailyReview.isComplete
        ? context.l10n.homeResumeReview
        : context.l10n.homeReviewNow;

    final cards = <Widget>[
      _ActionCard(
        key: const ValueKey<String>('home_daily_review_card'),
        icon: Icons.style_outlined,
        tone: AppFeatureTones.review,
        title: context.l10n.dailyReviewTitle,
        description: context.l10n.homeReviewDescription,
        actionLabel: reviewAction,
        onPressed: onOpenReview,
      ),
      _ActionCard(
        key: const ValueKey<String>('home_start_practice_card'),
        icon: Icons.quiz_outlined,
        tone: AppFeatureTones.practice,
        title: context.l10n.homePracticeTitle,
        description: context.l10n.practiceJourneySubtitle,
        actionLabel: context.l10n.homeStartPractice,
        onPressed: onOpenPractice,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              cards.first,
              const SizedBox(height: AppSpacing.space3),
              cards.last,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards.first),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: cards.last),
            ],
          ),
        );
      },
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
    return _FeatureCard(
      key: const ValueKey<String>('home_notebook_shortcut'),
      icon: Icons.bookmark_outline,
      title: context.l10n.homeNotebookShortcutTitle,
      description: context.l10n.homeNotebookShortcutDescription,
      actionLabel: context.l10n.navigationNotebook,
      tone: AppFeatureTones.neutral,
      onPressed: onPressed,
      compact: true,
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
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final RikiFeatureTone tone;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: EdgeInsets.all(compact ? AppSpacing.space3 : AppSpacing.space4),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: compact ? const <BoxShadow>[] : AppShadows.sakuraCard,
      borderRadius: AppRadius.cardLarge,
      onTap: onPressed,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(icon: icon, compact: true, tone: tone),
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

          if (constraints.maxWidth < 300) {
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.tone,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
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
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraCard,
      borderRadius: AppRadius.cardSmooth,
      onTap: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, tone: tone),
          const SizedBox(height: AppSpacing.space3),
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.space1),
          Text(description, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.space3),
          TextButton.icon(
            onPressed: onPressed,
            style: TextButton.styleFrom(foregroundColor: tone.foreground),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(actionLabel),
          ),
        ],
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
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final RikiFeatureTone tone;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderSubtle,
      boxShadow: AppShadows.sakuraSubtle,
      borderRadius: AppRadius.cardSmooth,
      child: Row(
        children: [
          _IconTile(icon: icon, compact: true, tone: tone),
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
    this.compact = false,
    this.tone = AppFeatureTones.brand,
  });

  final IconData icon;
  final bool compact;
  final RikiFeatureTone tone;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 44.0;
    return RikiFeatureIcon(
      icon: icon,
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
