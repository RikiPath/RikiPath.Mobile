import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal bottom sheet xác nhận gói học, Mentor, thời gian và học phí trước khi đặt lịch hoặc thanh toán.
class LearnerMentorOrderConfirmationSheet extends ConsumerStatefulWidget {
  const LearnerMentorOrderConfirmationSheet({
    required this.planId,
    required this.slot,
    this.plan,
    this.subscriptionId,
    super.key,
  });

  final int planId;
  final LearnerMentorAvailability slot;
  final MentorMeetingPlan? plan;
  final int? subscriptionId;

  static Future<void> show(
    BuildContext context, {
    required int planId,
    required LearnerMentorAvailability slot,
    MentorMeetingPlan? plan,
    int? subscriptionId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LearnerMentorOrderConfirmationSheet(
        planId: planId,
        slot: slot,
        plan: plan,
        subscriptionId: subscriptionId,
      ),
    );
  }

  @override
  ConsumerState<LearnerMentorOrderConfirmationSheet> createState() =>
      _LearnerMentorOrderConfirmationSheetState();
}

class _LearnerMentorOrderConfirmationSheetState
    extends ConsumerState<LearnerMentorOrderConfirmationSheet> {
  final _questionController = TextEditingController();
  bool _isSubmitting = false;
  late final String _purchaseIdempotencyKey = _newPurchaseIdempotencyKey();

  String _newPurchaseIdempotencyKey() {
    final random = Random.secure();
    final hex = List<int>.generate(16, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final isExistingSubscription = widget.subscriptionId != null && widget.subscriptionId! > 0;

      if (isExistingSubscription) {
        // Đặt lịch trực tiếp bằng lượt học đã thanh toán
        final booking = await ref
            .read(learnerMentorMutationControllerProvider.notifier)
            .bookIncludedSession(
              subscriptionId: widget.subscriptionId!,
              mentorAvailabilityId: widget.slot.id,
              question: _questionController.text.trim(),
            );

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (booking != null) {
          Navigator.of(context).pop();
          ref.read(rikiToastServiceProvider.notifier).success(
                title: context.l10n.learnerMentorBookingSuccess,
                description: context.l10n.learnerMentorBookingSuccessDesc,
              );
          context.push(AppRoutes.learnerMentorBookingDetail(booking.id));
        } else {
          final error = ref.read(learnerMentorMutationControllerProvider).error;
          ref.read(rikiToastServiceProvider.notifier).error(
                title: 'Đặt lịch chưa thành công',
                description: error?.toString() ?? 'Khung giờ có thể đã được đặt, vui lòng thử lại.',
              );
        }
      } else {
        // Mua gói mới và chuyển sang thanh toán PayOS
        final purchase = await ref
            .read(learnerMentorMutationControllerProvider.notifier)
            .purchase(
              subscriptionPlanId: widget.planId,
              mentorAvailabilityId: widget.slot.id,
              idempotencyKey: _purchaseIdempotencyKey,
            );

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (purchase != null) {
          // Lưu ý định đặt slot dự kiến vào intent để tự động book khi thanh toán xong
          ref.read(learnerBookingIntentProvider.notifier).setIntent(
                LearnerBookingIntent(
                  planId: widget.planId,
                  plan: widget.plan,
                  slot: widget.slot,
                  mentorAvailabilityId: widget.slot.id,
                  subscriptionId: purchase.subscriptionId,
                  question: _questionController.text.trim(),
                ),
              );

          Navigator.of(context).pop();

          // Mở liên kết thanh toán PayOS nếu khả dụng
          final checkoutUri = purchase.safeCheckoutUri;
          if (checkoutUri != null) {
            try {
              await launchUrl(checkoutUri, mode: LaunchMode.externalApplication);
            } catch (_) {
              // Bỏ qua lỗi mở URL bên ngoài, màn hình trạng thái vẫn hiển thị nút mở lại
            }
          }

          // Điều hướng sang màn hình theo dõi trạng thái thanh toán và tự động hoàn tất slot
          if (mounted) {
            context.push(AppRoutes.learnerMentorPurchaseStatus(purchase.subscriptionId));
          }
        } else {
          final error = ref.read(learnerMentorMutationControllerProvider).error;
          ref.read(rikiToastServiceProvider.notifier).error(
                title: 'Không thể tạo đơn thanh toán',
                description: error?.toString() ?? 'Vui lòng kiểm tra lại kết nối mạng.',
              );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ref.read(rikiToastServiceProvider.notifier).error(
            title: 'Lỗi xử lý',
            description: e.toString(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startTime = widget.slot.startTime.displayValue;
    final endTime = widget.slot.endTime.displayValue;
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', locale);
    final timeFormat = DateFormat('HH:mm', locale);
    final isExistingSubscription = widget.subscriptionId != null && widget.subscriptionId! > 0;

    final planPriceFormatted = widget.plan != null
        ? NumberFormat.currency(
            locale: 'vi_VN',
            symbol: 'đ',
            decimalDigits: 0,
          ).format(widget.plan!.price)
        : null;

    return Container(
      key: const Key('learner_mentor_order_confirmation_sheet'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space5,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: AppColors.brandPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.learnerMentorConfirmBookingTitle,
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isExistingSubscription
                            ? context.l10n.learnerMentorIncludedSession
                            : 'Xác nhận thông tin và thanh toán an toàn',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            RikiCard(
              borderColor: AppColors.border,
              boxShadow: AppShadows.cardSoft,
              child: Column(
                children: [
                  LearnerMentorDetailRow(
                    icon: Icons.workspace_premium_outlined,
                    label: context.l10n.learnerMentorConfirmPackage,
                    value: widget.plan?.name ?? 'Gói Mentor 1-1',
                  ),
                  const Divider(),
                  LearnerMentorDetailRow(
                    icon: Icons.person_outline,
                    label: context.l10n.learnerMentorConfirmMentor,
                    value: widget.slot.mentorName,
                  ),
                  const Divider(),
                  LearnerMentorDetailRow(
                    icon: Icons.access_time_outlined,
                    label: context.l10n.learnerMentorConfirmTime,
                    value: '${dateFormat.format(startTime)}\n${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                  ),
                  const Divider(),
                  LearnerMentorDetailRow(
                    icon: Icons.payments_outlined,
                    label: context.l10n.learnerMentorConfirmPrice,
                    value: isExistingSubscription
                        ? context.l10n.learnerMentorIncludedSession
                        : (planPriceFormatted ?? 'Theo gói đã chọn'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            RikiInfoBanner(
              message: isExistingSubscription
                  ? 'Lịch học sẽ được xác nhận ngay lập tức bằng lượt học có sẵn trong tài khoản của bạn.'
                  : context.l10n.learnerMentorConfirmNote,
            ),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              controller: _questionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nội dung hoặc câu hỏi muốn trao đổi với Mentor (tùy chọn)',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.space3),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            RikiPrimaryButton(
              key: const Key('learner_mentor_confirm_submit_button'),
              label: _isSubmitting
                  ? 'Đang xử lý...'
                  : (isExistingSubscription
                      ? context.l10n.learnerMentorConfirmBooking
                      : context.l10n.learnerMentorPayWithPayOs),
              leadingIcon: isExistingSubscription ? Icons.check_circle_outline : Icons.payment,
              onPressed: _isSubmitting ? null : _handleConfirm,
            ),
            const SizedBox(height: AppSpacing.space2),
            RikiTextButton(
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
