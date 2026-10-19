import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

class JlptCatalogFilterChips extends StatelessWidget {
  const JlptCatalogFilterChips({
    required this.catalog,
    required this.selected,
    required this.onSelected,
    required this.onRetry,
    required this.keyPrefix,
    this.includeJlptPrefix = true,
    super.key,
  });

  final AsyncValue<List<JlptLevelCatalogItem>> catalog;
  final JlptLevelCatalogItem? selected;
  final ValueChanged<JlptLevelCatalogItem?> onSelected;
  final VoidCallback onRetry;
  final String keyPrefix;
  final bool includeJlptPrefix;

  @override
  Widget build(BuildContext context) {
    return catalog.when(
      loading: () => SizedBox(
        key: ValueKey<String>('${keyPrefix}_loading'),
        height: 40,
        child: const Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Padding(
        key: ValueKey<String>('${keyPrefix}_error'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.jlptCatalogLoadFailed,
                style: AppTypography.metadata.copyWith(color: AppColors.error),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
      data: (levels) {
        if (levels.isEmpty) {
          return Padding(
            key: ValueKey<String>('${keyPrefix}_empty'),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Text(
              context.l10n.jlptCatalogEmpty,
              style: AppTypography.metadata,
            ),
          );
        }
        return SizedBox(
          key: ValueKey<String>('${keyPrefix}_loaded'),
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            children: [
              _LevelChip(
                key: ValueKey<String>('${keyPrefix}_all'),
                label: context.l10n.all,
                selected: selected == null,
                onSelected: () => onSelected(null),
              ),
              for (final level in levels) ...[
                const SizedBox(width: AppSpacing.space2),
                _LevelChip(
                  key: ValueKey<String>(
                    '${keyPrefix}_${level.code.toLowerCase()}',
                  ),
                  label: includeJlptPrefix ? 'JLPT ${level.code}' : level.code,
                  selected: selected?.id == level.id,
                  onSelected: () => onSelected(level),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.brandTint,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.brandPrimary : AppColors.border,
      ),
      labelStyle: AppTypography.badgeText.copyWith(
        color: selected
            ? AppColors.brandPrimary
            : AppColors.learnerTextSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
    );
  }
}
