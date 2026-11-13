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
import 'package:rikipath_mobile/features/mentor/domain/availability_conflicts.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal bottom sheet xác nhận gói học, Mentor, thời gian và học phí trước khi đặt lịch hoặc thanh toán.
class LearnerMentorOrderConfirmationSheet extends ConsumerStatefulWidget {
  const LearnerMentorOrderConfirmationSheet({
    this.planId,
    required this.slot,
    this.plan,
    this.subscriptionId,
    this.requestedJlptLevel,
    super.key,
  });

  final int? planId;
  final LearnerMentorAvailability slot;
  final MentorMeetingPlan? plan;
  final int? subscriptionId;
  final String? requestedJlptLevel;

  static Future<LearnerMentorBooking?> show(
    BuildContext context, {
    int? planId,
    required LearnerMentorAvailability slot,
    MentorMeetingPlan? plan,
    int? subscriptionId,
    String? requestedJlptLevel,
  }) {
    return showModalBottomSheet<LearnerMentorBooking>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LearnerMentorOrderConfirmationSheet(
        planId: planId,
        slot: slot,
        plan: plan,
        subscriptionId: subscriptionId,
        requestedJlptLevel: requestedJlptLevel,
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
  String? _selectedJlptLevel;

  // Idempotency keys are generated once per user booking/purchase intent session.
  // Retries due to transient network glitches reuse the same key.
  late final String _purchaseIdempotencyKey = _newUuidKey();
  late final String _bookingOperationKey = _newBookingKey();

  static String _newUuidKey() {
    final random = Random.secure();
    final hex = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static String _newBookingKey() {
    final random = Random.secure();
    final hex = List<int>.generate(
      12,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return 'booking_$hex';
  }

  @override
  void initState() {
    super.initState();
    if (isSupportedConsultationJlptLevel(widget.requestedJlptLevel)) {
      _selectedJlptLevel = normalizeConsultationJlptLevel(
        widget.requestedJlptLevel,
      );
      return;
    }
    final planLevel = widget.plan?.jlptLevel;
    if (planLevel != null && isSupportedConsultationJlptLevel(planLevel)) {
      _selectedJlptLevel = normalizeConsultationJlptLevel(planLevel);
    }
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
      final creditBalance = ref
          .read(learnerCreditBalanceControllerProvider)
          .value;
      String? effectiveJlptLevel = _selectedJlptLevel;
      if (effectiveJlptLevel == null && widget.plan?.jlptLevel != null) {
        effectiveJlptLevel = normalizeConsultationJlptLevel(
          widget.plan!.jlptLevel,
        );
      }
      if (effectiveJlptLevel == null && creditBalance != null) {
        final supportedGrants = creditBalance.activeGrants
            .where(
              (grant) =>
                  grant.availableQuantity > 0 &&
                  isSupportedConsultationJlptLevel(grant.jlptLevel),
            )
            .toList();
        if (supportedGrants.length == 1) {
          effectiveJlptLevel = normalizeConsultationJlptLevel(
            supportedGrants.first.jlptLevel,
          );
        }
      }
      final hasCreditForLevel =
          effectiveJlptLevel != null &&
          (creditBalance?.availableForLevel(effectiveJlptLevel) ?? 0) > 0;
      final isExistingSubscription =
          (widget.subscriptionId != null && widget.subscriptionId! > 0) ||
          hasCreditForLevel;

      // Check again at the actual mutation boundary: the sheet may have stayed
      // open while an administrator changed the published calendar.
      final day = widget.slot.startTime.displayValue;
      final from = DateTime(day.year, day.month, day.day);
      final to = DateTime(day.year, day.month, day.day + 1);
      final latest = await ref
          .read(learnerMentorRepositoryProvider)
          .loadAvailability(
            from: from.toUtc(),
            to: to.toUtc(),
            mentorId: widget.slot.mentorId,
            jlptLevel: effectiveJlptLevel,
          );
      if (!mounted) return;
      final view = AvailabilityConflictView(latest);
      final current = view.slots
          .where((slot) => slot.id == widget.slot.id)
          .firstOrNull;
      if (current == null ||
          !view.canBook(current) ||
          current.startTime.value != widget.slot.startTime.value ||
          current.endTime.value != widget.slot.endTime.value) {
        setState(() => _isSubmitting = false);
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: 'Lịch chưa khả dụng',
              description:
                  'Lịch đã thay đổi hoặc bị trùng. Vui lòng tải lại và chọn giờ khác.',
            );
        return;
      }
      if (effectiveJlptLevel == null) {
        setState(() => _isSubmitting = false);
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: 'Chưa chọn trình độ JLPT',
              description:
                  'Vui lòng chọn trình độ JLPT (N5 - N2) trước khi xác nhận đặt lịch.',
            );
        return;
      }

      if (!isSupportedConsultationJlptLevel(effectiveJlptLevel)) {
        setState(() => _isSubmitting = false);
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: 'Trình độ chưa được hỗ trợ',
              description:
                  'Hệ thống tư vấn 1-1 chỉ hỗ trợ trình độ JLPT N5, N4, N3 và N2 (không hỗ trợ N1).',
            );
        return;
      }

      if (isExistingSubscription) {
        if (hasCreditForLevel) {
          final availForLevel =
              creditBalance?.availableForLevel(effectiveJlptLevel) ?? 0;
          final errorMsg = validateBookingJlptEligibility(
            selectedJlptLevel: effectiveJlptLevel,
            mentorQualifiedLevels: const [],
            availableTicketsForLevel: availForLevel,
            requireTicketNow: true,
          );
          if (errorMsg != null) {
            setState(() => _isSubmitting = false);
            ref
                .read(rikiToastServiceProvider.notifier)
                .error(title: 'Vé không phù hợp', description: errorMsg);
            return;
          }
        }
        // Đặt lịch trực tiếp bằng lượt học đã thanh toán hoặc vé khả dụng
        // Idempotency key is preserved across retries of the same booking intent
        final booking = await ref
            .read(learnerMentorMutationControllerProvider.notifier)
            .bookWithCredit(
              slotId: widget.slot.id,
              operationKey: _bookingOperationKey,
              notes: _questionController.text.trim(),
              jlptLevel: effectiveJlptLevel,
            );

        LearnerMentorBooking? confirmedBooking = booking;
        if (confirmedBooking == null) {
          try {
            final ownBookings = await ref
                .read(learnerMentorRepositoryProvider)
                .loadBookings();
            confirmedBooking = ownBookings
                .where(
                  (item) =>
                      item.mentorAvailabilityId == widget.slot.id &&
                      (item.status == MentorMeetingStatus.assigned ||
                          item.status == MentorMeetingStatus.accepted),
                )
                .firstOrNull;
          } catch (_) {
            // Nếu mạng vẫn lỗi, giữ operation key để lần thử lại không tạo lịch trùng.
          }
        }
        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (confirmedBooking != null) {
          final title = context.l10n.learnerMentorBookingSuccess;
          final description = context.l10n.learnerMentorBookingSuccessDesc;
          ref
              .read(rikiToastServiceProvider.notifier)
              .success(title: title, description: description);
          Navigator.of(context).pop(confirmedBooking);
        } else {
          final error = ref.read(learnerMentorMutationControllerProvider).error;
          ref
              .read(rikiToastServiceProvider.notifier)
              .error(
                title: context.l10n.learnerMentorBookingsError,
                description:
                    error?.toString() ??
                    'Chưa xác nhận được kết quả đặt lịch. Vui lòng kiểm tra Lịch của tôi trước khi thử lại.',
              );
        }
      } else {
        if (widget.planId == null) {
          setState(() => _isSubmitting = false);
          ref
              .read(rikiToastServiceProvider.notifier)
              .error(
                title: 'Chưa chọn gói tư vấn',
                description: 'Vui lòng chọn gói phù hợp trước khi thanh toán.',
              );
          return;
        }
        // Mua gói và đặt lịch thông qua PayOS checkout link
        final purchase = await ref
            .read(learnerMentorMutationControllerProvider.notifier)
            .purchase(
              subscriptionPlanId: widget.planId!,
              mentorAvailabilityId: widget.slot.id,
              idempotencyKey: _purchaseIdempotencyKey,
              jlptLevel: effectiveJlptLevel,
            );

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (purchase != null) {
          Navigator.of(context).pop();

          // Mở liên kết thanh toán PayOS nếu khả dụng
          final checkoutUri = purchase.safeCheckoutUri;
          if (checkoutUri != null) {
            try {
              await launchUrl(
                checkoutUri,
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {
              // Bỏ qua lỗi mở URL bên ngoài, màn hình trạng thái vẫn hiển thị nút mở lại
            }
          }

          // Điều hướng sang màn hình theo dõi trạng thái thanh toán và tự động hoàn tất slot
          if (mounted) {
            try {
              context.push(
                AppRoutes.learnerMentorPurchaseStatus(purchase.subscriptionId),
              );
            } catch (_) {}
          }
        } else {
          final error = ref.read(learnerMentorMutationControllerProvider).error;
          ref
              .read(rikiToastServiceProvider.notifier)
              .error(
                title: 'Không thể tạo đơn thanh toán',
                description:
                    error?.toString() ?? 'Vui lòng kiểm tra lại kết nối mạng.',
              );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(title: 'Lỗi xử lý', description: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startTime = widget.slot.startTime.displayValue;
    final endTime = widget.slot.endTime.displayValue;
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', locale);
    final timeFormat = DateFormat('HH:mm', locale);
    final creditBalance = ref
        .watch(learnerCreditBalanceControllerProvider)
        .value;

    final planPriceFormatted = widget.plan != null
        ? NumberFormat.currency(
            locale: 'vi_VN',
            symbol: 'đ',
            decimalDigits: 0,
          ).format(widget.plan!.price)
        : null;

    final supportedGrants =
        creditBalance?.activeGrants
            .where(
              (g) =>
                  g.availableQuantity > 0 &&
                  isSupportedConsultationJlptLevel(g.jlptLevel),
            )
            .toList() ??
        [];

    if (_selectedJlptLevel == null && supportedGrants.length == 1) {
      _selectedJlptLevel = normalizeConsultationJlptLevel(
        supportedGrants.first.jlptLevel,
      );
    }

    final effectiveJlpt =
        _selectedJlptLevel ??
        (isSupportedConsultationJlptLevel(widget.plan?.jlptLevel)
            ? normalizeConsultationJlptLevel(widget.plan?.jlptLevel)
            : null);
    final hasCreditForLevel =
        effectiveJlpt != null &&
        (creditBalance?.availableForLevel(effectiveJlpt) ?? 0) > 0;
    final isExistingSubscription =
        (widget.subscriptionId != null && widget.subscriptionId! > 0) ||
        hasCreditForLevel;

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
                    value: widget.plan?.name ?? 'Gói tư vấn 1-1',
                  ),
                  const Divider(),
                  if (effectiveJlpt != null) ...[
                    LearnerMentorDetailRow(
                      icon: Icons.school_outlined,
                      label: 'Trình độ JLPT',
                      value: 'JLPT $effectiveJlpt',
                    ),
                    const Divider(),
                  ],
                  LearnerMentorDetailRow(
                    icon: Icons.person_outline,
                    label: context.l10n.learnerMentorConfirmMentor,
                    value: widget.slot.mentorName,
                  ),
                  const Divider(),
                  LearnerMentorDetailRow(
                    icon: Icons.access_time_outlined,
                    label: context.l10n.learnerMentorConfirmTime,
                    value:
                        '${dateFormat.format(startTime)}\n${timeFormat.format(startTime)} - ${timeFormat.format(endTime)} (90 phút)',
                  ),
                  const Divider(),
                  LearnerMentorDetailRow(
                    icon: Icons.payments_outlined,
                    label: context.l10n.learnerMentorConfirmPrice,
                    value: isExistingSubscription
                        ? (hasCreditForLevel &&
                                  (widget.subscriptionId == null ||
                                      widget.subscriptionId! <= 0)
                              ? '1 vé JLPT $effectiveJlpt (${creditBalance?.availableForLevel(effectiveJlpt) ?? 0} vé còn lại)'
                              : context.l10n.learnerMentorIncludedSession)
                        : (planPriceFormatted ?? 'Theo gói đã chọn'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Interactive Level Selector if multiple levels are available or plan level is unspecified
            if (widget.plan?.jlptLevel == null &&
                widget.requestedJlptLevel == null &&
                supportedGrants.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.cardWarmWhite,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderSubtlePink),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn trình độ JLPT cho buổi hẹn (N5 - N2):',
                      style: AppTypography.metadata.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: AppSpacing.space2,
                      children: ['N5', 'N4', 'N3', 'N2'].map((lvl) {
                        final count =
                            creditBalance?.availableForLevel(lvl) ?? 0;
                        final isSelected = _selectedJlptLevel == lvl;
                        return ChoiceChip(
                          key: Key('jlpt_chip_$lvl'),
                          label: Text('$lvl ($count vé)'),
                          selected: isSelected,
                          selectedColor: AppColors.primaryContainer,
                          onSelected: (selected) {
                            setState(
                              () => _selectedJlptLevel = selected ? lvl : null,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            RikiInfoBanner(
              message: isExistingSubscription
                  ? 'Lịch học sẽ được xác nhận ngay lập tức bằng vé tư vấn có sẵn trong tài khoản của bạn.'
                  : context.l10n.learnerMentorConfirmNote,
            ),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              controller: _questionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'Nội dung hoặc câu hỏi muốn trao đổi với cố vấn (tùy chọn)',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                ),
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
              leadingIcon: isExistingSubscription
                  ? Icons.check_circle_outline
                  : Icons.payment,
              onPressed: _isSubmitting ? null : _handleConfirm,
            ),
            const SizedBox(height: AppSpacing.space2),
            RikiTextButton(
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
