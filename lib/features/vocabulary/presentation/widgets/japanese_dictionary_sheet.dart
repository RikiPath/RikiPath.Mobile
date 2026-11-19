import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/vocabulary/data/japanese_dictionary_repository.dart';

Future<void> showJapaneseDictionarySheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.learnerBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _JapaneseDictionarySheet(),
  );
}

class _JapaneseDictionarySheet extends ConsumerStatefulWidget {
  const _JapaneseDictionarySheet();

  @override
  ConsumerState<_JapaneseDictionarySheet> createState() =>
      _JapaneseDictionarySheetState();
}

class _JapaneseDictionarySheetState
    extends ConsumerState<_JapaneseDictionarySheet> {
  final TextEditingController _queryController = TextEditingController();
  bool _loading = false;
  bool _hasSearched = false;
  String? _error;
  List<JapaneseDictionaryCandidate> _results =
      const <JapaneseDictionaryCandidate>[];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Vui lòng nhập cách đọc Hiragana hoặc Katakana.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });
    try {
      final list = await ref
          .read(japaneseDictionaryRepositoryProvider)
          .searchByKana(query);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = list;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không tra cứu được. Vui lòng nhập ký tự Kana (vd: たべる).',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Từ điển Kana → Kanji',
                    style: AppTypography.sectionTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey<String>('kana_dictionary_input'),
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập Hiragana / Katakana (vd: たべる)',
                      prefixIcon: Icon(Icons.translate_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                FilledButton(
                  key: const ValueKey<String>('kana_dictionary_search_button'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _loading ? null : _search,
                  child: const Text('Tra cứu'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              RikiErrorBanner(message: _error!)
            else if (!_hasSearched)
              const Expanded(
                child: RikiEmptyState(
                  icon: Icons.translate_rounded,
                  title: 'Tra cứu Kanji theo cách đọc Kana',
                  message:
                      'Nhập On-yomi hoặc Kun-yomi bằng Hiragana/Katakana để tìm mặt chữ Kanji, âm Hán Việt và nghĩa.',
                ),
              )
            else if (_results.isEmpty)
              const Expanded(
                child: RikiEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Không tìm thấy Kanji phù hợp',
                  message: 'Thử nhập cách đọc Kana khác (ví dụ: にち, みる).',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  key: const ValueKey<String>('kana_dictionary_results_list'),
                  itemCount: _results.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space2),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return RikiCard(
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.brandTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.surface,
                              style: AppTypography.pageTitle.copyWith(
                                fontSize: 24,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      item.readingKana,
                                      style: AppTypography.cardTitle,
                                    ),
                                    if (item.sinoVietnamese != null &&
                                        item.sinoVietnamese!.trim().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandTint,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          item.sinoVietnamese!,
                                          style: AppTypography.badgeText.copyWith(
                                            color: AppColors.brandPrimary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (item.meaning != null &&
                                    item.meaning!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.meaning!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
