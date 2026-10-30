import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình kiểm tra trạng thái thanh toán gói học Mentor và tự động hoàn tất đặt lịch.
class LearnerMentorPurchaseStatusScreen extends ConsumerStatefulWidget {
  const LearnerMentorPurchaseStatusScreen({
    required this.subscriptionId,
    super.key,
  });

  final int? subscriptionId;

  @override
  ConsumerState<LearnerMentorPurchaseStatusScreen> createState() =>
      _LearnerMentorPurchaseStatusScreenState();
}

class _LearnerMentorPurchaseStatusScreenState
    extends ConsumerState<LearnerMentorPurchaseStatusScreen> {
  Timer? _pollTimer;
  bool _autoBookingAttempted = false;
  bool _isAutoBooking = false;
  LearnerMentorBooking? _confirmedBooking;
  String? _slotConflictMessage;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _syncPolling(bool shouldPoll) {
    if (!shouldPoll) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
      final id = widget.subscriptionId;
      if (id == null || id <= 0 || !mounted) return;
      ref
          .read(learnerMentorPurchaseStatusControllerProvider(id).notifier)
          .poll();
    });
  }

  Future<void> _attemptAutoBooking(
    int subscriptionId,
    LearnerBookingIntent intent,
  ) async {
    if (_autoBookingAttempted || _isAutoBooking || intent.slot == null) return;
    _autoBookingAttempted = true;
    setState(() {
      _isAutoBooking = true;
      _slotConflictMessage = null;
    });

    try {
      final booking = await ref
          .read(learnerMentorMutationControllerProvider.notifier)
          .bookIncludedSession(
            subscriptionId: subscriptionId,
            mentorAvailabilityId: intent.slot!.id,
            question: intent.question,
          );

      if (!mounted) return;
      setState(() => _isAutoBooking = false);

      if (booking != null) {
        setState(() => _confirmedBooking = booking);
        // Đặt lịch thành công, xóa intent tạm thời
        ref.read(learnerBookingIntentProvider.notifier).clear();
        ref.read(rikiToastServiceProvider.notifier).success(
              title: context.l10n.learnerMentorBookingSuccess,
              description: context.l10n.learnerMentorBookingSuccessDesc,
            );
      } else {
        // Slot đã bị đặt trước hoặc hết hạn
        final error = ref.read(learnerMentorMutationControllerProvider).error;
        setState(() {
          _slotConflictMessage = error?.toString() ??
              context.l10n.learnerMentorSlotConflict;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAutoBooking = false;
        _slotConflictMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.subscriptionId;
    if (id == null || id <= 0) {
      return _PurchaseStatusScaffold(
        child: MentorEmptyState(
          icon: Icons.receipt_long_outlined,
          title: context.l10n.learnerMentorPurchaseStatus,
          description: context.l10n.learnerMentorMeetingNotFound,
        ),
      );
    }

    final provider = learnerMentorPurchaseStatusControllerProvider(id);
    final state = ref.watch(provider);

    ref.listen(provider, (_, next) {
      final status = next.value;
      final isPending = status?.paymentStatus == MentorPaymentStatus.pending;
      _syncPolling(isPending);

      // Khi thanh toán chuyển sang Paid, kiểm tra và tự động đối soát đặt lịch nếu có intent
      if (status?.paymentStatus == MentorPaymentStatus.paid &&
          !_autoBookingAttempted &&
          !_isAutoBooking) {
        final intent = ref.read(learnerBookingIntentProvider);
        if (intent != null && intent.subscriptionId == id && intent.slot != null) {
          _attemptAutoBooking(id, intent);
        }
      }
    });

    // Lắng nghe phục hồi intent khi tiến trình app được khôi phục sau khi thanh toán ở trình duyệt ngoài
    ref.listen(learnerBookingIntentProvider, (_, nextIntent) {
      final status = ref.read(provider).value;
      if (status?.paymentStatus == MentorPaymentStatus.paid &&
          !_autoBookingAttempted &&
          !_isAutoBooking &&
          nextIntent != null &&
          nextIntent.subscriptionId == id &&
          nextIntent.slot != null) {
        _attemptAutoBooking(id, nextIntent);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final status = ref.read(provider).value;
      final intent = ref.read(learnerBookingIntentProvider);
      if (status?.paymentStatus == MentorPaymentStatus.paid &&
          !_autoBookingAttempted &&
          !_isAutoBooking &&
          intent != null &&
          intent.subscriptionId == id &&
          intent.slot != null) {
        _attemptAutoBooking(id, intent);
      }
    });

    return _PurchaseStatusScaffold(
      child: switch (state) {
        AsyncLoading() => const MentorListSkeleton(
            key: Key('learner_mentor_purchase_status_loading'),
          ),
        AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('learner_mentor_purchase_status_error'),
              message: context.l10n.learnerMentorPurchaseStatusError,
              onRetry: ref.read(provider.notifier).refreshStatus,
            ),
          ),
        AsyncData(:final value) => _PurchaseStatusBody(
            status: value,
            isAutoBooking: _isAutoBooking,
            confirmedBooking: _confirmedBooking,
            slotConflictMessage: _slotConflictMessage,
            onRefresh: ref.read(provider.notifier).refreshStatus,
          ),
      },
    );
  }
}

class _PurchaseStatusScaffold extends StatelessWidget {
  const _PurchaseStatusScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('learner_mentor_purchase_status_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.learnerMentorPurchaseStatus)),
      body: SafeArea(top: false, child: child),
    );
  }
}

class _PurchaseStatusBody extends ConsumerWidget {
  const _PurchaseStatusBody({
    required this.status,
    required this.onRefresh,
    this.isAutoBooking = false,
    this.confirmedBooking,
    this.slotConflictMessage,
  });

  final MentorMeetingPurchaseStatus status;
  final Future<void> Function() onRefresh;
  final bool isAutoBooking;
  final LearnerMentorBooking? confirmedBooking;
  final String? slotConflictMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intent = ref.watch(learnerBookingIntentProvider);
    final isPaid = status.paymentStatus == MentorPaymentStatus.paid;
    final isPending = status.paymentStatus == MentorPaymentStatus.pending;

    // Ưu tiên hiển thị booking vừa tạo hoặc booking sẵn có trong subscription
    final activeBooking = confirmedBooking ?? status.bookings.firstOrNull;

    return ListView(
      key: const Key('learner_mentor_purchase_status_content'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        if (isPending) ...[
          RikiInfoBanner(message: context.l10n.learnerMentorStatusPolling),
          const SizedBox(height: AppSpacing.space4),
        ] else if (isPaid) ...[
          RikiCard(
            borderColor: AppColors.brandPrimary.withValues(alpha: 0.35),
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.06),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.brandPrimary, size: 30),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thanh toán thành công',
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'Gói ${status.planName} đã được kích hoạt trên hệ thống.',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Trạng thái đang tự động hoàn tất đặt lịch
        if (isAutoBooking) ...[
          RikiCard(
            borderColor: AppColors.brandPrimary.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      'Đang tự động xác nhận lịch học với Mentor...',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Trường hợp slot bị trùng hoặc hết chỗ sau thanh toán
        if (slotConflictMessage != null) ...[
          RikiCard(
            borderColor: AppColors.warning,
            backgroundColor: AppColors.warning.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        'Khung giờ đã chọn không còn trống',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  slotConflictMessage ?? context.l10n.learnerMentorSlotConflict,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiPrimaryButton(
                  label: context.l10n.learnerMentorChooseAnotherSlot,
                  leadingIcon: Icons.calendar_month_outlined,
                  onPressed: () => context.push(
                    AppRoutes.learnerMentorAvailability(
                      intent?.planId ?? 1,
                      subscriptionId: status.subscriptionId,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Chi tiết booking thành công
        if (activeBooking != null) ...[
          RikiCard(
            borderColor: AppColors.brandPrimary.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available, color: AppColors.brandPrimary, size: 26),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        'Buổi học đã được đặt thành công',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                LearnerMentorDetailRow(
                  icon: Icons.person_outline,
                  label: context.l10n.learnerMentorMentorLabel,
                  value: activeBooking.mentorName ?? 'Mentor RikiPath',
                ),
                const Divider(),
                LearnerMentorDetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Thời gian học',
                  value: mentorTimeLabel(activeBooking.scheduledAt, context),
                ),
                const Divider(),
                LearnerMentorDetailRow(
                  icon: Icons.verified_outlined,
                  label: 'Trạng thái',
                  value: learnerMentorBookingStatusLabel(activeBooking.status, context),
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiPrimaryButton(
                  label: context.l10n.learnerMentorViewBookingDetail,
                  leadingIcon: Icons.visibility_outlined,
                  onPressed: () => context.push(
                    AppRoutes.learnerMentorBookingDetail(activeBooking.id),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Thông tin gói học và trạng thái thanh toán
        RikiCard(
          boxShadow: AppShadows.cardSoft,
          borderColor: AppColors.border,
          child: Column(
            children: [
              LearnerMentorDetailRow(
                icon: Icons.workspace_premium_outlined,
                label: context.l10n.learnerMentorPlansTitle,
                value: status.planName,
              ),
              const Divider(),
              LearnerMentorDetailRow(
                icon: Icons.payments_outlined,
                label: context.l10n.learnerMentorPaymentLabel,
                value: learnerMentorPaymentStatusLabel(
                  status.paymentStatus,
                  context,
                ),
              ),
              const Divider(),
              LearnerMentorDetailRow(
                key: const Key('learner_mentor_sessions_usage'),
                icon: Icons.video_call_outlined,
                label: context.l10n.learnerMentorPlanSessions(
                  status.meetingSessionsIncluded,
                ),
                value: context.l10n.learnerMentorSessionsUsage(
                  status.meetingSessionsUsed,
                  status.meetingSessionsIncluded,
                ),
              ),
            ],
          ),
        ),

        if (status.isCheckoutExpired) ...[
          const SizedBox(height: AppSpacing.space4),
          RikiWarningBanner(message: context.l10n.learnerMentorCheckoutExpired),
        ],

        if (status.isQaSimulated && isPending) ...[
          const SizedBox(height: AppSpacing.space4),
          Container(
            key: const Key('learner_mentor_qa_payment_demo'),
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: Column(
              children: [
                Text(
                  'CHẾ ĐỘ DEMO — KHÔNG CHUYỂN TIỀN',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: AppSpacing.space2),
                const Text(
                  'QR minh họa không phải QR ngân hàng và không thể thanh toán.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox.square(
                  dimension: 176,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(176),
                        painter: _QaDemoMatrixPainter(status.subscriptionId),
                      ),
                      DecoratedBox(
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            'DEMO',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text('Giao dịch QA #${status.subscriptionId}'),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space4),

        // Nút mở trang thanh toán nếu đang Pending
        if (isPending && !status.isQaSimulated) ...[
          RikiPrimaryButton(
            key: const Key('learner_mentor_open_checkout_button'),
            label: context.l10n.learnerMentorOpenPayOs,
            leadingIcon: Icons.open_in_new,
            onPressed: () async {
              try {
                // Tự động đồng bộ trước khi mở lại
                await onRefresh();
              } catch (_) {}
            },
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Nút nếu gói còn lượt và chưa đặt hết
        if (isPaid && status.remainingSessions > 0 && activeBooking == null) ...[
          RikiPrimaryButton(
            label: context.l10n.learnerMentorBookNow,
            leadingIcon: Icons.calendar_today_outlined,
            onPressed: () => context.push(
              AppRoutes.learnerMentorAvailability(
                intent?.planId ?? 1,
                subscriptionId: status.subscriptionId,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Nút kiểm tra lại trạng thái
        RikiSecondaryButton(
          key: const Key('learner_mentor_refresh_purchase_status'),
          label: context.l10n.learnerMentorRefreshStatus,
          leadingIcon: Icons.refresh,
          onPressed: onRefresh,
        ),
        const SizedBox(height: AppSpacing.space3),

        // Nút xem toàn bộ danh sách lịch học
        RikiTextButton(
          label: context.l10n.learnerMentorMyMeetings,
          leadingIcon: Icons.list_alt,
          onPressed: () => context.push(AppRoutes.learnerMentorBookings),
        ),
      ],
    );
  }
}

class _QaDemoMatrixPainter extends CustomPainter {
  const _QaDemoMatrixPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 21;
    final random = Random(seed);
    final paint = Paint()..color = Colors.black87;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (var row = 0; row < 21; row++) {
      for (var column = 0; column < 21; column++) {
        // Decorative, deliberately non-standard matrix; it is not a payment QR code.
        if (random.nextInt(3) == 0) {
          canvas.drawRect(
            Rect.fromLTWH(column * cell, row * cell, cell * .82, cell * .82),
            paint,
          );
        }
      }
    }
    final stripePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = cell * 1.8;
    canvas.drawLine(Offset(0, size.height * .5), Offset(size.width, size.height * .5), stripePaint);
  }

  @override
  bool shouldRepaint(covariant _QaDemoMatrixPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
