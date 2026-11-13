import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_display_title.dart';

class MockTestScreen extends ConsumerStatefulWidget {
  const MockTestScreen({required this.testId, super.key});

  final String testId;

  @override
  ConsumerState<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends ConsumerState<MockTestScreen> {
  Timer? _timer;

  int? get _testId => int.tryParse(widget.testId);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = ref.read(mockTestControllerProvider).value;
      if (state?.hasActiveAttempt != true) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      final now = ref.read(mockTestNowProvider)();
      if (state != null &&
          state.remainingAt(now) <= Duration.zero &&
          !state.isSubmitting) {
        _autoSubmitOnExpiry();
        return;
      }
      setState(() {});
    });
  }

  Future<void> _autoSubmitOnExpiry() async {
    _timer?.cancel();
    _timer = null;
    final outcome = await ref
        .read(mockTestControllerProvider.notifier)
        .finalizeExpired();
    if (!mounted) return;
    if (outcome != MockTestSubmitOutcome.failed) {
      context.pushReplacement(AppRoutes.mockTestResult(widget.testId));
    } else {
      _ensureTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(mockTestControllerProvider);
    final active = flow.value;
    return PopScope(
      canPop: active?.hasActiveAttempt != true || active?.result != null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave();
        if (shouldLeave && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          title: Text(context.l10n.mockTestTitle),
          leading: IconButton(
            onPressed: () async {
              if (active?.hasActiveAttempt == true &&
                  active?.result == null &&
                  !await _confirmLeave()) {
                return;
              }
              if (context.mounted) context.pop();
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: flow.when(
          loading: () =>
              RikiFullScreenLoader(title: context.l10n.mockLoadingTitle),
          error: (_, _) => RikiErrorState(
            title: context.l10n.mockLoadFailed,
            message: context.l10n.checkConnectionRetry,
            actionLabel: context.l10n.retry,
            onAction: ref
                .read(mockTestControllerProvider.notifier)
                .retryCatalog,
          ),
          data: (state) {
            final testId = _testId;
            final test = state.tests
                .where((candidate) => candidate.id == testId)
                .firstOrNull;
            if (test == null) {
              return RikiEmptyState(
                icon: Icons.assignment_late_outlined,
                title: context.l10n.mockTestTitle,
                message: context.l10n.mockTestUnavailable,
              );
            }

            if (state.selectedTest?.id != test.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref
                      .read(mockTestControllerProvider.notifier)
                      .selectTest(test.id);
                }
              });
              return RikiFullScreenLoader(title: context.l10n.mockLoadingTitle);
            }

            if (state.result != null) {
              return const SizedBox.shrink();
            }
            if (!state.hasActiveAttempt) {
              return _MockInstructions(state: state, onStart: _start);
            }

            _ensureTimer();
            final now = ref.read(mockTestNowProvider)();
            final remaining = state.remainingAt(now);
            if (remaining <= Duration.zero && !state.isSubmitting) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _autoSubmitOnExpiry();
              });
            }
            return _MockQuestionView(
              state: state,
              remaining: remaining,
              onSubmit: _confirmSubmit,
            );
          },
        ),
      ),
    );
  }

  Future<void> _start() async {
    final started = await ref
        .read(mockTestControllerProvider.notifier)
        .startSelectedTest();
    if (started) _ensureTimer();
  }

  Future<bool> _confirmLeave() async {
    return showRikiConfirmationDialog(
      context: context,
      title: context.l10n.leaveMockTitle,
      message: context.l10n.leaveMockMessage,
      confirmLabel: context.l10n.leaveAction,
      cancelLabel: context.l10n.continueAction,
      icon: Icons.logout,
      destructive: true,
    );
  }

  Future<void> _confirmSubmit() async {
    final shouldSubmit = await showRikiConfirmationDialog(
      context: context,
      title: context.l10n.submitMockTitle,
      message: context.l10n.submitMockMessage,
      confirmLabel: context.l10n.submitAction,
      cancelLabel: context.l10n.cancel,
      icon: Icons.task_alt_outlined,
    );
    if (shouldSubmit != true || !mounted) return;

    final outcome = await ref
        .read(mockTestControllerProvider.notifier)
        .submit();
    if (!mounted) return;
    if (outcome != MockTestSubmitOutcome.failed) {
      _timer?.cancel();
      _timer = null;
      context.pushReplacement(AppRoutes.mockTestResult(widget.testId));
    }
  }
}

