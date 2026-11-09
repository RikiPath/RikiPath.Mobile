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
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
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

  String _loadError(Object error) {
    if (error is TimeoutException) {
      return 'Kết nối lịch quá thời gian. Vui lòng thử lại.';
    }
    if (error is ServerError) {
      return 'Máy chủ chưa tải được lịch cố vấn. Vui lòng thử lại sau.';
    }
    return appErrorMessage(error, context.l10n);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(learnerCalendarEventsProvider);
    if (eventsAsync case AsyncData(value: final events)) {
      _lastSuccessfulEvents = events;
    }

    Widget calendar(List<SakuraCalendarEvent> events) => SakuraCalendarShell(
      events: events,
      roleName: 'Học viên RikiPath',
      fabLabel: 'Đặt lịch cố vấn',
      fabIcon: Icons.calendar_month_outlined,
      initialMode: widget.initialMode,
      initialDate: widget.initialDate,
      onFabPressed: () => context.push(AppRoutes.learnerMentorBookings),
    );

    void retry() {
      ref.invalidate(learnerMentorBookingsControllerProvider);
      ref.invalidate(learnerCalendarEventsProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: eventsAsync.when(
        skipLoadingOnRefresh: false,
        loading: () => Stack(
          children: [
            calendar(_lastSuccessfulEvents ?? const []),
            _CalendarNotice(
              message: _lastSuccessfulEvents == null
                  ? 'Đang tải lịch học...'
                  : 'Đang đồng bộ lịch...',
              loading: true,
            ),
          ],
        ),
        error: (err, stack) => _lastSuccessfulEvents == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 42),
                      const SizedBox(height: 12),
                      Text(_loadError(err), textAlign: TextAlign.center),
                      TextButton(
                        onPressed: retry,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  calendar(_lastSuccessfulEvents!),
                  _CalendarNotice(
                    message:
                        'Chưa đồng bộ được lịch mới. Đang hiển thị dữ liệu đã tải.',
                    onRetry: retry,
                  ),
                ],
              ),
        data: calendar,
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
    top: MediaQuery.paddingOf(context).top + 8,
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
