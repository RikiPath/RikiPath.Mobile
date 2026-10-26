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
      setState(() {});
    });
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
            return _MockQuestionView(
              state: state,
              remaining: state.remainingAt(ref.read(mockTestNowProvider)()),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(test.jlptLevelName, style: AppTypography.badgeText),
              const SizedBox(height: AppSpacing.space2),
              Text(test.title, style: AppTypography.pageTitle),
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
        const SizedBox(height: AppSpacing.space4),
        RikiCard(
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
              if (question.imageUrl != null || question.audioUrl != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  context.l10n.mockMediaAvailable,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
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
      color: selected ? AppColors.brandTint : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InkWell(
        key: ValueKey<String>('mock_option_${option.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : AppColors.learnerOutline,
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
              Expanded(child: Text(option.content)),
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
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$minutes:$seconds',
        style: AppTypography.badgeText.copyWith(
          color: AppColors.brandPrimary,
          fontWeight: FontWeight.w700,
        ),
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
