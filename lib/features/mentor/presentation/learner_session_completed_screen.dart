import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình tổng kết khi buổi học 1-1 hoàn thành (Screen 15 theo chuẩn Neo-Japoniste Sakura).
class LearnerSessionCompletedScreen extends ConsumerWidget {
  const LearnerSessionCompletedScreen({
    required this.bookingId,
    super.key,
  });

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(learnerMentorBookingsControllerProvider);

    return Scaffold(
      key: const Key('learner_session_completed_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Buổi học đã hoàn thành'),
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
                message: 'Không thể tải chi tiết buổi học.',
                onRetry: ref
                    .read(learnerMentorBookingsControllerProvider.notifier)
                    .retry,
              ),
            ),
          AsyncData(:final value) => _buildContent(
              context,
              value.where((b) => b.id == bookingId).firstOrNull,
            ),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, LearnerMentorBooking? booking) {
    final mentorName = booking?.mentorName ?? 'Mentor RikiPath';

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
                        decoration: BoxDecoration(
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
                        'Buổi học đã hoàn thành!',
                        style: AppTypography.pageTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        'Chúc mừng bạn đã hoàn thành xuất sắc 50 phút luyện tập cùng Mentor hôm nay.',
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
                        'Thông tin buổi học',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      LearnerMentorDetailRow(
                        icon: Icons.person_outline,
                        label: 'Mentor hướng dẫn',
                        value: mentorName,
                      ),
                      const Divider(),
                      LearnerMentorDetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Thời lượng',
                        value: '50 phút',
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
                          'Đừng quên ôn lại tài liệu và bài tập mà Mentor đã ghi chú nhé!',
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
}
