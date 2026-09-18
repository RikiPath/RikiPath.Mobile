import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';

class GrammarDetailView extends StatelessWidget {
  const GrammarDetailView({
    required this.entry,
    required this.onOpenRelated,
    super.key,
  });

  final GrammarEntry entry;
  final ValueChanged<RelatedGrammar> onOpenRelated;

  @override
  Widget build(BuildContext context) {
    final enrichment = entry.enrichment;
    final examples = enrichment?.examples ?? const <GrammarExample>[];

    return ListView(
      key: const ValueKey<String>('grammar_detail_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        if (entry.source == GrammarDataSource.fixture) ...[
          const _FixtureNotice(),
          const SizedBox(height: AppSpacing.space3),
        ],
        _HeroCard(entry: entry),
        const SizedBox(height: AppSpacing.space4),
        if (entry.explanation != null) ...[
          _SectionCard(
            key: const ValueKey<String>('grammar_explanation_section'),
            title: 'Ý nghĩa & bản chất',
            icon: Icons.lightbulb_outline,
            child: SelectableText(
              entry.explanation!,
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
        _SectionCard(
          key: const ValueKey<String>('grammar_structure_section'),
          title: 'Cấu trúc ngữ pháp',
          icon: Icons.account_tree_outlined,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.learnerSurfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: SelectableText(
              entry.structure,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.learnerTextPrimary,
              ),
            ),
          ),
        ),
        if (enrichment?.usageNotes.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.space4),
          _BulletSection(
            title: 'Cách sử dụng',
            icon: Icons.rule_outlined,
            items: enrichment!.usageNotes,
          ),
        ],
        if (examples.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          _ExamplesSection(examples: examples),
        ] else if (entry.exampleSentence != null) ...[
          const SizedBox(height: AppSpacing.space4),
          _ExamplesSection(
            examples: <GrammarExample>[
              GrammarExample(sentence: entry.exampleSentence!),
            ],
          ),
        ],
        if (enrichment?.cautions.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.space4),
          _CautionsSection(items: enrichment!.cautions),
        ],
        if (enrichment?.related.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.space4),
          _RelatedSection(items: enrichment!.related, onOpen: onOpenRelated),
        ],
      ],
    );
  }
}

class _FixtureNotice extends StatelessWidget {
  const _FixtureNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('grammar_detail_fixture_notice'),
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
              'Nội dung mở rộng là dữ liệu minh họa cục bộ, không phải response API.',
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.entry});

  final GrammarEntry entry;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.learnerOutline,
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JlptBadge(entry.level),
          const SizedBox(height: AppSpacing.space3),
          SelectableText(
            entry.title,
            style: AppTypography.heroTitle.copyWith(
              color: AppColors.learnerTextPrimary,
              fontSize: 34,
            ),
          ),
          if (entry.explanation != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              entry.explanation!,
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExamplesSection extends StatelessWidget {
  const _ExamplesSection({required this.examples});

  final List<GrammarExample> examples;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const ValueKey<String>('grammar_examples_section'),
      title: 'Ví dụ thực tế',
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
                  fontWeight: FontWeight.w700,
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

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const ValueKey<String>('grammar_usage_section'),
      title: title,
      icon: icon,
      child: Column(
        children: [for (final item in items) _BulletRow(text: item)],
      ),
    );
  }
}

class _CautionsSection extends StatelessWidget {
  const _CautionsSection({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('grammar_cautions_section'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningText,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  'Lưu ý khi dùng',
                  style: AppTypography.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          for (final item in items) _BulletRow(text: item),
        ],
      ),
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({required this.items, required this.onOpen});

  final List<RelatedGrammar> items;
  final ValueChanged<RelatedGrammar> onOpen;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const ValueKey<String>('grammar_related_section'),
      title: 'Ngữ pháp liên quan & phân biệt',
      icon: Icons.compare_arrows,
      child: Column(
        children: [
          for (final item in items)
            Material(
              color: Colors.transparent,
              child: ListTile(
                key: ValueKey<String>('grammar_related_${item.routeKey}'),
                contentPadding: EdgeInsets.zero,
                title: Text(item.title, style: AppTypography.cardTitle),
                subtitle: Text(item.summary, style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpen(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(child: Text(text, style: AppTypography.body)),
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
    super.key,
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
