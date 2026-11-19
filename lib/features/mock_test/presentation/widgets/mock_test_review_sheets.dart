import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_library_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_display_title.dart';

Future<void> showMockTestHistorySheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.learnerBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _MockTestHistorySheet(),
  );
}

Future<void> showMockTestWrongQuestionsSheet(
  BuildContext context,
  WidgetRef ref, {
  int? practiceTestId,
  String? title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.learnerBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _MockTestWrongQuestionsSheet(
      practiceTestId: practiceTestId,
      title: title,
    ),
  );
}

class _MockTestHistorySheet extends ConsumerStatefulWidget {
  const _MockTestHistorySheet();

  @override
  ConsumerState<_MockTestHistorySheet> createState() =>
      _MockTestHistorySheetState();
}

class _MockTestHistorySheetState extends ConsumerState<_MockTestHistorySheet> {
  LiveMockTestDetailedResult? _detailed;
  String? _detailTitle;
  bool _loadingDetail = false;
  String? _detailError;

  Future<void> _openAttemptDetail(MockTestHistoryRecord entry) async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
      _detailTitle = entry.title;
    });
    try {
      final result = await ref
          .read(mockTestRepositoryProvider)
          .loadDetailedResult(entry.attemptId);
      if (!mounted) return;
      setState(() {
        _detailed = result;
        _loadingDetail = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detailError = 'Không tải được chi tiết bài làm. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJa = Localizations.localeOf(context).languageCode == 'ja';
    final historyAsync = ref.watch(mockTestLibraryHistoryProvider);

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (_detailed != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => setState(() {
                      _detailed = null;
                      _detailError = null;
                    }),
                  ),
                Expanded(
                  child: Text(
                    _detailed != null
                        ? mockTestDisplayTitle(
                            _detailTitle ?? '',
                            japanese: isJa,
                          )
                        : (isJa ? '模擬試験の履歴' : 'Lịch sử thi thử'),
                    style: AppTypography.sectionTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space3),
            if (_loadingDetail)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_detailed != null)
              Expanded(
                child: ListView.separated(
                  key: const ValueKey<String>('mock_history_detail_list'),
                  itemCount: _detailed!.questions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space3),
                  itemBuilder: (context, index) {
                    final q = _detailed!.questions[index];
                    final correctOpt =
                        q.options.where((o) => o.isCorrect).firstOrNull;
                    final selectedOpt = q.options
                        .where((o) => o.id == q.selectedOptionId)
                        .firstOrNull;
                    return RikiCard(
                      borderColor: q.isCorrect
                          ? AppColors.successBorder
                          : AppColors.errorBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Câu ${index + 1}',
                                style: AppTypography.badgeText.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                q.isCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 16,
                                color: q.isCorrect
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(q.questionText, style: AppTypography.body),
                          const SizedBox(height: 6),
                          Text(
                            'Bạn chọn: ${selectedOpt?.text ?? q.response?.toString() ?? 'Chưa chọn'}',
                            style: AppTypography.bodySmall.copyWith(
                              color: q.isCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          Text(
                            'Đáp án đúng: ${correctOpt?.text ?? q.answerKey?.toString() ?? '—'}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (q.explanation != null &&
                              q.explanation!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              q.explanation!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_detailError != null) ...[
                      RikiErrorBanner(message: _detailError!),
                      const SizedBox(height: AppSpacing.space3),
                    ],
                    Expanded(
                      child: historyAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => RikiErrorState(
                          title: 'Không tải được lịch sử thi thử',
                          message: 'Kiểm tra kết nối và thử lại.',
                          actionLabel: 'Thử lại',
                          onAction: () =>
                              ref.invalidate(mockTestLibraryHistoryProvider),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const RikiEmptyState(
                              icon: Icons.history_rounded,
                              title: 'Chưa có lượt thi hoàn thành',
                              message:
                                  'Hoàn thành một đề thi thử để lưu điểm và xem lại câu sai tại đây.',
                            );
                          }
                          final df = DateFormat('dd/MM/yyyy HH:mm');
                          return ListView.separated(
                            key: const ValueKey<String>(
                              'mock_history_entries_list',
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.space3),
                            itemBuilder: (context, index) {
                              final entry = items[index];
                              return RikiCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            mockTestDisplayTitle(
                                              entry.title,
                                              japanese: isJa,
                                            ),
                                            style: AppTypography.cardTitle,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandTint,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            '${entry.totalScore.round()}%',
                                            style: AppTypography.badgeText
                                                .copyWith(
                                                  color: AppColors.brandPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'JLPT ${entry.jlptLevelName} • ${df.format(entry.submittedAt.toLocal())}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              _openAttemptDetail(entry),
                                          icon: const Icon(
                                            Icons.fact_check_outlined,
                                            size: 16,
                                          ),
                                          label: const Text('Xem chi tiết'),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () =>
                                              showMockTestWrongQuestionsSheet(
                                                context,
                                                ref,
                                                practiceTestId: entry.mockTestId,
                                                title: entry.title,
                                              ),
                                          icon: const Icon(
                                            Icons.quiz_outlined,
                                            size: 16,
                                          ),
                                          label: const Text('Ôn câu sai'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MockTestWrongQuestionsSheet extends ConsumerStatefulWidget {
  const _MockTestWrongQuestionsSheet({this.practiceTestId, this.title});

  final int? practiceTestId;
  final String? title;

  @override
  ConsumerState<_MockTestWrongQuestionsSheet> createState() =>
      _MockTestWrongQuestionsSheetState();
}

class _MockTestWrongQuestionsSheetState
    extends ConsumerState<_MockTestWrongQuestionsSheet> {
  final Map<int, int> _chosenOptionByQuestion = <int, int>{};
  final Set<int> _revealedQuestions = <int>{};

  @override
  Widget build(BuildContext context) {
    final isJa = Localizations.localeOf(context).languageCode == 'ja';
    final asyncQuestions = ref.watch(
      mockTestWrongQuestionsProvider(widget.practiceTestId),
    );

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title == null
                        ? (isJa ? '誤答復習セッション' : 'Ôn tập câu làm sai')
                        : 'Ôn câu sai — ${mockTestDisplayTitle(widget.title!, japanese: isJa)}',
                    style: AppTypography.sectionTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space3),
            Expanded(
              child: asyncQuestions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => RikiErrorState(
                  title: 'Không tải được câu hỏi ôn tập',
                  message: 'Vui lòng thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(
                    mockTestWrongQuestionsProvider(widget.practiceTestId),
                  ),
                ),
                data: (questions) {
                  if (questions.isEmpty) {
                    return const RikiEmptyState(
                      icon: Icons.celebration_outlined,
                      title: 'Không có câu sai nào cần ôn',
                      message:
                          'Tuyệt vời! Bạn đã trả lời đúng các câu trong những đề thi gần nhất.',
                    );
                  }
                  return ListView.separated(
                    key: const ValueKey<String>('mock_wrong_questions_list'),
                    itemCount: questions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.space3),
                    itemBuilder: (context, index) {
                      final card = questions[index];
                      final chosenId = _chosenOptionByQuestion[card.questionId];
                      final revealed =
                          _revealedQuestions.contains(card.questionId) ||
                          chosenId != null;

                      return RikiCard(
                        borderColor: AppColors.borderSubtlePink,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Câu ${index + 1}',
                                  style: AppTypography.cardTitle,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorBackground,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Sai ${card.timesAnsweredWrong} lần',
                                    style: AppTypography.badgeText.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(card.questionText, style: AppTypography.body),
                            const SizedBox(height: 10),
                            for (final option in card.options) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _chosenOptionByQuestion[card.questionId] =
                                        option.id;
                                    _revealedQuestions.add(card.questionId);
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !revealed
                                          ? AppColors.surfaceMuted
                                          : option.isCorrect
                                          ? AppColors.successBackground
                                          : chosenId == option.id
                                          ? AppColors.errorBackground
                                          : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: !revealed
                                            ? AppColors.borderSubtlePink
                                            : option.isCorrect
                                            ? AppColors.successBorder
                                            : chosenId == option.id
                                            ? AppColors.errorBorder
                                            : AppColors.borderSubtlePink,
                                      ),
                                    ),
                                    child: Text(
                                      option.text,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight:
                                            revealed && option.isCorrect
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            if (!revealed)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _revealedQuestions.add(card.questionId);
                                }),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                ),
                                label: const Text('Hiện đáp án & giải thích'),
                              )
                            else if (card.explanation != null &&
                                card.explanation!.trim().isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.brandTint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  card.explanation!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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
