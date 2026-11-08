import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorProfileScreen extends ConsumerWidget {
  const MentorProfileScreen({this.applicationMode = false, super.key});

  final bool applicationMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorProfileControllerProvider);

    return Scaffold(
      key: const Key('mentor_profile_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(
          applicationMode
              ? context.l10n.mentorApplicationTitle
              : 'Hồ sơ Cố vấn',
        ),
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('mentor_profile_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('mentor_profile_error'),
              message: 'Không thể tải thông tin hồ sơ chuyên gia.',
              onRetry: ref.read(mentorProfileControllerProvider.notifier).retry,
            ),
          ),
          AsyncData(:final value) => _MentorProfileForm(
            profile: value,
            applicationMode: applicationMode,
          ),
        },
      ),
    );
  }
}

class _MentorProfileForm extends StatefulWidget {
  const _MentorProfileForm({
    required this.profile,
    required this.applicationMode,
  });

  final MentorProfileData profile;
  final bool applicationMode;

  @override
  State<_MentorProfileForm> createState() => _MentorProfileFormState();
}

class _MentorProfileFormState extends State<_MentorProfileForm> {
  late final TextEditingController _bioController;
  late final TextEditingController _expertiseController;
  late final TextEditingController _workplaceController;
  late final TextEditingController _expController;
  late final TextEditingController _videoUrlController;
  String? _selectedJlpt;
  bool _isSaving = false;
  bool _isUploadingDocument = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bioController = TextEditingController(text: p.bio ?? '');
    _expertiseController = TextEditingController(text: p.expertise ?? '');
    _workplaceController = TextEditingController(text: p.workplace ?? '');
    _expController = TextEditingController(
      text: p.yearsOfExperience?.toString() ?? '',
    );
    _videoUrlController = TextEditingController(
      text: p.introductionVideoUrl ?? '',
    );
    _selectedJlpt = p.jlptLevel;
  }

  @override
  void dispose() {
    _bioController.dispose();
    _expertiseController.dispose();
    _workplaceController.dispose();
    _expController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final l10n = context.l10n;

    return Consumer(
      builder: (context, ref, _) {
        return SingleChildScrollView(
          key: const Key('mentor_profile_scroll'),
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 1. Personal Information Overview
            RikiCard(
              borderColor: AppColors.border,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.applicationMode
                        ? l10n.mentorApplicationPersonal
                        : 'Thông tin cá nhân',
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.brandPrimary.withValues(
                          alpha: 0.12,
                        ),
                        backgroundImage: p.avatarUrl?.isNotEmpty == true
                            ? NetworkImage(p.avatarUrl!)
                            : null,
                        child: p.avatarUrl?.isNotEmpty == true
                            ? null
                            : const Icon(
                                Icons.person,
                                color: AppColors.brandPrimary,
                                size: 32,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName,
                              style: AppTypography.cardTitle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.email,
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (p.phoneNumber != null &&
                                p.phoneNumber!.isNotEmpty)
                              Text(
                                p.phoneNumber!,
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // 2. Unified Form: Information + Certificate + Single Submit Button
            RikiCard(
              borderColor: AppColors.border,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.applicationMode
                        ? l10n.mentorApplicationExpertise
                        : 'Chuyên môn và kinh nghiệm',
                    style: AppTypography.cardTitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Bio
                  TextField(
                    key: const Key('mentor_profile_bio_input'),
                    controller: _bioController,
                    maxLines: 3,
                    enabled: !p.isPending,
                    decoration: InputDecoration(
                      labelText: widget.applicationMode
                          ? l10n.mentorApplicationBioRequired
                          : 'Giới thiệu bản thân *',
                      hintText:
                          'Kinh nghiệm giảng dạy, phương pháp hướng dẫn...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Expertise
                  TextField(
                    key: const Key('mentor_profile_expertise_input'),
                    controller: _expertiseController,
                    enabled: !p.isPending,
                    decoration: InputDecoration(
                      labelText: widget.applicationMode
                          ? l10n.mentorApplicationExpertiseRequired
                          : 'Lĩnh vực chuyên môn *',
                      hintText: 'JLPT N1, N2, Giao tiếp thương mại...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // JLPT Level
                  DropdownButtonFormField<String>(
                    key: const Key('mentor_profile_jlpt_input'),
                    isExpanded: true,
                    initialValue: _selectedJlpt,
                    decoration: InputDecoration(
                      labelText: widget.applicationMode
                          ? l10n.mentorApplicationJlptRequired
                          : 'Trình độ tiếng Nhật *',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'N1', child: Text('JLPT N1')),
                      DropdownMenuItem(value: 'N2', child: Text('JLPT N2')),
                      DropdownMenuItem(value: 'N3', child: Text('JLPT N3')),
                      DropdownMenuItem(
                        value: 'Native',
                        child: Text('Bản ngữ (Native)'),
                      ),
                    ],
                    onChanged: p.isPending
                        ? null
                        : (val) => setState(() => _selectedJlpt = val),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Years of Experience
                  TextField(
                    key: const Key('mentor_profile_exp_input'),
                    controller: _expController,
                    enabled: !p.isPending,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số năm kinh nghiệm',
                      hintText: 'Ví dụ: 5',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Workplace
                  TextField(
                    key: const Key('mentor_profile_workplace_input'),
                    controller: _workplaceController,
                    enabled: !p.isPending,
                    decoration: const InputDecoration(
                      labelText: 'Nơi công tác / Đơn vị hiện tại',
                      hintText: 'Ví dụ: Đại học FPT / Riki Nihongo',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Video URL
                  TextField(
                    key: const Key('mentor_profile_video_input'),
                    controller: _videoUrlController,
                    enabled: !p.isPending,
                    decoration: const InputDecoration(
                      labelText: 'Link video giới thiệu (YouTube / Drive)',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Certificate Section
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Chứng chỉ xác minh *',
                    style: AppTypography.cardTitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  if (p.hasVerificationDocument) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.brandPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Text(
                              widget.applicationMode
                                  ? l10n.mentorApplicationDocumentUploaded
                                  : 'Đã tải chứng chỉ xác minh lên kho riêng tư.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!p.isPending) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key(
                            'mentor_upload_verification_document_button',
                          ),
                          onPressed: _isUploadingDocument
                              ? null
                              : () => _uploadDocument(ref),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            _isUploadingDocument
                                ? (widget.applicationMode
                                    ? l10n.mentorApplicationUploading
                                    : 'Đang tải chứng chỉ...')
                                : 'Chọn lại chứng chỉ khác',
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      widget.applicationMode
                          ? l10n.mentorApplicationDocumentRequired
                          : 'Bắt buộc: tải chứng chỉ PDF, JPEG hoặc PNG (tối đa 5 MB) trước khi gửi.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    RikiSecondaryButton(
                      key: const Key(
                        'mentor_upload_verification_document_button',
                      ),
                      label: _isUploadingDocument
                          ? (widget.applicationMode
                              ? l10n.mentorApplicationUploading
                              : 'Đang tải chứng chỉ...')
                          : (widget.applicationMode
                              ? l10n.mentorApplicationUpload
                              : 'Chọn và tải chứng chỉ'),
                      leadingIcon: Icons.upload_file_outlined,
                      onPressed: (p.isPending || _isUploadingDocument)
                          ? null
                          : () => _uploadDocument(ref),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space4),

                  // Single Submit action
                  if (widget.applicationMode || !p.isApproved) ...[
                    RikiPrimaryButton(
                      key: const Key('mentor_submit_verification_button'),
                      label: p.isPending
                          ? (widget.applicationMode
                              ? l10n.mentorApplicationPending
                              : 'Đang chờ xét duyệt')
                          : (widget.applicationMode
                              ? l10n.mentorApplicationSubmit
                              : 'Gửi hồ sơ xét duyệt'),
                      loadingLabel: widget.applicationMode
                          ? l10n.mentorApplicationSubmitting
                          : 'Đang gửi...',
                      leadingIcon: Icons.send_outlined,
                      isLoading: _isSubmitting,
                      onPressed: (p.isPending || _isSubmitting)
                          ? null
                          : () => _handleUnifiedSubmit(context, ref),
                    ),
                  ] else ...[
                    // For already approved mentor updating profile
                    RikiPrimaryButton(
                      key: const Key('mentor_profile_save_button'),
                      label: _isSaving ? 'Đang lưu...' : 'Lưu cập nhật hồ sơ',
                      leadingIcon: Icons.save_outlined,
                      onPressed: _isSaving ? null : () => _saveProfileOnly(ref),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // 3. Review Status Section (At bottom)
            _buildVerificationStatusCard(context, p),
            const SizedBox(height: AppSpacing.space5),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationStatusCard(
    BuildContext context,
    MentorProfileData p,
  ) {
    final statusColor = p.isApproved
        ? AppColors.brandPrimary
        : (p.isPending
            ? AppColors.warning
            : (p.isRejected ? AppColors.error : AppColors.textMuted));

    final statusText = p.isApproved
        ? 'Đã xác minh (Hoạt động)'
        : (p.isPending
            ? (widget.applicationMode
                ? context.l10n.mentorApplicationPending
                : 'Đang chờ xét duyệt')
            : (p.isRejected
                ? 'Hồ sơ bị từ chối'
                : (p.isChangesRequested
                    ? 'Yêu cầu bổ sung thông tin'
                    : 'Chưa nộp xét duyệt')));

    return RikiCard(
      borderColor: statusColor.withValues(alpha: 0.3),
      backgroundColor: statusColor.withValues(alpha: 0.04),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                p.isApproved ? Icons.verified : Icons.verified_user_outlined,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.applicationMode
                          ? context.l10n.mentorApplicationStatusLabel
                          : 'Trạng thái xét duyệt',
                      style: AppTypography.cardTitle,
                    ),
                    Text(
                      statusText,
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (p.isRejected && p.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Lý do từ chối: ${p.rejectionReason}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          if (p.isChangesRequested && p.reviewNotes != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Ghi chú yêu cầu: ${p.reviewNotes}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ],
          if (p.isPending) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Hồ sơ của bạn đã được gửi tới Quản trị viên và đang trong quá trình xét duyệt.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleUnifiedSubmit(BuildContext context, WidgetRef ref) {
    final bio = _bioController.text.trim();
    final expertise = _expertiseController.text.trim();
    final jlpt = _selectedJlpt;
    final p = widget.profile;

    if (bio.isEmpty) {
      ref.read(rikiToastServiceProvider.notifier).warning(
            title: 'Chưa điền thông tin',
            description: 'Vui lòng nhập Giới thiệu bản thân (*).',
          );
      return;
    }

    if (expertise.isEmpty) {
      ref.read(rikiToastServiceProvider.notifier).warning(
            title: 'Chưa điền thông tin',
            description: 'Vui lòng nhập Lĩnh vực chuyên môn (*).',
          );
      return;
    }

    if (jlpt == null || jlpt.isEmpty) {
      ref.read(rikiToastServiceProvider.notifier).warning(
            title: 'Chưa chọn trình độ',
            description: 'Vui lòng chọn Trình độ tiếng Nhật (*).',
          );
      return;
    }

    if (!p.hasVerificationDocument) {
      ref.read(rikiToastServiceProvider.notifier).warning(
            title: 'Chưa tải chứng chỉ',
            description: 'Vui lòng chọn và tải chứng chỉ trước khi gửi hồ sơ.',
          );
      return;
    }

    _showSubmitVerificationDialog(context, ref);
  }

  Future<void> _saveProfileOnly(WidgetRef ref) async {
    setState(() => _isSaving = true);
    final expVal = int.tryParse(_expController.text.trim());
    final ok = await ref
        .read(mentorProfileControllerProvider.notifier)
        .updateProfile(
          bio: _bioController.text.trim(),
          expertise: _expertiseController.text.trim(),
          jlptLevel: _selectedJlpt,
          yearsOfExperience: expVal,
          workplace: _workplaceController.text.trim(),
          introductionVideoUrl: _videoUrlController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      ref.read(rikiToastServiceProvider.notifier).success(
            title: 'Cập nhật thành công',
            description: 'Hồ sơ chuyên gia của bạn đã được lưu.',
          );
    } else {
      ref.read(rikiToastServiceProvider.notifier).error(
            title: 'Cập nhật thất bại',
            description: 'Không thể lưu hồ sơ. Vui lòng kiểm tra lại.',
          );
    }
  }

  void _showSubmitVerificationDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Nộp hồ sơ xét duyệt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thông tin chuyên môn và chứng chỉ đã tải lên sẽ được gửi để Quản trị viên xét duyệt.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.space3),
              TextField(
                key: const Key('submit_verification_notes_input'),
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú cho Quản trị viên',
                  hintText: 'Chứng chỉ JLPT N1 năm 2024, kinh nghiệm 3 năm...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            key: const Key('confirm_submit_verification_button'),
            onPressed: () async {
              if (_isSubmitting) return;
              Navigator.of(dialogCtx).pop();
              setState(() => _isSubmitting = true);

              // 1. Save profile information first
              final expVal = int.tryParse(_expController.text.trim());
              final okUpdate = await ref
                  .read(mentorProfileControllerProvider.notifier)
                  .updateProfile(
                    bio: _bioController.text.trim(),
                    expertise: _expertiseController.text.trim(),
                    jlptLevel: _selectedJlpt,
                    yearsOfExperience: expVal,
                    workplace: _workplaceController.text.trim(),
                    introductionVideoUrl: _videoUrlController.text.trim(),
                  );
              if (!okUpdate) {
                if (!mounted) return;
                setState(() => _isSubmitting = false);
                ref.read(rikiToastServiceProvider.notifier).error(
                      title: 'Cập nhật thất bại',
                      description: 'Không thể lưu hồ sơ. Vui lòng kiểm tra lại.',
                    );
                return;
              }

              // 2. Submit verification
              final okSubmit = await ref
                  .read(mentorProfileControllerProvider.notifier)
                  .submitVerification(notes: notesController.text.trim());
              if (!mounted) return;
              setState(() => _isSubmitting = false);
              if (okSubmit) {
                ref.read(rikiToastServiceProvider.notifier).success(
                      title: 'Nộp hồ sơ thành công',
                      description:
                          'Hồ sơ của bạn đã được gửi tới Quản trị viên để xét duyệt.',
                    );
              } else {
                ref.read(rikiToastServiceProvider.notifier).error(
                      title: 'Nộp hồ sơ thất bại',
                      description:
                          'Không thể gửi hồ sơ xét duyệt. Vui lòng thử lại.',
                    );
              }
            },
            child: const Text('Gửi xét duyệt'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(WidgetRef ref) async {
    setState(() => _isUploadingDocument = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (file == null || !mounted) return;
      final length = await file.length();
      if (length == null || length <= 0 || length > 5 * 1024 * 1024) {
        ref.read(rikiToastServiceProvider.notifier).error(
              title: 'Tài liệu không hợp lệ',
              description: 'Chứng chỉ phải nhỏ hơn 5 MB.',
            );
        return;
      }
      final bytes = await file.readAsBytes();
      final ok = await ref
          .read(mentorProfileControllerProvider.notifier)
          .uploadVerificationDocument(bytes: bytes, fileName: file.name);
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).info(
            title: ok ? 'Đã tải chứng chỉ' : 'Không thể tải chứng chỉ',
            description: ok
                ? 'Tài liệu được lưu trong kho riêng tư.'
                : 'Vui lòng thử lại hoặc liên hệ hỗ trợ.',
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).error(
            title: 'Không thể mở tài liệu',
            description: 'Vui lòng chọn lại PDF, JPEG hoặc PNG.',
          );
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }
}
