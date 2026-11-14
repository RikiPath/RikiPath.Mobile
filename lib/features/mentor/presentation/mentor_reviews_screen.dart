import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';

enum _ReviewFilter { all, unreplied }

/// Displays Mentor rating summary, 5-to-1 breakdown, paginated Learner reviews,
/// and modal reply / edit-reply workflow (`/mentor/reviews`).
class MentorReviewsScreen extends ConsumerStatefulWidget {
  const MentorReviewsScreen({super.key});

  @override
  ConsumerState<MentorReviewsScreen> createState() =>
      _MentorReviewsScreenState();
}

class _MentorReviewsScreenState extends ConsumerState<MentorReviewsScreen> {
  _ReviewFilter _filter = _ReviewFilter.all;
  bool _loadingMore = false;

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      await ref.read(mentorReviewsControllerProvider.notifier).loadMore();
    } catch (err) {
      if (mounted) {
        ref.read(rikiToastServiceProvider.notifier).error(
          title: context.l10n.toastActionFailedTitle,
          description: appErrorMessage(err, context.l10n),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _openReplySheet(MentorReviewItem review) async {
    final l10n = context.l10n;
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cardLarge),
        ),
      ),
      builder: (_) => _ReviewReplySheet(
        initialReply: review.mentorReply ?? '',
        learnerName: review.learnerName,
      ),
    );

    if (submitted == null || !mounted) return;
    final ok = await runWithAppLoadingOverlay<bool>(
      context,
      title: l10n.loadingOverlaySubmittingTitle,
      action: () => ref
          .read(mentorReviewsControllerProvider.notifier)
          .replyToReview(reviewId: review.id, reply: submitted),
    );
    if (!mounted) return;
    if (ok) {
      ref.read(rikiToastServiceProvider.notifier).success(
        title: l10n.mentorReviewsTitle,
        description: l10n.mentorReviewsReplyLabel,
      );
    } else {
      ref.read(rikiToastServiceProvider.notifier).error(
        title: l10n.toastActionFailedTitle,
        description: l10n.commonErrorServer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bundleAsync = ref.watch(mentorReviewsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.mentorReviewsTitle),
      ),
      body: bundleAsync.when(
        loading: () => const Center(child: RikiAnimatedStudyLoader()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiErrorState(
              title: l10n.mentorReviewsTitle,
              message: appErrorMessage(err, l10n),
              actionLabel: l10n.mentorCommonRetry,
              onAction: () =>
                  ref.read(mentorReviewsControllerProvider.notifier).refresh(),
            ),
          ),
        ),
        data: (bundle) {
          final visibleReviews = switch (_filter) {
            _ReviewFilter.all => bundle.reviews,
            _ReviewFilter.unreplied => bundle.reviews
                .where((item) => !item.hasReply)
                .toList(growable: false),
          };

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () =>
                ref.read(mentorReviewsControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                _RatingSummaryCard(summary: bundle.summary),
                const SizedBox(height: AppSpacing.space4),
                Wrap(
                  spacing: AppSpacing.space2,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.mentorMeetingsFilterAll),
                      selected: _filter == _ReviewFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _ReviewFilter.all),
                    ),
                    ChoiceChip(
                      label: Text(l10n.mentorHomeMetricUnrepliedReviews),
                      selected: _filter == _ReviewFilter.unreplied,
                      onSelected: (_) =>
                          setState(() => _filter = _ReviewFilter.unreplied),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                if (visibleReviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space6),
                    child: RikiEmptyState(
                      icon: Icons.star_outline_rounded,
                      title: l10n.mentorReviewsTitle,
                      message: l10n.mentorReviewsEmpty,
                    ),
                  )
                else ...[
                  for (final review in visibleReviews) ...[
                    _ReviewItemCard(
                      review: review,
                      onReplyPressed: () => _openReplySheet(review),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                  ],
                  if (bundle.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.space2),
                      child: OutlinedButton(
                        onPressed: _loadingMore ? null : _loadMore,
                        child: _loadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.mentorChatLoadOlder),
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.summary});

  final MentorRatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = summary.totalReviews;

    return RikiCard(
      backgroundColor: AppColors.surface,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.averageRating.toStringAsFixed(1),
                      style: AppTypography.pageTitle.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < summary.averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.mentorReviewsAverageLabel} · '
                      '${summary.totalReviews} ${l10n.mentorReviewsTotalLabel.toLowerCase()}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      '${summary.positiveRatePercent.toStringAsFixed(0)}%',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.mentorReviewsPositiveRate,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          for (var star = 5; star >= 1; star--) ...[
            Builder(
              builder: (context) {
                final count = summary.ratingBreakdown[star] ?? 0;
                final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$star★',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: AppColors.cardBorderMuted,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewItemCard extends StatelessWidget {
  const _ReviewItemCard({
    required this.review,
    required this.onReplyPressed,
  });

  final MentorReviewItem review;
  final VoidCallback onReplyPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final comment = review.comment?.trim();
    final reply = review.mentorReply?.trim();

    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandTint,
                child: Text(
                  review.learnerName.isNotEmpty
                      ? review.learnerName.characters.first.toUpperCase()
                      : 'L',
                  style: AppTypography.cardTitle.copyWith(
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
                      review.learnerName,
                      style: AppTypography.cardTitle,
                    ),
                    Text(
                      '#${review.mentorBookingId} · '
                      '${formatShortDateTime(review.createdAtUtc)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(comment, style: AppTypography.bodyMedium),
          ],
          if (reply != null && reply.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.brandPrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.mentorReviewsReplyLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (review.mentorRepliedAtUtc != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatShortDateTime(review.mentorRepliedAtUtc),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reply, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Align(
            alignment: Alignment.centerRight,
            child: review.hasReply
                ? TextButton.icon(
                    onPressed: onReplyPressed,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.mentorReviewsEditReplyAction),
                  )
                : OutlinedButton.icon(
                    onPressed: onReplyPressed,
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: Text(l10n.mentorMeetingReplyReviewButton),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewReplySheet extends StatefulWidget {
  const _ReviewReplySheet({
    required this.initialReply,
    required this.learnerName,
  });

  final String initialReply;
  final String learnerName;

  @override
  State<_ReviewReplySheet> createState() => _ReviewReplySheetState();
}

class _ReviewReplySheetState extends State<_ReviewReplySheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialReply,
  );
  static const int _maxLength = 1000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final trimmed = _controller.text.trim();
    final isValid = trimmed.isNotEmpty && trimmed.length <= _maxLength;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.space4,
        AppSpacing.screenHorizontal,
        AppSpacing.space5 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.mentorMeetingReplyReviewButton} · ${widget.learnerName}',
                  style: AppTypography.sectionTitle,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 6,
            maxLength: _maxLength,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.mentorReviewsReplyHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.mentorCommonCancel),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: RikiPrimaryButton(
                  label: l10n.mentorReviewsSubmitReply,
                  onPressed: isValid
                      ? () => Navigator.of(context).pop(trimmed)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
