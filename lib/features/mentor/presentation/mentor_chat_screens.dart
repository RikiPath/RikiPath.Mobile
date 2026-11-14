import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_chat_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_chat.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// List of 1-1 Mentor<->Learner booking chat threads (`/mentor/chat`).
class MentorChatThreadsScreen extends ConsumerWidget {
  const MentorChatThreadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final threadsAsync = ref.watch(mentorChatThreadsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.mentorChatThreadsTitle),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: RikiAnimatedStudyLoader()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiErrorState(
              title: l10n.mentorChatThreadsTitle,
              message: appErrorMessage(err, l10n),
              actionLabel: l10n.mentorCommonRetry,
              onAction: () =>
                  ref.read(mentorChatThreadsControllerProvider.notifier).refresh(),
            ),
          ),
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: () =>
                  ref.read(mentorChatThreadsControllerProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                children: [
                  const SizedBox(height: 64),
                  RikiEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: l10n.mentorChatThreadsTitle,
                    message: l10n.mentorChatThreadsEmpty,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () =>
                ref.read(mentorChatThreadsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              itemCount: threads.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.space3),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return _ChatThreadCard(
                  thread: thread,
                  onTap: () =>
                      context.push(AppRoutes.mentorChatRoom(thread.bookingId)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatThreadCard extends StatelessWidget {
  const _ChatThreadCard({required this.thread, required this.onTap});

  final MentorChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasUnread = thread.unreadCount > 0;
    final displayName = thread.learnerName.trim().isEmpty
        ? l10n.mentorLearnerUnknown
        : thread.learnerName.trim();
    final initial = displayName.substring(0, 1).toUpperCase();

    return RikiCard(
      onTap: onTap,
      backgroundColor: hasUnread ? AppColors.brandTint : AppColors.cardWarmWhite,
      borderColor: hasUnread
          ? AppColors.brandSelectedBorder
          : AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatShortDateTime(
                        thread.lastMessage?.sentAt ?? thread.scheduledAt,
                      ),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  thread.lastMessage?.text ?? l10n.mentorChatEmptyMessages,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: thread.lastMessage == null
                        ? AppColors.textMuted
                        : hasUnread
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: MentorStatusBadge(
                        label:
                            '#${thread.bookingId} · ${mentorStatusLabel(MentorMeetingStatus.fromApiValue(thread.bookingStatus), context)}',
                        color: thread.canSendMessages
                            ? AppColors.brandPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Real-time SignalR `/hubs/mentor-chat` room for one booking (`/mentor/chat/:bookingId`).
class MentorChatRoomScreen extends ConsumerStatefulWidget {
  const MentorChatRoomScreen({super.key, required this.bookingId});

  final int? bookingId;

  @override
  ConsumerState<MentorChatRoomScreen> createState() =>
      _MentorChatRoomScreenState();
}

class _MentorChatRoomScreenState extends ConsumerState<MentorChatRoomScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.bookingId;
    if (id == null || id <= 0) {
      return Scaffold(
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(title: Text(l10n.mentorChatThreadsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiEmptyState(
              icon: Icons.chat_bubble_outline,
              title: l10n.mentorChatThreadsTitle,
              message: l10n.mentorMeetingNotFound,
            ),
          ),
        ),
      );
    }

    final roomAsync = ref.watch(mentorChatRoomControllerProvider(id));
    final currentUserId = ref.watch(authenticatedUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: roomAsync.when(
          loading: () => Text(l10n.mentorChatThreadsTitle),
          error: (_, _) => Text(l10n.mentorChatThreadsTitle),
          data: (room) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.thread.learnerName.trim().isEmpty
                    ? '#${room.thread.bookingId}'
                    : room.thread.learnerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle,
              ),
              Text(
                '#${room.thread.bookingId} · ${formatShortDateTime(room.thread.scheduledAt)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.meetingDetailsAction,
            onPressed: () => context.push(AppRoutes.mentorMeetingDetail(id)),
          ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const Center(child: RikiAnimatedStudyLoader()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiErrorState(
              title: l10n.mentorChatThreadsTitle,
              message: appErrorMessage(err, l10n),
              actionLabel: l10n.mentorCommonRetry,
              onAction: () =>
                  ref.invalidate(mentorChatRoomControllerProvider(id)),
            ),
          ),
        ),
        data: (room) => Column(
          children: [
            _ChatConnectionBar(
              status: room.connectionStatus,
              onReconnect: () => ref
                  .read(mentorChatRoomControllerProvider(id).notifier)
                  .reconnect(),
            ),
            if (!room.thread.canSendMessages)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.space2,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: RikiInfoBanner(message: l10n.mentorChatReadOnlyBanner),
              ),
            Expanded(
              child: room.messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppSpacing.screenHorizontal,
                        ),
                        child: RikiEmptyState(
                          icon: Icons.mark_chat_unread_outlined,
                          title: l10n.mentorChatThreadsTitle,
                          message: l10n.mentorChatEmptyMessages,
                          compact: true,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(
                        AppSpacing.screenHorizontal,
                      ),
                      itemCount:
                          room.messages.length + (room.hasMoreOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (room.hasMoreOlder && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: room.isLoadingOlder
                                    ? null
                                    : () => _loadOlder(id),
                                icon: room.isLoadingOlder
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.history, size: 16),
                                label: Text(l10n.mentorChatLoadOlder),
                              ),
                            ),
                          );
                        }
                        final msgIndex = room.hasMoreOlder ? index - 1 : index;
                        final message = room.messages[msgIndex];
                        final isMine =
                            (currentUserId != null &&
                                message.senderUserId == currentUserId) ||
                            message.senderRole.toLowerCase() == 'mentor';
                        return _SakuraChatBubble(
                          message: message,
                          isMine: isMine,
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  8,
                  AppSpacing.screenHorizontal,
                  10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _composerController,
                        enabled: room.thread.canSendMessages && !room.isSending,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: room.thread.canSendMessages
                            ? (_) => _send(id)
                            : null,
                        decoration: InputDecoration(
                          hintText: l10n.mentorChatInputHint,
                          filled: true,
                          fillColor: AppColors.learnerBackground,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(
                              color: AppColors.cardBorderMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          room.thread.canSendMessages && !room.isSending
                          ? () => _send(id)
                          : null,
                      icon: room.isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadOlder(int bookingId) async {
    try {
      await ref
          .read(mentorChatRoomControllerProvider(bookingId).notifier)
          .loadOlder();
    } catch (err) {
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).error(
        title: appErrorMessage(err, context.l10n),
      );
    }
  }

  Future<void> _send(int bookingId) async {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    try {
      await ref
          .read(mentorChatRoomControllerProvider(bookingId).notifier)
          .sendMessage(text);
      _composerController.clear();
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (err) {
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).error(
        title: appErrorMessage(err, context.l10n),
      );
    }
  }
}

class _ChatConnectionBar extends StatelessWidget {
  const _ChatConnectionBar({required this.status, required this.onReconnect});

  final MentorChatConnectionStatus status;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    if (status == MentorChatConnectionStatus.connected ||
        status == MentorChatConnectionStatus.disconnected) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final (message, color) = switch (status) {
      MentorChatConnectionStatus.connecting => (
        l10n.mentorChatConnecting,
        AppColors.warning,
      ),
      MentorChatConnectionStatus.reconnecting => (
        l10n.mentorChatReconnecting,
        AppColors.warning,
      ),
      MentorChatConnectionStatus.failed => (
        l10n.mentorChatDisconnected,
        AppColors.error,
      ),
      _ => ('', AppColors.textMuted),
    };
    return Material(
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: status == MentorChatConnectionStatus.failed ? onReconnect : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.sync_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (status == MentorChatConnectionStatus.failed)
                Text(
                  l10n.mentorChatReconnect,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SakuraChatBubble extends StatelessWidget {
  const _SakuraChatBubble({required this.message, required this.isMine});

  final MentorChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine
        ? AppColors.brandPrimary
        : AppColors.cardWarmWhite;
    final textColor = isMine ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                border: isMine
                    ? null
                    : Border.all(color: AppColors.cardBorderMuted),
                boxShadow: AppShadows.sakuraSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine && message.senderName.isNotEmpty) ...[
                    Text(
                      message.senderName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message.text,
                    style: AppTypography.bodyMedium.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(
                          message.sentAt.value.toLocal(),
                        ),
                        style: AppTypography.caption.copyWith(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textMuted,
                        ),
                      ),
                      if (isMine && message.isRead) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
