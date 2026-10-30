import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';

class PlacementTestScreen extends ConsumerStatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  ConsumerState<PlacementTestScreen> createState() =>
      _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
  }

  void _syncClockTimer(bool showActiveAttempt) {
    if (!showActiveAttempt) {
      _clockTimer?.cancel();
      _clockTimer = null;
      return;
    }
    if (_clockTimer != null) return;

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final current = ref.read(placementTestControllerProvider).asData?.value;
      if (current?.hasActiveAttempt != true) {
        _clockTimer?.cancel();
        _clockTimer = null;
        return;
      }
      ref.read(placementTestControllerProvider.notifier).expireIfNeeded();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(placementTestControllerProvider);
    final controller = ref.read(placementTestControllerProvider.notifier);
    _syncClockTimer(asyncState.asData?.value.hasActiveAttempt == true);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey<String>('placement_test_back_button'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final status = asyncState.value?.status;
              context.go(
                status?.targetJlptLevelId != null &&
                        status?.targetExamDate != null
                    ? AppRoutes.home
                    : AppRoutes.onboarding,
              );
            }
          },
        ),
        title: Text(
          context.l10n.placementTitle,
          style: AppTypography.sectionTitle,
        ),
      ),
      body: asyncState.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.placementLoading),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: RikiCard(
              key: const ValueKey<String>('placement_test_error_card'),
              boxShadow: const <BoxShadow>[],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.placementLoadErrorTitle,
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    context.l10n.placementLoadErrorDescription,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  RikiPrimaryButton(
                    key: const ValueKey<String>('placement_test_retry_button'),
                    label: context.l10n.retry,
                    onPressed: controller.refreshStatus,
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (state) {
          if (state.result != null) {
            return _PlacementResultView(
              state: state,
              result: state.result!,
              onRetake: controller.prepareRetake,
              onApplyRecommendation: () async {
                final applied = await controller.applyRecommendation();
                if (applied && context.mounted) {
                  context.go(AppRoutes.learnRoadmap);
                }
              },
              onSetExamDate: () => context.go(AppRoutes.profileJlptGoal),
              onOpenStandardRoadmap: () => context.go(AppRoutes.learnRoadmap),
            );
          }
          if (state.hasActiveAttempt) {
            final elapsed = ref.read(placementTestElapsedProvider)();
            return _PlacementActiveAttemptView(
              state: state,
              remaining: state.remainingAtElapsed(elapsed),
              onSelectQuestion: (index) {
                unawaited(controller.showQuestion(index));
              },
              onSelectOption: (questionId, optionId) {
                unawaited(controller.selectAnswer(questionId, optionId));
              },
              onSubmit: () {
                unawaited(controller.submit());
              },
            );
          }
          return _PlacementIntroView(
            state: state,
            onStart: () {
              if (state.shouldRetryResultRecovery) {
                unawaited(controller.refreshStatus());
              } else {
                unawaited(controller.startTest());
              }
            },
          );
        },
      ),
    );
  }
}

class _PlacementIntroView extends StatelessWidget {
  const _PlacementIntroView({required this.state, required this.onStart});

