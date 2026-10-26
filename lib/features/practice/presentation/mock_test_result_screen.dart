import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';

class MockTestResultScreen extends ConsumerWidget {
  const MockTestResultScreen({required this.testId, super.key});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(mockTestControllerProvider);
    final expectedTestId = int.tryParse(testId);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.mockResultTitle),
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.practice),
          icon: const Icon(Icons.close),
        ),
      ),
      body: flow.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.mockLoadingTitle),
        error: (_, _) => RikiErrorState(
          title: context.l10n.mockLoadFailed,
          message: context.l10n.checkConnectionRetry,
          actionLabel: context.l10n.retry,
          onAction: ref.read(mockTestControllerProvider.notifier).retryCatalog,
        ),
        data: (state) {
          final result = state.result;
          if (result == null || result.mockTestId != expectedTestId) {
            return RikiEmptyState(
              icon: Icons.assignment_outlined,
              title: context.l10n.mockResultTitle,
              message: context.l10n.mockResultUnavailable,
              actionLabel: context.l10n.backToPractice,
              onAction: () => context.go(AppRoutes.practice),
            );
          }
          final test = state.selectedTest;
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
                      '${result.totalScore.round()}%',
                      key: const ValueKey<String>('mock_backend_total_score'),
                      style: AppTypography.heroTitle.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      context.l10n.mockCorrectCount(
                        result.correctCount,
                        result.totalCount,
                      ),
                      style: AppTypography.cardTitle,
                    ),
                    if (test != null) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        '${test.title} • ${test.jlptLevelName}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.learnerTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      context.l10n.mockBackendResultNotice,
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
                    for (final section in result.sections)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space2,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(section.sectionTitle)),
                            Text(
                              context.l10n.mockSectionResult(
                                section.correctCount,
                                section.totalCount,
                                section.score.round(),
                              ),
                              style: AppTypography.cardTitle,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (state.actionIssue != null) ...[
                const SizedBox(height: AppSpacing.space3),
                _ResultActionError(
                  issue: state.actionIssue!,
                  onRetry: ref
                      .read(mockTestControllerProvider.notifier)
                      .loadResult,
                ),
              ],
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
                onPressed: () {
                  ref.read(mockTestControllerProvider.notifier).prepareRetake();
                  context.go(AppRoutes.mockTest(testId));
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

class MockTestDetailedReviewScreen extends ConsumerStatefulWidget {
  const MockTestDetailedReviewScreen({required this.testId, super.key});

  final String testId;

  @override
  ConsumerState<MockTestDetailedReviewScreen> createState() =>
      _MockTestDetailedReviewScreenState();
}

class _MockTestDetailedReviewScreenState
    extends ConsumerState<MockTestDetailedReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mockTestControllerProvider.notifier).loadDetailedResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(mockTestControllerProvider);
    final expectedTestId = int.tryParse(widget.testId);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.detailedReview)),
      body: flow.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.mockLoadingTitle),
        error: (_, _) => RikiErrorState(
          title: context.l10n.mockLoadFailed,
          message: context.l10n.checkConnectionRetry,
          actionLabel: context.l10n.retry,
          onAction: ref.read(mockTestControllerProvider.notifier).retryCatalog,
        ),
        data: (state) {
          if (state.isDetailedLoading) {
            return RikiFullScreenLoader(title: context.l10n.mockLoadingTitle);
          }
          final detailed = state.detailedResult;
          if (detailed == null || detailed.mockTestId != expectedTestId) {
            if (state.actionIssue != null) {
              return _ResultActionError(
                issue: state.actionIssue!,
                onRetry: ref
                    .read(mockTestControllerProvider.notifier)
                    .loadDetailedResult,
              );
            }
            return RikiEmptyState(
              icon: Icons.fact_check_outlined,
              title: context.l10n.detailedReview,
              message: context.l10n.mockResultUnavailable,
            );
          }
          return ListView.separated(
            key: const ValueKey<String>('mock_detailed_review_view'),
            padding: const EdgeInsets.all(AppSpacing.space4),
            itemCount: detailed.questions.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.space3),
            itemBuilder: (context, index) => _ReviewQuestionCard(
              index: index,
              question: detailed.questions[index],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  const _ReviewQuestionCard({required this.index, required this.question});

  final int index;
  final LiveMockTestQuestionReview question;

  @override
  Widget build(BuildContext context) {
    final selected = question.options
        .where((option) => option.id == question.selectedOptionId)
        .firstOrNull;
    final correct = question.options
        .where((option) => option.isCorrect)
        .firstOrNull;
    return RikiCard(
      borderColor: question.isCorrect
          ? AppColors.successBorder
          : AppColors.errorBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.questionNumber(index + 1),
            style: AppTypography.badgeText.copyWith(
              color: question.isCorrect
                  ? AppColors.success
                  : AppColors.errorText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(question.questionText, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.space3),
          Text(
            context.l10n.selectedAnswer(
              selected?.text ?? context.l10n.notAnswered,
            ),
          ),
          Text(
            context.l10n.correctAnswer(
              correct?.text ?? context.l10n.mockAnswerUnavailable,
            ),
          ),
          if (question.explanation?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              question.explanation!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.learnerTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultActionError extends StatelessWidget {
  const _ResultActionError({required this.issue, required this.onRetry});

  final MockTestActionIssue issue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (issue) {
      MockTestActionIssue.expired => context.l10n.mockExpired,
      MockTestActionIssue.alreadyCompleted => context.l10n.mockAlreadyCompleted,
      MockTestActionIssue.networkUncertain => context.l10n.mockNetworkUncertain,
      MockTestActionIssue.conflict => context.l10n.mockAttemptConflict,
      MockTestActionIssue.notFound => context.l10n.mockTestUnavailable,
      MockTestActionIssue.validation => context.l10n.mockValidationFailed,
      MockTestActionIssue.unknown => context.l10n.mockSubmitFailed,
    };
    return RikiErrorState(
      key: ValueKey<String>('mock_result_error_${issue.name}'),
      title: context.l10n.mockActionFailed,
      message: message,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
    );
  }
}
