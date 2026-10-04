import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';

class MockTestScreen extends ConsumerStatefulWidget {
  const MockTestScreen({required this.testId, super.key});

  final String testId;

  @override
  ConsumerState<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends ConsumerState<MockTestScreen> {
  Timer? _timer;
  bool _resultNavigationScheduled = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final state = ref.read(demoPracticeControllerProvider).value;
      if (state == null || !state.hasActiveMockAttempt) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      final didFinish = await ref
          .read(demoPracticeControllerProvider.notifier)
          .finalizeExpiredMockTest();
      if (didFinish) {
        _scheduleResultNavigation(state.mockTest.id);
        return;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(demoPracticeControllerProvider);
    return PopScope(
      canPop: practice.value?.hasActiveMockAttempt != true,
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
              final state = practice.value;
              if (state?.hasActiveMockAttempt == true &&
                  !await _confirmLeave()) {
                return;
              }
              if (context.mounted) context.pop();
            },
            icon: const Icon(Icons.arrow_back),
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
            if (state.mockTest.id != widget.testId) {
              return RikiEmptyState(
                icon: Icons.assignment_late_outlined,
                title: context.l10n.mockTestTitle,
                message: context.l10n.mockTestUnavailable,
              );
            }
            if (state.mockAttempt?.status == DemoMockSessionStatus.submitted) {
              final testPath = AppRoutes.mockTest(state.mockTest.id);
              if (GoRouterState.of(context).uri.path == testPath) {
                _scheduleResultNavigation(state.mockTest.id);
              }
              return const SizedBox.shrink();
            }
            if (!state.hasActiveMockAttempt) {
              return _MockInstructions(
                state: state,
                onStart: () async {
                  await ref
                      .read(demoPracticeControllerProvider.notifier)
                      .startMockTest();
                  _ensureTimer();
                },
              );
            }
            _ensureTimer();
            return _MockQuestionView(
              state: state,
              remaining: state.remainingMockTime(
                ref.read(practiceNowProvider)(),
              ),
              onSubmit: _confirmSubmit,
            );
          },
        ),
      ),
    );
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
    if (shouldSubmit != true) return;
    await ref.read(demoPracticeControllerProvider.notifier).submitMockTest();
    _scheduleResultNavigation(widget.testId);
  }

  void _scheduleResultNavigation(String testId) {
    if (_resultNavigationScheduled || !mounted) return;
    _resultNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openResult(testId));
  }

  void _openResult(String testId) {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    context.pushReplacement(AppRoutes.mockTestResult(testId));
  }
}

class _MockInstructions extends StatelessWidget {
  const _MockInstructions({required this.state, required this.onStart});

  final DemoPracticeState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final test = state.mockTest;
    return ListView(
      key: const ValueKey<String>('mock_test_instructions'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        const SizedBox(height: AppSpacing.space3),
        RikiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(test.level, style: AppTypography.badgeText),
              const SizedBox(height: AppSpacing.space2),
              Text(test.title, style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.space4),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: context.l10n.mockMinutes(test.timeLimitMinutes),
              ),
              const SizedBox(height: AppSpacing.space2),
              _InfoRow(
                icon: Icons.quiz_outlined,
                label: context.l10n.mockQuestionCount(test.questions.length),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                context.l10n.mockLocalScoringNotice,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.learnerTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        RikiPrimaryButton(
          key: const ValueKey<String>('mock_test_start_button'),
          label: context.l10n.startMockTest,
          trailingIcon: Icons.arrow_forward,
          onPressed: onStart,
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

  final DemoPracticeState state;
  final Duration remaining;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(demoPracticeControllerProvider.notifier);
    final question = state.currentMockQuestion;
    final index = state.currentMockQuestionIndex;
    final total = state.mockTest.questions.length;
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
                question.section,
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(question.prompt, style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.space4),
              for (final option in question.options) ...[
                _MockOptionTile(
                  option: option,
                  selected: state.mockAnswers[question.id] == option.id,
                  onTap: () =>
                      controller.selectMockAnswer(question.id, option.id),
                ),
                const SizedBox(height: AppSpacing.space2),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Row(
          children: [
            Expanded(
              child: RikiSecondaryButton(
                label: context.l10n.previousQuestion,
                leadingIcon: Icons.arrow_back,
                onPressed: index == 0
                    ? null
                    : () => controller.showMockQuestion(index - 1),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: index == total - 1
                  ? RikiPrimaryButton(
                      key: const ValueKey<String>('mock_test_submit_button'),
                      label: context.l10n.submitAction,
                      onPressed: onSubmit,
                    )
                  : RikiPrimaryButton(
                      label: context.l10n.nextQuestion,
                      trailingIcon: Icons.arrow_forward,
                      onPressed: () => controller.showMockQuestion(index + 1),
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

  final DemoMockOption option;
  final bool selected;
  final VoidCallback onTap;

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
              Expanded(child: Text(option.label)),
            ],
          ),
        ),
      ),
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
