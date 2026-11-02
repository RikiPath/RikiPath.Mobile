import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorProfileScreen extends ConsumerWidget {
  const MentorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorProfileControllerProvider);

    return Scaffold(
      key: const Key('mentor_profile_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: const Text('Hồ sơ cố vấn')),
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
          AsyncData(:final value) => _MentorProfileForm(profile: value),
        },
      ),
    );
  }
}

class _MentorProfileForm extends StatefulWidget {
  const _MentorProfileForm({required this.profile});

  final MentorProfileData profile;

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

    return Consumer(
      builder: (context, ref, _) {
        return ListView(
          key: const Key('mentor_profile_scroll'),
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            // Header card
            RikiCard(
              borderColor: AppColors.border,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
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
                        if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty)
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
            ),
            const SizedBox(height: AppSpacing.space4),

            // Verification status card
            _buildVerificationCard(context, ref, p),
            const SizedBox(height: AppSpacing.space4),

            // Profile info section
            RikiCard(
              borderColor: AppColors.border,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Thông tin chuyên môn',
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
                    decoration: const InputDecoration(
                      labelText: 'Giới thiệu bản thân (Bio)',
                      hintText:
                          'Kinh nghiệm giảng dạy, phương pháp hướng dẫn...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Expertise
                  TextField(
                    key: const Key('mentor_profile_expertise_input'),
                    controller: _expertiseController,
                    decoration: const InputDecoration(
                      labelText: 'Lĩnh vực chuyên môn',
                      hintText: 'JLPT N1, N2, Giao tiếp thương mại...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // JLPT Level
                  DropdownButtonFormField<String>(
                    key: const Key('mentor_profile_jlpt_input'),
                    initialValue: _selectedJlpt,
                    decoration: const InputDecoration(
                      labelText: 'Trình độ tiếng Nhật',
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
                    onChanged: (val) => setState(() => _selectedJlpt = val),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Years of Experience
                  TextField(
                    key: const Key('mentor_profile_exp_input'),
                    controller: _expController,
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
                    decoration: const InputDecoration(
                      labelText: 'Link video giới thiệu (YouTube / Drive)',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Save button
                  RikiPrimaryButton(
                    key: const Key('mentor_profile_save_button'),
                    label: _isSaving ? 'Đang lưu...' : 'Lưu cập nhật hồ sơ',
                    leadingIcon: Icons.save_outlined,
                    onPressed: _isSaving
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            final expVal = int.tryParse(
                              _expController.text.trim(),
                            );
                            final ok = await ref
                                .read(mentorProfileControllerProvider.notifier)
                                .updateProfile(
                                  bio: _bioController.text.trim(),
                                  expertise: _expertiseController.text.trim(),
                                  jlptLevel: _selectedJlpt,
                                  yearsOfExperience: expVal,
                                  workplace: _workplaceController.text.trim(),
                                  introductionVideoUrl: _videoUrlController.text
                                      .trim(),
                                );
                            if (!mounted) return;
                            setState(() => _isSaving = false);
                            if (ok) {
                              ref
                                  .read(rikiToastServiceProvider.notifier)
                                  .success(
                                    title: 'Cập nhật thành công',
                                    description:
                                        'Hồ sơ chuyên gia của bạn đã được lưu.',
                                  );
                            } else {
                              ref
                                  .read(rikiToastServiceProvider.notifier)
                                  .error(
                                    title: 'Cập nhật thất bại',
                                    description:
                                        'Không thể lưu hồ sơ. Vui lòng kiểm tra lại.',
                                  );
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
          ],
        );
      },
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    WidgetRef ref,
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
              ? 'Đang chờ xét duyệt'
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
              Text(
                'Trạng thái xét duyệt: ',
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  statusText,
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
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
          if (!p.isApproved) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              p.hasVerificationDocument
                  ? 'Chứng chỉ đã được tải lên kho bảo vệ.'
                  : 'Vui lòng tải chứng chỉ PDF, JPEG hoặc PNG (tối đa 5 MB).',
            ),
            if (!p.isPending) ...[
              const SizedBox(height: AppSpacing.space2),
              RikiSecondaryButton(
                key: const Key('mentor_upload_verification_document_button'),
                label: _isUploadingDocument
                    ? 'Đang tải chứng chỉ...'
                    : 'Chọn và tải chứng chỉ',
                leadingIcon: Icons.upload_file_outlined,
                onPressed: _isUploadingDocument
                    ? null
                    : () => _uploadDocument(ref),
              ),
            ],
            const SizedBox(height: AppSpacing.space2),
            RikiSecondaryButton(
              key: const Key('mentor_submit_verification_button'),
              label: p.isPending
                  ? 'Đang chờ xét duyệt'
                  : 'Nộp hồ sơ xin xét duyệt',
              leadingIcon: Icons.upload_file_outlined,
              onPressed: p.isPending || !p.hasVerificationDocument
                  ? null
                  : () => _showSubmitVerificationDialog(context, ref),
            ),
          ],
        ],
      ),
    );
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
                'Chứng chỉ đã tải lên sẽ được gửi để Quản trị viên xét duyệt.',
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
              Navigator.of(dialogCtx).pop();
              final ok = await ref
                  .read(mentorProfileControllerProvider.notifier)
                  .submitVerification(notes: notesController.text.trim());
              if (!mounted) return;
              if (ok) {
                ref
                    .read(rikiToastServiceProvider.notifier)
                    .success(
                      title: 'Nộp hồ sơ thành công',
                      description:
                          'Hồ sơ của bạn đã được gửi tới Quản trị viên để xét duyệt.',
                    );
              } else {
                ref
                    .read(rikiToastServiceProvider.notifier)
                    .error(
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
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
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
      ref
          .read(rikiToastServiceProvider.notifier)
          .info(
            title: ok ? 'Đã tải chứng chỉ' : 'Không thể tải chứng chỉ',
            description: ok
                ? 'Tài liệu được lưu trong kho riêng tư.'
                : 'Vui lòng thử lại hoặc liên hệ hỗ trợ.',
          );
    } catch (_) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: 'Không thể mở tài liệu',
            description: 'Vui lòng chọn lại PDF, JPEG hoặc PNG.',
          );
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }
}
