import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/writing_practice/application/writing_practice_controller.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';

class WritingPracticeScreen extends ConsumerStatefulWidget {
  const WritingPracticeScreen({required this.script, super.key});

  final WritingScript script;

  @override
  ConsumerState<WritingPracticeScreen> createState() =>
      _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends ConsumerState<WritingPracticeScreen> {
  KanjiWritingCollection _kanjiCollection = KanjiWritingCollection.due;

  @override
  void didUpdateWidget(WritingPracticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.script != widget.script) {
      _kanjiCollection = KanjiWritingCollection.due;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = WritingQueueRequest(
      script: widget.script,
      kanjiCollection: _kanjiCollection,
    );
    final queue = ref.watch(writingPracticeControllerProvider(request));
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.writingTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space4,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.writingSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                _WritingScriptTabs(selected: widget.script),
                if (widget.script == WritingScript.kanji) ...[
                  const SizedBox(height: AppSpacing.space3),
                  _KanjiCollectionControl(
                    value: _kanjiCollection,
                    onChanged: (value) {
                      if (value == _kanjiCollection) return;
                      setState(() => _kanjiCollection = value);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.space4),
                Text(
                  context.l10n.writingSelectCharacter,
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  context.l10n.writingQueueHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
            ),
          ),
          Expanded(
            child: queue.when(
              loading: () => const RikiSectionSkeleton(
                itemCount: 6,
                cardHeight: 72,
                showSearch: false,
                showFilters: false,
                cardLeading: false,
              ),
              error: (error, _) => RikiErrorState(
                title: context.l10n.writingLoadFailed,
                message: appErrorMessage(error, context.l10n),
                actionLabel: context.l10n.retry,
                onAction: () => ref
                    .read(writingPracticeControllerProvider(request).notifier)
                    .retry(),
              ),
              data: (state) => state.items.isEmpty
                  ? _WritingEmptyState(script: widget.script)
                  : _WritingCharacterGrid(
                      items: state.items,
                      onSelected: (character) {
                        ref
                            .read(
                              writingPracticeControllerProvider(
                                request,
                              ).notifier,
                            )
                            .selectCharacter(character.id);
                        context.push(_detailRoute(character));
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WritingScriptTabs extends StatelessWidget {
  const _WritingScriptTabs({required this.selected});

  final WritingScript selected;

  @override
  Widget build(BuildContext context) {
    return _SegmentedControl(
      surfaceKey: const ValueKey<String>('writing_script_control_surface'),
      children: [
        for (final script in WritingScript.values)
          Expanded(
            child: _SegmentButton(
              key: ValueKey<String>('writing_tab_${script.name}'),
              label: _scriptLabel(context, script),
              selected: script == selected,
              onPressed: () => context.go(_scriptRoute(script)),
            ),
          ),
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.surfaceKey, required this.children});

  final Key surfaceKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: surfaceKey,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space1),
        child: Row(children: children),
      ),
    );
  }
}

class _KanjiCollectionControl extends StatelessWidget {
  const _KanjiCollectionControl({required this.value, required this.onChanged});

  final KanjiWritingCollection value;
  final ValueChanged<KanjiWritingCollection> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SegmentedControl(
      surfaceKey: const ValueKey<String>(
        'writing_kanji_collection_control_surface',
      ),
      children: [
        for (final collection in KanjiWritingCollection.values) ...[
          Expanded(
            child: _SegmentButton(
              key: ValueKey<String>(
                'writing_kanji_collection_${collection.name}',
              ),
              label: collection == KanjiWritingCollection.due
                  ? context.l10n.writingDue
                  : context.l10n.writingAll,
              selected: collection == value,
              onPressed: () => onChanged(collection),
            ),
          ),
        ],
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandTint : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.compact),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.compact),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space3,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inputLabel.copyWith(
              color: selected ? AppColors.brandPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _WritingCharacterGrid extends StatelessWidget {
  const _WritingCharacterGrid({required this.items, required this.onSelected});

  final List<WritingCharacter> items;
  final ValueChanged<WritingCharacter> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey<String>('writing_character_grid'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 116,
        mainAxisExtent: 146,
        mainAxisSpacing: AppSpacing.space3,
        crossAxisSpacing: AppSpacing.space3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _WritingCharacterCard(
          key: ValueKey<String>('writing_character_${item.id}'),
          item: item,
          onPressed: () => onSelected(item),
        );
      },
    );
  }
}

class _WritingCharacterCard extends StatelessWidget {
  const _WritingCharacterCard({
    required this.item,
    required this.onPressed,
    super.key,
  });

  final WritingCharacter item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.cardSoft,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.character,
                  style: AppTypography.heroTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 44,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  item.romaji ??
                      item.meaning ??
                      context.l10n.writingStrokeCount(item.strokeCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  item.writingScore == null
                      ? (item.isNew
                            ? context.l10n.writingNewCharacter
                            : context.l10n.writingReviewCharacter)
                      : context.l10n.writingLastScore(item.writingScore!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.badgeText.copyWith(
                    color: item.isNew
                        ? AppColors.brandPrimary
                        : AppColors.success,
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

class _WritingEmptyState extends StatelessWidget {
  const _WritingEmptyState({required this.script});

  final WritingScript script;

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(
      icon: Icons.draw_outlined,
      title: context.l10n.writingEmptyTitle,
      message: script == WritingScript.kanji
          ? context.l10n.writingKanjiEmptyMessage
          : context.l10n.writingKanaEmptyMessage(_scriptLabel(context, script)),
    );
  }
}

String _detailRoute(WritingCharacter character) => switch (character.script) {
  WritingScript.hiragana => AppRoutes.writingHiraganaDetail(character.id),
  WritingScript.katakana => AppRoutes.writingKatakanaDetail(character.id),
  WritingScript.kanji => AppRoutes.writingKanjiDetail(character.id),
};

String _scriptRoute(WritingScript script) => switch (script) {
  WritingScript.hiragana => AppRoutes.writingHiragana,
  WritingScript.katakana => AppRoutes.writingKatakana,
  WritingScript.kanji => AppRoutes.writingKanji,
};

String _scriptLabel(BuildContext context, WritingScript script) =>
    switch (script) {
      WritingScript.hiragana => context.l10n.writingHiragana,
      WritingScript.katakana => context.l10n.writingKatakana,
      WritingScript.kanji => context.l10n.writingKanji,
    };
