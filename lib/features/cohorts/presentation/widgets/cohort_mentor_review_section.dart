import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';

/// Lets the learner rate each Mentor who actually delivered at least one of
/// their sessions (primary or substitute). One review per Mentor per course;
/// an existing review is edited in place instead of duplicated.
class CohortMentorReviewSection extends ConsumerStatefulWidget {
  const CohortMentorReviewSection({
    required this.courseId,
    required this.mentors,
    super.key,
  });

  final int courseId;

  /// Mentors eligible for review (delivered sessions only).
  final List<CompletionMentorItem> mentors;

  @override
  ConsumerState<CohortMentorReviewSection> createState() =>
      _CohortMentorReviewSectionState();
}

class _CohortMentorReviewSectionState
    extends ConsumerState<CohortMentorReviewSection> {
  final TextEditingController _comment = TextEditingController();
  int? _mentorId;
  int _rating = 0;
  int? _editingReviewId;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  static String _stars(int rating) {
    final filled = rating < 0 ? 0 : (rating > 5 ? 5 : rating);
    return '${'★' * filled}${'☆' * (5 - filled)}';
  }

  void _selectMentor(int mentorId, CohortMentorReview? existing) {
    setState(() {
      _mentorId = mentorId;
      _editingReviewId = existing?.id;
      _rating = existing?.rating ?? 0;
      _comment.text = existing?.comment ?? '';
    });
  }

  Future<void> _submit() async {
    final mentorId = _mentorId;
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    if (mentorId == null || _rating < 1 || _rating > 5) {
      toasts.error(
        title: 'Thiếu đánh giá',
        description: 'Vui lòng chọn Mentor và số sao từ 1 đến 5.',
      );
      return;
    }
    if (_submitting) return;
    _submitting = true;
    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang lưu đánh giá...',
        action: () => ref
            .read(learnerMyCoursesProvider.notifier)
            .saveMentorReview(
              courseId: widget.courseId,
              mentorId: mentorId,
              reviewId: _editingReviewId,
              rating: _rating,
              comment: _comment.text,
            ),
      );
      if (!mounted) return;
      setState(() {
        _mentorId = null;
        _editingReviewId = null;
        _rating = 0;
        _comment.clear();
      });
      toasts.success(title: 'Đã lưu đánh giá Mentor');
    } catch (error) {
      if (!mounted) return;
      toasts.error(
        title: 'Chưa lưu được đánh giá',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      _submitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsState = ref.watch(
      learnerCourseMentorReviewsProvider(widget.courseId),
    );
    final reviews = reviewsState.value ?? const <CohortMentorReview>[];
    CohortMentorReview? reviewFor(int mentorId) =>
        reviews.where((r) => r.mentorId == mentorId).firstOrNull;

    return RikiCard(
      key: const Key('cohort_mentor_review_section'),
      backgroundColor: Colors.white,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đánh giá Mentor', style: AppTypography.cardTitle),
          const SizedBox(height: 4),
          Text(
            'Bạn có thể đánh giá Mentor đã trực tiếp dạy bạn ít nhất một buổi.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.mentors.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Chưa có buổi học nào hoàn thành để đánh giá.',
              style: AppTypography.bodySmall,
            ),
          ] else ...[
            for (final m in widget.mentors) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.mentorName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (reviewFor(m.mentorId) case final r?)
                          Text(
                            '${_stars(r.rating)} ${r.comment}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: ValueKey('review_mentor_${m.mentorId}'),
                    onPressed: () =>
                        _selectMentor(m.mentorId, reviewFor(m.mentorId)),
                    child: Text(
                      reviewFor(m.mentorId) != null ? 'Sửa' : 'Đánh giá',
                    ),
                  ),
                ],
              ),
              if (_mentorId == m.mentorId) ...[
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        key: ValueKey('review_star_$i'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _rating = i),
                        icon: Icon(
                          i <= _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
                TextField(
                  key: const Key('review_comment_field'),
                  controller: _comment,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    key: const Key('review_submit_button'),
                    onPressed: _submit,
                    child: Text(
                      _editingReviewId != null
                          ? 'Cập nhật đánh giá'
                          : 'Gửi đánh giá',
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
