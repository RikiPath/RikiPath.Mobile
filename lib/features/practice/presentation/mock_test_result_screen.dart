import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';

class MockTestResultScreen extends ConsumerWidget {
  const MockTestResultScreen({required this.testId, super.key});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(demoPracticeControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.mockResultTitle),
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.practice),
          icon: const Icon(Icons.close),
        ),
      ),
      body: practice.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.mockLoadingTitle),
        error: (_, _) => RikiErrorState(
          title: context.l10n.mockLoadFailed,
          message: context.l10n.checkConnectionRetry,
          actionLabel: context.l10n.retry,
          onAction: ref.read(demoPracticeControllerProvider.notifier).retry,
        ),
        data: (state) {
          final result = state.mockResult;
          if (result == null || state.mockTest.id != testId) {
            return RikiEmptyState(
              icon: Icons.assignment_outlined,
              title: context.l10n.mockResultTitle,
              message: context.l10n.mockResultUnavailable,
            );
          }
          return ListView(
            key: const ValueKey<String>('mock_test_result_view'),
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              RikiCard(
                borderColor: AppColors.successBorder,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.successBackground,
                      foregroundColor: AppColors.success,
                      child: Icon(Icons.emoji_events_outlined, size: 34),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      '${result.percentage}%',
                      style: AppTypography.heroTitle.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      context.l10n.mockCorrectCount(result.score, result.total),
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '${state.mockTest.title} • ${state.mockTest.level}',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.learnerTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      context.l10n.mockLocalResultNotice,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              RikiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.sectionBreakdown,
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    for (final entry in result.sectionScores.entries)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space2,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Text(
                              context.l10n.mockSectionResult(
                                entry.value,
                                result.sectionTotals[entry.key] ?? 0,
                                result.sectionPercentage(entry.key),
                              ),
                              style: AppTypography.cardTitle,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              RikiPrimaryButton(
                key: const ValueKey<String>('mock_detailed_review_button'),
                label: context.l10n.detailedReview,
                trailingIcon: Icons.arrow_forward,
                onPressed: () =>
                    context.push(AppRoutes.mockTestDetailedReview(testId)),
              ),
              const SizedBox(height: AppSpacing.space2),
              RikiSecondaryButton(
                key: const ValueKey<String>('mock_test_retake_button'),
                label: context.l10n.retakeMockTest,
                leadingIcon: Icons.replay,
                onPressed: () async {
                  await ref
                      .read(demoPracticeControllerProvider.notifier)
                      .prepareMockRetake();
                  if (context.mounted) {
                    context.go(AppRoutes.mockTest(testId));
                  }
                },
              ),
              const SizedBox(height: AppSpacing.space2),
              RikiSecondaryButton(
                label: context.l10n.backToPractice,
                onPressed: () => context.go(AppRoutes.practice),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MockTestDetailedReviewScreen extends ConsumerWidget {
  const MockTestDetailedReviewScreen({required this.testId, super.key});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(demoPracticeControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.detailedReview)),
      body: practice.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.mockLoadingTitle),
        error: (_, _) => RikiErrorState(
          title: context.l10n.mockLoadFailed,
          message: context.l10n.checkConnectionRetry,
          actionLabel: context.l10n.retry,
          onAction: ref.read(demoPracticeControllerProvider.notifier).retry,
        ),
        data: (state) {
          final result = state.mockResult;
          final resultAttempt = state.mockResultAttempt;
          if (result == null ||
              resultAttempt == null ||
              state.mockTest.id != testId) {
            return RikiEmptyState(
              icon: Icons.fact_check_outlined,
              title: context.l10n.detailedReview,
              message: context.l10n.mockResultUnavailable,
            );
          }
          return ListView.separated(
            key: const ValueKey<String>('mock_detailed_review_view'),
            padding: const EdgeInsets.all(AppSpacing.space4),
            itemCount: state.mockTest.questions.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.space3),
            itemBuilder: (context, index) {
              final question = state.mockTest.questions[index];
              final selectedId = resultAttempt.answers[question.id];
              final selected = question.options
                  .where((option) => option.id == selectedId)
                  .firstOrNull;
              final correct = question.options
                  .where((option) => option.id == question.correctOptionId)
                  .first;
              final isCorrect = selectedId == question.correctOptionId;
              return RikiCard(
                borderColor: isCorrect
                    ? AppColors.successBorder
                    : AppColors.errorBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.questionNumber(index + 1),
                      style: AppTypography.badgeText.copyWith(
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.errorText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(question.prompt, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      context.l10n.selectedAnswer(
                        selected?.label ?? context.l10n.notAnswered,
                      ),
                    ),
                    Text(context.l10n.correctAnswer(correct.label)),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      question.explanation,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.learnerTextSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
