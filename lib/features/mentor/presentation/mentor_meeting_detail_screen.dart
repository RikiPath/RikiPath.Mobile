import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';

class MentorMeetingDetailScreen extends ConsumerWidget {
  const MentorMeetingDetailScreen({required this.meetingId, super.key});

  final int? meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorMeetingsControllerProvider);
    return Scaffold(
      key: const Key('mentor_meeting_detail_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.mentorMeetingDetailTitle)),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('mentor_meeting_detail_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('mentor_meeting_detail_error'),
              message: context.l10n.mentorMeetingsError,
              onRetry: ref
                  .read(mentorMeetingsControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _DetailData(
            meeting: value
                .where((meeting) => meeting.id == meetingId)
                .firstOrNull,
            onJoin: (uri) => _openMeeting(ref, context, uri),
            onAccept: meetingId == null
                ? null
                : () async {
                    final success = await ref
                        .read(mentorMeetingsControllerProvider.notifier)
                        .acceptMeeting(meetingId!);
                    if (!context.mounted) return;
                    if (success) {
                      ref.read(rikiToastServiceProvider.notifier).success(
                            title: 'Xác nhận thành công',
                            description: 'Buổi học đã được xác nhận thành công.',
                          );
                    } else {
                      ref.read(rikiToastServiceProvider.notifier).error(
                            title: 'Xác nhận thất bại',
                            description: 'Không thể xác nhận lịch học. Vui lòng thử lại.',
                          );
                    }
                  },
          ),
        },
      ),
    );
  }

  Future<void> _openMeeting(
    WidgetRef ref,
    BuildContext context,
    Uri uri,
  ) async {
    final room = MeetingRoomReference.resolve(webUri: uri);
    if (MeetingNativeRollout.isEnabled) {
      if (room == null) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: context.l10n.mentorJoinFailedTitle,
              description: context.l10n.meetingLinkInvalid,
            );
        return;
      }
      await context.push(AppRoutes.meetingRoom(room.roomId), extra: room);
      return;
    }
    final opened = await ref.read(mentorMeetingLinkLauncherProvider).open(uri);
    if (opened || !context.mounted) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: context.l10n.mentorJoinFailedTitle,
          description: context.l10n.mentorJoinFailedDescription,
        );
  }
}

class _DetailData extends StatelessWidget {
  const _DetailData({
    required this.meeting,
    required this.onJoin,
    this.onAccept,
  });

  final MentorMeetingSummary? meeting;
  final Future<void> Function(Uri uri) onJoin;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final value = meeting;
    if (value == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: MentorEmptyState(
            key: const Key('mentor_meeting_detail_missing'),
            icon: Icons.event_busy_outlined,
            title: context.l10n.mentorMeetingDetailTitle,
            description: context.l10n.mentorMeetingNotFound,
          ),
        ),
      );
    }

    final meetingUri = value.safeMeetingUri;
    final nativeRoom = MeetingRoomReference.resolve(webUri: meetingUri);
    final canJoin = MeetingNativeRollout.isEnabled
        ? nativeRoom != null
        : meetingUri != null;
    final isAssigned = value.status == MentorMeetingStatus.assigned;
    final isAccepted = value.status == MentorMeetingStatus.accepted;

    return ListView(
      key: const Key('mentor_meeting_detail_content'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        // Hero Card trạng thái yêu cầu
        RikiCard(
          borderColor: isAccepted
              ? AppColors.brandPrimary.withValues(alpha: 0.35)
              : AppColors.warning.withValues(alpha: 0.4),
          backgroundColor: isAccepted
              ? AppColors.brandPrimary.withValues(alpha: 0.04)
              : AppColors.warning.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppColors.brandTint
                      : AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAccepted
                      ? Icons.check_circle_outline
                      : Icons.assignment_ind_outlined,
                  color: isAccepted ? AppColors.brandPrimary : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAccepted
                          ? 'Đã xác nhận buổi học'
                          : (isAssigned
                              ? 'Yêu cầu học mới'
                              : mentorStatusLabel(value.status, context)),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAccepted
                          ? 'Buổi học đã được lên lịch. Vui lòng vào phòng đúng giờ.'
                          : 'Học viên đã đăng ký khung giờ dạy của bạn. Vui lòng kiểm tra và xác nhận.',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        MentorPageHeader(
          title: context.l10n.mentorMeetingDetailTitle,
          subtitle: value.learnerName ?? context.l10n.mentorLearnerUnknown,
        ),
        const SizedBox(height: AppSpacing.space4),
        RikiCard(
          borderColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                icon: Icons.person_outline,
                label: context.l10n.mentorLearnerLabel,
                value: value.learnerName ?? context.l10n.mentorLearnerUnknown,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: context.l10n.mentorScheduleLabel,
                value: mentorTimeLabel(value.scheduledAt, context),
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.verified_outlined,
                label: context.l10n.mentorStatusLabel,
                value: mentorStatusLabel(value.status, context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        if (value.status == MentorMeetingStatus.assigned && onAccept != null) ...[
          RikiPrimaryButton(
            key: const Key('mentor_accept_meeting_button'),
            label: 'Xác nhận buổi học',
            leadingIcon: Icons.check_circle_outline,
            onPressed: onAccept,
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
        if (!canJoin)
          RikiInfoBanner(
            key: const Key('mentor_meeting_link_unavailable'),
            message: context.l10n.mentorMeetingLinkUnavailable,
          )
        else
          RikiPrimaryButton(
            key: const Key('mentor_join_meeting_button'),
            label: context.l10n.mentorJoinMeeting,
            leadingIcon: Icons.videocam_outlined,
            onPressed: () => onJoin(meetingUri!),
          ),
        const SizedBox(height: AppSpacing.space4),

        // Ghi chú & mục tiêu học tập của học viên
        RikiCard(
          borderColor: AppColors.border,
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 18, color: AppColors.brandPrimary),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    'Mục tiêu học viên cần hỗ trợ',
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Ôn tập lộ trình học JLPT, giải thích các dạng bài đọc hiểu N3-N2 và luyện nói giao tiếp tiếng Nhật.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        RikiTextButton(
          label: MaterialLocalizations.of(context).backButtonTooltip,
          leadingIcon: Icons.arrow_back,
          onPressed: context.pop,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandTint,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.brandPrimary, size: 21),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
