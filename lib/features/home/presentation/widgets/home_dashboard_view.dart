import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({
    required this.dashboard,
    required this.onOpenLearning,
    required this.onOpenNotebook,
    required this.onOpenPractice,
    super.key,
  });

  final HomeDashboard dashboard;
  final VoidCallback onOpenLearning;
  final VoidCallback onOpenNotebook;
  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('home_success_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        _GreetingSection(dashboard: dashboard),
        const SizedBox(height: AppSpacing.space5),
        _FirstLessonCard(
          lesson: dashboard.firstLesson,
          onPressed: onOpenLearning,
        ),
        const SizedBox(height: AppSpacing.space4),
        _RoadmapCard(
          roadmap: dashboard.roadmap,
          onPressed: onOpenLearning,
        ),
        const SizedBox(height: AppSpacing.space4),
        _SetupCard(
          setup: dashboard.setup,
          onOpenLearning: onOpenLearning,
        ),
        const SizedBox(height: AppSpacing.space6),
        Text(
          'Làm quen với công cụ học tập',
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.learnerTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        _ToolGrid(
          tools: dashboard.tools,
          onOpenNotebook: onOpenNotebook,
          onOpenPractice: onOpenPractice,
        ),
      ],
    );
  }
}

class HomeErrorView extends StatelessWidget {
  const HomeErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('home_error_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        const SizedBox(height: AppSpacing.space10),
        RikiCard(
          borderColor: AppColors.learnerOutline,
          boxShadow: const <BoxShadow>[],
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.errorBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  color: AppColors.errorText,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Chưa thể tải Trang chủ',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Vui lòng kiểm tra kết nối và thử lại.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>('home_retry_button'),
                label: 'Thử lại',
                leadingIcon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final greeting = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, ${dashboard.learnerName}! 👋',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.compactPageTitle.copyWith(
                color: AppColors.learnerTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Mục tiêu JLPT ${dashboard.jlptTarget.label}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
                const _DotSeparator(),
                Text(
                  dashboard.goalStatus,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );
        final status = _JourneyStatus(label: dashboard.journeyStatus);

        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greeting,
              const SizedBox(height: AppSpacing.space3),
              status,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: AppSpacing.space3),
            status,
          ],
        );
      },
    );
  }
}

class _JourneyStatus extends StatelessWidget {
  const _JourneyStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.learnerOutline),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.badgeText.copyWith(
              color: AppColors.brandPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstLessonCard extends StatelessWidget {
  const _FirstLessonCard({required this.lesson, required this.onPressed});

  final HomeLessonSummary lesson;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final percentage = (lesson.progress * 100).round();

    return RikiCard(
      borderColor: AppColors.learnerOutline,
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: AppSpacing.space2,
            spacing: AppSpacing.space3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Eyebrow(
                icon: Icons.flag_outlined,
                label: lesson.eyebrow,
              ),
              _Pill(label: lesson.badge),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            lesson.title,
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.learnerTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            lesson.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.learnerTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Chưa bắt đầu',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            ' • ${lesson.completedParts}/${lesson.totalParts} phần hoàn thành',
                      ),
                    ],
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                '$percentage%',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.learnerTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: lesson.progress,
              minHeight: 10,
              color: AppColors.brandPrimary,
              backgroundColor: AppColors.learnerSurfaceHigh,
              semanticsLabel: 'Tiến độ bài học $percentage phần trăm',
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          RikiPrimaryButton(
            key: const ValueKey<String>('home_start_learning_button'),
            label: 'Bắt đầu học',
            trailingIcon: Icons.arrow_forward,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({required this.roadmap, required this.onPressed});

  final HomeRoadmapSummary roadmap;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.learnerOutline,
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconTile(
                icon: Icons.map_outlined,
                backgroundColor: AppColors.learnerSurfaceHigh,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roadmap.title,
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.learnerTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      roadmap.subtitle,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.learnerTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              _Pill(label: '${roadmap.stageCount} chặng'),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            roadmap.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.learnerTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Được cá nhân hóa theo năng lực',
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.learnerTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              RikiTextButton(
                key: const ValueKey<String>('home_roadmap_button'),
                label: 'Xem lộ trình',
                trailingIcon: Icons.arrow_forward,
                onPressed: onPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.setup, required this.onOpenLearning});

  final HomeSetupSummary setup;
  final VoidCallback onOpenLearning;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      backgroundColor: AppColors.learnerSurface,
      borderColor: AppColors.learnerSurfaceHigh,
      boxShadow: const <BoxShadow>[],
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconTile(
                icon: Icons.task_alt,
                backgroundColor: AppColors.learnerSurfaceHigh,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết lập ban đầu',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.learnerTextPrimary,
                      ),
                    ),
                    Text(
                      'Các bước khởi đầu cho người mới',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.learnerTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(label: '${setup.completedCount}/${setup.totalCount} hoàn tất'),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          for (var index = 0; index < setup.items.length; index++) ...[
            _SetupItemTile(
              item: setup.items[index],
              onPressed:
                  setup.items[index].actionLabel == null ? null : onOpenLearning,
            ),
            if (index != setup.items.length - 1)
              const SizedBox(height: AppSpacing.space2),
          ],
        ],
      ),
    );
  }
}

