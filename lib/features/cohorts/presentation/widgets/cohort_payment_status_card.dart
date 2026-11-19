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
    extends ConsumerState<CohortPaymentStatusCard>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _cancelling = false;
  bool _autoExpiredReconciled = false;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTimers();
  }

  @override
  void didUpdateWidget(covariant CohortPaymentStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.paymentState != widget.course.paymentState ||
        oldWidget.course.paymentExpiresAt != widget.course.paymentExpiresAt ||
        oldWidget.course.id != widget.course.id) {
      _autoExpiredReconciled = false;
      _syncTimers();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    if (state == AppLifecycleState.resumed &&
        widget.course.paymentState == 'AwaitingPayment') {
      _syncTimers();
      unawaited(_check(silent: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _syncTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;

    if (widget.course.paymentState != 'AwaitingPayment') {
      _remaining = null;
      return;
    }

    final expiresAt = widget.course.paymentExpiresAt;
    if (expiresAt != null) {
      _updateRemaining(expiresAt);
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemaining(expiresAt),
      );
    }

    _pollTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) {
        if (mounted && !_checking && widget.course.paymentState == 'AwaitingPayment') {
          unawaited(_check(silent: true));
        }
      },
    );
  }

  void _updateRemaining(DateTime expiresAt) {
    if (!mounted) return;
    final diff = expiresAt.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
    if (diff.isNegative && !_autoExpiredReconciled) {
      _autoExpiredReconciled = true;
      unawaited(_check(silent: true));
    }
  }

  String _formatDuration(Duration d) {
    final totalSec = d.inSeconds;
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _continuePayment() async {
    final rawUrl = widget.course.checkoutUrl;
    final uri = parseSafeExternalHttpUri(rawUrl);
    if (uri == null || rawUrl == null) return;
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        await Clipboard.setData(ClipboardData(text: rawUrl));
        if (!mounted) return;
        ref.read(rikiToastServiceProvider.notifier).info(
          title: 'Đã sao chép liên kết thanh toán',
          description:
              'Không thể tự mở trình duyệt. Hãy dán liên kết vào trình duyệt để hoàn tất PayOS.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(title: 'Không thể mở trang thanh toán');
    }
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking || _cancelling) return;
    setState(() => _checking = true);
    try {
      await ref
          .read(learnerMyCoursesProvider.notifier)
          .reconcilePayment(widget.course.id);
    } catch (error) {
      if (!silent && mounted) {
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

  Future<void> _cancelPendingHold() async {
    if (_cancelling || _checking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy giữ chỗ thanh toán?'),
        content: const Text(
          'Chỗ trong lớp sẽ được giải phóng ngay. Nếu bạn đã chuyển khoản PayOS, hãy dùng "Kiểm tra thanh toán" thay vì hủy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hủy giữ chỗ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang hủy giữ chỗ...',
        action: () => ref
            .read(learnerMyCoursesProvider.notifier)
            .cancelPendingEnrollment(widget.course.id),
      );
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã hủy giữ chỗ');
    } catch (error) {
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Chưa thể hủy giữ chỗ',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
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
        if (exp == null) {
          body = 'Chỗ của bạn đang được giữ trong thời gian thanh toán.';
        } else if (_remaining == Duration.zero) {
          body = 'Hạn giữ chỗ đã kết thúc — đang xác minh với hệ thống thanh toán.';
        } else {
          final countdown = _remaining != null
              ? 'Còn ${_formatDuration(_remaining!)} · '
              : '';
          body =
              '${countdown}Giữ chỗ đến ${DateFormat('dd/MM/yyyy HH:mm').format(exp)}.';
        }
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
            Text(
              body,
              key: Key('payment_status_countdown_${course.id}'),
              style: AppTypography.bodySmall,
            ),
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
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: _cancelling ? null : _continuePayment,
                    child: const Text('Tiếp tục thanh toán'),
                  ),
                OutlinedButton(
                  key: Key('check_payment_${course.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: _checking || _cancelling ? null : () => _check(),
                  child: Text(_checking ? 'Đang kiểm tra...' : 'Kiểm tra thanh toán'),
                ),
                TextButton(
                  key: Key('cancel_pending_payment_${course.id}'),
                  onPressed: _checking || _cancelling ? null : _cancelPendingHold,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Hủy giữ chỗ'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
