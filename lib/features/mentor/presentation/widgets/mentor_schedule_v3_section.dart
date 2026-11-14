import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_schedule_v3_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_schedule_v3.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorScheduleV3Card extends ConsumerStatefulWidget {
  const MentorScheduleV3Card({this.onDirtyChanged, super.key});

  final ValueChanged<bool>? onDirtyChanged;

  @override
  ConsumerState<MentorScheduleV3Card> createState() =>
      _MentorScheduleV3CardState();
}

class _MentorScheduleV3CardState extends ConsumerState<MentorScheduleV3Card> {
  int? _syncedScheduleId;
  bool _autoPublish = true;
  String _timeZoneId = 'Asia/Ho_Chi_Minh';
  DateTime _effectiveFrom = DateTime.now().toUtc();
  List<MentorScheduleRuleDraft> _draftRules = const <MentorScheduleRuleDraft>[];
  bool _dirty = false;

  void _updateDirtyFlag(bool next, {bool notifyAsync = false}) {
    if (_dirty == next) return;
    _dirty = next;
    final callback = widget.onDirtyChanged;
    if (callback == null) return;
    if (notifyAsync) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) callback(next);
      });
    } else {
      callback(next);
    }
  }

  void _syncFromSchedule(MentorScheduleV3 schedule) {
    if (_dirty && _syncedScheduleId == schedule.scheduleId) return;
    _syncedScheduleId = schedule.scheduleId;
    _autoPublish = schedule.autoPublish;
    _timeZoneId = schedule.timeZoneId.isNotEmpty
        ? schedule.timeZoneId
        : 'Asia/Ho_Chi_Minh';
    _effectiveFrom = schedule.effectiveFrom;
    _draftRules = schedule.rules
        .map(
          (r) => MentorScheduleRuleDraft(
            weekday: r.weekday,
            daypart: r.daypart,
            localStart: r.localStart,
            localEnd: r.localEnd,
            effectiveFrom: r.effectiveFrom,
            effectiveTo: r.effectiveTo,
          ),
        )
        .toList();
    _updateDirtyFlag(false, notifyAsync: true);
  }

  Future<void> _addRuleDialog() async {
    var selectedWeekday = DateTime.monday % 7; // 1 = Monday
    var selectedDaypart = MentorDaypart.evening;

    final result = await showDialog<({int weekday, MentorDaypart daypart})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.l10n.mentorScheduleV3AddRule),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedWeekday,
                decoration: const InputDecoration(
                  labelText: 'Thứ trong tuần',
                  border: OutlineInputBorder(),
                ),
                items: const [1, 2, 3, 4, 5, 6, 0]
                    .map(
                      (day) => DropdownMenuItem<int>(
                        value: day,
                        child: Text(_weekdayLabel(day)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedWeekday = v);
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              DropdownButtonFormField<MentorDaypart>(
                initialValue: selectedDaypart,
                decoration: const InputDecoration(
                  labelText: 'Khung giờ làm việc',
                  border: OutlineInputBorder(),
                ),
                items: MentorDaypart.values
                    .map(
                      (dp) => DropdownMenuItem<MentorDaypart>(
                        value: dp,
                        child: Text(_daypartLabel(dp)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedDaypart = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.l10n.mentorCommonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                ctx,
              ).pop((weekday: selectedWeekday, daypart: selectedDaypart)),
              child: Text(context.l10n.mentorCommonSave),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    final duplicate = _draftRules.any(
      (r) => r.weekday == result.weekday && r.daypart == result.daypart,
    );
    if (duplicate) {
      ref
          .read(rikiToastServiceProvider.notifier)
          .info(title: 'Quy tắc cho thứ và khung giờ này đã tồn tại.');
      return;
    }

    setState(() {
      _draftRules = <MentorScheduleRuleDraft>[
        ..._draftRules,
        MentorScheduleRuleDraft(
          weekday: result.weekday,
          daypart: result.daypart,
          localStart: result.daypart.defaultStart,
          localEnd: result.daypart.defaultEnd,
          effectiveFrom: DateTime.now().toUtc(),
        ),
      ]..sort(_compareRuleDraft);
      _updateDirtyFlag(true);
    });
  }

  Future<bool> _saveRules() async {
    final l10n = context.l10n;
    try {
      await runWithAppLoadingOverlay<MentorScheduleV3>(
        context,
        title: l10n.mentorScheduleV3SaveRules,
        action: () => ref
            .read(mentorScheduleV3ControllerProvider.notifier)
            .updateSchedule(
              UpdateMentorScheduleV3Request(
                timeZoneId: _timeZoneId,
                autoPublish: _autoPublish,
                effectiveFrom: _effectiveFrom,
                rules: _draftRules,
              ),
            ),
      );
      if (!mounted) return false;
      setState(() => _updateDirtyFlag(false));
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã lưu lịch làm việc định kỳ.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: l10n.mentorScheduleV3SaveRules,
            description: appErrorMessage(error, l10n),
          );
      return false;
    }
  }

  Future<void> _previewNext7Days() async {
    if (_dirty) {
      final saved = await _saveRules();
      if (!saved || !mounted) return;
    }
    final l10n = context.l10n;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 6));

    try {
      final result = await runWithAppLoadingOverlay<MentorSlotPreviewResult>(
        context,
        title: l10n.mentorScheduleV3Preview,
        action: () => ref
            .read(mentorScheduleV3ControllerProvider.notifier)
            .previewSlots(startDate: start, endDate: end),
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _SlotPreviewSheet(preview: result),
      );
    } catch (error) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: l10n.mentorScheduleV3Preview,
            description: appErrorMessage(error, l10n),
          );
    }
  }

  Future<void> _publishNext7Days() async {
    if (_dirty) {
      final saved = await _saveRules();
      if (!saved || !mounted) return;
    }
    final l10n = context.l10n;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 6));

    try {
      final result = await runWithAppLoadingOverlay<MentorPublishSlotsResult>(
        context,
        title: l10n.mentorScheduleV3Publish,
        action: () => ref
            .read(mentorScheduleV3ControllerProvider.notifier)
            .publishSlots(startDate: start, endDate: end),
      );
      ref.invalidate(mentorAvailabilityControllerProvider);
      ref.invalidate(mentorCalendarEventsProvider);
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(
            title: 'Đã công bố ${result.createdCount} khung giờ mới.',
            description:
                'Tổng ${result.totalSlotsProcessed} khung giờ xử lý (bỏ qua ${result.skippedExistingCount} khung giờ đã có).',
          );
    } catch (error) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: l10n.mentorScheduleV3Publish,
            description: appErrorMessage(error, l10n),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheduleAsync = ref.watch(mentorScheduleV3ControllerProvider);
    final profile = ref.watch(mentorProfileControllerProvider).value;
    final isApprovedMentor = profile?.isApproved ?? false;

    return RikiCard(
      key: const Key('mentor_schedule_v3_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_mosaic_outlined,
                size: 20,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  l10n.mentorScheduleV3Title,
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            l10n.mentorScheduleV3Subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (profile != null && !isApprovedMentor) ...[
            const SizedBox(height: AppSpacing.space3),
            RikiWarningBanner(
              key: const Key('mentor_schedule_v3_approval_notice'),
              title: l10n.mentorScheduleV3Title,
              message: l10n.mentorScheduleV3ApprovalRequired,
              icon: Icons.verified_user_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          switch (scheduleAsync) {
            AsyncLoading() => const RikiSkeleton(height: 76),
            AsyncError(:final error) => MentorErrorState(
              key: const Key('mentor_schedule_v3_error'),
              message: appErrorMessage(error, l10n),
              onRetry: () =>
                  ref.read(mentorScheduleV3ControllerProvider.notifier).refresh(),
            ),
            AsyncData(:final value) => Builder(
              builder: (context) {
                _syncFromSchedule(value);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: [
                        MentorStatusBadge(
                          label: _timeZoneId,
                          color: AppColors.info,
                        ),
                        MentorStatusBadge(
                          label: '${_draftRules.length} quy tắc',
                          color: AppColors.brandPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _autoPublish,
                        onChanged: (next) {
                          setState(() {
                            _autoPublish = next;
                            _updateDirtyFlag(true);
                          });
                        },
                        title: Text(
                          l10n.mentorScheduleV3AutoPublish,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_draftRules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space2,
                        ),
                        child: Text(
                          'Chưa có quy tắc ca định kỳ nào. Hãy thêm quy tắc bên dưới.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      ..._draftRules.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final rule = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.space2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space3,
                            vertical: AppSpacing.space2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _weekdayLabel(rule.weekday),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${_daypartShortName(rule.daypart)} (${rule.localStart} – ${rule.localEnd})',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.mentorScheduleV3DeleteSlot,
                                onPressed: () {
                                  setState(() {
                                    _draftRules = List.of(_draftRules)
                                      ..removeAt(idx);
                                    _updateDirtyFlag(true);
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.space2),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('mentor_schedule_v3_add_rule'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: _addRuleDialog,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              l10n.mentorScheduleV3AddRule,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: RikiPrimaryButton(
                            key: const Key('mentor_schedule_v3_save_button'),
                            label: l10n.mentorScheduleV3SaveRules,
                            onPressed: _saveRules,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('mentor_schedule_v3_preview_button'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: isApprovedMentor && _draftRules.isNotEmpty
                                ? _previewNext7Days
                                : null,
                            icon: const Icon(
                              Icons.preview_outlined,
                              size: 18,
                            ),
                            label: Text(
                              l10n.mentorScheduleV3Preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('mentor_schedule_v3_publish_button'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              foregroundColor: AppColors.brandPrimary,
                            ),
                            onPressed: isApprovedMentor && _draftRules.isNotEmpty
                                ? _publishNext7Days
                                : null,
                            icon: const Icon(
                              Icons.publish_rounded,
                              size: 18,
                            ),
                            label: Text(
                              l10n.mentorScheduleV3Publish,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          },
        ],
      ),
    );
  }
}

class MentorAvailabilitySlotItemCard extends ConsumerWidget {
  const MentorAvailabilitySlotItemCard({
    required this.slot,
    required this.index,
    super.key,
  });

  final MentorAvailabilitySlot slot;
  final int index;

  Future<String?> _promptReason(BuildContext context, String title) async {
    final l10n = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (ctx) => _ReasonPromptDialog(
        title: title,
        hint: l10n.mentorScheduleV3ReasonHint,
        confirmLabel: l10n.mentorCommonConfirm,
        cancelLabel: l10n.mentorCommonCancel,
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mentorScheduleV3DeleteSlot),
        content: const Text(
          'Bạn có chắc muốn xóa khung giờ rảnh chưa có học viên đặt này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.mentorCommonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.mentorCommonConfirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _runMutation(
    BuildContext context,
    WidgetRef ref, {
    required String loadingTitle,
    required String successTitle,
    required Future<void> Function() action,
  }) async {
    final l10n = context.l10n;
    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: loadingTitle,
        action: action,
      );
      ref.invalidate(mentorAvailabilityControllerProvider);
      ref.invalidate(mentorCalendarEventsProvider);
      if (!context.mounted) return;
      ref.read(rikiToastServiceProvider.notifier).success(title: successTitle);
    } catch (error) {
      if (!context.mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: loadingTitle,
            description: appErrorMessage(error, l10n),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statusBadge = _slotStatusInfo(slot, l10n);
    final canDelete =
        !slot.isBooked && slot.bookedCount == 0 && !slot.hasCancelRequest;
    final canRequestCancel =
        !slot.isBooked && !slot.isRejected && !slot.hasCancelRequest;
    final canRequestChange = !slot.isRejected && !slot.hasChangeRequest;
    final hasActions = canDelete || canRequestCancel || canRequestChange;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: RikiCard(
        key: ValueKey<String>('mentor_availability_$index'),
        backgroundColor: AppColors.cardWarmWhite,
        borderColor: AppColors.cardBorderMuted,
        boxShadow: AppShadows.sakuraSubtle,
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: slot.isBooked
                        ? AppColors.surfaceSubtle
                        : AppColors.successBackground,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    slot.isBooked
                        ? Icons.event_busy_outlined
                        : Icons.event_available_outlined,
                    color: slot.isBooked
                        ? AppColors.textSecondary
                        : AppColors.success,
                    size: 23,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.isBooked
                            ? l10n.mentorSlotBooked
                            : l10n.mentorSlotOpen,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${mentorTimeLabel(slot.startTime, context)} – ${DateFormat('HH:mm').format(slot.endTime.displayValue)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Wrap(
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space1,
                        children: [
                          MentorStatusBadge(
                            label: statusBadge.label,
                            color: statusBadge.color,
                          ),
                          MentorStatusBadge(
                            label:
                                '${l10n.mentorScheduleSlotBookedCount}: ${slot.bookedCount}/${slot.maxLearners}',
                            color: AppColors.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasActions)
                  PopupMenuButton<String>(
                    key: Key('mentor_slot_actions_${slot.id}'),
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    tooltip: 'Tùy chọn khung giờ',
                    onSelected: (action) async {
                      if (action == 'delete') {
                        if (!await _confirmDelete(context)) return;
                        if (!context.mounted) return;
                        await _runMutation(
                          context,
                          ref,
                          loadingTitle: l10n.mentorScheduleV3DeleteSlot,
                          successTitle: 'Đã xóa khung giờ.',
                          action: () => ref
                              .read(mentorScheduleV3ControllerProvider.notifier)
                              .deleteAvailability(slot.id),
                        );
                      } else if (action == 'disable') {
                        final reason = await _promptReason(
                          context,
                          l10n.mentorScheduleV3DisableSlot,
                        );
                        if (reason == null || !context.mounted) return;
                        await _runMutation(
                          context,
                          ref,
                          loadingTitle: l10n.mentorScheduleV3DisableSlot,
                          successTitle: 'Đã đóng khung giờ.',
                          action: () => ref
                              .read(mentorScheduleV3ControllerProvider.notifier)
                              .disableSlot(slot.id, reason: reason),
                        );
                      } else if (action == 'cancel') {
                        final reason = await _promptReason(
                          context,
                          l10n.mentorScheduleV3RequestCancel,
                        );
                        if (reason == null || !context.mounted) return;
                        await _runMutation(
                          context,
                          ref,
                          loadingTitle: l10n.mentorScheduleV3RequestCancel,
                          successTitle: 'Đã gửi yêu cầu hủy khung giờ.',
                          action: () => ref
                              .read(mentorScheduleV3ControllerProvider.notifier)
                              .requestCancelAvailabilities(
                                <int>[slot.id],
                                reason: reason,
                              ),
                        );
                      } else if (action == 'change') {
                        final reason = await _promptReason(
                          context,
                          l10n.mentorScheduleV3RequestChange,
                        );
                        if (reason == null || !context.mounted) return;
                        await _runMutation(
                          context,
                          ref,
                          loadingTitle: l10n.mentorScheduleV3RequestChange,
                          successTitle: 'Đã gửi yêu cầu đổi ca.',
                          action: () => ref
                              .read(mentorScheduleV3ControllerProvider.notifier)
                              .requestSlotChange(slot.id, reason),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      if (canDelete)
                        PopupMenuItem<String>(
                          key: Key('mentor_slot_delete_${slot.id}'),
                          value: 'delete',
                          child: Text(l10n.mentorScheduleV3DeleteSlot),
                        ),
                      if (canDelete)
                        PopupMenuItem<String>(
                          key: Key('mentor_slot_disable_${slot.id}'),
                          value: 'disable',
                          child: Text(l10n.mentorScheduleV3DisableSlot),
                        ),
                      if (canRequestCancel)
                        PopupMenuItem<String>(
                          key: Key('mentor_slot_cancel_${slot.id}'),
                          value: 'cancel',
                          child: Text(l10n.mentorScheduleV3RequestCancel),
                        ),
                      if (canRequestChange)
                        PopupMenuItem<String>(
                          key: Key('mentor_slot_change_${slot.id}'),
                          value: 'change',
                          child: Text(l10n.mentorScheduleV3RequestChange),
                        ),
                    ],
                  ),
              ],
            ),
            if (slot.rejectionReason?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Từ chối: ${slot.rejectionReason!.trim()}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            if (slot.cancelReason?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Lý do xin hủy: ${slot.cancelReason!.trim()}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
            if (slot.changeRequestReason?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Đổi ca: ${slot.changeRequestReason!.trim()}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.info),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotPreviewSheet extends StatelessWidget {
  const _SlotPreviewSheet({required this.preview});

  final MentorSlotPreviewResult preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.space3),
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.cardWarmWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mentorScheduleV3Preview,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              'Tổng ${preview.totalCandidateSlots} khung giờ · Mới: ${preview.newSlotsCount} · Đã có: ${preview.existingSlotsCount} · Trùng: ${preview.conflictSlotsCount}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: preview.slots.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        child: Text(
                          'Không có khung giờ nào được tạo trong 7 ngày tới từ quy tắc hiện tại.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: preview.slots.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.space2),
                      itemBuilder: (ctx, i) {
                        final item = preview.slots[i];
                        final dateStr = DateFormat('dd/MM/yyyy')
                            .format(item.localDate);
                        final badgeColor = item.hasConflict
                            ? AppColors.error
                            : item.isExisting
                            ? AppColors.textSecondary
                            : AppColors.success;
                        final badgeText = item.hasConflict
                            ? 'Xung đột'
                            : item.isExisting
                            ? 'Đã có'
                            : 'Mới';
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$dateStr · ${item.localStart}–${item.localEnd}',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      item.conflictReason ??
                                          _daypartShortName(item.daypart),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: item.hasConflict
                                            ? AppColors.error
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              MentorStatusBadge(
                                label: badgeText,
                                color: badgeColor,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.space3),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.mentorCommonCancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonPromptDialog extends StatefulWidget {
  const _ReasonPromptDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<_ReasonPromptDialog> createState() => _ReasonPromptDialogState();
}

class _ReasonPromptDialogState extends State<_ReasonPromptDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.length < 5) {
              setState(
                () => _error = 'Vui lòng nhập ít nhất 5 ký tự lý do.',
              );
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

({String label, Color color}) _slotStatusInfo(
  MentorAvailabilitySlot slot,
  AppLocalizations l10n,
) {
  if (slot.isRejected) {
    return (label: l10n.mentorScheduleSlotRejected, color: AppColors.error);
  }
  if (slot.hasCancelRequest) {
    return (
      label: l10n.mentorScheduleSlotCancelRequested,
      color: AppColors.warning,
    );
  }
  if (slot.hasChangeRequest) {
    return (label: 'Xin đổi ca', color: AppColors.info);
  }
  if (slot.isPendingApproval) {
    return (label: l10n.mentorScheduleSlotPending, color: AppColors.warning);
  }
  return (label: l10n.mentorScheduleSlotApproved, color: AppColors.success);
}

int _compareRuleDraft(MentorScheduleRuleDraft a, MentorScheduleRuleDraft b) {
  final aOrder = a.weekday == 0 ? 7 : a.weekday;
  final bOrder = b.weekday == 0 ? 7 : b.weekday;
  final dayCmp = aOrder.compareTo(bOrder);
  if (dayCmp != 0) return dayCmp;
  return a.daypart.index.compareTo(b.daypart.index);
}

String _weekdayLabel(int weekday) => switch (weekday) {
  1 => 'Thứ Hai',
  2 => 'Thứ Ba',
  3 => 'Thứ Tư',
  4 => 'Thứ Năm',
  5 => 'Thứ Sáu',
  6 => 'Thứ Bảy',
  _ => 'Chủ Nhật',
};

String _daypartShortName(MentorDaypart daypart) => switch (daypart) {
  MentorDaypart.morning => 'Ca sáng',
  MentorDaypart.noon => 'Ca trưa',
  MentorDaypart.afternoon => 'Ca chiều',
  MentorDaypart.evening => 'Ca tối',
};

String _daypartLabel(MentorDaypart daypart) =>
    '${_daypartShortName(daypart)} (${daypart.defaultStart}–${daypart.defaultEnd})';
