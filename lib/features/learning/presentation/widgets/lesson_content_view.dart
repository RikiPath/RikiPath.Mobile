import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_shared_widgets.dart';

class LessonContentTabs extends StatelessWidget {
  const LessonContentTabs({
    required this.lesson,
    required this.selectedTab,
    required this.onSelected,
    super.key,
  });

  final Lesson lesson;
  final LessonContentTab selectedTab;
  final ValueChanged<LessonContentTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space1),
      decoration: BoxDecoration(
        color: AppColors.learnerSurface,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        children: [
          _LessonTabButton(
            label: context.l10n.contentTab,
            icon: Icons.article_outlined,
            selected: selectedTab == LessonContentTab.content,
            onPressed: () => onSelected(LessonContentTab.content),
          ),
          _LessonTabButton(
            label: context.l10n.notesTab(lesson.noteCount),
            icon: Icons.edit_note_outlined,
            selected: selectedTab == LessonContentTab.notes,
            onPressed: () => onSelected(LessonContentTab.notes),
          ),
          _LessonTabButton(
            label: context.l10n.vocabularyTab(lesson.videoVocabularyCount),
            icon: Icons.style_outlined,
            selected: selectedTab == LessonContentTab.vocabulary,
            onPressed: () => onSelected(LessonContentTab.vocabulary),
          ),
        ],
      ),
    );
  }
}

class LessonArticleContent extends StatelessWidget {
  const LessonArticleContent({required this.lesson, super.key});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('lesson_article_content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ArticleCard(
          title: context.l10n.lessonObjective,
          icon: Icons.flag_outlined,
          child: Text(
            lesson.objective,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        _ArticleCard(
          title: context.l10n.coreStructure,
          icon: Icons.auto_stories_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (
                var index = 0;
                index < lesson.article.formulas.length;
                index++
              ) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.learnerSurfaceLow,
                    borderRadius: BorderRadius.circular(AppRadius.compact),
                  ),
                  child: Text(
                    lesson.article.formulas[index],
                    textAlign: TextAlign.center,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
                if (index != lesson.article.formulas.length - 1)
                  const SizedBox(height: AppSpacing.space2),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        _ArticleCard(
          title: context.l10n.meaning,
          icon: Icons.menu_book_outlined,
          child: Text(
            lesson.article.meaning,
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.brandPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        _ArticleCard(
          title: context.l10n.usageAndContext,
          icon: Icons.format_list_numbered,
          child: Column(
            children: [
              for (
                var index = 0;
                index < lesson.article.usageSteps.length;
                index++
              ) ...[
                _NumberedCopy(
                  number: index + 1,
                  text: lesson.article.usageSteps[index],
                ),
                if (index != lesson.article.usageSteps.length - 1)
                  const SizedBox(height: AppSpacing.space3),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          context.l10n.practicalExamplesTitle,
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.learnerTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        for (
          var index = 0;
          index < lesson.article.examples.length;
          index++
        ) ...[
          _ExampleCard(example: lesson.article.examples[index]),
          if (index != lesson.article.examples.length - 1)
            const SizedBox(height: AppSpacing.space3),
        ],
        const SizedBox(height: AppSpacing.space4),
        _ArticleCard(
          title: context.l10n.importantGrammarNotes,
          icon: Icons.warning_amber_rounded,
          child: Column(
            children: [
              for (
                var index = 0;
                index < lesson.article.importantNotes.length;
                index++
              ) ...[
                _NumberedCopy(
                  number: index + 1,
                  text: lesson.article.importantNotes[index],
                ),
                if (index != lesson.article.importantNotes.length - 1)
                  const SizedBox(height: AppSpacing.space3),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class LessonVocabularyContent extends StatelessWidget {
  const LessonVocabularyContent({required this.lesson, super.key});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('lesson_vocabulary_content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.space3,
          runSpacing: AppSpacing.space1,
          children: [
            Text(
              context.l10n.importantVocabulary,
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.learnerTextPrimary,
              ),
            ),
            Text(
              context.l10n.wordsAppearing(lesson.vocabulary.length),
              style: AppTypography.metadata.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        for (var index = 0; index < lesson.vocabulary.length; index++) ...[
          LessonVocabularyTile(item: lesson.vocabulary[index]),
          if (index != lesson.vocabulary.length - 1)
            const SizedBox(height: AppSpacing.space3),
        ],
      ],
    );
  }
}

class LessonArticleOnlyView extends StatelessWidget {
  const LessonArticleOnlyView({
    required this.lesson,
    required this.onOpenVideo,
    super.key,
  });

  final Lesson lesson;
  final VoidCallback onOpenVideo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('lesson_article_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        RikiCard(
          backgroundColor: AppColors.learnerSurfaceLow,
          boxShadow: const <BoxShadow>[],
          child: Row(
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.topicUpper(lesson.category.toUpperCase()),
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      context.l10n.topicSubtitle,
                      style: AppTypography.cardTitle,
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                key: const ValueKey<String>('lesson_article_open_video'),
                tooltip: context.l10n.openLessonVideo,
                onPressed: onOpenVideo,
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space5),
        LessonArticleContent(lesson: lesson),
      ],
    );
  }
}

class _LessonTabButton extends StatelessWidget {
  const _LessonTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.compact),
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space1,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.compact),
              boxShadow: selected ? AppShadows.cardSoft : const <BoxShadow>[],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badgeText.copyWith(
                    color: selected
                        ? AppColors.brandPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      boxShadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppColors.brandPrimary),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.learnerTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          child,
        ],
      ),
    );
  }
}

class _NumberedCopy extends StatelessWidget {
  const _NumberedCopy({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: AppColors.learnerSurface,
          foregroundColor: AppColors.learnerTextPrimary,
          child: Text(
            '$number',
            style: AppTypography.badgeText.copyWith(fontSize: 10),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.example});

  final LessonExample example;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.brandBorder,
      boxShadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  example.japanese,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.learnerTextPrimary,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.brandTint,
                foregroundColor: AppColors.brandPrimary,
                child: Icon(Icons.volume_up_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            example.reading,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.learnerSurfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.compact),
            ),
            child: Text(
              '👉 ${example.translation}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.learnerTextPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
