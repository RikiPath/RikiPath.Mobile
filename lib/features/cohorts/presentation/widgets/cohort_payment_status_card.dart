import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thẻ trạng thái thanh toán trọn khóa. Chỉ hiển thị "Đã xác nhận thanh toán"
/// khi server xác nhận (paymentState == 'Confirmed').
class CohortPaymentStatusCard extends ConsumerStatefulWidget {
  const CohortPaymentStatusCard({required this.course, super.key});

  final LearnerStudyCourseDetail course;

  @override
  ConsumerState<CohortPaymentStatusCard> createState() =>
      _CohortPaymentStatusCardState();
}

class _CohortPaymentStatusCardState
    extends ConsumerState<CohortPaymentStatusCard> {
  bool _checking = false;

  Future<void> _continuePayment() async {
    final url = widget.course.checkoutUrl;
    if (url == null || !url.startsWith('https://')) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(title: 'Không thể mở trang thanh toán');
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await ref
          .read(learnerMyCoursesProvider.notifier)
          .reconcilePayment(widget.course.id);
    } catch (error) {
      if (mounted) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: 'Chưa thể kiểm tra thanh toán',
              description: appErrorMessage(error, context.l10n),
            );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final state = course.paymentState;
    if (state.isEmpty) return const SizedBox.shrink();

    String title;
    String? body;
    Color color = AppColors.info;
    var showActions = false;
    switch (state) {
      case 'Confirmed':
        title = 'Đã xác nhận thanh toán';
        color = AppColors.success;
      case 'AwaitingPayment':
        title = 'Đang chờ xác nhận thanh toán';
        final exp = course.paymentExpiresAt;
        body = exp == null
            ? 'Chỗ của bạn đang được giữ trong thời gian thanh toán.'
            : 'Chỗ được giữ đến ${DateFormat('dd/MM/yyyy HH:mm').format(exp)}.';
        showActions = true;
      case 'Expired':
      case 'Failed':
      case 'Cancelled':
        title = state == 'Expired'
            ? 'Phiên thanh toán đã hết hạn'
            : 'Thanh toán chưa thành công';
        body = 'Chỗ đã được nhả. Bạn có thể đăng ký lại lớp này.';
        color = AppColors.error;
      case 'PaidUnderReview':
        title = 'Đã nhận thanh toán';
        body = 'Admin đang xử lý ghi danh.';
      default:
        return const SizedBox.shrink();
    }

    return RikiCard(
      key: Key('payment_status_card_${course.id}'),
      backgroundColor: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle),
          if (body != null) ...[
            const SizedBox(height: 4),
            Text(body, style: AppTypography.bodySmall),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (course.checkoutUrl != null)
                  ElevatedButton(
                    key: Key('continue_payment_${course.id}'),
                    onPressed: _continuePayment,
                    child: const Text('Tiếp tục thanh toán'),
                  ),
                OutlinedButton(
                  key: Key('check_payment_${course.id}'),
                  onPressed: _checking ? null : _check,
                  child: const Text('Kiểm tra thanh toán'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
