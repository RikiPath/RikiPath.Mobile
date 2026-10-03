import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';

class DailyReviewScreen extends ConsumerWidget {
  const DailyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(demoPracticeControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.dailyReviewTitle),
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: practice.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.reviewLoadingTitle),
        error: (_, _) => _ReviewError(
          onRetry: ref.read(demoPracticeControllerProvider.notifier).retry,
        ),
        data: (state) => state.reviewQueue.isEmpty
            ? const _ReviewEmpty()
            : state.isReviewComplete
            ? _ReviewSummary(state: state)
            : _ReviewCardView(state: state),
      ),
    );
  }
}

class _ReviewCardView extends ConsumerWidget {
  const _ReviewCardView({required this.state});

  final DemoPracticeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = state.currentReviewCard!;
    final current = state.reviewIndex + 1;
    final total = state.reviewQueue.length;
    return ListView(
      key: const ValueKey<String>('daily_review_card_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.reviewProgress(current, total),
                style: AppTypography.cardTitle,
              ),
            ),
            Text(
              '${(current * 100 / total).round()}%',
              style: AppTypography.badgeText.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        RikiProgressIndicator(
          value: current / total,
          minHeight: 8,
          backgroundColor: AppColors.brandTint,
          semanticsLabel: context.l10n.reviewProgress(current, total),
        ),
        const SizedBox(height: AppSpacing.space5),
        RikiCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space5,
            vertical: AppSpacing.space8,
          ),
          child: Column(
            children: [
              Text(
                card.contentType,
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(
                card.term,
                textAlign: TextAlign.center,
                style: AppTypography.heroTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              if (state.isReviewAnswerVisible) ...[
                const SizedBox(height: AppSpacing.space3),
                if (card.reading != null)
                  Text(card.reading!, style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  card.meaning,
                  key: const ValueKey<String>('review_answer'),
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.space6),
                Text(
                  context.l10n.reviewRecallPrompt,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space5),
        if (!state.isReviewAnswerVisible)
          RikiPrimaryButton(
            key: const ValueKey<String>('review_reveal_button'),
            label: context.l10n.revealAnswer,
            onPressed: ref
                .read(demoPracticeControllerProvider.notifier)
                .revealReviewAnswer,
          )
        else
          _ReviewAnswerButtons(
            onAnswer: ref
                .read(demoPracticeControllerProvider.notifier)
                .answerReview,
          ),
      ],
    );
  }
}

class _ReviewAnswerButtons extends StatelessWidget {
  const _ReviewAnswerButtons({required this.onAnswer});

  final ValueChanged<DemoReviewAnswer> onAnswer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.space2) / 2;
        return Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final answer in DemoReviewAnswer.values)
              SizedBox(
                width: itemWidth,
                child: OutlinedButton.icon(
                  key: ValueKey<String>('review_answer_${answer.name}'),
                  onPressed: () => onAnswer(answer),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _foreground(answer),
                    backgroundColor: _background(answer),
                    side: BorderSide(color: _foreground(answer)),
                  ),
                  icon: Icon(_icon(answer), size: 18),
                  label: Text(_label(context, answer)),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _icon(DemoReviewAnswer answer) => switch (answer) {
    DemoReviewAnswer.again => Icons.replay,
    DemoReviewAnswer.hard => Icons.fitness_center_outlined,
    DemoReviewAnswer.good => Icons.thumb_up_alt_outlined,
    DemoReviewAnswer.easy => Icons.auto_awesome_outlined,
  };

  Color _foreground(DemoReviewAnswer answer) => switch (answer) {
    DemoReviewAnswer.again => AppColors.errorText,
    DemoReviewAnswer.hard => AppColors.warningText,
    DemoReviewAnswer.good => AppColors.info,
    DemoReviewAnswer.easy => AppColors.success,
  };

  Color _background(DemoReviewAnswer answer) => switch (answer) {
    DemoReviewAnswer.again => AppColors.errorBackground,
    DemoReviewAnswer.hard => AppColors.warningBackground,
    DemoReviewAnswer.good => AppColors.infoBackground,
    DemoReviewAnswer.easy => AppColors.successBackground,
  };

  String _label(BuildContext context, DemoReviewAnswer answer) =>
      switch (answer) {
        DemoReviewAnswer.again => context.l10n.reviewAgain,
        DemoReviewAnswer.hard => context.l10n.reviewHard,
        DemoReviewAnswer.good => context.l10n.reviewGood,
        DemoReviewAnswer.easy => context.l10n.reviewEasy,
      };
}

class _ReviewSummary extends ConsumerWidget {
  const _ReviewSummary({required this.state});

  final DemoPracticeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      key: const ValueKey<String>('daily_review_summary'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        const SizedBox(height: AppSpacing.space5),
        RikiCard(
          borderColor: AppColors.successBorder,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.successBackground,
                foregroundColor: AppColors.success,
                child: Icon(Icons.check_rounded, size: 34),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                context.l10n.reviewCompleteTitle,
                textAlign: TextAlign.center,
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.reviewCompleteCount(state.reviewAnswers.length),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space4),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  for (final answer in DemoReviewAnswer.values)
                    _ReviewCountChip(
                      label: context.l10n.reviewResponseCount(
                        _answerLabel(context, answer),
                        state.reviewSession.count(answer),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        RikiSecondaryButton(
          label: context.l10n.reviewAgainAction,
          leadingIcon: Icons.replay,
          onPressed: ref
              .read(demoPracticeControllerProvider.notifier)
              .restartReview,
        ),
        const SizedBox(height: AppSpacing.space2),
        RikiPrimaryButton(
          label: context.l10n.backToPractice,
          onPressed: context.pop,
        ),
      ],
    );
  }
}

class _ReviewCountChip extends StatelessWidget {
  const _ReviewCountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: AppColors.brandPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _answerLabel(BuildContext context, DemoReviewAnswer answer) =>
    switch (answer) {
      DemoReviewAnswer.again => context.l10n.reviewAgain,
      DemoReviewAnswer.hard => context.l10n.reviewHard,
      DemoReviewAnswer.good => context.l10n.reviewGood,
      DemoReviewAnswer.easy => context.l10n.reviewEasy,
    };

class _ReviewEmpty extends StatelessWidget {
  const _ReviewEmpty();

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(
      icon: Icons.auto_awesome_outlined,
      title: context.l10n.dailyReviewTitle,
      message: context.l10n.reviewQueueEmpty,
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      title: context.l10n.reviewLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
    );
  }
}
