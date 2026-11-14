import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_compensation_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

String formatCompensationVnd(num amount) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
).format(amount);

String _dateLabel(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
}

String earningStatusLabel(String status) => switch (status) {
  'Eligible' => 'Đủ điều kiện, chờ chốt kỳ',
  'HeldDisputed' => 'Tạm giữ do khiếu nại',
  'LockedInPayroll' => 'Đã đưa vào kỳ lương',
  'Paid' => 'Đã chi trả',
  _ => status,
};

String payrollStatusLabel(String status) => switch (status) {
  'Draft' => 'Bản nháp',
  'Review' => 'Đang rà soát',
  'Approved' => 'Đã phê duyệt',
  'Paid' => 'Đã chi trả',
  'Closed' => 'Đã đóng kỳ',
  _ => status,
};

/// Nhãn trạng thái chi trả. Chỉ trạng thái `Paid` mới được hiển thị là
/// "Đã chi trả"; `Processing` và `UnknownPendingReconciliation` không bao giờ
/// được coi là đã nhận tiền.
String payoutStatusLabel(String status) => switch (status) {
  'PendingExecution' => 'Chờ thực hiện chi trả',
  'Processing' => 'Đang xử lý chuyển tiền',
  'UnknownPendingReconciliation' => 'Đang đối soát kết quả chuyển tiền',
  'OnHoldMissingEvidence' => 'Chờ chứng từ chuyển khoản',
  'Paid' => 'Đã chi trả',
  'FailedRetryable' => 'Chuyển tiền chưa thành công, sẽ thực hiện lại',
  'Cancelled' => 'Đã hủy',
  _ => status,
};

String payoutMethodLabel(String? method) => switch (method) {
  'ManualBankTransfer' => 'Chuyển khoản ngân hàng',
  'PayOsPayout' => 'Chi trả tự động qua payOS',
  _ => 'Chưa chọn phương thức',
};

String bankVerificationLabel(String status) => switch (status) {
  'PendingVerification' => 'Chờ quản trị viên xác minh',
  'Verified' => 'Đã xác minh',
  'Rejected' => 'Bị từ chối, vui lòng cập nhật lại',
  'Superseded' => 'Phiên bản cũ',
  _ => status,
};

