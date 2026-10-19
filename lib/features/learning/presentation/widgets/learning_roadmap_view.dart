import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_localization.dart';

class LearningRoadmapView extends StatelessWidget {
  const LearningRoadmapView({
    required this.snapshot,
    required this.onOpenProgress,
    required this.onContinueLesson,
    this.onOpenLesson,
    super.key,
  });

  final LearningSnapshot snapshot;
  final VoidCallback onOpenProgress;
  final VoidCallback onContinueLesson;
  final ValueChanged<String>? onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('learning_roadmap_success_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        _RoadmapProgressSummary(snapshot: snapshot),
        const SizedBox(height: AppSpacing.space5),
        if (snapshot.lessons.isNotEmpty)
          Column(
            children: [
              for (var index = 0; index < snapshot.lessons.length; index++) ...[
                _LiveLessonCard(
                  lesson: snapshot.lessons[index],
                  onOpen: () => (onOpenLesson ?? (_) => onContinueLesson())(
                    snapshot.lessons[index].routeId,
                  ),
                ),
                if (index != snapshot.lessons.length - 1)
                  const SizedBox(height: AppSpacing.space3),
              ],
            ],
          )
        else if (snapshot.chapters.isNotEmpty)
          Stack(
            children: [
              const Positioned(
                left: 16,
                top: AppSpacing.space6,
                bottom: AppSpacing.space6,
                child: SizedBox(
                  width: 2,
                  child: ColoredBox(color: AppColors.border),
                ),
              ),
              Column(
                children: [
                  for (
                    var index = 0;
                    index < snapshot.chapters.length;
                    index++
                  ) ...[
                    _RoadmapChapterCard(
                      chapter: snapshot.chapters[index],
                      onOpenProgress: onOpenProgress,
                      onContinueLesson: onContinueLesson,
                    ),
                    if (index != snapshot.chapters.length - 1)
                      const SizedBox(height: AppSpacing.space4),
                  ],
                ],
              ),
            ],
          )
        else
          RikiCard(
            key: const ValueKey<String>('learning_roadmap_empty'),
            boxShadow: const <BoxShadow>[],
            child: Text(
              context.l10n.learningLessonsEmptyMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoadmapProgressSummary extends StatelessWidget {
  const _RoadmapProgressSummary({required this.snapshot});

  final LearningSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      context.l10n.overallProgressTitle,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (snapshot.certificateLevelId == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successBackground,
                          border: Border.all(color: AppColors.successBorder),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          context.l10n.onTrack,
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                '${snapshot.overallPercent}%',
                style: AppTypography.pageTitle.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: snapshot.overallProgress,
              minHeight: 10,
              color: AppColors.brandPrimary,
              backgroundColor: AppColors.learnerSurfaceLow,
              semanticsLabel: context.l10n.overallProgressSemantics(
                snapshot.overallPercent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.space3,
            runSpacing: AppSpacing.space1,
            children: [
              if (snapshot.certificateLevelId == null)
                Text(
                  context.l10n.completedChapters(
                    snapshot.completedChapters,
                    snapshot.totalChapters,
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                context.l10n.achievedLessons(
                  snapshot.completedLessons,
                  snapshot.totalLessons,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveLessonCard extends StatelessWidget {
  const _LiveLessonCard({required this.lesson, required this.onOpen});

  final LearningLessonSummary lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      key: ValueKey<String>('roadmap_live_lesson_${lesson.lessonId}'),
      boxShadow: const <BoxShadow>[],
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: lesson.isCompleted
                ? AppColors.successBackground
                : AppColors.brandTint,
            foregroundColor: lesson.isCompleted
                ? AppColors.success
                : AppColors.brandPrimary,
            child: Icon(
              lesson.isCompleted ? Icons.check : Icons.menu_book_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.lessonNumber(lesson.sortOrder),
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(lesson.title, style: AppTypography.cardTitle),
                Text(
                  lesson.languageSkillName,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                LinearProgressIndicator(
                  value: lesson.progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: lesson.isCompleted
                      ? AppColors.success
                      : AppColors.brandPrimary,
                  backgroundColor: AppColors.learnerSurfaceLow,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          IconButton(
            tooltip: context.l10n.continueLearning,
            onPressed: onOpen,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _RoadmapChapterCard extends StatelessWidget {
  const _RoadmapChapterCard({
    required this.chapter,
    required this.onOpenProgress,
    required this.onContinueLesson,
  });

  final RoadmapChapter chapter;
  final VoidCallback onOpenProgress;
  final VoidCallback onContinueLesson;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      key: ValueKey<String>('roadmap_chapter_${chapter.status.name}'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: chapter.status.borderColor,
          width: chapter.status == RoadmapChapterStatus.current ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: chapter.status == RoadmapChapterStatus.current
            ? AppShadows.selectedCard
            : AppShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChapterHeader(chapter: chapter),
          const SizedBox(height: AppSpacing.space3),
          Text(
            chapter.description,
            style: AppTypography.bodySmall.copyWith(
              color: chapter.status == RoadmapChapterStatus.locked
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          _ChapterSkills(chapter: chapter),
          if (chapter.status == RoadmapChapterStatus.completed) ...[
            const SizedBox(height: AppSpacing.space2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey<String>('roadmap_open_progress_button'),
                onPressed: onOpenProgress,
                label: Text(context.l10n.reviewResults),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right, size: 18),
              ),
            ),
          ],
          if (chapter.status == RoadmapChapterStatus.current) ...[
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey<String>('roadmap_continue_lesson_button'),
                onPressed: onContinueLesson,
                label: Text(context.l10n.continueLessonNineteen),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ],
          if (chapter.lockedReason != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: Text(
                chapter.lockedReason!,
                textAlign: TextAlign.center,
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return chapter.status == RoadmapChapterStatus.locked
        ? Opacity(opacity: 0.78, child: card)
        : card;
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.chapter});

  final RoadmapChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: chapter.status.markerBackground,
            shape: BoxShape.circle,
          ),
          child: chapter.status == RoadmapChapterStatus.completed
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : chapter.status == RoadmapChapterStatus.locked
              ? const Icon(
                  Icons.lock_outline,
                  color: AppColors.textMuted,
                  size: 20,
                )
              : Text(
                  '${chapter.number}',
                  style: AppTypography.cardTitle.copyWith(
                    color: chapter.status.markerForeground,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    context.l10n.chapterNumberUpper(chapter.number),
                    style: AppTypography.badgeText.copyWith(
                      color: chapter.status.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    context.l10n.lessonRange(
                      chapter.firstLesson,
                      chapter.lastLesson,
                    ),
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                chapter.title,
                style: AppTypography.sectionTitle.copyWith(
                  color: chapter.status == RoadmapChapterStatus.locked
                      ? AppColors.textSecondary
                      : AppColors.learnerTextPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: chapter.status.statusBackground,
            border: Border.all(color: chapter.status.statusBorder),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            chapter.status.localizedLabel(context),
            style: AppTypography.badgeText.copyWith(
              color: chapter.status.foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChapterSkills extends StatelessWidget {
  const _ChapterSkills({required this.chapter});

  final RoadmapChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chapter.status != RoadmapChapterStatus.locked) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    chapter.status == RoadmapChapterStatus.completed
                        ? context.l10n.skillsAchievedUpper
                        : context.l10n.fiveSkillProgressUpper,
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (chapter.status == RoadmapChapterStatus.current)
                  Text(
                    context.l10n.lessonCountUpper(
                      chapter.completedLessons,
                      chapter.totalLessons,
                    ),
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.brandPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          if (chapter.status == RoadmapChapterStatus.current)
            for (var index = 0; index < chapter.skills.length; index++) ...[
              _CurrentSkillTile(skill: chapter.skills[index]),
              if (index != chapter.skills.length - 1)
                const SizedBox(height: AppSpacing.space2),
            ]
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - AppSpacing.space2) / 2;
                return Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    for (final skill in chapter.skills)
                      SizedBox(
                        width:
                            chapter.skills.length.isOdd &&
                                skill == chapter.skills.last
                            ? constraints.maxWidth
                            : width,
                        child: _CompactSkillTile(skill: skill),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CompactSkillTile extends StatelessWidget {
  const _CompactSkillTile({required this.skill});

  final ChapterSkillSummary skill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.compact),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              skill.category.localizedLabel(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space1),
          Flexible(
            child: Text(
              skill.detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: skill.status == ChapterSkillStatus.completed
                    ? AppColors.success
                    : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentSkillTile extends StatelessWidget {
  const _CurrentSkillTile({required this.skill});

  final ChapterSkillSummary skill;

  @override
  Widget build(BuildContext context) {
    final color = switch (skill.status) {
      ChapterSkillStatus.completed => AppColors.success,
      ChapterSkillStatus.inProgress => AppColors.brandPrimary,
      ChapterSkillStatus.notStarted ||
      ChapterSkillStatus.locked => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.compact),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  skill.category.localizedLabel(context),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Flexible(
                child: Text(
                  skill.detail,
                  textAlign: TextAlign.end,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (skill.progress != null) ...[
            const SizedBox(height: AppSpacing.space1),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: skill.progress,
                minHeight: 6,
                color: color,
                backgroundColor: AppColors.progressTrack,
                semanticsLabel: context.l10n.progressSemantics(
                  skill.category.localizedLabel(context),
                  ((skill.progress ?? 0) * 100).round(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension on RoadmapChapterStatus {
  String localizedLabel(BuildContext context) => switch (this) {
    RoadmapChapterStatus.completed => context.l10n.statusCompleted,
    RoadmapChapterStatus.current => context.l10n.statusLearning,
    RoadmapChapterStatus.available => context.l10n.statusReady,
    RoadmapChapterStatus.locked => context.l10n.statusNotStarted,
  };

  Color get foreground => switch (this) {
    RoadmapChapterStatus.completed => AppColors.success,
    RoadmapChapterStatus.current => AppColors.brandPrimary,
    RoadmapChapterStatus.available => AppColors.info,
    RoadmapChapterStatus.locked => AppColors.textMuted,
  };

  Color get borderColor => switch (this) {
    RoadmapChapterStatus.completed => AppColors.successBorder,
    RoadmapChapterStatus.current => AppColors.brandPrimary,
    RoadmapChapterStatus.available => AppColors.infoBorder,
    RoadmapChapterStatus.locked => AppColors.border,
  };

  Color get markerBackground => switch (this) {
    RoadmapChapterStatus.completed => AppColors.successAccent,
    RoadmapChapterStatus.current => AppColors.brandPrimary,
    RoadmapChapterStatus.available => AppColors.infoBackground,
    RoadmapChapterStatus.locked => AppColors.border,
  };

  Color get markerForeground => switch (this) {
    RoadmapChapterStatus.completed ||
    RoadmapChapterStatus.current => Colors.white,
    RoadmapChapterStatus.available => AppColors.info,
    RoadmapChapterStatus.locked => AppColors.textMuted,
  };

  Color get statusBackground => switch (this) {
    RoadmapChapterStatus.completed => AppColors.successBackground,
    RoadmapChapterStatus.current => AppColors.brandTint,
    RoadmapChapterStatus.available => AppColors.infoBackground,
    RoadmapChapterStatus.locked => AppColors.surfaceSubtle,
  };

  Color get statusBorder => switch (this) {
    RoadmapChapterStatus.completed => AppColors.successBorder,
    RoadmapChapterStatus.current => AppColors.brandBorder,
    RoadmapChapterStatus.available => AppColors.infoBorder,
    RoadmapChapterStatus.locked => AppColors.border,
  };
}