class _MockInstructions extends StatelessWidget {
  const _MockInstructions({required this.state, required this.onStart});

  final MockTestFlowState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final test = state.selectedTest!;
    return ListView(
      key: const ValueKey<String>('mock_test_instructions'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        const SizedBox(height: AppSpacing.space3),
        RikiCard(
          backgroundColor: AppColors.cardWarmWhite,
          borderColor: AppColors.borderSubtlePink,
          boxShadow: AppShadows.sakuraSubtle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.borderSubtlePink,
                            ),
                          ),
                          child: Text(
                            test.jlptLevelName,
                            style: AppTypography.badgeText.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          mockTestDisplayTitle(
                            test.title,
                            japanese:
                                Localizations.localeOf(context).languageCode ==
                                'ja',
                          ),
                          style: AppTypography.pageTitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  const SakuraMascot(pose: SakuraMascotPose.studying, size: 72),
                ],
              ),
              if (test.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  test.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: context.l10n.mockMinutes(test.timeLimitMinutes),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                context.l10n.mockBackendScoringNotice,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.learnerTextSecondary,
                ),
              ),
            ],
          ),
        ),
        if (state.actionIssue != null) ...[
          const SizedBox(height: AppSpacing.space3),
          _MockActionError(issue: state.actionIssue!),
        ],
        const SizedBox(height: AppSpacing.space4),
        RikiPrimaryButton(
          key: const ValueKey<String>('mock_test_start_button'),
          label: context.l10n.startMockTest,
          loadingLabel: context.l10n.mockStarting,
          isLoading: state.isStarting,
          trailingIcon: Icons.arrow_forward,
          onPressed: state.isStarting ? null : onStart,
        ),
      ],
    );
  }
}

class _MockQuestionView extends ConsumerWidget {
  const _MockQuestionView({
    required this.state,
    required this.remaining,
    required this.onSubmit,
  });

