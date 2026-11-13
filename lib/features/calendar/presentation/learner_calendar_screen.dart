import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/calendar/application/learner_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/application/sakura_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_event_detail_sheet.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';

class LearnerCalendarScreen extends ConsumerStatefulWidget {
  const LearnerCalendarScreen({
    super.key,
    this.initialMode = SakuraCalendarViewMode.month,
    this.initialDate,
  });

  final SakuraCalendarViewMode initialMode;
  final DateTime? initialDate;

  @override
  ConsumerState<LearnerCalendarScreen> createState() =>
      _LearnerCalendarScreenState();
}

class _LearnerCalendarScreenState extends ConsumerState<LearnerCalendarScreen> {
  // Scoped to this route: never share another learner's events across sessions.
  List<SakuraCalendarEvent>? _lastSuccessfulEvents;
  List<SakuraCalendarEvent>? _lastAvailableSlots;
  List<SakuraCalendarEvent>? _lastSrsEvents;
  List<SakuraCalendarEvent>? _lastLearningEvents;

  String _loadError(Object error) {
    if (error is TimeoutException) {
      return 'Kết nối lịch quá thời gian. Vui lòng thử lại.';
    }
    if (error is ServerError) {
      return 'Máy chủ chưa tải được dữ liệu lịch. Vui lòng thử lại sau.';
    }
    return appErrorMessage(error, context.l10n);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(learnerCalendarEventsProvider);
    final slotsAsync = ref.watch(learnerCalendarAvailableSlotsProvider);
    final srsAsync = ref.watch(learnerCalendarSrsEventsProvider);
    final learningAsync = ref.watch(learnerCalendarLearningEventsProvider);
    final sessionExpired = [
      eventsAsync.error,
      slotsAsync.error,
      srsAsync.error,
      learningAsync.error,
    ].any((error) => error is UnauthorizedError);
    if (sessionExpired) {
      _lastSuccessfulEvents = null;
      _lastAvailableSlots = null;
      _lastSrsEvents = null;
      _lastLearningEvents = null;
    }
    // Slot có thể đã được người khác đặt; không giữ slot cũ khi tải mới thất bại.
    if (slotsAsync.hasError) _lastAvailableSlots = null;
    if (!sessionExpired) {
      if (eventsAsync case AsyncData(value: final events)) {
        _lastSuccessfulEvents = events;
      }
      if (slotsAsync case AsyncData(value: final slots)) {
        _lastAvailableSlots = slots;
      }
      if (srsAsync case AsyncData(value: final srs)) {
        _lastSrsEvents = srs;
      }
      if (learningAsync case AsyncData(value: final learning)) {
        _lastLearningEvents = learning;
      }
    }

    final combinedEvents = <SakuraCalendarEvent>[
      ...?_lastSuccessfulEvents,
      ...?_lastAvailableSlots,
      ...?_lastSrsEvents,
      ...?_lastLearningEvents,
    ]..sort((a, b) => a.startTime.compareTo(b.startTime));

    final failedSources = <String>[
      if (eventsAsync.hasError) 'lịch hẹn',
      if (slotsAsync.hasError) 'lịch trống',
      if (srsAsync.hasError) 'thẻ ôn tập',
      if (learningAsync.hasError) 'tiến độ học',
    ];
    final loading =
        eventsAsync.isLoading ||
        slotsAsync.isLoading ||
        srsAsync.isLoading ||
        learningAsync.isLoading;
    final allFailed =
        failedSources.length == 4 &&
        _lastSuccessfulEvents == null &&
        _lastAvailableSlots == null &&
        _lastSrsEvents == null &&
        _lastLearningEvents == null;

    void retry() {
      _lastAvailableSlots = null;
      ref.invalidate(learnerMentorBookingsControllerProvider);
      ref.invalidate(learnerMentorAvailabilityControllerProvider);
      ref.invalidate(learnerCalendarEventsProvider);
      ref.invalidate(learnerCalendarAvailableSlotsProvider);
      ref.invalidate(learnerCalendarSrsEventsProvider);
      ref.invalidate(learnerCalendarLearningEventsProvider);
    }

    Widget calendar(List<SakuraCalendarEvent> events) => SakuraCalendarShell(
      events: events,
      roleName: 'Học viên RikiPath',
      fabLabel: context.l10n.mentorFinderTitle,
      fabIcon: Icons.calendar_month_outlined,
      initialMode: widget.initialMode,
      initialDate: widget.initialDate,
      onFabPressed: () async {
        final selectedDate = ref
            .read(sakuraCalendarControllerProvider)
            .selectedDate;
        await context.push(
          AppRoutes.learnerMentorFindSlots(),
          extra: selectedDate,
        );
        if (mounted) retry();
      },
      onEventSelected: (event) async {
        if (event.type == SakuraCalendarEventType.srsReview) {
          await context.push(AppRoutes.dailyReview);
          if (mounted) {
            ref.invalidate(learnerCalendarSrsEventsProvider);
          }
        } else if (event.type == SakuraCalendarEventType.availableSlot) {
          await context.push(
            AppRoutes.learnerMentorFindSlots(
              availabilityId: event.availabilityId,
            ),
            extra: event.startTime,
          );
          if (mounted) retry();
        } else if (event.type == SakuraCalendarEventType.learningPlan) {
          await context.push(AppRoutes.learnRoadmap);
          if (mounted) ref.invalidate(learnerCalendarLearningEventsProvider);
        } else {
          SakuraEventDetailSheet.show(context, event: event);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          calendar(combinedEvents),
          if (sessionExpired)
            _CalendarNotice(
              message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            )
          else if (allFailed)
            _CalendarNotice(
              message: _loadError(
                eventsAsync.error ??
                    slotsAsync.error ??
                    srsAsync.error ??
                    learningAsync.error!,
              ),
              onRetry: retry,
            )
          else if (failedSources.isNotEmpty)
            _CalendarNotice(
              message:
                  'Chưa đồng bộ được ${failedSources.join(', ')}. '
                  '${_loadError(eventsAsync.error ?? slotsAsync.error ?? srsAsync.error ?? learningAsync.error!)}',
              onRetry: retry,
            )
          else if (loading)
            _CalendarNotice(
              message: combinedEvents.isEmpty
                  ? 'Đang tải lịch học...'
                  : 'Đang đồng bộ lịch...',
              loading: true,
            ),
        ],
      ),
    );
  }
}

class _CalendarNotice extends StatelessWidget {
  const _CalendarNotice({
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Positioned(
    top: MediaQuery.paddingOf(context).top + 72,
    left: 16,
    right: 16,
    child: Material(
      color: AppColors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (loading) ...[
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message, maxLines: 2)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    ),
  );
}