  final PlacementTestFlowState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    return ListView(
      key: const ValueKey<String>('placement_test_intro_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        RikiCard(
          borderColor: AppColors.brandBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.placementIntroTitle,
                          style: AppTypography.pageTitle,
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          context.l10n.placementIntroDescription,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (status.hasCompletedPlacementTest) ...[
                const SizedBox(height: AppSpacing.space4),
                Container(
                  key: const ValueKey<String>(
                    'placement_test_completed_banner',
                  ),
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.learnerBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.placementLatestScore(
                          status.latestScorePercent?.toStringAsFixed(0) ?? '0',
                        ),
                        style: AppTypography.cardTitle,
                      ),
                      if (status.assessedJlptLevelName != null ||
                          status.recommendedTargetJlptLevelName != null) ...[
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          context.l10n.placementLatestLevels(
                            status.assessedJlptLevelName ?? '-',
                            status.recommendedTargetJlptLevelName ?? '-',
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (state.actionIssue != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  _issueMessage(context, state.actionIssue!),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>('placement_test_start_button'),
                label: state.isStarting
                    ? context.l10n.placementStarting
                    : state.shouldRetryResultRecovery
                    ? context.l10n.placementRecoverResult
                    : (status.hasCompletedPlacementTest
                          ? context.l10n.placementRetake
                          : context.l10n.placementStart),
                leadingIcon: Icons.play_arrow_rounded,
                onPressed: state.isStarting ? null : onStart,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlacementActiveAttemptView extends StatelessWidget {
  const _PlacementActiveAttemptView({
    required this.state,
    required this.remaining,
    required this.onSelectQuestion,
    required this.onSelectOption,
    required this.onSubmit,
  });

  final PlacementTestFlowState state;
  final Duration remaining;
  final ValueChanged<int> onSelectQuestion;
  final void Function(int questionId, int optionId) onSelectOption;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final attempt = state.attempt!;
    final question = state.currentQuestion!;
    final selectedOptionId = attempt.answers[question.id];
    final currentIndex = attempt.currentQuestionIndex;
    final total = attempt.questions.length;
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Column(
      key: const ValueKey<String>('placement_test_active_view'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space4,
              AppSpacing.space6,
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.placementQuestionProgress(
                      currentIndex + 1,
                      total,
                      state.answeredQuestionCount,
                    ),
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    key: const ValueKey<String>('placement_test_timer_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$minutes:$seconds',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  for (var i = 0; i < total; i++)
                    InkWell(
                      key: ValueKey<String>('placement_question_chip_$i'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onSelectQuestion(i),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == currentIndex
                              ? AppColors.brandPrimary
                              : (attempt.answers.containsKey(
                                      attempt.questions[i].id,
                                    )
                                    ? AppColors.brandTint
                                    : AppColors.surface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: i == currentIndex
                                ? AppColors.brandPrimary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.metadata.copyWith(
                            color: i == currentIndex
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              RikiCard(
                key: ValueKey<String>('placement_question_card_${question.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            question.jlptLevelName,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            question.sectionTitle,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(question.content, style: AppTypography.sectionTitle),
                    if (question.imageUrl case final imageUrl?) ...[
                      const SizedBox(height: AppSpacing.space3),
                      _PlacementQuestionImage(
                        questionId: question.id,
                        imageUrl: imageUrl,
                      ),
                    ],
                    if (question.audioUrl != null) ...[
                      const SizedBox(height: AppSpacing.space3),
                      const _PlacementAudioUnavailable(),
                    ],
                    const SizedBox(height: AppSpacing.space4),
                    for (final option in question.options) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space2,
                        ),
                        child: InkWell(
                          key: ValueKey<String>(
                            'placement_option_${question.id}_${option.id}',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSelectOption(question.id, option.id),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.space3),
                            decoration: BoxDecoration(
                              color: selectedOptionId == option.id
                                  ? AppColors.brandTint
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedOptionId == option.id
                                    ? AppColors.brandPrimary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedOptionId == option.id
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: selectedOptionId == option.id
                                      ? AppColors.brandPrimary
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.space3),
                                Expanded(
                                  child: Text(
                                    option.content,
                                    style: AppTypography.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (state.actionIssue != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  _issueMessage(context, state.actionIssue!),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space4,
              AppSpacing.space4,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (currentIndex > 0) ...[
                  Expanded(
                    child: RikiSecondaryButton(
                      key: const ValueKey<String>('placement_prev_button'),
                      label: context.l10n.placementPreviousQuestion,
                      onPressed: state.isSubmitting
                          ? null
                          : () => onSelectQuestion(currentIndex - 1),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                ],
                Expanded(
                  flex: 2,
                  child: currentIndex < total - 1
                      ? RikiPrimaryButton(
                          key: const ValueKey<String>('placement_next_button'),
                          label: context.l10n.placementNextQuestion,
                          onPressed: state.isSubmitting
                              ? null
                              : () => onSelectQuestion(currentIndex + 1),
                        )
                      : RikiPrimaryButton(
                          key: const ValueKey<String>(
                            'placement_submit_button',
                          ),
                          label: state.isSubmitting
                              ? context.l10n.placementGrading
                              : context.l10n.placementSubmit,
                          onPressed: state.isSubmitting ? null : onSubmit,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlacementQuestionImage extends StatelessWidget {
  const _PlacementQuestionImage({
    required this.questionId,
    required this.imageUrl,
  });

  final int questionId;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.placementQuestionImageSemantics,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          key: ValueKey<String>('placement_question_image_$questionId'),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
          errorBuilder: (_, _, _) => Container(
            key: ValueKey<String>(
              'placement_question_image_unavailable_$questionId',
            ),
            constraints: const BoxConstraints(minHeight: 96),
            alignment: Alignment.center,
            color: AppColors.learnerBackground,
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.space2),
                Flexible(
                  child: Text(context.l10n.placementQuestionImageUnavailable),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacementAudioUnavailable extends StatelessWidget {
  const _PlacementAudioUnavailable();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.placementAudioUnavailableSemantics,
      liveRegion: true,
      child: Container(
        key: const ValueKey<String>('placement_audio_unavailable'),
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.learnerBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_off_outlined, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(context.l10n.placementAudioUnavailableDescription),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacementResultView extends StatelessWidget {
  const _PlacementResultView({
    required this.state,
    required this.result,
    required this.onRetake,
    required this.onApplyRecommendation,
    required this.onSetExamDate,
    required this.onOpenStandardRoadmap,
  });

  final PlacementTestFlowState state;
  final PlacementTestResult result;
  final VoidCallback onRetake;
  final VoidCallback onApplyRecommendation;
  final VoidCallback onSetExamDate;
  final VoidCallback onOpenStandardRoadmap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('placement_test_result_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        RikiCard(
          borderColor: AppColors.brandBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.placementResultTitle,
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.placementResultScore(
                  result.totalScore.toStringAsFixed(0),
                  result.correctCount,
                  result.totalQuestions,
                ),
                key: const ValueKey<String>('placement_result_score_text'),
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  Expanded(
                    child: _LevelSummaryBox(
                      key: const ValueKey<String>(
                        'placement_assessed_level_box',
                      ),
                      label: context.l10n.placementAssessedLevel,
                      levelName: result.assessedJlptLevelName,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: _LevelSummaryBox(
                      key: const ValueKey<String>(
                        'placement_recommended_level_box',
                      ),
                      label: context.l10n.placementRecommendedLevel,
                      levelName: result.recommendedTargetJlptLevelName,
                      highlighted: true,
                    ),
                  ),
                ],
              ),
              if (result.levelBreakdowns.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  context.l10n.placementBreakdownTitle,
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                for (final item in result.levelBreakdowns) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'JLPT ${item.jlptLevelName}',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.correctCount}/${item.totalCount} (${item.scorePercent.toStringAsFixed(0)}%)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (result.sections.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  context.l10n.placementSectionBreakdownTitle,
                  key: const ValueKey<String>(
                    'placement_result_sections_title',
                  ),
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                for (final section in result.sections) ...[
                  Padding(
                    key: ValueKey<String>(
                      'placement_result_section_${section.mockTestSectionId}',
                    ),
                    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          section.sectionTitle,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                section.languageSkillName,
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '${section.correctCount}/${section.totalCount} '
                              '(${section.score.toStringAsFixed(0)}%)',
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (result.wrongQuestionIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  context.l10n.placementWrongQuestionsSummary(
                    result.wrongQuestionIds.length,
                    result.wrongQuestionIds.join(', '),
                  ),
                  key: const ValueKey<String>(
                    'placement_result_wrong_questions_summary',
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>(
                  'placement_apply_recommendation_button',
                ),
                label: switch (state.recommendationPhase) {
                  PlacementRecommendationPhase.applyingGoal =>
                    context.l10n.placementApplyingGoal,
                  PlacementRecommendationPhase.generatingLearningPath =>
                    context.l10n.placementGeneratingPath,
                  PlacementRecommendationPhase.refreshingLearningPath =>
                    context.l10n.placementRefreshingPath,
                  PlacementRecommendationPhase.idle =>
                    context.l10n.placementApplyGoalAndPath(
                      result.recommendedTargetJlptLevelName,
                    ),
                },
                leadingIcon: Icons.check_circle_outline_rounded,
                onPressed: state.isApplyingRecommendation
                    ? null
                    : onApplyRecommendation,
              ),
              if (state.actionIssue != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  _issueMessage(context, state.actionIssue!),
                  key: const ValueKey<String>('placement_recommendation_error'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              if (state.actionIssue ==
                  PlacementTestActionIssue.examDateRequired) ...[
                const SizedBox(height: AppSpacing.space3),
                RikiSecondaryButton(
                  key: const ValueKey<String>('placement_set_exam_date_button'),
                  label: context.l10n.placementSetExamDate,
                  onPressed: onSetExamDate,
                ),
                const SizedBox(height: AppSpacing.space2),
                TextButton(
                  key: const ValueKey<String>(
                    'placement_open_standard_roadmap_button',
                  ),
                  onPressed: onOpenStandardRoadmap,
                  child: Text(context.l10n.placementOpenStandardRoadmap),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              RikiSecondaryButton(
                key: const ValueKey<String>('placement_retake_button'),
                label: context.l10n.placementRetake,
                onPressed: state.isApplyingRecommendation ? null : onRetake,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelSummaryBox extends StatelessWidget {
  const _LevelSummaryBox({
    required this.label,
    required this.levelName,
    this.highlighted = false,
    super.key,
  });

  final String label;
  final String levelName;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.brandTint : AppColors.learnerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppColors.brandBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'JLPT $levelName',
            style: AppTypography.sectionTitle.copyWith(
              color: highlighted
                  ? AppColors.brandPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

String _issueMessage(BuildContext context, PlacementTestActionIssue issue) {
  return switch (issue) {
    PlacementTestActionIssue.validation =>
      context.l10n.placementIssueValidation,
    PlacementTestActionIssue.examDateRequired =>
      context.l10n.placementIssueExamDateRequired,
    PlacementTestActionIssue.expired => context.l10n.placementIssueExpired,
    PlacementTestActionIssue.bankNotReady =>
      context.l10n.placementIssueBankNotReady,
    PlacementTestActionIssue.invalidAnswer =>
      context.l10n.placementIssueInvalidAnswer,
    PlacementTestActionIssue.notCompleted =>
      context.l10n.placementIssueNotCompleted,
    PlacementTestActionIssue.alreadyCompleted =>
      context.l10n.placementIssueAlreadyCompleted,
    PlacementTestActionIssue.conflict => context.l10n.placementIssueConflict,
    PlacementTestActionIssue.notFound => context.l10n.placementIssueNotFound,
    PlacementTestActionIssue.networkUncertain =>
      context.l10n.placementIssueNetwork,
    PlacementTestActionIssue.localPersistence =>
      context.l10n.placementIssuePersistence,
    PlacementTestActionIssue.unknown => context.l10n.placementIssueUnknown,
  };
}
