import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final TextEditingController _gradingController = TextEditingController(
    text: '昨日、本を読んだり、音楽を聞いたりしました。',
  );

  @override
  void dispose() {
    _gradingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(demoPracticeControllerProvider);
    final analyticsState = ref.watch(learnerAnalyticsControllerProvider);
    final notificationState = ref.watch(notificationControllerProvider);
    final analytics = analyticsState.value;
    final liveStreak = analytics?.isAvailable(AnalyticsSection.streak) == true
        ? analytics?.streakDays
        : null;
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: HomeHeader(
        streakDays: liveStreak,
        isStreakLoading: analyticsState.isLoading,
        unreadNotificationCount: notificationState.value?.unreadCount,
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: practice.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.practiceLoadingTitle),
        error: (_, _) => _PracticeError(
          onRetry: ref.read(demoPracticeControllerProvider.notifier).retry,
        ),
        data: (state) => ListView(
          key: const ValueKey<String>('practice_landing_view'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          children: [
            Text(
              context.l10n.practiceJourneyTitle,
              style: AppTypography.pageTitle,
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              context.l10n.practiceJourneySubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.learnerTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            _PracticeEntryCard(
              key: const ValueKey<String>('practice_daily_review_card'),
              icon: Icons.style_outlined,
              title: context.l10n.dailyReviewTitle,
              description: state.isReviewComplete
                  ? context.l10n.reviewCompleteCount(state.reviewAnswers.length)
                  : context.l10n.reviewDueCount(state.reviewQueue.length),
              tone: AppFeatureTones.review,
              status: context.l10n.reviewProgress(
                state.reviewIndex.clamp(0, state.reviewQueue.length),
                state.reviewQueue.length,
              ),
              onPressed: () => context.push(AppRoutes.dailyReview),
            ),
            const SizedBox(height: AppSpacing.space3),
            _PracticeEntryCard(
              key: const ValueKey<String>('practice_mock_test_card'),
              icon: Icons.assignment_outlined,
              title: state.mockTest.title,
              description: context.l10n.mockSummary(
                state.mockTest.level,
                state.mockTest.timeLimitMinutes,
                state.mockTest.questions.length,
              ),
              tone: AppFeatureTones.practice,
              status: _mockStatus(context, state),
              onPressed: () => context.push(
                state.hasActiveMockAttempt || !state.hasRecentMockResult
                    ? AppRoutes.mockTest(state.mockTest.id)
                    : AppRoutes.mockTestResult(state.mockTest.id),
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            Text(
              context.l10n.practiceStudioTitle,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              context.l10n.practiceStudioSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.learnerTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _PracticeEntryCard(
              key: const ValueKey<String>('practice_speech_card'),
              icon: Icons.record_voice_over_outlined,
              title: context.l10n.practiceSpeechTitle,
              description: context.l10n.practiceSpeechDescription,
              tone: AppFeatureTones.speech,
              status: context.l10n.practiceSpeechStatus,
              onPressed: () => context.push(AppRoutes.speechPractice),
            ),
            const SizedBox(height: AppSpacing.space3),
            _PracticeEntryCard(
              key: const ValueKey<String>('practice_writing_card'),
              icon: Icons.draw_outlined,
              title: context.l10n.practiceWritingTitle,
              description: context.l10n.practiceWritingDescription,
              tone: AppFeatureTones.writing,
              status: context.l10n.practiceWritingStatus,
              onPressed: () => context.push(AppRoutes.writingHiragana),
            ),
            const SizedBox(height: AppSpacing.space3),
            _PracticeEntryCard(
              key: const ValueKey<String>('practice_text_scan_card'),
              icon: Icons.document_scanner_outlined,
              title: context.l10n.practiceTextScanTitle,
              description: context.l10n.practiceTextScanDescription,
              tone: AppFeatureTones.textScan,
              status: context.l10n.practiceTextScanStatus,
              onPressed: () => context.push(AppRoutes.textScan),
            ),
            const SizedBox(height: AppSpacing.space5),
            Text(
              context.l10n.additionalPractice,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            _AiGradingCard(
              state: state,
              controller: _gradingController,
              onSubmit: () => ref
                  .read(demoPracticeControllerProvider.notifier)
                  .submitAiGrading(_gradingController.text),
            ),
            const SizedBox(height: AppSpacing.space3),
            _MentorDemoCard(state: state),
          ],
        ),
      ),
    );
  }

  String _mockStatus(BuildContext context, DemoPracticeState state) {
    return switch (state.mockSessionStatus) {
      DemoMockSessionStatus.notStarted => context.l10n.notStarted,
      DemoMockSessionStatus.inProgress => context.l10n.mockInProgress(
        state.answeredQuestionCount,
        state.mockTest.questions.length,
      ),
      DemoMockSessionStatus.submitted => context.l10n.mockCompletedStatus(
        state.mockResult?.percentage ?? 0,
      ),
    };
  }
}

class _PracticeEntryCard extends StatelessWidget {
  const _PracticeEntryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
    required this.status,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final RikiFeatureTone tone;
  final String status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      onTap: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RikiFeatureIcon(icon: icon, tone: tone),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RikiStatusPill(label: status, tone: tone),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _AiGradingCard extends StatelessWidget {
  const _AiGradingCard({
    required this.state,
    required this.controller,
    required this.onSubmit,
  });

  final DemoPracticeState state;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final result = state.gradingResult;
    final loading = state.gradingStatus == DemoGradingStatus.processing;
    return RikiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RikiFeatureIcon(
                icon: Icons.auto_awesome_outlined,
                tone: AppFeatureTones.ai,
                extent: 40,
                iconSize: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  context.l10n.aiWritingPractice,
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.practiceAnswerLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          RikiPrimaryButton(
            key: const ValueKey<String>('ai_grading_submit_button'),
            label: context.l10n.gradePractice,
            loadingLabel: context.l10n.gradingPractice,
            isLoading: loading,
            onPressed: onSubmit,
          ),
          if (result != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              context.l10n.aiGradingResult(result.score, result.feedback),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MentorDemoCard extends ConsumerWidget {
  const _MentorDemoCard({required this.state});

  final DemoPracticeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = state.mentorPlans.firstOrNull;
    final slot = state.mentorSlots.firstOrNull;
    if (plan == null || slot == null) return const SizedBox.shrink();
    final controller = ref.read(demoPracticeControllerProvider.notifier);
    return RikiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RikiFeatureIcon(
                icon: Icons.support_agent_outlined,
                tone: AppFeatureTones.meeting,
                extent: 40,
                iconSize: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  context.l10n.mentorConsultation,
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${plan.name}\n${slot.mentorName} • ${slot.timeLabel}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space3),
          if (state.bookingStatus == DemoBookingStatus.idle)
            RikiSecondaryButton(
              key: const ValueKey<String>('demo_checkout_button'),
              label: context.l10n.openDemoBooking,
              onPressed: controller.beginDemoCheckout,
            )
          else if (state.bookingStatus == DemoBookingStatus.checkout)
            RikiPrimaryButton(
              key: const ValueKey<String>('demo_payment_success_button'),
              label: context.l10n.confirmDemoBooking,
              onPressed: controller.confirmDemoBooking,
            )
          else
            Text(
              context.l10n.demoBookingConfirmed,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _PracticeError extends StatelessWidget {
  const _PracticeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      title: context.l10n.practiceLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
    );
  }
}
