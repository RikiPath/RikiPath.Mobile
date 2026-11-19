import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';
import 'package:rikipath_mobile/core/widgets/riki_state_view.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/mentor_calendar_event_sheet.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class MentorCalendarScreen extends ConsumerWidget {
  const MentorCalendarScreen({
    super.key,
    this.initialMode = SakuraCalendarViewMode.month,
  });

  final SakuraCalendarViewMode initialMode;

  void _reloadCalendar(WidgetRef ref) {
    ref.invalidate(mentorAssignedCohortsProvider);
    ref.invalidate(mentorAvailabilityControllerProvider);
    ref.invalidate(mentorCalendarEventsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(mentorCalendarEventsProvider);
    final cohortsErr = ref.watch(mentorAssignedCohortsProvider).hasError;
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
            dataIncomplete: cohortsErr || availabilityErr,
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
            drawerExtraSection: const _MentorGoogleCalendarSyncTile(),
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

class _MentorGoogleCalendarSyncTile extends ConsumerStatefulWidget {
  const _MentorGoogleCalendarSyncTile();

  @override
  ConsumerState<_MentorGoogleCalendarSyncTile> createState() =>
      _MentorGoogleCalendarSyncTileState();
}

class _MentorGoogleCalendarSyncTileState
    extends ConsumerState<_MentorGoogleCalendarSyncTile>
    with WidgetsBindingObserver {
  bool _awaitingOAuthReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingOAuthReturn) {
      _awaitingOAuthReturn = false;
      ref.invalidate(mentorGoogleCalendarControllerProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(mentorGoogleCalendarControllerProvider);
    final toasts = ref.read(rikiToastServiceProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐỒNG BỘ GOOGLE CALENDAR',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          switch (statusAsync) {
            AsyncLoading() => const SizedBox(
              height: 28,
              child: Center(child: LinearProgressIndicator()),
            ),
            AsyncError(:final error) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appErrorMessage(error, context.l10n),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(mentorGoogleCalendarControllerProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
            AsyncData(:final value) =>
              !value.configured
                  ? Text(
                      'Google Calendar chưa được cấu hình trên máy chủ.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.connected
                              ? (value.lastSyncedAt != null
                                    ? 'Đã kết nối · Đồng bộ ${DateFormat('dd/MM HH:mm').format(value.lastSyncedAt!.toLocal())}'
                                    : 'Đã kết nối Google Calendar')
                              : 'Chưa kết nối Google Calendar',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        if (!value.connected)
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final url = await ref
                                    .read(
                                      mentorGoogleCalendarControllerProvider
                                          .notifier,
                                    )
                                    .connect();
                                final uri = parseSafeExternalHttpUri(url);
                                if (uri != null) {
                                  _awaitingOAuthReturn = true;
                                  final opened = await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!opened) _awaitingOAuthReturn = false;
                                }
                              } catch (err) {
                                if (!context.mounted) return;
                                toasts.error(
                                  title: 'Chưa kết nối được Google Calendar',
                                  description: appErrorMessage(err, context.l10n),
                                );
                              }
                            },
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: const Text('Kết nối Google Calendar'),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                ),
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(
                                          mentorGoogleCalendarControllerProvider
                                              .notifier,
                                        )
                                        .syncNow();
                                    toasts.success(
                                      title: 'Đã đồng bộ Google Calendar',
                                    );
                                  } catch (err) {
                                    if (!context.mounted) return;
                                    toasts.error(
                                      title: 'Đồng bộ thất bại',
                                      description: appErrorMessage(
                                        err,
                                        context.l10n,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Đồng bộ ngay'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(
                                          mentorGoogleCalendarControllerProvider
                                              .notifier,
                                        )
                                        .disconnect();
                                    toasts.success(
                                      title: 'Đã ngắt kết nối Google Calendar',
                                    );
                                  } catch (err) {
                                    if (!context.mounted) return;
                                    toasts.error(
                                      title: 'Chưa ngắt kết nối được',
                                      description: appErrorMessage(
                                        err,
                                        context.l10n,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Ngắt kết nối'),
                              ),
                            ],
                          ),
                      ],
                    ),
          },
        ],
      ),
    );
  }
}
