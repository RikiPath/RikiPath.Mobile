import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/vocabulary/application/vocabulary_controller.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';

class VocabularyDetailView extends StatelessWidget {
  const VocabularyDetailView({
    required this.state,
    required this.onPlayAudio,
    required this.onSave,
    required this.onOpenLesson,
    super.key,
  });

  final VocabularyDetailState state;
  final Future<bool> Function() onPlayAudio;
  final VoidCallback onSave;
  final ValueChanged<VocabularyRelatedLesson> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final entry = state.entry;
    final enrichment = entry.enrichment;
    final examples = enrichment?.examples ?? const <VocabularyExample>[];

    return ListView(
      key: const ValueKey<String>('vocabulary_detail_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        if (entry.source == VocabularyDataSource.fixture) ...[
          const _FixtureNotice(),
          const SizedBox(height: AppSpacing.space3),
        ],
        _WordHero(
          entry: entry,
          isPlayingAudio: state.isPlayingAudio,
          onPlayAudio: onPlayAudio,
        ),
        if (state.audioError != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            state.audioError!,
            textAlign: TextAlign.center,
            style: AppTypography.validationText,
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        _MeaningCard(entry: entry),
        if (entry.exampleSentence != null && examples.isEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          _SectionCard(
            title: 'Ví dụ',
            icon: Icons.format_quote_outlined,
            child: SelectableText(
              entry.exampleSentence!,
              style: AppTypography.body.copyWith(
                color: AppColors.learnerTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (examples.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          _ExamplesCard(examples: examples),
        ],
        if (enrichment?.collocations.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.space4),
          _CollocationsCard(collocations: enrichment!.collocations),
        ],
        if (enrichment?.nuance != null) ...[
          const SizedBox(height: AppSpacing.space4),
          _SectionCard(
            title: 'Sắc thái sử dụng',
            icon: Icons.lightbulb_outline,
            child: Text(enrichment!.nuance!, style: AppTypography.body),
          ),
        ],
        if (enrichment?.kanji.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.space4),
          _KanjiCard(parts: enrichment!.kanji),
        ],
        if (enrichment?.relatedLessons.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.space4),
          _RelatedLessonsCard(
            lessons: enrichment!.relatedLessons,
            onOpenLesson: onOpenLesson,
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        _NotebookCard(state: state, onSave: onSave),
      ],
    );
  }
}

class _FixtureNotice extends StatelessWidget {
  const _FixtureNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('vocabulary_detail_fixture_notice'),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 20,
            color: AppColors.warningText,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              'Nội dung mở rộng bên dưới là dữ liệu minh họa cục bộ.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warningText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordHero extends StatelessWidget {
  const _WordHero({
    required this.entry,
    required this.isPlayingAudio,
    required this.onPlayAudio,
  });

  final VocabularyEntry entry;
  final bool isPlayingAudio;
  final Future<bool> Function() onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final sinoVietnamese = entry.enrichment?.sinoVietnamese;
    final partOfSpeech = entry.partOfSpeech?.trim();

    return RikiCard(
      borderColor: AppColors.learnerOutline,
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        children: [
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            alignment: WrapAlignment.center,
            children: [
              JlptBadge(entry.level),
              if (partOfSpeech != null && partOfSpeech.isNotEmpty)
                _Pill(label: partOfSpeech),
              if (entry.enrichment?.frequencyLabel != null)
                _Pill(
                  label: entry.enrichment!.frequencyLabel!,
                  color: AppColors.success,
                  background: AppColors.successBackground,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          SelectableText(
            entry.reading,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SelectableText(
            entry.word,
            textAlign: TextAlign.center,
            style: AppTypography.heroTitle.copyWith(
              color: AppColors.learnerTextPrimary,
              fontSize: 50,
              height: 1.2,
            ),
          ),
          if (sinoVietnamese != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              sinoVietnamese,
              textAlign: TextAlign.center,
              style: AppTypography.badgeText.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          OutlinedButton.icon(
            key: const ValueKey<String>('vocabulary_detail_audio_button'),
            onPressed: entry.audioUrl == null || isPlayingAudio
                ? null
                : onPlayAudio,
            icon: isPlayingAudio
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.volume_up_outlined),
            label: Text(
              entry.audioUrl == null ? 'Chưa có âm thanh' : 'Nghe phát âm',
            ),
          ),
        ],
      ),
    );
  }
}

class _MeaningCard extends StatelessWidget {
  const _MeaningCard({required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    final definition = entry.enrichment?.definition;
    return _SectionCard(
      title: 'Ý nghĩa',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.meaning,
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.learnerTextPrimary,
            ),
          ),
          if (definition != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(definition, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

class _ExamplesCard extends StatelessWidget {
  const _ExamplesCard({required this.examples});

  final List<VocabularyExample> examples;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Ví dụ',
      icon: Icons.format_quote_outlined,
      child: Column(
        children: [
          for (var index = 0; index < examples.length; index++) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                examples[index].sentence,
                style: AppTypography.body.copyWith(
                  color: AppColors.learnerTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (examples[index].translation != null) ...[
              const SizedBox(height: AppSpacing.space1),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  examples[index].translation!,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
            if (index != examples.length - 1) ...[
              const SizedBox(height: AppSpacing.space3),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.space3),
            ],
          ],
        ],
      ),
    );
  }
}

class _CollocationsCard extends StatelessWidget {
  const _CollocationsCard({required this.collocations});

  final List<VocabularyCollocation> collocations;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Cụm từ thường gặp',
      icon: Icons.hub_outlined,
      child: Column(
        children: [
          for (final collocation in collocations)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      collocation.phrase,
                      style: AppTypography.body.copyWith(
                        color: AppColors.learnerTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      collocation.meaning,
                      textAlign: TextAlign.end,
                      style: AppTypography.bodySmall,
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

class _KanjiCard extends StatelessWidget {
  const _KanjiCard({required this.parts});

  final List<VocabularyKanjiPart> parts;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Phân tích Kanji',
      icon: Icons.grid_view_outlined,
      child: Column(
        children: [
          for (final part in parts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.compact),
                    ),
                    child: Text(
                      part.character,
                      style: AppTypography.pageTitle.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.sinoVietnamese,
                          style: AppTypography.cardTitle,
                        ),
                        Text(part.meaning, style: AppTypography.bodySmall),
                        Text(
                          'On: ${part.onReading}',
                          style: AppTypography.metadata,
                        ),
                      ],
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

class _RelatedLessonsCard extends StatelessWidget {
  const _RelatedLessonsCard({
    required this.lessons,
    required this.onOpenLesson,
  });

  final List<VocabularyRelatedLesson> lessons;
  final ValueChanged<VocabularyRelatedLesson> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Bài học liên quan',
      icon: Icons.school_outlined,
      child: Column(
        children: [
          for (final lesson in lessons)
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.brandTint,
                  foregroundColor: AppColors.brandPrimary,
                  child: Text('${lesson.number}'),
                ),
                title: Text(lesson.title, style: AppTypography.cardTitle),
                subtitle: Text(lesson.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenLesson(lesson),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({required this.state, required this.onSave});

  final VocabularyDetailState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (state.isSaved) {
      return Container(
        key: const ValueKey<String>('vocabulary_saved_banner'),
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.successBackground,
          border: Border.all(color: AppColors.successBorder),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const Icon(Icons.bookmark, color: AppColors.success),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                state.savedListName == null
                    ? 'Từ này đã được lưu.'
                    : 'Đã lưu vào ${state.savedListName}.',
                style: AppTypography.body.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      title: 'Sổ từ cá nhân',
      icon: Icons.bookmark_border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lưu từ này để ôn tập trong danh sách của bạn.',
            style: AppTypography.bodySmall,
          ),
          if (state.notebookError != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(state.notebookError!, style: AppTypography.validationText),
          ],
          const SizedBox(height: AppSpacing.space3),
          RikiPrimaryButton(
            key: const ValueKey<String>('vocabulary_save_button'),
            label: 'Lưu vào Sổ từ',
            loadingLabel: 'Đang xử lý...',
            isLoading: state.isLoadingNotebook || state.isSaving,
            leadingIcon: Icons.bookmark_add_outlined,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
      borderColor: AppColors.border,
      boxShadow: const <BoxShadow>[],
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.brandPrimary),
              const SizedBox(width: AppSpacing.space2),
              Expanded(child: Text(title, style: AppTypography.sectionTitle)),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.color = AppColors.textSecondary,
    this.background = AppColors.surfaceSubtle,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppTypography.badgeText.copyWith(color: color)),
    );
  }
}
