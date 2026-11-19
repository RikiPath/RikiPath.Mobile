import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/subscriptions/application/subscription_controller.dart';
import 'package:rikipath_mobile/features/subscriptions/domain/subscription_models.dart';
import 'package:url_launcher/url_launcher.dart';

final NumberFormat _vndFmt = NumberFormat('#,###', 'vi_VN');
final DateFormat _subDateFmt = DateFormat('dd/MM/yyyy');

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen>
    with WidgetsBindingObserver {
  SubscriptionCheckoutResult? _pendingCheckout;
  String? _pendingStatus;
  Timer? _pollTimer;
  int? _purchasingPlanId;
  bool _checkingStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pending = _pendingCheckout;
    if (pending == null || _pendingStatus != 'Pending') return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _startPolling(pending.purchaseId);
      unawaited(_checkStatus(pending.purchaseId, silent: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCheckoutUrl(String url) async {
    final uri = parseSafeExternalHttpUri(url);
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    if (uri == null) {
      toasts.error(title: 'Liên kết thanh toán không hợp lệ');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      toasts.info(
        title: 'Không mở được trình duyệt',
        description: 'Đã sao chép liên kết thanh toán PayOS vào khay nhớ tạm.',
      );
    }
  }

  Future<void> _startPurchase(SubscriptionPlanOffer plan) async {
    if (_purchasingPlanId != null) return;
    setState(() => _purchasingPlanId = plan.id);
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    try {
      final result = await ref
          .read(subscriptionActionsProvider)
          .purchasePlan(plan.id);
      if (!mounted) return;
      setState(() {
        _pendingCheckout = result;
        _pendingStatus = 'Pending';
      });
      _startPolling(result.purchaseId);
      await _openCheckoutUrl(result.checkoutUrl);
    } catch (error) {
      if (!mounted) return;
      toasts.error(
        title: 'Chưa tạo được đơn PayOS',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      if (mounted) setState(() => _purchasingPlanId = null);
    }
  }

  void _startPolling(int purchaseId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _pendingStatus == 'Pending' && !_checkingStatus) {
        unawaited(_checkStatus(purchaseId, silent: true));
      }
    });
  }

  Future<void> _checkStatus(int purchaseId, {bool silent = false}) async {
    if (_checkingStatus) return;
    setState(() => _checkingStatus = true);
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    try {
      final status = await ref
          .read(subscriptionActionsProvider)
          .checkPurchaseStatus(purchaseId);
      if (!mounted) return;
      setState(() => _pendingStatus = status);
      if (status != 'Pending') {
        _pollTimer?.cancel();
        if (status == 'Paid') {
          toasts.success(title: 'Thanh toán thành công! Gói học đã được kích hoạt.');
        } else if (!silent) {
          toasts.info(title: 'Trạng thái đơn #$purchaseId: $status');
        }
      } else if (!silent) {
        toasts.info(title: 'Đơn #$purchaseId đang chờ thanh toán.');
      }
    } catch (error) {
      if (!mounted || silent) return;
      toasts.error(
        title: 'Chưa kiểm tra được trạng thái',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(studyAccessProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      key: const Key('subscriptions_screen'),
      backgroundColor: AppColors.profileBackground,
      appBar: AppBar(title: const Text('Gói tự học & Lượt AI')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studyAccessProvider);
          ref.invalidate(subscriptionPlansProvider);
          await Future.wait([
            ref.read(studyAccessProvider.future),
            ref.read(subscriptionPlansProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            if (_pendingCheckout != null) ...[
              _buildPendingCard(_pendingCheckout!),
              const SizedBox(height: AppSpacing.space4),
            ],
            switch (accessAsync) {
              AsyncLoading() => const RikiSkeleton(height: 120),
              AsyncError(:final error) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RikiErrorBanner(
                    message: appErrorMessage(error, context.l10n),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(studyAccessProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
              AsyncData(:final value) => _buildAccessCard(value),
            },
            const SizedBox(height: AppSpacing.space5),
            Text('Các gói & lượt bổ sung', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.space3),
            switch (plansAsync) {
              AsyncLoading() => const RikiSkeleton(height: 180),
              AsyncError(:final error) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RikiErrorBanner(
                    message: appErrorMessage(error, context.l10n),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(subscriptionPlansProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
              AsyncData(:final value) => value.isEmpty
                  ? Text(
                      'Hiện chưa có gói nào đang mở bán.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Column(
                      children: [
                        for (final plan in value) ...[
                          _buildPlanCard(plan),
                          const SizedBox(height: AppSpacing.space3),
                        ],
                      ],
                    ),
            },
            if (accessAsync case AsyncData(:final value)
                when value.purchases.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space4),
              Text('Lịch sử gói đã mua', style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.space2),
              for (final p in value.purchases)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RikiCard(
                    backgroundColor: AppColors.cardWarmWhite,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.planName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                [
                                  '${_vndFmt.format(p.amountPaid)}đ',
                                  if (p.endDate != null)
                                    'HSD ${_subDateFmt.format(p.endDate!)}',
                                  'Lượt AI còn: ${p.aiUsesRemaining}',
                                ].join(' · '),
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          p.active ? 'Đang dùng' : 'Hết hạn',
                          style: AppTypography.bodySmall.copyWith(
                            color: p.active
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(SubscriptionCheckoutResult checkout) {
    final isPaid = _pendingStatus == 'Paid';
    return RikiCard(
      key: const Key('subscription_pending_card'),
      backgroundColor: AppColors.brandTint,
      borderColor: AppColors.brandBorder,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đơn PayOS #${checkout.purchaseId} · ${_pendingStatus ?? 'Pending'}',
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 8),
          if (!isPaid)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => _openCheckoutUrl(checkout.checkoutUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Mở cổng PayOS'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _checkingStatus
                      ? null
                      : () => _checkStatus(checkout.purchaseId),
                  child: Text(
                    _checkingStatus ? 'Đang kiểm tra...' : 'Kiểm tra trạng thái',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(StudyAccessStatus access) {
    return RikiCard(
      key: const Key('subscription_access_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            access.active
                ? (access.planName ?? 'Gói tự học đang hoạt động')
                : 'Chưa có gói tự học hoạt động',
            style: AppTypography.cardTitle,
          ),
          if (access.selfStudyExpiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Hạn dùng: ${_subDateFmt.format(access.selfStudyExpiresAt!)}'
              '${access.selfStudyDaysRemaining != null ? ' (còn ${access.selfStudyDaysRemaining} ngày)' : ''}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _QuotaChip(
                label: 'Chấm AI: ${access.aiGradingUsesRemaining} lượt',
              ),
              _QuotaChip(
                label:
                    'Luyện nói AI: ${access.speaking ? 'Mở' : '${access.speakingUsesRemaining} lượt'}',
              ),
              _QuotaChip(
                label:
                    'Luyện viết AI: ${access.writing ? 'Mở' : '${access.writingUsesRemaining} lượt'}',
              ),
              _QuotaChip(
                label: 'Lộ trình AI: ${access.learningPathUsesRemaining} lượt',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanOffer plan) {
    return RikiCard(
      key: ValueKey('subscription_plan_${plan.id}'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: plan.isPopular
          ? AppColors.brandPrimary
          : AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name, style: AppTypography.cardTitle),
              ),
              Text(
                '${_vndFmt.format(plan.price)}đ',
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              plan.kindLabel,
              if (plan.durationDays > 0) '${plan.durationDays} ngày',
              if (plan.aiUses > 0) '${plan.aiUses} lượt AI',
            ].join(' · '),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(plan.description!, style: AppTypography.bodySmall),
          ],
          const SizedBox(height: 12),
          RikiPrimaryButton(
            key: ValueKey('buy_subscription_${plan.id}'),
            label: _purchasingPlanId == plan.id
                ? 'Đang tạo liên kết PayOS...'
                : 'Mua gói qua PayOS',
            onPressed: _purchasingPlanId == null
                ? () => _startPurchase(plan)
                : null,
          ),
        ],
      ),
    );
  }
}

class _QuotaChip extends StatelessWidget {
  const _QuotaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: AppTypography.metadata),
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.surfaceSubtle,
    );
  }
}
