import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';

class LearnerAnalyticsScreen extends ConsumerWidget {
  const LearnerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(learnerAnalyticsControllerProvider);
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
      body: analytics.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.analyticsLoadingTitle),
        error: (_, _) => _AnalyticsError(
          onRetry: ref.read(learnerAnalyticsControllerProvider.notifier).retry,
        ),
        data: (data) => _AnalyticsContent(data: data),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.data});

  final LearnerAnalytics data;

  @override
  Widget build(BuildContext context) {
    final noAvailableData = data.isEmpty && data.unavailableSections.isEmpty;
    if (noAvailableData) {
      return RikiEmptyState(
        icon: Icons.insights_outlined,
        title: context.l10n.learningAnalyticsTitle,
        message: context.l10n.analyticsEmpty,
      );
    }
    return ListView(
      key: const ValueKey<String>('analytics_success_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        if (data.isAvailable(AnalyticsSection.streak))
          _MetricCard(
            icon: Icons.local_fire_department_outlined,
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
  });

  final IconData icon;
  final RikiFeatureTone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      child: Row(
        children: [
          RikiFeatureIcon(icon: icon, tone: tone),
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
