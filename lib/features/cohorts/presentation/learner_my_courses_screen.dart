import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_payment_status_card.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class LearnerMyCoursesScreen extends ConsumerWidget {
  const LearnerMyCoursesScreen({super.key});

  static String _courseStatusLabel(String status) => switch (status) {
    'Active' || 'Ready' => 'Đang học',
    'Pending' || 'PendingPayment' => 'Chờ thanh toán',
    'Completed' => 'Đã hoàn thành',
    'Cancelled' => 'Đã hủy',
    'PaymentFailed' => 'Thanh toán thất bại',
    'PaymentExpired' => 'Hết hạn giữ chỗ',
    'PaymentReview' => 'Đang xem xét thanh toán',
    'Transferred' => 'Đã chuyển lớp',
    _ => status,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerMyCoursesProvider);

    return Scaffold(
      key: const Key('learner_my_courses_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Lớp đang học của tôi'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.learnerCohorts),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Tìm lớp'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('learner_my_courses_loading'),
          ),
          AsyncError(:final error) => Center(
            child: MentorErrorState(
              message: appErrorMessage(error, context.l10n),
              onRetry: ref.read(learnerMyCoursesProvider.notifier).refresh,
            ),
          ),
          AsyncData(:final value) => value.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MentorEmptyState(
                          icon: Icons.school_outlined,
                          title: 'Bạn chưa tham gia lớp học nào',
                          description:
                              'Khám phá các lớp ôn JLPT theo nhóm cố định đang mở ghi danh.',
                        ),
                        const SizedBox(height: 16),
                        RikiPrimaryButton(
                          label: 'Khám phá lớp ôn JLPT',
                          onPressed: () =>
                              context.push(AppRoutes.learnerCohorts),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      ref.read(learnerMyCoursesProvider.notifier).refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    itemCount: value.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.space3),
                    itemBuilder: (context, index) {
                      final course = value[index];
                      return RikiCard(
                        key: ValueKey('my_course_card_${course.id}'),
                        backgroundColor: AppColors.cardWarmWhite,
                        borderColor: AppColors.cardBorderMuted,
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        onTap: () => context.push(
                          AppRoutes.learnerCohortDetail(course.id),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                MentorStatusBadge(
                                  label: '${course.level} · ${course.sessionType}',
                                  color: AppColors.brandPrimary,
                                ),
                                const SizedBox(width: 8),
                                MentorStatusBadge(
                                  label: _courseStatusLabel(course.status),
                                  color: course.status == 'Active'
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(course.name, style: AppTypography.cardTitle),
                            const SizedBox(height: 4),
                            Text(
                              'Mentor: ${course.mentorName.isEmpty ? "Đang cập nhật" : course.mentorName}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              '${course.totalSessions} buổi · BTVN đạt: ${course.eligibility.passedOnTimeHomework}/${course.eligibility.requiredHomework}',
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (course.startsAt != null)
                              Text(
                                'Khai giảng: ${DateFormat('dd/MM/yyyy HH:mm').format(course.startsAt!)}',
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (course.paymentState.isNotEmpty &&
                                course.paymentState != 'Confirmed') ...[
                              const SizedBox(height: 10),
                              CohortPaymentStatusCard(course: course),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        },
      ),
    );
  }
}
