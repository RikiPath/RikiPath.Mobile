import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_kpi_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_schedule_v3_controller.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/application/push_notification_service.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';

class RikiPathApp extends ConsumerStatefulWidget {
  const RikiPathApp({super.key});

  @override
  ConsumerState<RikiPathApp> createState() => _RikiPathAppState();
}

class _RikiPathAppState extends ConsumerState<RikiPathApp> {
  int? _bootstrappedPushUserId;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    final authenticatedUserId = ref.watch(authenticatedUserIdProvider);

    void onForegroundNotification(PushNotificationPayload payload) {
      ref
          .read(notificationBellTriggerProvider.notifier)
          .onRealtimeNotification(payload);
      if (payload.title.isNotEmpty || payload.body.isNotEmpty) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .info(
              title: payload.title.isNotEmpty ? payload.title : 'Thông báo mới',
              description: payload.body,
            );
      }
      ref.invalidate(notificationControllerProvider);
      ref.invalidate(mentorAvailabilityControllerProvider);
      ref.invalidate(mentorCalendarEventsProvider);
      ref.invalidate(mentorAssignedCohortsProvider);
      ref.invalidate(learnerMyCoursesProvider);
      ref.invalidate(mentorScheduleV3ControllerProvider);
      if (payload.type == 'MentorVerificationResult' ||
          (payload.title.isEmpty && payload.body.isEmpty)) {
        ref.invalidate(mentorProfileControllerProvider);
      }
    }

    ref.listen<int?>(authenticatedUserIdProvider, (previous, next) {
      if (previous != next) {
        ref.read(rikiToastServiceProvider.notifier).clear();
        ref.invalidate(mentorAvailabilityControllerProvider);
        ref.invalidate(mentorProfileControllerProvider);
        ref.invalidate(mentorWeeklyScheduleControllerProvider);
        ref.invalidate(mentorKpiSummaryProvider);
        ref.invalidate(mentorCalendarEventsProvider);
        ref.invalidate(mentorAssignedCohortsProvider);
        ref.invalidate(learnerMyCoursesProvider);
      }
      if (next != null) {
        ref
            .read(pushNotificationServiceProvider)
            .connectForegroundNotifications(
              onNotification: onForegroundNotification,
            );
        ref
            .read(pushNotificationServiceProvider)
            .initializeFirebaseMessaging(
              router: router,
              onForegroundNotification: onForegroundNotification,
            );
      } else {
        ref
            .read(pushNotificationServiceProvider)
            .disconnectForegroundNotifications();
      }
    });

    if (authenticatedUserId == null) {
      _bootstrappedPushUserId = null;
    } else if (_bootstrappedPushUserId != authenticatedUserId) {
      _bootstrappedPushUserId = authenticatedUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(pushNotificationServiceProvider)
            .connectForegroundNotifications(
              onNotification: onForegroundNotification,
            );
        ref
            .read(pushNotificationServiceProvider)
            .initializeFirebaseMessaging(
              router: router,
              onForegroundNotification: onForegroundNotification,
            );
      });
    }

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      routerConfig: router,
      builder: (context, child) =>
          RikiToastHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
