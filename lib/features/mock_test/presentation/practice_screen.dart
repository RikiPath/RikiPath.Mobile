import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_scroll_scaffold.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/presentation/widgets/practice_hero_banner.dart';

/// The landing page is navigation only. Exams and writing keep their own
/// server-backed flows and do not load a fixture when this page opens.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyReviews = ref.watch(dailyReviewControllerProvider);
    final analyticsState = ref.watch(learnerAnalyticsControllerProvider);
    final notificationState = ref.watch(notificationControllerProvider);
    final analytics = analyticsState.value;
    final liveStreak = analytics?.isAvailable(AnalyticsSection.streak) == true
        ? analytics?.streakDays
        : null;

    return SakuraScrollScaffold(
      backgroundColor: AppColors.learnerBackground,
      appBarBuilder: (context, isScrolled) => HomeHeader(
        isScrolled: isScrolled,
        streakDays: liveStreak,
        isStreakLoading: analyticsState.isLoading,
        unreadNotificationCount: notificationState.value?.unreadCount,
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
        onCalendarPressed: () => context.push(AppRoutes.calendar),
      ),
      body: ListView(
        key: const ValueKey<String>('practice_landing_view'),
        padding: const EdgeInsets.only(bottom: AppSpacing.space8),
        children: [
          const PracticeHeroBanner(
            key: ValueKey<String>('practice_hero_banner'),
          ),
          const SizedBox(height: AppSpacing.space4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Column(
              children: [
                _PracticeEntryCard(
                  key: const ValueKey<String>('practice_mock_library_card'),
                  icon: Icons.assignment_outlined,
                  icon3d: Sakura3DIconType.mockExam,
                  title: context.l10n.mockLibraryTitle,
                  description: context.l10n.mockLibraryDescription,
                  tone: AppFeatureTones.practice,
                  onPressed: () => context.push(AppRoutes.mockTestLibrary),
                ),
                const SizedBox(height: AppSpacing.space3),
                _LiveDailyReviewCard(state: dailyReviews),
                const SizedBox(height: AppSpacing.space3),
                _PracticeEntryCard(
                  key: const ValueKey<String>('practice_essay_writing_card'),
                  icon: Icons.edit_note_outlined,
                  icon3d: Sakura3DIconType.essay,
                  title: context.l10n.essayWritingTitle,
                  description: context.l10n.essayWritingDescription,
                  tone: AppFeatureTones.writing,
                  onPressed: () => context.push(AppRoutes.essayWriting),
                ),
                const SizedBox(height: AppSpacing.space3),
                _PracticeEntryCard(
                  key: const ValueKey<String>('practice_writing_card'),
                  icon: Icons.draw_outlined,
                  icon3d: Sakura3DIconType.brush,
                  title: context.l10n.practiceWritingTitle,
                  description: context.l10n.practiceWritingDescription,
                  tone: AppFeatureTones.writing,
                  onPressed: () => context.push(AppRoutes.writingHiragana),
                ),
                const SizedBox(height: AppSpacing.space3),
                _PracticeEntryCard(
                  key: const ValueKey<String>('practice_speech_card'),
                  icon: Icons.record_voice_over_outlined,
                  icon3d: Sakura3DIconType.speech,
                  title: context.l10n.practiceSpeechTitle,
                  description: context.l10n.practiceSpeechDescription,
                  tone: AppFeatureTones.speech,
                  onPressed: () => context.push(AppRoutes.speechPractice),
                ),
                const SizedBox(height: AppSpacing.space3),
                _PracticeEntryCard(
                  key: const ValueKey<String>('practice_text_scan_card'),
                  icon: Icons.document_scanner_outlined,
                  icon3d: Sakura3DIconType.ocr,
                  title: context.l10n.practiceTextScanTitle,
                  description: context.l10n.practiceTextScanDescription,
                  tone: AppFeatureTones.textScan,
                  onPressed: () => context.push(AppRoutes.textScan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDailyReviewCard extends StatelessWidget {
  const _LiveDailyReviewCard({required this.state});

  final AsyncValue<DailyReviewState> state;

  @override
  Widget build(BuildContext context) {
    final value = state.value;
    final description = state.isLoading
        ? context.l10n.reviewLoadingTitle
        : state.hasError
        ? context.l10n.reviewLoadFailed
        : value!.isComplete
        ? context.l10n.reviewCompleteCount(value.reviewedCount)
        : context.l10n.reviewDueCount(value.cards.length - value.currentIndex);
    final status = value == null
        ? (state.isLoading ? context.l10n.loading : context.l10n.retry)
        : context.l10n.reviewProgress(
            value.currentIndex.clamp(0, value.cards.length),
            value.cards.length,
          );

    return _PracticeEntryCard(
      key: const ValueKey<String>('practice_daily_review_card'),
      icon: Icons.style_outlined,
      icon3d: Sakura3DIconType.srs,
      title: context.l10n.dailyReviewTitle,
      description: description,
      tone: AppFeatureTones.review,
      status: status,
      onPressed: () => context.push(AppRoutes.dailyReview),
    );
  }
}

class _PracticeEntryCard extends StatelessWidget {
  const _PracticeEntryCard({
    required this.icon,
    required this.icon3d,
    required this.title,
    required this.description,
    required this.tone,
    required this.onPressed,
    this.status,
    super.key,
  });

  final IconData icon;
  final Sakura3DIconType icon3d;
  final String title;
  final String description;
  final RikiFeatureTone tone;
  final String? status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final stackStatus = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
    final statusLabel = status;
    return RikiCard(
      onTap: onPressed,
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
          RikiFeatureIcon(icon: icon, icon3d: icon3d, tone: tone),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle,
                      ),
                    ),
                    if (!stackStatus && statusLabel != null) ...[
                      const SizedBox(width: AppSpacing.space2),
                      RikiStatusPill(label: statusLabel, tone: tone),
                    ],
                  ],
                ),
                if (stackStatus && statusLabel != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RikiStatusPill(label: statusLabel, tone: tone),
                  ),
                ],
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
}
