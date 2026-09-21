import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_shared_widgets.dart';

class LessonDetailView extends StatelessWidget {
  const LessonDetailView({
    required this.lesson,
    required this.onStart,
    super.key,
  });

  final Lesson lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('lesson_detail_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        _LessonHero(lesson: lesson),
        const SizedBox(height: AppSpacing.space4),
        _ObjectiveCard(objective: lesson.objective),
        const SizedBox(height: AppSpacing.space4),
        _StreakCard(lesson: lesson),
        const SizedBox(height: AppSpacing.space5),
        _SectionHeader(
          title: context.l10n.lessonContentCount(lesson.parts.length),
          trailing: context.l10n.totalDuration(lesson.durationMinutes),
        ),
        const SizedBox(height: AppSpacing.space3),
        for (var index = 0; index < lesson.parts.length; index++) ...[
          _LessonPartTile(part: lesson.parts[index]),
          if (index != lesson.parts.length - 1)
            const SizedBox(height: AppSpacing.space2),
        ],
        const SizedBox(height: AppSpacing.space5),
        _SectionHeader(
          title: context.l10n.focusVocabulary,
          trailing: context.l10n.vocabularyCount(lesson.detailVocabularyCount),
        ),
        const SizedBox(height: AppSpacing.space3),
        for (
          var index = 0;
          index < lesson.vocabulary.take(2).length;
          index++
        ) ...[
          LessonVocabularyTile(item: lesson.vocabulary[index]),
          if (index != lesson.vocabulary.take(2).length - 1)
            const SizedBox(height: AppSpacing.space2),
        ],
        const SizedBox(height: AppSpacing.space5),
        _SectionHeader(title: context.l10n.relatedGrammarShort),
        const SizedBox(height: AppSpacing.space3),
        for (var index = 0; index < lesson.relatedGrammar.length; index++) ...[
          _RelatedGrammarCard(grammar: lesson.relatedGrammar[index]),
          if (index != lesson.relatedGrammar.length - 1)
            const SizedBox(height: AppSpacing.space2),
        ],
        const SizedBox(height: AppSpacing.space5),
        RikiPrimaryButton(
          key: const ValueKey<String>('lesson_start_button'),
          label: lesson.progress.resumePositionSeconds > 0
              ? context.l10n.continueLessonProgress(
                  lesson.progress.progressPercent,
                )
              : context.l10n.startLesson,
          trailingIcon: Icons.arrow_forward,
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _LessonHero extends StatelessWidget {
  const _LessonHero({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonMetadataWrap(lesson: lesson),
          const SizedBox(height: AppSpacing.space3),
          Text(
            lesson.title,
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.learnerTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.l10n.focusLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(AppRadius.compact),
                ),
                child: Text(
                  lesson.focus,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          LessonProgressMeter(progress: lesson.progress),
          const SizedBox(height: AppSpacing.space2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              context.l10n.partProgress(
                lesson.currentPartNumber,
                lesson.parts.length,
              ),
              style: AppTypography.metadata.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({required this.objective});

  final String objective;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      backgroundColor: AppColors.learnerSurfaceLow,
      boxShadow: const <BoxShadow>[],
      borderColor: AppColors.learnerSurfaceLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
            child: Icon(Icons.flag_outlined, size: 20),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.lessonObjective,
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.learnerTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  objective,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      boxShadow: const <BoxShadow>[],
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.warningBackground,
            foregroundColor: AppColors.skillGrammar,
            child: Icon(Icons.local_fire_department_outlined, size: 20),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.streakMotivation(lesson.streakDays),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.learnerTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.keepStreakMessage,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${lesson.detailXp} XP',
            style: AppTypography.badgeText.copyWith(
              color: AppColors.learnerTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonPartTile extends StatelessWidget {
  const _LessonPartTile({required this.part});

  final LessonPart part;

  @override
  Widget build(BuildContext context) {
    final isCurrent = part.status == LessonPartStatus.current;
    final isCompleted = part.status == LessonPartStatus.completed;
    final color = isCurrent
        ? AppColors.brandPrimary
        : isCompleted
        ? AppColors.success
        : AppColors.textMuted;
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      borderColor: isCurrent ? AppColors.brandSelectedBorder : AppColors.border,
      backgroundColor: isCurrent ? AppColors.brandTint : AppColors.surface,
      boxShadow: const <BoxShadow>[],
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isCurrent
                ? AppColors.brandPrimary
                : isCompleted
                ? AppColors.successBackground
                : AppColors.learnerSurfaceLow,
            foregroundColor: isCurrent ? Colors.white : color,
            child: Icon(
              isCurrent
                  ? Icons.play_arrow
                  : isCompleted
                  ? Icons.check_circle_outline
                  : Icons.menu_book_outlined,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${part.number}. ${part.title}',
                  style: AppTypography.cardTitle.copyWith(color: color),
                ),
                Text(
                  '${part.subtitle} • '
                  '${context.l10n.durationMinutes(part.durationMinutes)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          if (isCompleted)
            Text(
              context.l10n.done,
              style: AppTypography.badgeText.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (isCurrent)
            const Icon(Icons.play_circle_fill, color: AppColors.brandPrimary)
          else
            const Icon(
              Icons.lock_outline,
              color: AppColors.textMuted,
              size: 19,
            ),
        ],
      ),
    );
  }
}

class _RelatedGrammarCard extends StatelessWidget {
  const _RelatedGrammarCard({required this.grammar});

  final LessonRelatedGrammar grammar;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      boxShadow: const <BoxShadow>[],
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.learnerSurfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.compact),
            ),
            child: Text(
              '${grammar.number}',
              style: AppTypography.badgeText.copyWith(
                color: AppColors.learnerTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grammar.title, style: AppTypography.cardTitle),
                Text(
                  grammar.description,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.learnerTextPrimary,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTypography.metadata.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
