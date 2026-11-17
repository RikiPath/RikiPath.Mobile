import 'dart:typed_data';

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
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';

typedef TransferEvidencePicker =
    Future<({Uint8List bytes, String name, String mime})?> Function();

/// Học viên xem Mentor chính/lớp hiện tại và gửi YÊU CẦU chuyển lớp để Admin xem xét.
/// Phản hồi/đánh giá Mentor là luồng riêng; đánh giá thấp không tự tạo yêu cầu chuyển lớp.
class CohortTransferSection extends ConsumerStatefulWidget {
  const CohortTransferSection({
    required this.course,
    required this.pickEvidence,
    super.key,
  });

  final LearnerStudyCourseDetail course;
  final TransferEvidencePicker pickEvidence;

  @override
  ConsumerState<CohortTransferSection> createState() =>
      _CohortTransferSectionState();
}

class _CohortTransferSectionState extends ConsumerState<CohortTransferSection> {
  final TextEditingController _reason = TextEditingController();
  int? _targetCohortId;
  String? _idempotencyKey;
  ({Uint8List bytes, String name, String mime})? _evidence;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.length < 10) {
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Thiếu lý do chuyển lớp',
        description: 'Vui lòng nhập lý do từ 10 đến 1000 ký tự.',
      );
      return;
    }
    _idempotencyKey ??= generateClientIdempotencyKey();
    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang gửi yêu cầu chuyển lớp...',
        action: () => ref
            .read(learnerMyCoursesProvider.notifier)
            .requestCohortTransfer(
              courseId: widget.course.id,
              targetCohortId: _targetCohortId,
              reason: reason,
              idempotencyKey: _idempotencyKey!,
              evidenceBytes: _evidence?.bytes,
              evidenceFileName: _evidence?.name,
              evidenceContentType: _evidence?.mime,
            ),
      );
      if (!mounted) return;
      _reason.clear();
      setState(() {
        _idempotencyKey = null;
        _evidence = null;
        _targetCohortId = null;
      });
      ref.read(rikiToastServiceProvider.notifier).success(
        title: 'Đã gửi yêu cầu chuyển lớp',
        description: 'Admin sẽ xem xét và thông báo kết quả cho bạn.',
      );
    } catch (error) {
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Chưa gửi được yêu cầu',
        description: appErrorMessage(error, context.l10n),
      );
    }
  }

  Future<void> _withdraw(CohortTransferRequestItem request) async {
    try {
      await ref
          .read(learnerMyCoursesProvider.notifier)
          .withdrawCohortTransfer(request.id);
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã rút yêu cầu chuyển lớp');
    } catch (error) {
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Chưa rút được yêu cầu',
        description: appErrorMessage(error, context.l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final requestsState = ref.watch(learnerTransferRequestsProvider);
    final cohorts = ref.watch(learnerCohortDiscoveryProvider).value?.cohorts ??
        const <StudyCohortSummary>[];
    final candidates = cohorts
        .where((c) => c.id != course.cohortId && c.level == course.level)
        .toList();
    final requests = (requestsState.value ?? const <CohortTransferRequestItem>[])
        .where((r) => r.sourceCourseId == course.id || r.destinationCourseId == course.id)
        .toList();
    final hasPending = requests.any((r) => r.isPending && r.sourceCourseId == course.id);
    final canRequest = course.cohortId != null &&
        course.status == 'Active' &&
        course.paymentStatus == 'Paid' &&
        !hasPending;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return RikiCard(
      key: const Key('cohort_transfer_section'),
      backgroundColor: Colors.white,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yêu cầu chuyển lớp', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(
            'Mentor chính: ${course.mentorName.isEmpty ? 'Chưa phân công' : course.mentorName} · Lớp hiện tại #${course.cohortId}. '
            'Admin xem xét sức chứa, lịch, cấp độ và chính sách; lịch sử điểm danh và BTVN được giữ nguyên.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Góp ý hoặc đánh giá Mentor dùng mục phản hồi riêng — không tự động chuyển lớp.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (course.status == 'Transferred') ...[
            const SizedBox(height: 8),
            MentorStatusBadge(label: 'Đã chuyển sang lớp mới', color: AppColors.success),
          ],
          if (canRequest) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: const Key('transfer_target_dropdown'),
              initialValue: _targetCohortId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Lớp muốn chuyển đến (không bắt buộc)'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Nhờ Admin chọn lớp phù hợp')),
                for (final c in candidates)
                  DropdownMenuItem<int?>(
                    value: c.id,
                    enabled: c.seatsAvailable > 0,
                    child: Text(
                      '${c.name} · ${c.mentorName} · còn ${c.seatsAvailable}/${c.capacity} chỗ',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _targetCohortId = v),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('transfer_reason_field'),
              controller: _reason,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Lý do chuyển lớp (bắt buộc)'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RikiSecondaryButton(
                  label: _evidence == null ? 'Đính kèm minh chứng' : 'Đổi minh chứng',
                  onPressed: () async {
                    final picked = await widget.pickEvidence();
                    if (picked != null && mounted) setState(() => _evidence = picked);
                  },
                ),
                if (_evidence != null) Text(_evidence!.name, style: AppTypography.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            RikiPrimaryButton(
              key: const Key('transfer_submit_button'),
              label: 'Gửi yêu cầu chuyển lớp',
              onPressed: _submit,
            ),
          ],
          const SizedBox(height: 12),
          if (requestsState.isLoading)
            const LinearProgressIndicator()
          else if (requestsState.hasError)
            Text(
              appErrorMessage(requestsState.error!, context.l10n),
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            )
          else if (requests.isEmpty)
            Text('Chưa có yêu cầu chuyển lớp nào.', style: AppTypography.bodySmall)
          else
            for (final r in requests) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Yêu cầu #${r.id} · ${fmt.format(r.createdAtUtc)}',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  MentorStatusBadge(
                    label: r.statusLabel,
                    color: r.status == 'Approved'
                        ? AppColors.success
                        : r.status == 'Pending'
                            ? AppColors.brandPrimary
                            : AppColors.textSecondary,
                  ),
                ],
              ),
              Text(
                '${r.sourceCohortName ?? '#${r.sourceCohortId}'} → ${r.targetCohortName ?? r.requestedTargetCohortName ?? 'Admin chọn lớp'}',
                style: AppTypography.bodySmall,
              ),
              Text('Lý do: ${r.reason}', style: AppTypography.bodySmall),
              if (r.status == 'Rejected' && (r.decisionNote ?? '').isNotEmpty)
                Text(
                  'Lý do từ chối: ${r.decisionNote}',
                  key: Key('transfer_rejection_${r.id}'),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                ),
              for (final h in r.history)
                Text(
                  '${fmt.format(h.atUtc)} · ${h.action}: ${h.detail}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              if (r.isPending)
                TextButton(
                  onPressed: () => _withdraw(r),
                  child: const Text('Rút yêu cầu'),
                ),
            ],
        ],
      ),
    );
  }
}
