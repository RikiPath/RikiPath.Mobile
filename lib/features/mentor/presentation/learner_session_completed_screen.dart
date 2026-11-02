import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình tổng kết sau khi buổi tư vấn 1-1 hoàn thành.
class LearnerSessionCompletedScreen extends ConsumerWidget {
  const LearnerSessionCompletedScreen({required this.bookingId, super.key});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(learnerMentorBookingsControllerProvider);

    return Scaffold(
      key: const Key('learner_session_completed_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Buổi tư vấn đã hoàn thành'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (bookingsState) {
          AsyncLoading() => const MentorListSkeleton(),
          AsyncError() => Center(
            child: MentorErrorState(
              message: 'Không thể tải chi tiết buổi tư vấn.',
              onRetry: ref
                  .read(learnerMentorBookingsControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _buildContent(
            context,
            ref,
            value.where((b) => b.id == bookingId).firstOrNull,
          ),
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    LearnerMentorBooking? booking,
  ) {
    final mentorName = booking?.mentorName ?? 'Cố vấn RikiPath';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: AppSpacing.space4),
                // Celebration Sakura Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.cardSoft,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.brandTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.brandPrimary,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'Buổi tư vấn đã hoàn thành!',
                        style: AppTypography.pageTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        'Bạn đã hoàn thành buổi tư vấn cùng cố vấn. Hãy xem lại những nội dung đã trao đổi nhé!',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Session details card
                RikiCard(
                  borderColor: AppColors.border,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin buổi tư vấn',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      LearnerMentorDetailRow(
                        icon: Icons.person_outline,
                        label: 'Cố vấn hỗ trợ',
                        value: mentorName,
                      ),
                      const Divider(),
                      LearnerMentorDetailRow(
                        icon: Icons.verified_outlined,
                        label: 'Trạng thái',
                        value: 'Đã hoàn thành',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Review and Dispute actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('completed_review_button'),
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text('Đánh giá'),
                        onPressed: () => _showReviewDialog(context, ref),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('completed_dispute_button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        icon: const Icon(
                          Icons.report_problem_outlined,
                          size: 18,
                        ),
                        label: const Text('Khiếu nại'),
                        onPressed: () => _showDisputeDialog(context, ref),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),

                // Next steps note
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.brandPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          'Đừng quên xem lại tài liệu và ghi chú từ cố vấn nhé!',
                          style: AppTypography.metadata,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          RikiPrimaryButton(
            key: const Key('learner_completed_next_session_button'),
            label: 'Đặt buổi học tiếp theo',
            leadingIcon: Icons.calendar_month_outlined,
            onPressed: () => context.push(AppRoutes.learnerMentorMeetings),
          ),
          const SizedBox(height: AppSpacing.space2),
          RikiSecondaryButton(
            key: const Key('learner_completed_home_button'),
            label: 'Về trang chủ',
            leadingIcon: Icons.home_outlined,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    var rating = 5;
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Đánh giá buổi học'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => rating = star),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('completed_review_comment_input'),
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Nhận xét',
                      hintText: 'Nhập phản hồi của bạn về buổi học...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                key: const Key('completed_submit_review_button'),
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  final res = await ref
                      .read(learnerMentorMutationControllerProvider.notifier)
                      .createReview(
                        bookingId: bookingId,
                        rating: rating,
                        comment: commentController.text.trim(),
                      );
                  if (res != null) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .success(
                          title: 'Gửi đánh giá thành công',
                          description: 'Cảm ơn phản hồi của bạn.',
                        );
                  } else {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(title: 'Không thể gửi đánh giá');
                  }
                },
                child: const Text('Gửi'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, WidgetRef ref) {
    var selectedCategory = 1;
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Khiếu nại buổi học'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Thời hạn gửi khiếu nại trong vòng 48h sau khi kết thúc buổi học.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Lý do khiếu nại',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Chất lượng tư vấn'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Cố vấn vắng mặt'),
                      ),
                      DropdownMenuItem(value: 3, child: Text('Sự cố kỹ thuật')),
                      DropdownMenuItem(value: 4, child: Text('Khác')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('completed_dispute_reason_input'),
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Chi tiết vấn đề',
                      hintText: 'Mô tả chi tiết để được hỗ trợ...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                key: const Key('completed_submit_dispute_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(title: 'Vui lòng nhập lý do khiếu nại');
                    return;
                  }
                  Navigator.of(dialogCtx).pop();
                  final res = await ref
                      .read(learnerMentorMutationControllerProvider.notifier)
                      .createDispute(
                        bookingId: bookingId,
                        category: selectedCategory,
                        reason: reason,
                      );
                  if (res != null) {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .success(
                          title: 'Gửi khiếu nại thành công',
                          description: 'Ban quản trị sẽ liên hệ hỗ trợ bạn.',
                        );
                  } else {
                    ref
                        .read(rikiToastServiceProvider.notifier)
                        .error(title: 'Không thể gửi khiếu nại');
                  }
                },
                child: const Text('Gửi khiếu nại'),
              ),
            ],
          );
        },
      ),
    );
  }
}
