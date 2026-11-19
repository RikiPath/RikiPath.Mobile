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
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_transfer_section.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';

/// Learner complaint form + own complaint list for one course.
///
/// When the enrollment is `PaidUnderReview` the section is highlighted and
/// defaults to the payment/enrollment category so the learner can request a
/// refund review. The client never decides the outcome — Admin does.
class CohortComplaintSection extends ConsumerStatefulWidget {
  const CohortComplaintSection({
    required this.course,
    required this.mentors,
    required this.pickEvidence,
    super.key,
  });

  final LearnerStudyCourseDetail course;

  /// Mentors the complaint may optionally target (id → name).
  final List<({int id, String name})> mentors;
  final TransferEvidencePicker pickEvidence;

  @override
  ConsumerState<CohortComplaintSection> createState() =>
      _CohortComplaintSectionState();
}

class _CohortComplaintSectionState
    extends ConsumerState<CohortComplaintSection> {
  static const int _maxEvidenceBytes = 10 * 1024 * 1024;
  static const String _paidUnderReviewMessage =
      'Giao dịch đã được ghi nhận nhưng chưa thể hoàn tất ghi danh. '
      'Bộ phận quản trị sẽ xem xét yêu cầu của bạn.';

  final TextEditingController _message = TextEditingController();
  late String _category;
  int? _mentorId;
  bool _refundReview = false;
  String? _idempotencyKey;
  ({Uint8List bytes, String name, String mime})? _evidence;
  bool _submitting = false;

  bool get _paidUnderReview => widget.course.paymentState == 'PaidUnderReview';
  bool get _isPayment => _category == CohortComplaintCategory.paymentEnrollment;

  @override
  void initState() {
    super.initState();
    _category = _paidUnderReview
        ? CohortComplaintCategory.paymentEnrollment
        : CohortComplaintCategory.teachingQuality;
    _refundReview = _paidUnderReview;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Any change to the draft invalidates the previous idempotency key so a
  /// genuinely different complaint is never deduplicated by the server.
  void _draftChanged(VoidCallback change) {
    setState(() {
      change();
      _idempotencyKey = null;
    });
  }

  Future<void> _pickEvidence() async {
    final picked = await widget.pickEvidence();
    if (picked == null || !mounted) return;
    if (picked.bytes.lengthInBytes > _maxEvidenceBytes) {
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Tệp quá lớn',
        description: 'Minh chứng tối đa 10MB (PDF/PNG/JPG).',
      );
      return;
    }
    _draftChanged(() => _evidence = picked);
  }

  Future<void> _submit() async {
    final message = _message.text.trim();
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    if (message.length < 10) {
      toasts.error(
        title: 'Thiếu nội dung khiếu nại',
        description: 'Vui lòng mô tả vấn đề từ 10 đến 2000 ký tự.',
      );
      return;
    }
    if (_submitting) return;
    _submitting = true;
    _idempotencyKey ??= generateClientIdempotencyKey();
    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang gửi khiếu nại...',
        action: () => ref
            .read(learnerMyCoursesProvider.notifier)
            .submitComplaint(
              courseId: widget.course.id,
              category: _category,
              message: message,
              mentorId: _isPayment ? null : _mentorId,
              refundReviewRequested: _isPayment && _refundReview,
              idempotencyKey: _idempotencyKey!,
              evidenceBytes: _evidence?.bytes,
              evidenceFileName: _evidence?.name,
              evidenceContentType: _evidence?.mime,
            ),
      );
      if (!mounted) return;
      _message.clear();
      setState(() {
        _idempotencyKey = null;
        _evidence = null;
        _mentorId = null;
      });
      toasts.success(
        title: 'Đã gửi khiếu nại',
        description: 'Bộ phận quản trị sẽ xem xét và phản hồi cho bạn.',
      );
    } catch (error) {
      if (!mounted) return;
      toasts.error(
        title: 'Chưa gửi được khiếu nại',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      _submitting = false;
    }
  }

  Color _statusColor(String status) => switch (status) {
    'Resolved' => AppColors.success,
    'Rejected' => AppColors.error,
    'UnderReview' => AppColors.warning,
    _ => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    final complaintsState = ref.watch(learnerComplaintsProvider);
    final complaints =
        (complaintsState.value ?? const <CohortComplaint>[])
            .where((c) => c.courseId == widget.course.id)
            .toList()
          ..sort(
            (a, b) => (b.createdAtUtc ?? DateTime(0)).compareTo(
              a.createdAtUtc ?? DateTime(0),
            ),
          );
    final highlight = _paidUnderReview;

    return RikiCard(
      key: const Key('cohort_complaint_section'),
      backgroundColor: highlight ? AppColors.warningBackground : Colors.white,
      borderColor: highlight ? AppColors.warning : AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Khiếu nại & hỗ trợ', style: AppTypography.cardTitle),
          if (highlight) ...[
            const SizedBox(height: 6),
            Text(
              _paidUnderReviewMessage,
              key: const Key('complaint_paid_under_review_hint'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warningText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cat in CohortComplaintCategory.all)
                ChoiceChip(
                  key: ValueKey('complaint_category_$cat'),
                  label: Text(CohortComplaintCategory.label(cat)),
                  selected: _category == cat,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _draftChanged(() => _category = cat),
                ),
            ],
          ),
          if (!_isPayment && widget.mentors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Mentor liên quan (tùy chọn)',
              style: AppTypography.metadata.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Không chọn'),
                  selected: _mentorId == null,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _draftChanged(() => _mentorId = null),
                ),
                for (final m in widget.mentors)
                  ChoiceChip(
                    key: ValueKey('complaint_mentor_${m.id}'),
                    label: Text(m.name),
                    selected: _mentorId == m.id,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _draftChanged(() => _mentorId = m.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            key: const Key('complaint_message_field'),
            controller: _message,
            maxLines: 4,
            maxLength: 2000,
            onChanged: (_) => _idempotencyKey = null,
            decoration: const InputDecoration(
              labelText: 'Mô tả vấn đề (bắt buộc)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_isPayment)
            // Material trong suốt: ListTile cần Material gần nhất để hiển thị hiệu ứng khi nằm trong thẻ có nền.
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const Key('complaint_refund_toggle'),
                contentPadding: EdgeInsets.zero,
                value: _refundReview,
                onChanged: (v) => _draftChanged(() => _refundReview = v),
                title: const Text('Đề nghị Admin xem xét hoàn tiền'),
                subtitle: const Text(
                  'Admin sẽ kiểm tra giao dịch trước khi quyết định.',
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const Key('complaint_evidence_button'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _pickEvidence,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _evidence?.name ?? 'Minh chứng (PDF/PNG/JPG ≤10MB)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton(
                key: const Key('complaint_submit_button'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _submit,
                child: const Text('Gửi khiếu nại'),
              ),
            ],
          ),
          if (complaints.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Khiếu nại đã gửi',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final c in complaints)
              Padding(
                key: ValueKey('complaint_item_${c.id}'),
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        MentorStatusBadge(
                          label: c.categoryLabel,
                          color: AppColors.brandPrimary,
                        ),
                        MentorStatusBadge(
                          label: c.statusLabel,
                          color: _statusColor(c.status),
                        ),
                        if (c.refundReviewRequested)
                          const MentorStatusBadge(
                            label: 'Đề nghị xét hoàn tiền',
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c.message, style: AppTypography.bodySmall),
                    if (c.mentorName != null)
                      Text(
                        'Mentor: ${c.mentorName}',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (c.createdAtUtc != null)
                      Text(
                        'Gửi lúc ${DateFormat('dd/MM/yyyy HH:mm').format(c.createdAtUtc!)}',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (c.hasMentorResponse)
                      Text(
                        'Phản hồi của Mentor: ${c.mentorResponse}',
                        style: AppTypography.bodySmall,
                      ),
                    if (c.decision != null)
                      Text(
                        'Kết luận của Admin: ${c.decision}',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
