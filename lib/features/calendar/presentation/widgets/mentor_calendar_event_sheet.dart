import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_configuration.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorCalendarEventSheet extends ConsumerWidget {
  const MentorCalendarEventSheet({
    required this.event,
    this.onNavigateDone,
    super.key,
  });

  final SakuraCalendarEvent event;
  final VoidCallback? onNavigateDone;

  static Future<void> show(
    BuildContext context, {
    required SakuraCalendarEvent event,
    VoidCallback? onNavigateDone,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MentorCalendarEventSheet(
        event: event,
        onNavigateDone: onNavigateDone,
      ),
    );
  }

  Future<void> _pushRoute(BuildContext context, String route) async {
    final hasShell = MentorShellScope.hasShell(context);
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).pop();
    if (router == null) return;
    if (hasShell && MentorNavigationConfiguration.instance.containsRoute(route)) {
      router.go(route);
      return;
    }
    await router.push(route);
    onNavigateDone?.call();
  }

  Future<void> _joinMeetingRoom(BuildContext context, WidgetRef ref) async {
    final safeUri = parseSafeExternalHttpUri(event.meetingLink);
    final room = MeetingRoomReference.resolve(
      roomId: event.roomId,
      webUri: safeUri,
    );

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
      final router = GoRouter.maybeOf(context);
      Navigator.of(context).pop();
      await router?.push(AppRoutes.meetingRoom(room.roomId), extra: room);
      onNavigateDone?.call();
      return;
    }

    if (safeUri == null) {
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: context.l10n.mentorJoinFailedTitle,
            description: context.l10n.mentorJoinFailedDescription,
          );
      return;
    }

    final opened = await ref
        .read(mentorMeetingLinkLauncherProvider)
        .open(safeUri);
    if (!opened && context.mounted) {
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: context.l10n.mentorJoinFailedTitle,
            description: context.l10n.mentorJoinFailedDescription,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accent = event.primaryColor;
    final dateFmt = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(event.startTime);
    final timeFmt =
        '${DateFormat('HH:mm').format(event.startTime)} – ${DateFormat('HH:mm').format(event.endTime)}';

    final bookingId = event.bookingId;
    final isConsultation =
        event.type == SakuraCalendarEventType.consultation && bookingId != null;
    final isCancelled = event.status == MentorMeetingStatus.cancelled;
    final isCompleted = event.status == MentorMeetingStatus.completed;
    final safeUri = parseSafeExternalHttpUri(event.meetingLink);
    final resolvedRoom = MeetingRoomReference.resolve(
      roomId: event.roomId,
      webUri: safeUri,
    );
    final canJoin =
        isConsultation &&
        !isCancelled &&
        !isCompleted &&
        (MeetingNativeRollout.isEnabled
            ? resolvedRoom != null
            : safeUri != null);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.space3),
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.cardWarmWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.sakuraSubtle,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: event.backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: event.borderColor),
                    ),
                    child: Text(
                      event.type.labelVi,
                      style: AppTypography.badgeText.copyWith(color: accent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  if (event.statusLabel != null)
                    MentorStatusBadge(
                      label: event.statusLabel!,
                      color: accent,
                    ),
                  const Spacer(),
                  if (event.jlptLevel?.trim().isNotEmpty == true)
                    MentorStatusBadge(
                      label: 'JLPT ${event.jlptLevel!.trim()}',
                      color: AppColors.brandPrimary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(event.title, style: AppTypography.sectionTitle),
              if (event.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  event.subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(dateFmt, style: AppTypography.bodySmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          timeFmt,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (event.notes != null && event.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.brandTint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.cardBorderMuted),
                  ),
                  child: Text(
                    event.notes!.trim(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              if (canJoin) ...[
                RikiPrimaryButton(
                  key: const Key('mentor_calendar_join_room_button'),
                  label: MeetingNativeRollout.isEnabled
                      ? 'Vào phòng tư vấn RikiPath'
                      : l10n.mentorJoinMeeting,
                  leadingIcon: Icons.videocam_rounded,
                  onPressed: () => _joinMeetingRoom(context, ref),
                ),
                const SizedBox(height: AppSpacing.space2),
              ],
              if (isConsultation) ...[
                RikiPrimaryButton(
                  label: 'Mở chi tiết lớp nhóm',
                  leadingIcon: Icons.groups_outlined,
                  onPressed: () =>
                      _pushRoute(context, AppRoutes.mentorCohortDetail(bookingId)),
                ),
                const SizedBox(height: AppSpacing.space2),
              ] else if (event.availabilityId != null) ...[
                RikiPrimaryButton(
                  label: l10n.mentorViewAvailability,
                  leadingIcon: Icons.edit_calendar_outlined,
                  onPressed: () =>
                      _pushRoute(context, AppRoutes.mentorAvailability),
                ),
                const SizedBox(height: AppSpacing.space2),
              ],
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.mentorCommonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
