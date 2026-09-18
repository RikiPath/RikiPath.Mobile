import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/kanji/application/kanji_controller.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';

class KanjiDetailView extends StatelessWidget {
  const KanjiDetailView({
    required this.state,
    required this.onPlayAudio,
    required this.onSave,
    required this.onOpenStrokeOrder,
    super.key,
  });

  final KanjiDetailState state;
  final VoidCallback onPlayAudio;
  final VoidCallback onSave;
  final VoidCallback onOpenStrokeOrder;

  @override
  Widget build(BuildContext context) {
    final entry = state.entry;
    final enrichment = entry.enrichment;

    return ListView(
      key: const ValueKey<String>('kanji_detail_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space6,
      ),
      children: [
        _HeroCard(entry: entry),
        const SizedBox(height: AppSpacing.space4),
        _ReadingSection(entry: entry, onPlayAudio: onPlayAudio),
        if (state.hasStrokeOrder) ...[
          const SizedBox(height: AppSpacing.space4),
          _StrokeOrderPreview(entry: entry, onOpen: onOpenStrokeOrder),
        ],
        if (enrichment?.mnemonic != null) ...[
          const SizedBox(height: AppSpacing.space4),
          _FixtureSection(
            title: 'Mẹo ghi nhớ',
            icon: Icons.lightbulb_outline,
            child: Text(enrichment!.mnemonic!, style: AppTypography.body),
          ),
        ],
        if (enrichment != null && enrichment.compounds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          _FixtureSection(
            title: 'Từ ghép thường gặp',
            icon: Icons.hub_outlined,
            child: Column(
              children: [
                for (final compound in enrichment.compounds)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      compound.word,
                      style: AppTypography.sectionTitle,
                    ),
                    subtitle: Text('${compound.reading} • ${compound.meaning}'),
                  ),
              ],
            ),
          ),
        ],
        if (enrichment?.example != null) ...[
          const SizedBox(height: AppSpacing.space4),
          _FixtureSection(
            title: 'Ví dụ',
            icon: Icons.format_quote,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrichment!.example!.sentence,
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  enrichment.example!.translation,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space5),
        RikiPrimaryButton(
          key: const ValueKey<String>('kanji_save_button'),
          label: state.isSaved ? 'Đã lưu vào Sổ từ' : 'Lưu vào Sổ từ',
          leadingIcon: state.isSaved ? Icons.bookmark : Icons.bookmark_border,
          isLoading: state.isSaving || state.isLoadingNotebook,
          onPressed: state.isSaved ? null : onSave,
        ),
        if (state.notebookError != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            state.notebookError!,
            textAlign: TextAlign.center,
            style: AppTypography.validationText,
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.entry});

  final KanjiEntry entry;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              JlptBadge(entry.level),
              _MetaPill(label: '${entry.strokeCount} nét'),
              if (entry.enrichment?.radical != null)
                _MetaPill(label: 'Bộ ${entry.enrichment!.radical}'),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Container(
            width: 144,
            height: 144,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.learnerSurfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Text(
              entry.character,
              style: AppTypography.heroTitle.copyWith(fontSize: 86, height: 1),
            ),
          ),
          if (entry.sinoVietnamese != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              entry.sinoVietnamese!,
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.brandPrimary,
                letterSpacing: 1,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space1),
          Text(
            entry.meaning,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          if (entry.source == KanjiDataSource.fixture) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              'Nội dung mở rộng dùng dữ liệu mẫu Stitch',
              textAlign: TextAlign.center,
              style: AppTypography.metadata.copyWith(
                color: AppColors.warningText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingSection extends StatelessWidget {
  const _ReadingSection({required this.entry, required this.onPlayAudio});

  final KanjiEntry entry;
  final VoidCallback onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Cách đọc', style: AppTypography.sectionTitle),
              ),
              IconButton(
                key: const ValueKey<String>('kanji_audio_button'),
                tooltip: entry.audioUrl == null
                    ? 'Chưa có âm thanh'
                    : 'Nghe cách đọc',
                onPressed: entry.audioUrl == null ? null : onPlayAudio,
                icon: Icon(
                  Icons.volume_up_outlined,
                  color: entry.audioUrl != null
                      ? AppColors.brandPrimary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          _ReadingRow(label: 'Âm On', value: entry.onYomi),
          const SizedBox(height: AppSpacing.space2),
          _ReadingRow(label: 'Âm Kun', value: entry.kunYomi),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 68, child: Text(label, style: AppTypography.metadata)),
        Expanded(
          child: Text(value ?? 'Chưa có dữ liệu', style: AppTypography.body),
        ),
      ],
    );
  }
}

class _StrokeOrderPreview extends StatelessWidget {
  const _StrokeOrderPreview({required this.entry, required this.onOpen});

  final KanjiEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thứ tự nét', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space3),
          AspectRatio(
            aspectRatio: 2,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.learnerSurfaceLow,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: entry.strokeOrderUrl == null
                  ? Text(
                      entry.character,
                      style: AppTypography.heroTitle.copyWith(fontSize: 64),
                    )
                  : Image.network(
                      entry.strokeOrderUrl.toString(),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          RikiSecondaryButton(
            key: const ValueKey<String>('kanji_open_strokes_button'),
            label: 'Xem chi tiết thứ tự nét',
            leadingIcon: Icons.draw_outlined,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _FixtureSection extends StatelessWidget {
  const _FixtureSection({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.brandPrimary),
              const SizedBox(width: AppSpacing.space2),
              Expanded(child: Text(title, style: AppTypography.sectionTitle)),
              Text(
                'MẪU',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.warningText,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.learnerSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppTypography.badgeText),
    );
  }
}