  final MockTestFlowState state;
  final Duration remaining;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(mockTestControllerProvider.notifier);
    final attempt = state.attempt!;
    final question = state.currentQuestion!;
    final index = attempt.currentQuestionIndex;
    final total = attempt.questions.length;
    return ListView(
      key: const ValueKey<String>('mock_test_question_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.questionProgress(index + 1, total),
                style: AppTypography.cardTitle,
              ),
            ),
            _TimerPill(remaining: remaining),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        RikiProgressIndicator(
          value: (index + 1) / total,
          minHeight: 8,
          backgroundColor: AppColors.brandTint,
          semanticsLabel: context.l10n.questionProgress(index + 1, total),
        ),
        const SizedBox(height: AppSpacing.space3),
        _QuestionNavigatorStrip(
          currentIndex: index,
          total: total,
          questions: attempt.questions,
          attempt: attempt,
          isSubmitting: state.isSubmitting,
          onSelect: controller.showQuestion,
        ),
        const SizedBox(height: AppSpacing.space4),
        RikiCard(
          backgroundColor: AppColors.cardWarmWhite,
          borderColor: AppColors.borderSubtlePink,
          boxShadow: AppShadows.sakuraSubtle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.sectionTitle,
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(question.content, style: AppTypography.sectionTitle),
              if (question.audioUrl != null) ...[
                const SizedBox(height: AppSpacing.space3),
                _MockAudioPlayerBanner(audioUrl: question.audioUrl!),
              ] else if (question.imageUrl != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  context.l10n.mockMediaAvailable,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              if (question.questionType.toLowerCase() == 'multiplechoice') ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: Text(
                    '(Chọn một hoặc nhiều đáp án)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final option in question.options) ...[
                  _MockCheckboxOptionTile(
                    option: option,
                    selected: (attempt.structuredAnswers[question.id] as List?)
                            ?.contains(option.id) ==
                        true,
                    onTap: state.isSubmitting
                        ? null
                        : () => controller.toggleMultipleChoiceOption(
                              question.id,
                              option.id,
                            ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                ],
              ] else if (question.questionType.toLowerCase() == 'ordering' ||
                  question.questionType.toLowerCase() == 'sentenceordering') ...[
                _MockOrderingWidget(
                  question: question,
                  currentSelection: (attempt.structuredAnswers[question.id] as List?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      const <String>[],
                  onChanged: state.isSubmitting
                      ? null
                      : (tokens) =>
                          controller.setOrderingAnswer(question.id, tokens),
                ),
              ] else if (question.questionType.toLowerCase() == 'fillblank' ||
                  question.questionType.toLowerCase() == 'shortanswer') ...[
                _MockFillBlankWidget(
                  question: question,
                  currentText:
                      (attempt.structuredAnswers[question.id] as String?) ?? '',
                  onChanged: state.isSubmitting
                      ? null
                      : (text) => controller.setTextAnswer(question.id, text),
                ),
              ] else ...[
                for (final option in question.options) ...[
                  _MockOptionTile(
                    option: option,
                    selected: attempt.answers[question.id] == option.id,
                    onTap: state.isSubmitting
                        ? null
                        : () => controller.selectAnswer(question.id, option.id),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                ],
              ],
            ],
          ),
        ),
        if (state.actionIssue != null) ...[
          const SizedBox(height: AppSpacing.space3),
          _MockActionError(issue: state.actionIssue!),
        ],
        const SizedBox(height: AppSpacing.space4),
        Row(
          children: [
            Expanded(
              child: RikiSecondaryButton(
                label: context.l10n.previousQuestion,
                leadingIcon: Icons.arrow_back,
                onPressed: index == 0 || state.isSubmitting
                    ? null
                    : () => controller.showQuestion(index - 1),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: index == total - 1
                  ? RikiPrimaryButton(
                      key: const ValueKey<String>('mock_test_submit_button'),
                      label: context.l10n.submitAction,
                      loadingLabel: context.l10n.mockSubmitting,
                      isLoading: state.isSubmitting,
                      onPressed: state.isSubmitting ? null : onSubmit,
                    )
                  : RikiPrimaryButton(
                      label: context.l10n.nextQuestion,
                      trailingIcon: Icons.arrow_forward,
                      onPressed: state.isSubmitting
                          ? null
                          : () => controller.showQuestion(index + 1),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestionNavigatorStrip extends StatelessWidget {
  const _QuestionNavigatorStrip({
    required this.currentIndex,
    required this.total,
    required this.questions,
    required this.attempt,
    required this.isSubmitting,
    required this.onSelect,
  });

  final int currentIndex;
  final int total;
  final List<LiveMockTestQuestion> questions;
  final LiveMockTestAttempt attempt;
  final bool isSubmitting;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space2),
        itemBuilder: (context, i) {
          final isCurrent = i == currentIndex;
          final isAnswered =
              i < questions.length && attempt.isQuestionAnswered(questions[i].id);

          Color bgColor;
          Color borderColor;
          Color textColor;

          if (isCurrent) {
            bgColor = AppColors.brandPrimary;
            borderColor = AppColors.brandPrimary;
            textColor = Colors.white;
          } else if (isAnswered) {
            bgColor = AppColors.brandTint;
            borderColor = AppColors.borderSubtlePink;
            textColor = AppColors.brandPrimary;
          } else {
            bgColor = AppColors.cardWarmWhite;
            borderColor = AppColors.borderSubtlePink;
            textColor = AppColors.learnerTextSecondary;
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: isSubmitting ? null : () => onSelect(i),
              child: Container(
                constraints: const BoxConstraints(minWidth: 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${i + 1}',
                      style: AppTypography.badgeText.copyWith(
                        color: textColor,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (isAnswered && !isCurrent) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.check, size: 12, color: textColor),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MockOptionTile extends StatelessWidget {
  const _MockOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LiveMockTestOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandTint : AppColors.cardWarmWhite,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InkWell(
        key: ValueKey<String>('mock_option_${option.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.cardWarmWhite,
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : AppColors.borderSubtlePink,
              width: selected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.brandPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  option.content,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected
                        ? AppColors.brandPrimary
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockActionError extends ConsumerWidget {
  const _MockActionError({required this.issue});

  final MockTestActionIssue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      key: ValueKey<String>('mock_action_error_${issue.name}'),
      title: context.l10n.mockActionFailed,
      message: message,
      actionLabel: context.l10n.close,
      onAction: ref.read(mockTestControllerProvider.notifier).clearActionIssue,
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final isUrgent = remaining.inMinutes < 5;
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final bgColor = isUrgent ? AppColors.errorBackground : AppColors.brandTint;
    final borderColor = isUrgent
        ? AppColors.errorBorder
        : AppColors.borderSubtlePink;
    final textColor = isUrgent ? AppColors.error : AppColors.brandPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$minutes:$seconds',
            style: AppTypography.badgeText.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.space2),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}


class _MockAudioPlayerBanner extends StatefulWidget {
  const _MockAudioPlayerBanner({required this.audioUrl});

  final String audioUrl;

  @override
  State<_MockAudioPlayerBanner> createState() => _MockAudioPlayerBannerState();
}

class _MockAudioPlayerBannerState extends State<_MockAudioPlayerBanner> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.borderSubtlePink),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: AppColors.brandPrimary,
              size: 32,
            ),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bài nghe JLPT (Audio)',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _isPlaying ? 'Đang phát âm thanh...' : 'Bấm để nghe đoạn hội thoại',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
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

class _MockCheckboxOptionTile extends StatelessWidget {
  const _MockCheckboxOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LiveMockTestOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandTint : AppColors.cardWarmWhite,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InkWell(
        key: ValueKey<String>('mock_checkbox_option_${option.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.cardWarmWhite,
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : AppColors.borderSubtlePink,
              width: selected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                color: selected ? AppColors.brandPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  option.content,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected
                        ? AppColors.brandPrimary
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockOrderingWidget extends StatelessWidget {
  const _MockOrderingWidget({
    required this.question,
    required this.currentSelection,
    required this.onChanged,
  });

  final LiveMockTestQuestion question;
  final List<String> currentSelection;
  final ValueChanged<List<String>>? onChanged;

  List<String> get _availableTokens {
    final raw = question.interactionData?['tokens'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return question.options.map((o) => o.content).toList();
  }

  @override
  Widget build(BuildContext context) {
    final remainingTokens = List<String>.from(_availableTokens);
    for (final token in currentSelection) {
      remainingTokens.remove(token);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thứ tự đã sắp xếp:',
          style: AppTypography.badgeText.copyWith(
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(AppSpacing.space2),
          decoration: BoxDecoration(
            color: AppColors.cardWarmWhite,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.borderSubtlePink),
          ),
          child: currentSelection.isEmpty
              ? Center(
                  child: Text(
                    'Chạm vào các từ bên dưới để sắp xếp',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.learnerTextSecondary,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < currentSelection.length; i++)
                      ActionChip(
                        label: Text('${i + 1}. ${currentSelection[i]}'),
                        avatar: const Icon(Icons.close, size: 14),
                        onPressed: onChanged == null
                            ? null
                            : () {
                                final next = List<String>.from(currentSelection)
                                  ..removeAt(i);
                                onChanged!(next);
                              },
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          'Từ / Cụm từ có sẵn:',
          style: AppTypography.badgeText.copyWith(
            color: AppColors.learnerTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final token in remainingTokens)
              ActionChip(
                label: Text(token),
                avatar: const Icon(Icons.add, size: 14),
                onPressed: onChanged == null
                    ? null
                    : () {
                        final next = List<String>.from(currentSelection)
                          ..add(token);
                        onChanged!(next);
                      },
              ),
          ],
        ),
      ],
    );
  }
}

class _MockFillBlankWidget extends StatefulWidget {
  const _MockFillBlankWidget({
    required this.question,
    required this.currentText,
    required this.onChanged,
  });

  final LiveMockTestQuestion question;
  final String currentText;
  final ValueChanged<String>? onChanged;

  @override
  State<_MockFillBlankWidget> createState() => _MockFillBlankWidgetState();
}

class _MockFillBlankWidgetState extends State<_MockFillBlankWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentText);
  }

  @override
  void didUpdateWidget(_MockFillBlankWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id ||
        (oldWidget.currentText != widget.currentText &&
            _controller.text != widget.currentText)) {
      _controller.text = widget.currentText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập câu trả lời:',
          style: AppTypography.badgeText.copyWith(
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _controller,
          enabled: widget.onChanged != null,
          decoration: InputDecoration(
            hintText: 'Nhập đáp án của bạn...',
            fillColor: AppColors.cardWarmWhite,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.borderSubtlePink),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
