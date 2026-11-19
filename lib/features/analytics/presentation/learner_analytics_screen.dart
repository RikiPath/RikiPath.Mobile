import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/subscriptions/domain/subscription_models.dart';

final DateFormat _historyDateFmt = DateFormat('dd/MM/yyyy HH:mm');

class LearnerAnalyticsScreen extends ConsumerWidget {
  const LearnerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(learnerAnalyticsControllerProvider);
    final monthly = ref.watch(learnerSkillMonthlyProvider);
    final history = ref.watch(learnerStudyHistoryProvider);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.learningAnalyticsTitle),
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(learnerAnalyticsControllerProvider);
          ref.invalidate(learnerSkillMonthlyProvider);
          ref.invalidate(learnerStudyHistoryProvider);
          await ref.read(learnerAnalyticsControllerProvider.future);
        },
        child: analytics.when(
          loading: () =>
              RikiFullScreenLoader(title: context.l10n.analyticsLoadingTitle),
          error: (_, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _AnalyticsError(
                onRetry: () {
                  ref.read(learnerAnalyticsControllerProvider.notifier).retry();
                  ref.invalidate(learnerSkillMonthlyProvider);
                  ref.invalidate(learnerStudyHistoryProvider);
                },
              ),
            ],
          ),
          data: (data) => _AnalyticsContent(
            data: data,
            monthly: monthly.value,
            history: history.value,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends ConsumerWidget {
  const _AnalyticsContent({
    required this.data,
    this.monthly,
    this.history,
  });

  final LearnerAnalytics data;
  final SkillMonthlySummary? monthly;
  final LearnerStudyHistory? history;

  Future<void> _regradePractice(
    BuildContext context,
    WidgetRef ref,
    int submissionId,
  ) async {
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    try {
      await ref
          .read(apiClientProvider)
          .post<Object?>('/api/PracticeSubmission/$submissionId/regrade');
      ref.invalidate(learnerStudyHistoryProvider);
      ref.invalidate(learnerAnalyticsControllerProvider);
      if (!context.mounted) return;
      toasts.success(title: 'Đã gửi yêu cầu chấm lại bài luyện tập');
    } catch (error) {
      if (!context.mounted) return;
      if (isSubscriptionOrAiGateError(error)) {
        toasts.error(
          title: 'Hết lượt chấm AI',
          description: 'Mở Gói tự học & Lượt AI để mua thêm lượt.',
        );
        unawaited(context.push(AppRoutes.profileSubscriptions));
        return;
      }
      toasts.error(
        title: 'Chưa chấm lại được',
        description: appErrorMessage(error, context.l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noAvailableData =
        data.isEmpty &&
        data.unavailableSections.isEmpty &&
        monthly == null &&
        history == null;
    if (noAvailableData) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          RikiEmptyState(
            icon: Icons.insights_outlined,
            title: context.l10n.learningAnalyticsTitle,
            message: context.l10n.analyticsEmpty,
          ),
        ],
      );
    }
    return ListView(
      key: const ValueKey<String>('analytics_success_view'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        if (data.isAvailable(AnalyticsSection.streak))
          _MetricCard(
            icon: Icons.local_fire_department_outlined,
            icon3d: Sakura3DIconType.streak,
            tone: AppFeatureTones.review,
            label: context.l10n.studyStreakLabel,
            value: context.l10n.streakDaysValue(data.streakDays),
          )
        else
          _UnavailableSection(label: context.l10n.studyStreakLabel),
        const SizedBox(height: AppSpacing.space3),
        if (data.isAvailable(AnalyticsSection.completion))
          _MetricCard(
            icon: Icons.task_alt_outlined,
            icon3d: Sakura3DIconType.achievement,
            tone: AppFeatureTones.success,
            label: context.l10n.completedLessonsLabel,
            value: context.l10n.analyticsCompletedLessons(
              data.completedLessons,
              data.totalLessons,
            ),
          )
        else
          _UnavailableSection(label: context.l10n.completedLessonsLabel),
        const SizedBox(height: AppSpacing.space5),
        Text(context.l10n.skillBreakdown, style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space3),
        if (!data.isAvailable(AnalyticsSection.skills))
          _UnavailableSection(label: context.l10n.skillBreakdown)
        else if (data.skills.isEmpty)
          RikiEmptyState(
            icon: Icons.auto_graph_outlined,
            title: context.l10n.skillBreakdown,
            message: context.l10n.analyticsSkillsEmpty,
            compact: true,
          )
        else
          for (final skill in data.skills) ...[
            _SkillCard(skill: skill),
            const SizedBox(height: AppSpacing.space3),
          ],
        if (monthly != null && (monthly!.skills.isNotEmpty || monthly!.summary.isNotEmpty)) ...[
          const SizedBox(height: AppSpacing.space4),
          Text('Tiến độ theo tháng (12 tháng)', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space2),
          RikiCard(
            key: const Key('analytics_skill_monthly_card'),
            boxShadow: const <BoxShadow>[],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (monthly!.assessedJlptLevel != null ||
                    monthly!.targetJlptLevel != null)
                  Text(
                    'Đánh giá: ${monthly!.assessedJlptLevel ?? '—'} · Mục tiêu: ${monthly!.targetJlptLevel ?? '—'} · Tổng lượt thi: ${monthly!.totalAttempts}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (monthly!.currentOverallScorePercent != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Điểm trung bình hiện tại: ${monthly!.currentOverallScorePercent!.toStringAsFixed(1)}%',
                    style: AppTypography.cardTitle,
                  ),
                ],
                if (monthly!.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(monthly!.summary, style: AppTypography.bodySmall),
                ],
                for (final item in monthly!.skills) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.languageSkillName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.currentScorePercent != null)
                        Text(
                          '${item.currentScorePercent!.toStringAsFixed(1)}%',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  if (item.currentAssessment.isNotEmpty)
                    Text(
                      item.currentAssessment,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (item.monthlyScores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final pt in item.monthlyScores.take(6))
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                '${pt.month}: ${pt.scorePercent?.toStringAsFixed(0) ?? '—'}%',
                                style: AppTypography.metadata,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
        if (history != null &&
            (history!.homeworkReport != null ||
                history!.mockTests.isNotEmpty ||
                history!.practices.isNotEmpty)) ...[
          const SizedBox(height: AppSpacing.space4),
          Text('Lịch sử học tập & bài thi', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space2),
          if (history!.homeworkReport != null &&
              (history!.homeworkReport!.assignedCount > 0 ||
                  history!.homeworkReport!.sessionCount > 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RikiCard(
                key: const Key('analytics_homework_report_card'),
                boxShadow: const <BoxShadow>[],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Báo cáo lớp nhóm (90 ngày gần nhất)',
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BTVN: đã nộp ${history!.homeworkReport!.submittedCount}/${history!.homeworkReport!.assignedCount}'
                      '${history!.homeworkReport!.homeworkPercent != null ? ' (${history!.homeworkReport!.homeworkPercent!.toStringAsFixed(0)}%)' : ''}',
                      style: AppTypography.bodySmall,
                    ),
                    Text(
                      'Điểm danh buổi học: ${history!.homeworkReport!.attendedCount}/${history!.homeworkReport!.sessionCount}'
                      '${history!.homeworkReport!.attendancePercent != null ? ' (${history!.homeworkReport!.attendancePercent!.toStringAsFixed(0)}%)' : ''}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          if (history!.mockTests.isNotEmpty)
            RikiCard(
              key: const Key('analytics_mock_history_card'),
              boxShadow: const <BoxShadow>[],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bài thi thử gần đây', style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  for (final m in history!.mockTests.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.title} (${m.jlptLevelName})',
                                  style: AppTypography.bodyMedium,
                                ),
                                if (m.submittedAt != null)
                                  Text(
                                    _historyDateFmt.format(m.submittedAt!),
                                    style: AppTypography.metadata.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${m.totalScore.toStringAsFixed(1)}đ',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (history!.practices.isNotEmpty) ...[
            const SizedBox(height: 10),
            RikiCard(
              key: const Key('analytics_practice_history_card'),
              boxShadow: const <BoxShadow>[],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lịch sử luyện Nói / Viết AI', style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  for (final p in history!.practices.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p.type} · ${p.levelCode}',
                                  style: AppTypography.bodyMedium,
                                ),
                                Text(
                                  [
                                    p.isGraded
                                        ? 'Điểm: ${p.overallScore?.toStringAsFixed(1) ?? '—'}'
                                        : 'Chưa có điểm AI',
                                    if (p.submittedAt != null)
                                      _historyDateFmt.format(p.submittedAt!),
                                  ].join(' · '),
                                  style: AppTypography.metadata.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _regradePractice(context, ref, p.id),
                            child: const Text('Chấm lại'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    this.icon3d,
  });

  final IconData icon;
  final Sakura3DIconType? icon3d;
  final RikiFeatureTone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      child: Row(
        children: [
          RikiFeatureIcon(icon: icon, icon3d: icon3d, tone: tone),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall),
                Text(value, style: AppTypography.pageTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill});

  final SkillBreakdown skill;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      boxShadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(skill.skill, style: AppTypography.cardTitle),
              ),
              Text(
                context.l10n.analyticsSkillScore(
                  _formatScore(skill.averageScore),
                  skill.attemptCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          RikiProgressIndicator(
            value: skill.progress,
            minHeight: 8,
            color: AppFeatureTones.learning.foreground,
            backgroundColor: AppFeatureTones.learning.background,
            semanticsLabel: skill.skill,
          ),
        ],
      ),
    );
  }

  String _formatScore(double score) {
    return score == score.roundToDouble()
        ? score.toStringAsFixed(0)
        : score.toStringAsFixed(1);
  }
}

class _UnavailableSection extends StatelessWidget {
  const _UnavailableSection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return RikiErrorBanner(
      title: label,
      message: context.l10n.analyticsSectionUnavailable,
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      title: context.l10n.analyticsLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
    );
  }
}