class _SetupItemTile extends StatelessWidget {
  const _SetupItemTile({required this.item, this.onPressed});

  final HomeSetupItem item;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: item.isComplete
          ? AppColors.learnerOutline
          : AppColors.brandSelectedBorder,
      boxShadow: const <BoxShadow>[],
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.isComplete
                  ? AppColors.learnerPrimaryFixed
                  : AppColors.learnerSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isComplete ? Icons.check : Icons.hourglass_top,
              color: AppColors.brandPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.cardTitle.copyWith(
                    color: item.isComplete
                        ? AppColors.learnerTextPrimary
                        : AppColors.brandPrimary,
                  ),
                ),
                Text(
                  item.description,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (item.actionLabel != null) ...[
            const SizedBox(width: AppSpacing.space2),
            TextButton(
              key: const ValueKey<String>('home_setup_learning_button'),
              onPressed: onPressed,
              child: Text(item.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({
    required this.tools,
    required this.onOpenNotebook,
    required this.onOpenPractice,
  });

  final List<HomeToolSummary> tools;
  final VoidCallback onOpenNotebook;
  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = tools.map((tool) {
          final isNotebook = tool.destination == HomeToolDestination.notebook;
          return _ToolCard(
            key: ValueKey<String>(
              isNotebook ? 'home_notebook_shortcut' : 'home_practice_shortcut',
            ),
            tool: tool,
            icon: isNotebook ? Icons.style_outlined : Icons.quiz_outlined,
            iconBackground: isNotebook
                ? AppColors.learnerPrimaryFixed
                : AppColors.learnerSurfaceHigh,
            onPressed: isNotebook ? onOpenNotebook : onOpenPractice,
          );
        }).toList();

        if (constraints.maxWidth < 340) {
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

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.icon,
    required this.iconBackground,
    required this.onPressed,
    super.key,
  });

  final HomeToolSummary tool;
  final IconData icon;
  final Color iconBackground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tool.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: RikiCard(
            borderColor: AppColors.learnerOutline,
            boxShadow: const <BoxShadow>[],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconTile(icon: icon, backgroundColor: iconBackground),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  tool.title,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.learnerTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  tool.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconTile(
          icon: icon,
          backgroundColor: AppColors.learnerPrimaryFixed,
          size: 32,
          iconSize: 18,
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          label.toUpperCase(),
          style: AppTypography.badgeText.copyWith(
            color: AppColors.learnerTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.backgroundColor,
    this.size = 36,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.compact),
      ),
      child: Icon(
        icon,
        color: AppColors.brandPrimary,
        size: iconSize,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.learnerPrimaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: AppColors.brandPrimaryPressed,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.learnerOutline,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(dimension: 4),
    );
  }
}
