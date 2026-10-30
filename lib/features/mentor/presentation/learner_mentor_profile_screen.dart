import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình thông tin chi tiết Mentor (Screen 03 theo chuẩn Neo-Japoniste Sakura).
class LearnerMentorProfileScreen extends ConsumerWidget {
  const LearnerMentorProfileScreen({
    required this.planId,
    required this.mentorId,
    super.key,
  });

  final int planId;
  final int mentorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentorsState = ref.watch(learnerMentorListControllerProvider);

    return Scaffold(
      key: const Key('learner_mentor_profile_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Thông tin Mentor'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.space3),
            child: RikiLanguageSwitcher(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (mentorsState) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('learner_mentor_profile_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('learner_mentor_profile_error'),
              message: 'Không thể tải thông tin Mentor.',
              onRetry: ref
                  .read(learnerMentorListControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _buildLoadedProfile(context, value),
        },
      ),
    );
  }

  Widget _buildLoadedProfile(
    BuildContext context,
    List<BookableMentor> mentors,
  ) {
    final mentor = mentors.where((m) => m.id == mentorId).firstOrNull;
    if (mentor == null) {
      return const Center(child: Text('Không tìm thấy thông tin Mentor.'));
    }
    return _buildProfile(context, mentor);
  }

  Widget _buildProfile(BuildContext context, BookableMentor mentor) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: [
              // Hero Profile Card
              RikiCard(
                boxShadow: AppShadows.cardSoft,
                borderColor: AppColors.border,
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.brandTint,
                          foregroundImage: mentor.avatarUrl != null
                              ? NetworkImage(mentor.avatarUrl!)
                              : null,
                          child: Text(
                            mentor.name.isNotEmpty
                                ? mentor.name.substring(0, 1).toUpperCase()
                                : 'M',
                            style: AppTypography.pageTitle.copyWith(
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      mentor.name,
                      style: AppTypography.sectionTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      mentor.headline?.isNotEmpty == true
                          ? mentor.headline!
                          : 'Thông tin chuyên môn chưa được cập nhật.',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space1,
                      alignment: WrapAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space3,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Học cùng Mentor',
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space3,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Phòng học trực tuyến',
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Bento highlight row
              Row(
                children: [
                  Expanded(
                    child: _BentoMetricTile(
                      icon: Icons.timer_outlined,
                      title: '50 phút',
                      subtitle: 'Thời lượng buổi học',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: _BentoMetricTile(
                      icon: Icons.people_outline,
                      title: '1 kèm 1',
                      subtitle: 'Đồng hành trực tiếp',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: _BentoMetricTile(
                      icon: Icons.videocam_outlined,
                      title: 'WebRTC',
                      subtitle: 'Riki Classroom',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),

              // Giới thiệu bản thân
              RikiCard(
                borderColor: AppColors.border,
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.menu_book_outlined,
                          color: AppColors.brandPrimary,
                          size: 20,
                        ),
                        SizedBox(width: AppSpacing.space2),
                        Text(
                          'Giới thiệu bản thân',
                          style: AppTypography.cardTitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      mentor.bio?.isNotEmpty == true
                          ? mentor.bio!
                          : 'Mentor chưa cập nhật phần giới thiệu.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Phương pháp hướng dẫn
              RikiCard(
                borderColor: AppColors.border,
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.psychology_outlined,
                          color: AppColors.brandPrimary,
                          size: 20,
                        ),
                        SizedBox(width: AppSpacing.space2),
                        Text(
                          'Phương pháp hướng dẫn',
                          style: AppTypography.cardTitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      mentor.teachingMethod?.isNotEmpty == true
                          ? mentor.teachingMethod!
                          : 'Mentor chưa cập nhật phương pháp hướng dẫn.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Cấp độ hỗ trợ
              RikiCard(
                borderColor: AppColors.border,
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cấp độ hỗ trợ', style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.space3),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: [
                        if (mentor.jlptLevels.isEmpty)
                          const Text('Chưa có thông tin cấp độ hỗ trợ.')
                        else
                          for (final level in mentor.jlptLevels)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space3,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                level,
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sticky Bottom Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: AppShadows.cardSoft,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: RikiPrimaryButton(
            key: const Key('learner_mentor_view_availability_button'),
            label: 'Xem lịch học',
            trailingIcon: Icons.calendar_month_outlined,
            onPressed: () => context.push(
              AppRoutes.learnerMentorAvailability(planId, mentorId: mentor.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _BentoMetricTile extends StatelessWidget {
  const _BentoMetricTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brandPrimary, size: 22),
          const SizedBox(height: AppSpacing.space1),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
