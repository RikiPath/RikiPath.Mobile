import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart'
    show mentorStatusLabel;

/// Mentor pre-session preparation screen (`/mentor/prep` or `/mentor/meetings/:id/prep`).
class MentorSessionPrepScreen extends ConsumerStatefulWidget {
  const MentorSessionPrepScreen({super.key, this.bookingId});

  final int? bookingId;

  @override
  ConsumerState<MentorSessionPrepScreen> createState() =>
      _MentorSessionPrepScreenState();
}

class _MentorSessionPrepScreenState
    extends ConsumerState<MentorSessionPrepScreen> {
  final Map<int, Set<int>> _checkedStepsByBooking = <int, Set<int>>{};
  int? _selectedBookingId;

  @override
  void initState() {
    super.initState();
    _selectedBookingId = widget.bookingId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meetingsAsync = ref.watch(mentorMeetingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.mentorPrepScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.mentorCommonRetry,
            onPressed: () {
              ref.invalidate(mentorMeetingsControllerProvider);
              final id = _effectiveBookingId(meetingsAsync.asData?.value);
              if (id != null) {
                ref.invalidate(mentorBookingDetailProvider(id));
                ref.invalidate(mentorBookingAttendanceProvider(id));
              }
            },
          ),
        ],
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: RikiAnimatedStudyLoader()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiErrorState(
              title: l10n.mentorMeetingsError,
              message: appErrorMessage(err, l10n),
              actionLabel: l10n.mentorCommonRetry,
              onAction: () => ref.invalidate(mentorMeetingsControllerProvider),
            ),
          ),
        ),
        data: (meetings) {
          final sorted = [...meetings]
            ..sort((a, b) {
              final aTime = a.scheduledAt?.value;
              final bTime = b.scheduledAt?.value;
              if (aTime == null && bTime == null) return b.id.compareTo(a.id);
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return aTime.compareTo(bTime);
            });

          final activeId = _effectiveBookingId(sorted);
          if (sorted.isEmpty || activeId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: RikiEmptyState(
                  icon: Icons.event_note_outlined,
                  title: l10n.mentorPrepScreenTitle,
                  message: l10n.mentorMeetingsEmpty,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () async {
              ref.invalidate(mentorMeetingsControllerProvider);
              ref.invalidate(mentorBookingDetailProvider(activeId));
              ref.invalidate(mentorBookingAttendanceProvider(activeId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                if (widget.bookingId == null && sorted.length > 1) ...[
                  Text(
                    l10n.mentorPrepSelectBookingHint,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: sorted
                          .take(10)
                          .map((m) {
                            final selected = m.id == activeId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                selected: selected,
                                label: Text(
                                  '#${m.id} · ${m.learnerName ?? l10n.mentorLearnerUnknown}',
                                ),
                                selectedColor: AppColors.brandTint,
                                onSelected: (_) =>
                                    setState(() => _selectedBookingId = m.id),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
                _PrepDetailBody(
                  bookingId: activeId,
                  checkedSteps:
                      _checkedStepsByBooking[activeId] ?? const <int>{},
                  onToggleStep: (index) {
                    setState(() {
                      final stepSet = _checkedStepsByBooking.putIfAbsent(
                        activeId,
                        () => <int>{},
                      );
                      if (stepSet.contains(index)) {
                        stepSet.remove(index);
                      } else {
                        stepSet.add(index);
                      }
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int? _effectiveBookingId(List<MentorMeetingSummary>? meetings) {
    if (_selectedBookingId != null && _selectedBookingId! > 0) {
      return _selectedBookingId;
    }
    if (meetings == null || meetings.isEmpty) return null;
    final upcoming = meetings.where(
      (m) =>
          m.status == MentorMeetingStatus.accepted ||
          m.status == MentorMeetingStatus.assigned,
    );
    return (upcoming.isNotEmpty ? upcoming.first : meetings.first).id;
  }
}

class _PrepDetailBody extends ConsumerWidget {
  const _PrepDetailBody({
    required this.bookingId,
    required this.checkedSteps,
    required this.onToggleStep,
  });

  final int bookingId;
  final Set<int> checkedSteps;
  final ValueChanged<int> onToggleStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detailAsync = ref.watch(mentorBookingDetailProvider(bookingId));
    final attendanceAsync = ref.watch(
      mentorBookingAttendanceProvider(bookingId),
    );

    return detailAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: RikiAnimatedStudyLoader()),
      ),
      error: (err, _) => RikiErrorState(
        title: l10n.mentorPrepScreenTitle,
        message: appErrorMessage(err, l10n),
        actionLabel: l10n.mentorCommonRetry,
        onAction: () => ref.invalidate(mentorBookingDetailProvider(bookingId)),
      ),
      data: (detail) {
        final roomAccessAsync =
            detail.roomId != null && detail.roomId!.trim().isNotEmpty
            ? ref.watch(mentorRoomAccessProvider(detail.roomId!.trim()))
            : null;
        final canJoin = canMentorJoinRoom(
          meetingLink: detail.meetingLink,
          roomId: detail.roomId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session identity & learner question
            RikiCard(
              backgroundColor: AppColors.cardWarmWhite,
              borderColor: AppColors.cardBorderMuted,
              boxShadow: AppShadows.sakuraSubtle,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail.learnerName ?? l10n.mentorLearnerUnknown,
                          style: AppTypography.sectionTitle,
                        ),
                      ),
                      MentorStatusBadge(
                        label: mentorStatusLabel(detail.status, context),
                        color: mentorMeetingStatusColor(detail.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '#${detail.id} · ${formatMentorTimestamp(detail.scheduledAt, context)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (detail.jlptLevel != null) ...[
                    const SizedBox(height: AppSpacing.space2),
                    MentorStatusBadge(
                      label: '${l10n.mentorMeetingJlptLevel}: ${detail.jlptLevel}',
                      color: AppColors.brandPrimary,
                      icon: Icons.school_outlined,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.mentorMeetingLearnerQuestion,
                    style: AppTypography.inputLabel,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.cardBorderMuted),
                    ),
                    child: Text(
                      detail.question ?? l10n.mentorMeetingNoQuestion,
                      style: AppTypography.bodyMedium.copyWith(
                        color: detail.question == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Room Access Readiness
            if (roomAccessAsync != null)
              roomAccessAsync.when(
                loading: () => RikiCard(
                  backgroundColor: AppColors.cardWarmWhite,
                  borderColor: AppColors.cardBorderMuted,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(child: Text(l10n.mentorPrepRoomAccessTitle)),
                    ],
                  ),
                ),
                error: (err, _) => RikiInfoBanner(
                  message:
                      '${l10n.mentorPrepRoomAccessTitle}: ${appErrorMessage(err, l10n)}',
                ),
                data: (access) => RikiCard(
                  backgroundColor: AppColors.cardWarmWhite,
                  borderColor: access.isRoomReady && access.canAccess
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.warning.withValues(alpha: 0.35),
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Row(
                    children: [
                      Icon(
                        access.isRoomReady && access.canAccess
                            ? Icons.meeting_room_outlined
                            : Icons.schedule_outlined,
                        color: access.isRoomReady && access.canAccess
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.mentorPrepRoomAccessTitle,
                              style: AppTypography.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              access.isRoomReady && access.canAccess
                                  ? l10n.mentorPrepRoomReady
                                  : (access.reason ??
                                        l10n.mentorPrepRoomNotReady),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.space3),

            // Pre-session interactive checklist (session-scoped UX helper)
            RikiCard(
              backgroundColor: AppColors.cardWarmWhite,
              borderColor: AppColors.cardBorderMuted,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mentorPrepChecklistTitle,
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  ...[
                    l10n.mentorPrepCheckAudio,
                    l10n.mentorPrepCheckQuestion,
                    l10n.mentorPrepCheckRoomReady,
                  ].asMap().entries.map(
                    (entry) => Material(
                      type: MaterialType.transparency,
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: AppColors.brandPrimary,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: checkedSteps.contains(entry.key),
                        onChanged: (_) => onToggleStep(entry.key),
                        title: Text(entry.value, style: AppTypography.bodyMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            RikiInfoBanner(message: l10n.mentorPrepNotesReadOnlyBanner),
            const SizedBox(height: AppSpacing.space3),

            // Attendance telemetry
            attendanceAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, _) => RikiInfoBanner(
                message: appErrorMessage(err, l10n),
              ),
              data: (records) => MentorAttendanceListCard(records: records),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Primary & secondary actions
            if (canJoin) ...[
              RikiPrimaryButton(
                label: l10n.mentorJoinMeeting,
                leadingIcon: Icons.videocam_outlined,
                onPressed: () => _joinRoom(context, ref, detail),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
            Row(
              children: [
                Expanded(
                  child: RikiSecondaryButton(
                    label: l10n.mentorActionChat,
                    leadingIcon: Icons.chat_bubble_outline,
                    onPressed: () =>
                        context.push(AppRoutes.mentorChatRoom(detail.id)),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: RikiSecondaryButton(
                    label: l10n.meetingDetailsAction,
                    leadingIcon: Icons.info_outline,
                    onPressed: () {
                      final router = GoRouter.maybeOf(context);
                      if (router != null && router.canPop()) {
                        final matches = router
                            .routerDelegate
                            .currentConfiguration
                            .matches;
                        if (matches.length >= 2 &&
                            matches[matches.length - 2].matchedLocation ==
                                AppRoutes.mentorMeetingDetail(detail.id)) {
                          context.pop();
                          return;
                        }
                      }
                      context.pushReplacement(
                        AppRoutes.mentorMeetingDetail(detail.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinRoom(
    BuildContext context,
    WidgetRef ref,
    MentorBookingDetail detail,
  ) async {
    final l10n = context.l10n;
    final uri = parseSafeExternalHttpUri(detail.meetingLink);
    final nativeRoom = resolveMentorNativeRoom(
      meetingLink: detail.meetingLink,
      roomId: detail.roomId,
    );
    if (MeetingNativeRollout.isEnabled && nativeRoom != null) {
      await context.push(
        AppRoutes.meetingRoom(nativeRoom.roomId),
        extra: nativeRoom,
      );
      return;
    }
    if (uri != null) {
      final launched = await ref
          .read(mentorMeetingLinkLauncherProvider)
          .open(uri);
      if (!launched && context.mounted) {
        ref.read(rikiToastServiceProvider.notifier).error(
          title: l10n.mentorJoinFailedTitle,
          description: l10n.mentorJoinFailedDescription,
        );
      }
      return;
    }
    if (nativeRoom != null) {
      await context.push(
        AppRoutes.meetingRoom(nativeRoom.roomId),
        extra: nativeRoom,
      );
    }
  }
}
