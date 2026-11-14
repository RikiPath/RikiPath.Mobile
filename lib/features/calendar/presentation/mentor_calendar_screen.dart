import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';
import 'package:rikipath_mobile/core/widgets/riki_state_view.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/mentor_calendar_event_sheet.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorCalendarScreen extends ConsumerWidget {
  const MentorCalendarScreen({
    super.key,
    this.initialMode = SakuraCalendarViewMode.month,
  });

  final SakuraCalendarViewMode initialMode;

  void _reloadCalendar(WidgetRef ref) {
    ref.invalidate(mentorMeetingsControllerProvider);
    ref.invalidate(mentorAvailabilityControllerProvider);
    ref.invalidate(mentorCalendarEventsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(mentorCalendarEventsProvider);
    final meetingsErr = ref.watch(mentorMeetingsControllerProvider).hasError;
    final availabilityErr = ref
        .watch(mentorAvailabilityControllerProvider)
        .hasError;

    final inShell = MentorShellScope.hasShell(context);

    Widget buildShellBody() {
      return eventsAsync.when(
        loading: () => const Center(
          child: RikiFullScreenLoader(
            title: 'Đang tải lịch giảng dạy...',
            semanticsLabel: 'Đang tải lịch giảng dạy',
          ),
        ),
        error: (err, _) => RikiErrorState(
          title: 'Không thể tải lịch giảng dạy',
          message: appErrorMessage(err, context.l10n),
          actionLabel: context.l10n.mentorCommonRetry,
          onAction: () => _reloadCalendar(ref),
        ),
        data: (events) {
          return SakuraCalendarShell(
            events: events,
            dataIncomplete: meetingsErr || availabilityErr,
            roleName: 'Cố vấn RikiPath',
            isMentor: true,
            showBackButton: !inShell,
            onBackPressed: inShell
                ? null
                : () => popOrGo(context, AppRoutes.mentor),
            fabLabel: 'Đăng ký lịch trống',
            fabIcon: Icons.add_alarm_outlined,
            initialMode: initialMode,
            onFabPressed: () async {
              if (inShell) {
                mentorNavigate(context, AppRoutes.mentorAvailability);
                return;
              }
              await context.push(AppRoutes.mentorAvailability);
              if (context.mounted) {
                _reloadCalendar(ref);
              }
            },
            onEventSelected: (event) => MentorCalendarEventSheet.show(
              context,
              event: event,
              onNavigateDone: () {
                if (context.mounted) {
                  _reloadCalendar(ref);
                }
              },
            ),
          );
        },
      );
    }

    // Avoid nesting a redundant Scaffold around SakuraCalendarShell's Scaffold
    // when rendered inside the persistent MentorShell.
    if (inShell && eventsAsync.hasValue) {
      return KeyedSubtree(
        key: const Key('mentor_calendar_screen'),
        child: buildShellBody(),
      );
    }

    final canPopRoute =
        GoRouter.maybeOf(context)?.canPop() ??
        (ModalRoute.of(context)?.canPop ?? true);
    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          popOrGo(context, AppRoutes.mentor);
        }
      },
      child: Scaffold(
        key: const Key('mentor_calendar_screen'),
        backgroundColor: AppColors.background,
        bottomNavigationBar: inShell
            ? null
            : const MentorBottomNavigationBar(selectedIndex: 1),
        body: buildShellBody(),
      ),
    );
  }
}
