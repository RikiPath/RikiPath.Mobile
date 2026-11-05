import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';
import 'package:rikipath_mobile/core/widgets/riki_state_view.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';

class MentorCalendarScreen extends ConsumerWidget {
  const MentorCalendarScreen({
    super.key,
    this.initialMode = SakuraCalendarViewMode.month,
  });

  final SakuraCalendarViewMode initialMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(mentorCalendarEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: eventsAsync.when(
        loading: () => const Center(
          child: RikiFullScreenLoader(
            title: 'Đang tải lịch giảng dạy...',
            semanticsLabel: 'Đang tải lịch giảng dạy',
          ),
        ),
        error: (err, stack) => RikiErrorState(
          title: 'Không thể tải lịch giảng dạy',
          message: err.toString(),
          actionLabel: 'Thử lại',
          onAction: () => ref.refresh(mentorCalendarEventsProvider),
        ),
        data: (events) {
          return SakuraCalendarShell(
            events: events,
            roleName: 'Cố vấn RikiPath',
            fabLabel: 'Đăng ký lịch trống',
            fabIcon: Icons.add_alarm_outlined,
            initialMode: initialMode,
            onFabPressed: () => context.push(AppRoutes.mentorAvailability),
          );
        },
      ),
    );
  }
}
