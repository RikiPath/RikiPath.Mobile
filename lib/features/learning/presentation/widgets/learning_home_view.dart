import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

class LearningHomeView extends StatelessWidget {
  const LearningHomeView({
    required this.snapshot,
    required this.onOpenRoadmap,
    required this.onOpenLesson,
    super.key,
  });

  final LearningSnapshot snapshot;
  final VoidCallback onOpenRoadmap;
  final VoidCallback onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('learning_home_success_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        const _LearningSectionTabs(),
        const SizedBox(height: AppSpacing.space4),
        _ProgressSummaryCard(snapshot: snapshot, onOpenRoadmap: onOpenRoadmap),
        const SizedBox(height: AppSpacing.space4),
        _CurrentLessonCard(
          lesson: snapshot.currentLesson,
          onOpenLesson: onOpenLesson,
        ),
        const SizedBox(height: AppSpacing.space5),
        Row(
          children: [
            Expanded(
              child: Text(
                'Các phần học chính',
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
            ),
            Text(
              'Xem tất cả',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        _LearningSections(
          sections: snapshot.sections,
          onOpenRoadmap: onOpenRoadmap,
        ),
      ],
    );
  }
}

class _LearningSectionTabs extends StatelessWidget {
  const _LearningSectionTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space1),
      decoration: BoxDecoration(
        color: AppColors.learnerSurfaceHighest,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _LearningSectionTab(
              label: 'Lộ trình',
              icon: Icons.map_outlined,
              selected: true,
            ),
          ),
          Expanded(
            child: _LearningSectionTab(
              label: 'Bài học',
              icon: Icons.menu_book_outlined,
            ),
          ),
          Expanded(
            child: _LearningSectionTab(
              label: 'Thư viện',
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningSectionTab extends StatelessWidget {
  const _LearningSectionTab({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      enabled: selected,
      label: label,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.compact),
          boxShadow: selected ? AppShadows.cardSoft : const <BoxShadow>[],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.brandPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: selected
                      ? AppColors.learnerTextPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.snapshot,
    required this.onOpenRoadmap,
  });

  final LearningSnapshot snapshot;
  final VoidCallback onOpenRoadmap;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.space3,
                  runSpacing: AppSpacing.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Mục tiêu JLPT ${snapshot.jlptTarget.label}',
                        style: AppTypography.badgeText.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Kỳ thi ${snapshot.examDateLabel}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${snapshot.overallPercent}%',
                    style: AppTypography.pageTitle.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'TIẾN ĐỘ TỔNG',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          _ProgressBar(
            value: snapshot.overallProgress,
            semanticsLabel: 'Tiến độ tổng ${snapshot.overallPercent} phần trăm',
            height: 10,
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.space3,
            runSpacing: AppSpacing.space1,
            children: [
              Text(
                'Đã hoàn thành ${snapshot.completedLessons}/'
                '${snapshot.totalLessons} bài học',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Chuỗi học: ${snapshot.streakDays} ngày 🔥',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.learnerTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          _MetricsRow(metrics: snapshot.metrics),
          const SizedBox(height: AppSpacing.space4),
          RikiPrimaryButton(
            key: const ValueKey<String>('learning_open_roadmap_button'),
            label: 'Tiếp tục lộ trình',
            trailingIcon: Icons.arrow_forward,
            onPressed: onOpenRoadmap,
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final List<LearningMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(child: _MetricItem(metric: metrics[index])),
            if (index != metrics.length - 1)
              const SizedBox(height: 36, child: VerticalDivider(width: 1)),
          ],
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.metric});

  final LearningMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.badgeText.copyWith(color: AppColors.textMuted),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${metric.current}'),
              TextSpan(
                text: '/${metric.total}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.learnerTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _CurrentLessonCard extends StatelessWidget {
  const _CurrentLessonCard({required this.lesson, required this.onOpenLesson});

  final CurrentLessonSummary lesson;
  final VoidCallback onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  'ĐANG HỌC DỞ',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.brandPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                'Chương ${lesson.chapterNumber} • Bài ${lesson.lessonNumber}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.learnerTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '${lesson.category}: ${lesson.pattern} • '
                      '${lesson.durationMinutes} phút',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _ProgressBar(
                  value: lesson.progress,
                  semanticsLabel:
                      'Tiến độ bài học ${lesson.progressPercent} phần trăm',
                  height: 8,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                '${lesson.progressPercent}%',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              TextButton(
                key: const ValueKey<String>('learning_continue_lesson_button'),
                onPressed: onOpenLesson,
                child: const Text('Học tiếp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearningSections extends StatelessWidget {
  const _LearningSections({
    required this.sections,
    required this.onOpenRoadmap,
  });

  final List<LearningSectionSummary> sections;
  final VoidCallback onOpenRoadmap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = sections.map((section) {
          return _LearningSectionCard(
            key: ValueKey<String>('learning_section_${section.kind.name}'),
            section: section,
            onPressed: section.kind == LearningSectionKind.roadmap
                ? onOpenRoadmap
                : null,
          );
        }).toList();

        if (constraints.maxWidth < 350) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1)
                  const SizedBox(height: AppSpacing.space3),
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                Expanded(child: cards[index]),
                if (index != cards.length - 1)
                  const SizedBox(width: AppSpacing.space3),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LearningSectionCard extends StatelessWidget {
  const _LearningSectionCard({
    required this.section,
    required this.onPressed,
    super.key,
  });

  final LearningSectionSummary section;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = RikiCard(
      borderColor: AppColors.border,
      boxShadow: const <BoxShadow>[],
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: section.kind.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.compact),
            ),
            child: Icon(section.kind.icon, color: section.kind.foregroundColor),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            section.title,
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.learnerTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            section.subtitle,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: section.kind.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.tag),
            ),
            child: Text(
              section.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.badgeText.copyWith(
                color: section.kind.foregroundColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: onPressed != null,
      enabled: onPressed != null,
      label: section.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: content,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.semanticsLabel,
    required this.height,
    this.color = AppColors.brandPrimary,
  });

  final double value;
  final String semanticsLabel;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        color: color,
        backgroundColor: AppColors.learnerSurfaceLow,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

extension on LearningSectionKind {
  IconData get icon => switch (this) {
    LearningSectionKind.roadmap => Icons.map_outlined,
    LearningSectionKind.lessons => Icons.menu_book_outlined,
    LearningSectionKind.library => Icons.inventory_2_outlined,
  };

  Color get foregroundColor => switch (this) {
    LearningSectionKind.roadmap => AppColors.brandPrimary,
    LearningSectionKind.lessons => AppColors.info,
    LearningSectionKind.library => AppColors.skillGrammar,
  };

  Color get backgroundColor => switch (this) {
    LearningSectionKind.roadmap => AppColors.brandTint,
    LearningSectionKind.lessons => AppColors.infoBackground,
    LearningSectionKind.library => AppColors.warningBackground,
  };
}
