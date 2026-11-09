import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/push_notification_payload.dart';
import 'package:rikipath_mobile/features/notifications/application/push_notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          TextButton(
            onPressed:
                state.value != null &&
                    !state.value!.isMutating &&
                    !state.value!.isListUnavailable &&
                    state.value!.items.any((item) => !item.isRead)
                ? () => _markAllRead(context, ref)
                : null,
            child: Text(context.l10n.markAllNotificationsRead),
          ),
        ],
      ),
      body: state.when(
        loading: () => RikiFullScreenLoader(
          title: context.l10n.loading,
          subtitle: context.l10n.notifications,
        ),
        error: (_, _) => _ErrorView(
          onRetry: ref.read(notificationControllerProvider.notifier).retry,
        ),
        data: (data) {
          if (data.isListUnavailable) {
            return _ErrorView(
              onRetry: ref.read(notificationControllerProvider.notifier).retry,
            );
          }
          if (data.items.isEmpty) {
            return const _EmptyView();
          }
          return Column(
            children: [
              if (data.isUnreadCountUnavailable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space4,
                    AppSpacing.space4,
                    0,
                  ),
                  child: RikiInfoBanner(
                    message: context.l10n.notificationsCountUnavailable,
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  itemBuilder: (context, index) => _NotificationTile(
                    notification: data.items[index],
                    onTap: data.isMutating
                        ? null
                        : () => _openNotification(
                            context,
                            ref,
                            data.items[index],
                          ),
                  ),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space3),
                  itemCount: data.items.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      final success = await ref
          .read(notificationControllerProvider.notifier)
          .markRead(notification);
      if (!context.mounted) return;
      if (!success) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(title: context.l10n.notificationsUpdateFailed);
        return;
      }
    }
    if (!context.mounted) return;
    final destination = ref
        .read(pushNotificationServiceProvider)
        .resolveDeepLink(
          PushNotificationPayload(
            notificationId: notification.id.toString(),
            title: notification.title,
            body: notification.message,
            type: notification.type,
            linkUrl: notification.linkUrl,
          ),
        );
    if (destination != AppRoutes.notifications) context.go(destination);
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(notificationControllerProvider.notifier)
        .markAllRead();
    if (success || !context.mounted) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .error(title: context.l10n.notificationsUpdateFailed);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${notification.title}. ${notification.message}',
      excludeSemantics: true,
      child: RikiCard(
        backgroundColor: notification.isRead
            ? AppColors.cardWarmWhite
            : AppColors.brandTint,
        borderColor: notification.isRead
            ? AppColors.cardBorderMuted
            : AppColors.brandSelectedBorder,
        boxShadow: notification.isRead
            ? const <BoxShadow>[]
            : AppShadows.sakuraSubtle,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.surfaceSubtle
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Icon(
                notification.isRead
                    ? Icons.notifications_none_outlined
                    : Icons.notifications_active_outlined,
                color: notification.isRead
                    ? AppColors.textSecondary
                    : AppColors.brandPrimary,
                size: 22,
              ),
            ),
            title: Text(
              notification.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardTitle,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space1),
              child: Text(
                notification.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall,
              ),
            ),
            trailing: notification.isRead
                ? null
                : const ExcludeSemantics(
                    child: Icon(
                      Icons.circle,
                      key: ValueKey<String>('notification_unread_indicator'),
                      size: 9,
                      color: AppColors.brandPrimary,
                    ),
                  ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(
      icon: Icons.notifications_none_outlined,
      title: context.l10n.notifications,
      message: context.l10n.notificationsEmpty,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      title: context.l10n.notificationsLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
    );
  }
}