class MentorCompensationScreen extends ConsumerWidget {
  const MentorCompensationScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTabIndex,
      child: Scaffold(
        key: const Key('mentor_compensation_screen'),
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          title: const Text('Thu nhập của tôi'),
          actions: [
            IconButton(
              key: const Key('mentor_compensation_bank_button'),
              tooltip: 'Tài khoản nhận thù lao',
              icon: const Icon(Icons.account_balance_outlined),
              onPressed: () => context.push(AppRoutes.mentorBankAccount),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Buổi tư vấn'),
              Tab(text: 'Kỳ lương'),
              Tab(text: 'Lịch sử chi trả'),
            ],
          ),
        ),
        body: const SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _OverviewTab(),
              _EarningsTab(),
              _PayrollsTab(),
              _PayoutsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _asyncBody<T>({
  required AsyncValue<T> state,
  required VoidCallback onRetry,
  required Widget Function(T value) builder,
  required String errorMessage,
}) {
  return switch (state) {
    AsyncData(:final value) => builder(value),
    AsyncError() => Center(
      child: MentorErrorState(message: errorMessage, onRetry: onRetry),
    ),
    _ => const Center(child: SakuraLoadingIndicator()),
  };
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorCompensationOverviewProvider);
    return _asyncBody(
      state: state,
      onRetry: () => ref.invalidate(mentorCompensationOverviewProvider),
      errorMessage: 'Chưa thể tải tổng quan thu nhập. Vui lòng thử lại.',
      builder: (overview) => RefreshIndicator(
        onRefresh: () {
          ref.invalidate(mentorHourlyRatesProvider);
          ref.invalidate(mentorQualificationsProvider);
          return ref.refresh(mentorCompensationOverviewProvider.future);
        },
        child: ListView(
          key: const Key('mentor_compensation_overview'),
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            _MetricCard(
              key: const Key('mentor_comp_total_paid'),
              icon: Icons.payments_outlined,
              title: 'Đã chi trả',
              value: formatCompensationVnd(overview.totalPaidVnd),
              highlight: true,
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.hourglass_bottom_outlined,
                    title: 'Chờ chốt kỳ lương',
                    value: formatCompensationVnd(
                      overview.totalEligibleUnassignedVnd,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.lock_clock_outlined,
                    title: 'Đã vào kỳ lương',
                    value: formatCompensationVnd(
                      overview.totalLockedInPayrollVnd,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            RikiCard(
              backgroundColor: AppColors.cardWarmWhite,
              borderColor: AppColors.cardBorderMuted,
              boxShadow: AppShadows.sakuraSubtle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin thù lao', style: AppTypography.sectionTitle),
                  const SizedBox(height: AppSpacing.space2),
                  _InfoRow(
                    label: 'Đơn giá giờ hiện tại',
                    value: overview.currentHourlyRate == null
                        ? 'Chưa được cấu hình'
                        : '${formatCompensationVnd(overview.currentHourlyRate!.hourlyRateVnd)}/giờ',
                  ),
                  _InfoRow(
                    label: 'Trình độ được hướng dẫn',
                    value: overview.activeQualifications.isEmpty
                        ? 'Chưa được cấp'
                        : overview.activeQualifications
                              .map((q) => q.jlptLevel)
                              .join(', '),
                  ),
                  _InfoRow(
                    label: 'Tài khoản nhận thù lao',
                    value: overview.currentBankAccount == null
                        ? 'Chưa đăng ký'
                        : '${overview.currentBankAccount!.bankShortName} '
                              '${overview.currentBankAccount!.maskedAccountNumber} · '
                              '${bankVerificationLabel(overview.currentBankAccount!.verificationStatus)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            const _HourlyRatesHistoryCard(),
            const SizedBox(height: AppSpacing.space3),
            const _QualificationsHistoryCard(),
            const SizedBox(height: AppSpacing.space3),
            Text(
              'Thù lao do hệ thống tính dựa trên đơn giá và hệ số trình độ đã chốt tại thời điểm đặt lịch, '
              'sau khi buổi tư vấn được xác nhận hoàn thành.',
              style: AppTypography.metadata.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsTab extends ConsumerWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorEarningsProvider);
    return _asyncBody(
      state: state,
      onRetry: () => ref.invalidate(mentorEarningsProvider),
      errorMessage: 'Chưa thể tải danh sách buổi tư vấn đã ghi nhận.',
      builder: (items) {
        if (items.isEmpty) {
          return const Center(
            child: MentorEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có buổi tư vấn được ghi nhận',
              description:
                  'Thu nhập sẽ xuất hiện sau khi buổi tư vấn hoàn thành và được xác nhận.',
            ),
          );
        }
        return ListView.separated(
          key: const Key('mentor_compensation_earnings_list'),
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
          itemBuilder: (context, index) {
            final e = items[index];
            return RikiCard(
              key: ValueKey('mentor_earning_${e.id}'),
              backgroundColor: AppColors.cardWarmWhite,
              borderColor: AppColors.cardBorderMuted,
              boxShadow: AppShadows.sakuraSubtle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LevelChip(level: e.jlptLevel),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          'Buổi tư vấn #${e.mentorBookingId}',
                          style: AppTypography.cardTitle,
                        ),
                      ),
                      Text(
                        formatCompensationVnd(e.eligibleAmountVnd),
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _InfoRow(
                    label: 'Thời lượng được duyệt',
                    value:
                        '${e.approvedEligibleMinutes}/${e.scheduledMinutes} phút '
                        '(${e.approvedEligibleHours.toStringAsFixed(2)} giờ)',
                  ),
                  _InfoRow(
                    label: 'Đơn giá đã chốt',
                    value:
                        '${formatCompensationVnd(e.frozenHourlyRateVnd)}/giờ',
                  ),
                  _InfoRow(
                    label: 'Hệ số trình độ',
                    value: '×${e.frozenLevelCoefficient.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'Trạng thái',
                    value: earningStatusLabel(e.status),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PayrollsTab extends ConsumerWidget {
  const _PayrollsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorPayrollsProvider);
    return _asyncBody(
      state: state,
      onRetry: () => ref.invalidate(mentorPayrollsProvider),
      errorMessage: 'Chưa thể tải kỳ lương.',
      builder: (items) {
        if (items.isEmpty) {
          return const Center(
            child: MentorEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Chưa có kỳ lương',
              description:
                  'Kỳ lương tháng được quản trị viên tổng hợp và phê duyệt.',
            ),
          );
        }
        return ListView.separated(
          key: const Key('mentor_compensation_payrolls_list'),
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
          itemBuilder: (context, index) {
            final p = items[index];
            final approved = p.status == 'Approved' || p.status == 'Paid';
            final minutes = p.lines.fold<int>(
              0,
              (sum, l) => sum + l.approvedEligibleMinutes,
            );
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    _PayrollDetailSheet(payrollId: p.id, fallback: p),
              ),
              child: RikiCard(
                key: ValueKey('mentor_payroll_${p.id}'),
                backgroundColor: AppColors.cardWarmWhite,
                borderColor: AppColors.cardBorderMuted,
                boxShadow: AppShadows.sakuraSubtle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kỳ lương tháng ${p.periodMonth}/${p.periodYear}',
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        Text(
                          payrollStatusLabel(p.status),
                          style: AppTypography.metadata.copyWith(
                            color: approved
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    _InfoRow(
                      label: 'Số buổi hoàn thành',
                      value: '${p.lines.length} buổi',
                    ),
                    _InfoRow(
                      label: 'Thời lượng được duyệt',
                      value:
                          '$minutes phút (${(minutes / 60).toStringAsFixed(2)} giờ)',
                    ),
                    _InfoRow(
                      label: 'Thù lao buổi tư vấn',
                      value: formatCompensationVnd(p.totalEarningsAmountVnd),
                    ),
                    _InfoRow(
                      label: 'Điều chỉnh',
                      value: formatCompensationVnd(p.totalAdjustmentsAmountVnd),
                    ),
                    for (final adj in p.adjustments)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.space3),
                        child: Text(
                          '• ${adj.reason}: ${formatCompensationVnd(adj.amountVnd)}',
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    const Divider(),
                    _InfoRow(
                      label: approved
                          ? 'Số tiền được duyệt chi trả'
                          : 'Tổng tạm tính (chưa phê duyệt)',
                      value: formatCompensationVnd(p.grossPayableAmountVnd),
                      emphasize: true,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.mentorCompPayrollDetailTitle,
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.brandPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorPayoutsProvider);
    return _asyncBody(
      state: state,
      onRetry: () => ref.invalidate(mentorPayoutsProvider),
      errorMessage: 'Chưa thể tải lịch sử chi trả.',
      builder: (items) {
        if (items.isEmpty) {
          return const Center(
            child: MentorEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Chưa có khoản chi trả',
              description:
                  'Khoản chi trả được tạo sau khi kỳ lương được phê duyệt.',
            ),
          );
        }
        return ListView.separated(
          key: const Key('mentor_compensation_payouts_list'),
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
          itemBuilder: (context, index) {
            final o = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    _PayoutDetailSheet(obligationId: o.id, fallback: o),
              ),
              child: RikiCard(
                key: ValueKey('mentor_payout_${o.id}'),
                backgroundColor: AppColors.cardWarmWhite,
                borderColor: AppColors.cardBorderMuted,
                boxShadow: AppShadows.sakuraSubtle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          o.isPaid
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          color: o.isPaid
                              ? AppColors.success
                              : AppColors.brandPrimary,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            payoutStatusLabel(o.status),
                            key: ValueKey('mentor_payout_status_${o.id}'),
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    _InfoRow(
                      label: 'Số tiền được duyệt',
                      value: formatCompensationVnd(o.payableAmountVnd),
                    ),
                    _InfoRow(
                      label: 'Đã nhận',
                      value: formatCompensationVnd(
                        o.isPaid ? o.paidAmountVnd : 0,
                      ),
                      emphasize: o.isPaid,
                    ),
                    _InfoRow(
                      label: 'Phương thức',
                      value: payoutMethodLabel(o.selectedExecutionMethod),
                    ),
                    _InfoRow(
                      label: 'Tài khoản nhận',
                      value:
                          '${o.recipientBankShortNameSnapshot} ${o.recipientMaskedAccountSnapshot}'
                              .trim(),
                    ),
                    if (o.isPaid)
                      _InfoRow(
                        label: 'Ngày chi trả',
                        value: _dateLabel(o.paidAtUtc),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'JLPT $level',
        style: AppTypography.metadata.copyWith(
          color: AppColors.brandPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.highlight = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: highlight
          ? AppColors.brandPrimary
          : AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandPrimary),
          const SizedBox(height: AppSpacing.space2),
          Text(
            title,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style:
                (highlight
                        ? AppTypography.sectionTitle
                        : AppTypography.cardTitle)
                    .copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: emphasize
                    ? AppColors.brandPrimary
                    : AppColors.textPrimary,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyRatesHistoryCard extends ConsumerWidget {
  const _HourlyRatesHistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ratesAsync = ref.watch(mentorHourlyRatesProvider);

    return RikiCard(
      key: const Key('mentor_comp_hourly_rates_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mentorCompHourlyRatesTitle, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space2),
          switch (ratesAsync) {
            AsyncLoading() => const RikiSkeleton(height: 52),
            AsyncError(:final error) => MentorErrorState(
              message: appErrorMessage(error, l10n),
              onRetry: () => ref.invalidate(mentorHourlyRatesProvider),
            ),
            AsyncData(:final value) => value.isEmpty
                ? Text(
                    'Chưa có lịch sử đơn giá thù lao.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  )
                : Column(
                    children: value.map((rate) {
                      final active = rate.isActive;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${formatCompensationVnd(rate.hourlyRateVnd)}/giờ',
                                    style: AppTypography.cardTitle.copyWith(
                                      color: active
                                          ? AppColors.brandPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                MentorStatusBadge(
                                  label: active ? 'Đang áp dụng' : 'Hết hiệu lực',
                                  color: active
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Từ ${_dateLabel(rate.effectiveFromUtc)}'
                              '${rate.effectiveToUtc != null ? ' đến ${_dateLabel(rate.effectiveToUtc)}' : ''}',
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (rate.reason?.trim().isNotEmpty == true)
                              Text(
                                rate.reason!.trim(),
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          },
        ],
      ),
    );
  }
}

class _QualificationsHistoryCard extends ConsumerWidget {
  const _QualificationsHistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final qualAsync = ref.watch(mentorQualificationsProvider);

    return RikiCard(
      key: const Key('mentor_comp_qualifications_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mentorCompQualificationsTitle,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          switch (qualAsync) {
            AsyncLoading() => const RikiSkeleton(height: 52),
            AsyncError(:final error) => MentorErrorState(
              message: appErrorMessage(error, l10n),
              onRetry: () => ref.invalidate(mentorQualificationsProvider),
            ),
            AsyncData(:final value) => value.isEmpty
                ? Text(
                    'Chưa có chứng nhận năng lực giảng dạy JLPT.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  )
                : Column(
                    children: value.map((qual) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _LevelChip(level: qual.jlptLevel),
                                const Spacer(),
                                MentorStatusBadge(
                                  label: qual.isActive
                                      ? 'Hiệu lực'
                                      : 'Đã thu hồi',
                                  color: qual.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ],
                            ),
                            if (qual.approvedAtUtc != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Cấp ngày: ${_dateLabel(qual.approvedAtUtc)}',
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (qual.notes?.trim().isNotEmpty == true)
                              Text(
                                qual.notes!.trim(),
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          },
        ],
      ),
    );
  }
}

class _PayrollDetailSheet extends ConsumerWidget {
  const _PayrollDetailSheet({
    required this.payrollId,
    required this.fallback,
  });

  final int payrollId;
  final MentorPayrollPeriodItem fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(mentorPayrollDetailProvider(payrollId));
    final data = async.value ?? fallback;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.space3),
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.cardWarmWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.mentorCompPayrollDetailTitle} (${data.periodMonth}/${data.periodYear})',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                payrollStatusLabel(data.status),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (async.isLoading) ...[
                const SizedBox(height: AppSpacing.space2),
                const LinearProgressIndicator(),
              ] else if (async.hasError) ...[
                const SizedBox(height: AppSpacing.space2),
                RikiInfoBanner(
                  message: appErrorMessage(async.error!, l10n),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              _InfoRow(
                label: 'Thù lao buổi tư vấn',
                value: formatCompensationVnd(data.totalEarningsAmountVnd),
              ),
              _InfoRow(
                label: 'Điều chỉnh',
                value: formatCompensationVnd(data.totalAdjustmentsAmountVnd),
              ),
              _InfoRow(
                label: 'Tổng kỳ lương',
                value: formatCompensationVnd(data.grossPayableAmountVnd),
                emphasize: true,
              ),
              if (data.approvedAtUtc != null)
                _InfoRow(
                  label: 'Ngày phê duyệt',
                  value: _dateLabel(data.approvedAtUtc),
                ),
              if (data.lines.isNotEmpty) ...[
                const Divider(height: AppSpacing.space5),
                Text('Chi tiết buổi trong kỳ', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.space2),
                ...data.lines.map(
                  (line) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _LevelChip(level: line.jlptLevel),
                            const SizedBox(width: AppSpacing.space2),
                            Expanded(
                              child: Text(
                                'Buổi #${line.mentorBookingId}',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              formatCompensationVnd(line.lineAmountVnd),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${line.approvedEligibleMinutes} phút · ${formatCompensationVnd(line.frozenHourlyRateVnd)}/giờ × ${line.frozenLevelCoefficient.toStringAsFixed(2)}',
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.mentorCommonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayoutDetailSheet extends ConsumerWidget {
  const _PayoutDetailSheet({
    required this.obligationId,
    required this.fallback,
  });

  final int obligationId;
  final MentorPayoutObligationItem fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(mentorPayoutDetailProvider(obligationId));
    final data = async.value ?? fallback;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.space3),
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.cardWarmWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.mentorCompPayoutDetailTitle,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                payoutStatusLabel(data.status),
                style: AppTypography.bodySmall.copyWith(
                  color: data.isPaid ? AppColors.success : AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (async.isLoading) ...[
                const SizedBox(height: AppSpacing.space2),
                const LinearProgressIndicator(),
              ] else if (async.hasError) ...[
                const SizedBox(height: AppSpacing.space2),
                RikiInfoBanner(
                  message: appErrorMessage(async.error!, l10n),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              _InfoRow(
                label: 'Số tiền được duyệt',
                value: formatCompensationVnd(data.payableAmountVnd),
              ),
              _InfoRow(
                label: 'Đã nhận',
                value: formatCompensationVnd(data.isPaid ? data.paidAmountVnd : 0),
                emphasize: data.isPaid,
              ),
              _InfoRow(
                label: 'Phương thức',
                value: payoutMethodLabel(data.selectedExecutionMethod),
              ),
              _InfoRow(
                label: 'Tài khoản nhận',
                value:
                    '${data.recipientBankShortNameSnapshot} ${data.recipientMaskedAccountSnapshot} (${data.recipientAccountHolderSnapshot})'
                        .trim(),
              ),
              if (data.paidAtUtc != null)
                _InfoRow(
                  label: 'Ngày chi trả',
                  value: _dateLabel(data.paidAtUtc),
                ),
              if (data.failureReason?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space2),
                  child: Text(
                    'Ghi chú sự cố: ${data.failureReason!.trim()}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (data.attempts.isNotEmpty) ...[
                const Divider(height: AppSpacing.space5),
                Text('Lịch sử lệnh chuyển tiền', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.space2),
                ...data.attempts.map(
                  (attempt) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Lần ${attempt.attemptNumber} · ${payoutMethodLabel(attempt.executionMethod)}',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              attempt.status,
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatCompensationVnd(attempt.amountVnd)} · ${_dateLabel(attempt.initiatedAtUtc)}',
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (attempt.transferReference?.trim().isNotEmpty == true)
                          Text(
                            'Mã giao dịch: ${attempt.transferReference!.trim()}',
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.mentorCommonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
