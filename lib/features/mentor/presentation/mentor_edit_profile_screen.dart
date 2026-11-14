import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_components.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class MentorEditProfileScreen extends ConsumerWidget {
  const MentorEditProfileScreen({this.applicationMode = false, super.key});

  final bool applicationMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(mentorProfileControllerProvider);
    final fallbackRoute = applicationMode
        ? AppRoutes.home
        : AppRoutes.mentorProfile;

    return switch (state) {
      AsyncData(:final value) => _MentorEditProfileForm(
        profile: value,
        applicationMode: applicationMode,
      ),
      AsyncLoading() => Scaffold(
        key: applicationMode
            ? const Key('mentor_profile_screen')
            : const Key('mentor_edit_profile_screen'),
        backgroundColor: AppColors.profileBackground,
        appBar: ProfileDetailHeader(
          title: applicationMode
              ? l10n.mentorApplicationTitle
              : l10n.profileEdit,
          fallbackRoute: fallbackRoute,
        ),
        body: const ProfileDetailSkeleton(
          key: Key('mentor_profile_loading'),
          groupCount: 2,
          rowsPerGroup: 3,
        ),
      ),
      AsyncError(:final error) => Scaffold(
        key: applicationMode
            ? const Key('mentor_profile_screen')
            : const Key('mentor_edit_profile_screen'),
        backgroundColor: AppColors.profileBackground,
        appBar: ProfileDetailHeader(
          title: applicationMode
              ? l10n.mentorApplicationTitle
              : l10n.profileEdit,
          fallbackRoute: fallbackRoute,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: RikiErrorState(
              title: l10n.mentorProfileErrorLoad,
              message: appErrorMessage(error, l10n),
              actionLabel: l10n.retry,
              onAction: () =>
                  ref.read(mentorProfileControllerProvider.notifier).retry(),
            ),
          ),
        ),
      ),
    };
  }
}

class _MentorEditProfileForm extends ConsumerStatefulWidget {
  const _MentorEditProfileForm({
    required this.profile,
    required this.applicationMode,
  });

  final MentorProfileData profile;
  final bool applicationMode;

  @override
  ConsumerState<_MentorEditProfileForm> createState() =>
      _MentorEditProfileFormState();
}

class _MentorEditProfileFormState
    extends ConsumerState<_MentorEditProfileForm> {
  static const List<String> _jlptOptions = ['N1', 'N2', 'N3', 'Native'];

  late TextEditingController _bioController;
  late TextEditingController _expertiseController;
  late TextEditingController _expController;
  late TextEditingController _workplaceController;
  late TextEditingController _videoUrlController;
  String? _selectedJlpt;

  late String _baselineBio;
  late String _baselineExpertise;
  String? _baselineJlpt;
  late String _baselineExp;
  late String _baselineWorkplace;
  late String _baselineVideo;

  String? _bioError;
  String? _expertiseError;
  String? _jlptError;
  String? _expError;
  String? _videoError;

  bool _isSaving = false;
  bool _isUploadingDocument = false;
  bool _isSubmitting = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _expertiseController = TextEditingController();
    _expController = TextEditingController();
    _workplaceController = TextEditingController();
    _videoUrlController = TextEditingController();
    _applyProfileToFields(widget.profile, resetControllers: true);

    _bioController.addListener(_onFieldChanged);
    _expertiseController.addListener(_onFieldChanged);
    _expController.addListener(_onFieldChanged);
    _workplaceController.addListener(_onFieldChanged);
    _videoUrlController.addListener(_onFieldChanged);
  }

  @override
  void didUpdateWidget(covariant _MentorEditProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      final wasDirty = _hasUnsavedChanges();
      _applyProfileToFields(widget.profile, resetControllers: !wasDirty);
    }
  }

  @override
  void dispose() {
    _bioController.removeListener(_onFieldChanged);
    _expertiseController.removeListener(_onFieldChanged);
    _expController.removeListener(_onFieldChanged);
    _workplaceController.removeListener(_onFieldChanged);
    _videoUrlController.removeListener(_onFieldChanged);
    _bioController.dispose();
    _expertiseController.dispose();
    _expController.dispose();
    _workplaceController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  String? _normalizeJlpt(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    for (final option in _jlptOptions) {
      if (option.toLowerCase() == trimmed.toLowerCase()) return option;
    }
    return null;
  }

  void _applyProfileToFields(
    MentorProfileData profile, {
    required bool resetControllers,
  }) {
    _baselineBio = (profile.bio ?? '').trim();
    _baselineExpertise = (profile.expertise ?? '').trim();
    _baselineJlpt = _normalizeJlpt(profile.jlptLevel);
    _baselineExp = profile.yearsOfExperience?.toString() ?? '';
    _baselineWorkplace = (profile.workplace ?? '').trim();
    _baselineVideo = (profile.introductionVideoUrl ?? '').trim();

    if (resetControllers) {
      _bioController.text = profile.bio ?? '';
      _expertiseController.text = profile.expertise ?? '';
      _selectedJlpt = _baselineJlpt;
      _expController.text = _baselineExp;
      _workplaceController.text = profile.workplace ?? '';
      _videoUrlController.text = profile.introductionVideoUrl ?? '';
      _isDirty = false;
    }
  }

  void _syncBaselineFromCurrentInputs() {
    final lockedApproved = !widget.applicationMode && widget.profile.isApproved;
    _baselineBio = _bioController.text.trim();
    _baselineVideo = _videoUrlController.text.trim();
    if (!lockedApproved) {
      _baselineExpertise = _expertiseController.text.trim();
      _baselineJlpt = _selectedJlpt;
      _baselineExp = _expController.text.trim();
      _baselineWorkplace = _workplaceController.text.trim();
    }
    if (mounted) {
      setState(() => _isDirty = false);
    }
  }

  void _onFieldChanged() {
    if (!mounted) return;
    final dirty = _hasUnsavedChanges();
    if (dirty != _isDirty ||
        _bioError != null ||
        _expertiseError != null ||
        _expError != null ||
        _videoError != null) {
      setState(() {
        _isDirty = dirty;
        if (_bioController.text.trim().isNotEmpty) _bioError = null;
        if (_expertiseController.text.trim().isNotEmpty) {
          _expertiseError = null;
        }
        _expError = null;
        _videoError = null;
      });
    }
  }

  bool _hasUnsavedChanges() {
    return _bioController.text.trim() != _baselineBio ||
        _expertiseController.text.trim() != _baselineExpertise ||
        _selectedJlpt != _baselineJlpt ||
        _expController.text.trim() != _baselineExp ||
        _workplaceController.text.trim() != _baselineWorkplace ||
        _videoUrlController.text.trim() != _baselineVideo;
  }

  int? _parseAndValidateExp(AppLocalizations l10n) {
    final raw = _expController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 50) {
      _expError = l10n.mentorProfileExpErrorInvalid;
      return -1;
    }
    return parsed;
  }

  bool _validateVideoUrl(AppLocalizations l10n) {
    final raw = _videoUrlController.text.trim();
    if (raw.isEmpty) return true;
    final parsed = parseSafeExternalHttpUri(raw);
    if (parsed == null) {
      _videoError = l10n.mentorProfileVideoErrorInvalid;
      return false;
    }
    return true;
  }

  bool _validateForSave(AppLocalizations l10n) {
    final isApproved = !widget.applicationMode && widget.profile.isApproved;
    String? bioErr;
    String? expErr;
    String? videoErr;

    if (_bioController.text.trim().isEmpty) {
      bioErr = l10n.mentorProfileValidationBioRequired;
    }
    if (!isApproved) {
      final rawExp = _expController.text.trim();
      if (rawExp.isNotEmpty) {
        final parsed = int.tryParse(rawExp);
        if (parsed == null || parsed < 0 || parsed > 50) {
          expErr = l10n.mentorProfileExpErrorInvalid;
        }
      }
    }
    if (_videoUrlController.text.trim().isNotEmpty &&
        parseSafeExternalHttpUri(_videoUrlController.text.trim()) == null) {
      videoErr = l10n.mentorProfileVideoErrorInvalid;
    }

    setState(() {
      _bioError = bioErr;
      _expertiseError = null;
      _jlptError = null;
      _expError = expErr;
      _videoError = videoErr;
    });

    return bioErr == null && expErr == null && videoErr == null;
  }

  bool _validateForSubmit(AppLocalizations l10n) {
    String? bioErr;
    String? expertiseErr;
    String? jlptErr;

    if (_bioController.text.trim().isEmpty) {
      bioErr = l10n.mentorProfileValidationBioRequired;
    }
    if (_expertiseController.text.trim().isEmpty) {
      expertiseErr = l10n.mentorProfileValidationExpertiseRequired;
    }
    if (_selectedJlpt == null) {
      jlptErr = l10n.mentorProfileValidationJlptRequired;
    }

    _expError = null;
    _videoError = null;
    final exp = _parseAndValidateExp(l10n);
    final videoValid = _validateVideoUrl(l10n);

    setState(() {
      _bioError = bioErr;
      _expertiseError = expertiseErr;
      _jlptError = jlptErr;
    });

    if (bioErr != null) {
      _showWarningToast(
        l10n.mentorProfileValidationMissingTitle,
        bioErr,
      );
      return false;
    }
    if (expertiseErr != null) {
      _showWarningToast(
        l10n.mentorProfileValidationMissingTitle,
        expertiseErr,
      );
      return false;
    }
    if (jlptErr != null) {
      _showWarningToast(
        l10n.mentorProfileValidationMissingTitle,
        jlptErr,
      );
      return false;
    }
    if (exp == -1 || !videoValid) {
      return false;
    }
    if (!widget.profile.hasVerificationDocument) {
      _showWarningToast(
        l10n.mentorProfileValidationMissingTitle,
        l10n.mentorProfileValidationCertRequired,
      );
      return false;
    }
    return true;
  }

  void _showWarningToast(String title, String description) {
    ref
        .read(rikiToastServiceProvider.notifier)
        .warning(title: title, description: description);
  }

  Future<void> _saveProfileOnly() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    if (!_validateForSave(l10n)) return;

    setState(() => _isSaving = true);
    final lockedApproved = !widget.applicationMode && widget.profile.isApproved;
    final expVal = lockedApproved
        ? widget.profile.yearsOfExperience
        : int.tryParse(_expController.text.trim());
    final jlptVal = lockedApproved ? widget.profile.jlptLevel : _selectedJlpt;
    final expertiseVal = lockedApproved
        ? widget.profile.expertise
        : _expertiseController.text.trim();
    final workplaceVal = lockedApproved
        ? widget.profile.workplace
        : _workplaceController.text.trim();

    final ok = await runWithAppLoadingOverlay(
      context,
      title: l10n.loadingOverlaySavingTitle,
      subtitle: l10n.loadingOverlayUpdatingSubtitle,
      action: () => ref
          .read(mentorProfileControllerProvider.notifier)
          .updateProfile(
            bio: _bioController.text.trim(),
            expertise: expertiseVal,
            jlptLevel: jlptVal,
            yearsOfExperience: expVal,
            workplace: workplaceVal,
            introductionVideoUrl: _videoUrlController.text.trim(),
          ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    final toast = ref.read(rikiToastServiceProvider.notifier);
    if (ok) {
      _syncBaselineFromCurrentInputs();
      toast.success(
        title: l10n.mentorProfileSaveSuccessTitle,
        description: l10n.mentorProfileSaveSuccessDesc,
      );
    } else {
      toast.error(
        title: l10n.mentorProfileSaveErrorTitle,
        description: l10n.mentorProfileSaveErrorDesc,
      );
    }
  }

  Future<void> _submitVerification() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    if (!_validateForSubmit(l10n)) return;
    _showSubmitVerificationDialog();
  }

  void _showSubmitVerificationDialog() {
    final l10n = context.l10n;
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.mentorProfileSubmitDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.mentorProfileSubmitDialogBody,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space3),
              TextField(
                key: const Key('submit_verification_notes_input'),
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.mentorProfileSubmitDialogNotesLabel,
                  hintText: l10n.mentorProfileSubmitDialogNotesHint,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_submit_verification_button'),
            onPressed: () async {
              final notes = notesController.text.trim();
              Navigator.of(dialogCtx).pop();
              await _performSubmitVerification(notes: notes);
            },
            child: Text(l10n.mentorProfileSubmitConfirmAction),
          ),
        ],
      ),
    );
  }

  Future<void> _performSubmitVerification({required String notes}) async {
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);
    final expVal = int.tryParse(_expController.text.trim());
    final notifier = ref.read(mentorProfileControllerProvider.notifier);

    final (okUpdate, okSubmit) = await runWithAppLoadingOverlay<(bool, bool)>(
      context,
      title: l10n.mentorApplicationSubmitting,
      subtitle: l10n.loadingOverlayCompletingSubtitle,
      action: () async {
        final updated = await notifier.updateProfile(
          bio: _bioController.text.trim(),
          expertise: _expertiseController.text.trim(),
          jlptLevel: _selectedJlpt,
          yearsOfExperience: expVal,
          workplace: _workplaceController.text.trim(),
          introductionVideoUrl: _videoUrlController.text.trim(),
        );
        if (!updated) return (false, false);
        final submitted = await notifier.submitVerification(notes: notes);
        return (true, submitted);
      },
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final toast = ref.read(rikiToastServiceProvider.notifier);
    if (!okUpdate) {
      toast.error(
        title: l10n.mentorProfileSaveErrorTitle,
        description: l10n.mentorProfileSaveErrorDesc,
      );
      return;
    }
    _syncBaselineFromCurrentInputs();
    if (okSubmit) {
      toast.success(
        title: l10n.mentorProfileSubmitSuccessTitle,
        description: l10n.mentorProfileSubmitSuccessDesc,
      );
    } else {
      toast.error(
        title: l10n.mentorProfileSubmitErrorTitle,
        description: l10n.mentorProfileSubmitErrorDesc,
      );
    }
  }

  Future<void> _uploadDocument() async {
    final l10n = context.l10n;
    setState(() => _isUploadingDocument = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (file == null || !mounted) return;
      final length = await file.length();
      if (length == null || length <= 0 || length > 5 * 1024 * 1024) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: l10n.mentorProfileDocInvalidTitle,
              description: l10n.mentorProfileDocTooLarge,
            );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final ok = await runWithAppLoadingOverlay(
        context,
        title: l10n.mentorApplicationUploading,
        subtitle: l10n.loadingOverlayUpdatingSubtitle,
        action: () => ref
            .read(mentorProfileControllerProvider.notifier)
            .uploadVerificationDocument(bytes: bytes, fileName: file.name),
      );
      if (!mounted) return;
      final toast = ref.read(rikiToastServiceProvider.notifier);
      if (ok) {
        toast.success(
          title: l10n.mentorProfileDocUploadedTitle,
          description: l10n.mentorProfileDocUploadedDesc,
        );
      } else {
        toast.error(
          title: l10n.mentorProfileDocUploadFailedTitle,
          description: l10n.mentorProfileDocUploadFailedDesc,
        );
      }
    } catch (_) {
      if (mounted) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: l10n.mentorProfileDocOpenFailedTitle,
              description: l10n.mentorProfileDocOpenFailedDesc,
            );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }

  Future<void> _viewUploadedDocument() async {
    final l10n = context.l10n;
    try {
      final doc = await runWithAppLoadingOverlay<MentorVerificationDocumentData>(
        context,
        title: l10n.mentorProfileDocumentLoading,
        action: () => ref
            .read(mentorOperationsRepositoryProvider)
            .loadVerificationDocument(),
      );
      if (!mounted) return;

      final bytes = doc.bytes;
      final signedUri = parseSafeExternalHttpUri(doc.signedUrl);

      if (bytes != null && bytes.isNotEmpty && doc.isImage) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: AppColors.cardWarmWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.mentorProfileViewDocument,
                          style: AppTypography.cardTitle,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: InteractiveViewer(
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      if (bytes != null && bytes.isNotEmpty && doc.isPdf) {
        final sizeKb = (bytes.length / 1024).clamp(1, 99999).round();
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.mentorProfileViewDocument),
            content: Text(l10n.mentorProfileDocumentPdfReady(sizeKb)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
              if (signedUri != null)
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final opened = await ref
                        .read(mentorMeetingLinkLauncherProvider)
                        .open(signedUri);
                    if (!opened && mounted) {
                      ref
                          .read(rikiToastServiceProvider.notifier)
                          .error(title: l10n.mentorProfileDocumentError);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.mentorProfileDocumentOpenExternal),
                ),
            ],
          ),
        );
        return;
      }

      if (signedUri != null) {
        final opened = await ref
            .read(mentorMeetingLinkLauncherProvider)
            .open(signedUri);
        if (!opened && mounted) {
          ref
              .read(rikiToastServiceProvider.notifier)
              .error(title: l10n.mentorProfileDocumentError);
        }
        return;
      }

      ref
          .read(rikiToastServiceProvider.notifier)
          .error(title: l10n.mentorProfileDocumentError);
    } catch (error) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: l10n.mentorProfileDocumentError,
            description: appErrorMessage(error, l10n),
          );
    }
  }

  void _handleBack() {
    final l10n = context.l10n;
    final fallbackRoute = widget.applicationMode
        ? AppRoutes.home
        : AppRoutes.mentorProfile;
    handleProtectedBackNavigation(
      context: context,
      hasUnsavedChanges: _hasUnsavedChanges(),
      fallbackRoute: fallbackRoute,
      title: l10n.discardChangesTitle,
      message: l10n.discardChangesMessage,
      stayLabel: l10n.discardChangesStay,
      discardLabel: l10n.discardChangesLeave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = widget.profile;
    final hasUnsavedChanges = _hasUnsavedChanges();
    final canPopRoute =
        !hasUnsavedChanges &&
        (GoRouter.maybeOf(context)?.canPop() ??
            (ModalRoute.of(context)?.canPop ?? true));
    final isLockedForApproved = !widget.applicationMode && p.isApproved;
    final canEditAllExpertise = !p.isPending && !isLockedForApproved;
    final isBusy = _isSaving || _isSubmitting || _isUploadingDocument;

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        key: widget.applicationMode
            ? const Key('mentor_profile_screen')
            : const Key('mentor_edit_profile_screen'),
        backgroundColor: AppColors.profileBackground,
        appBar: ProfileDetailHeader(
          title: widget.applicationMode
              ? l10n.mentorApplicationTitle
              : l10n.profileEdit,
          onBack: _handleBack,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const Key('mentor_edit_profile_scroll'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ProfileAnimatedEntrance(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.applicationMode) ...[
                    RikiInfoBanner(
                      icon: Icons.workspace_premium_outlined,
                      message: l10n.mentorApplicationIntro,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    ProfileFormSection(
                      title: l10n.mentorApplicationStatusLabel,
                      child: Row(
                        children: [
                          Icon(
                            p.isPending
                                ? Icons.hourglass_top_rounded
                                : (p.isApproved
                                    ? Icons.verified_outlined
                                    : Icons.pending_outlined),
                            size: 18,
                            color: p.isPending
                                ? AppColors.warningText
                                : (p.isApproved
                                    ? AppColors.success
                                    : AppColors.textSecondary),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Text(
                              p.isPending
                                  ? l10n.mentorVerificationPending
                                  : (p.isApproved
                                      ? l10n.mentorVerificationApproved
                                      : (p.isRejected
                                          ? l10n.mentorVerificationRejected
                                          : (p.isChangesRequested
                                              ? l10n.mentorVerificationChangesRequested
                                              : l10n.mentorVerificationUnverified))),
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space5),
                  ],

                // 1. Personal account info (read-only per Backend contract)
                ProfileFormSection(
                  title: l10n.mentorApplicationPersonal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProfileAvatar(
                          avatarUrl: p.avatarUrl,
                          radius: 46,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      _ReadOnlyPersonalRow(
                        icon: Icons.person_outline_rounded,
                        label: l10n.mentorProfilePersonalNameLabel,
                        value: p.fullName,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      _ReadOnlyPersonalRow(
                        icon: Icons.email_outlined,
                        label: l10n.mentorProfilePersonalEmailLabel,
                        value: p.email,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      _ReadOnlyPersonalRow(
                        icon: Icons.phone_outlined,
                        label: l10n.mentorProfilePersonalPhoneLabel,
                        value: (p.phoneNumber?.trim().isNotEmpty ?? false)
                            ? p.phoneNumber!.trim()
                            : '-',
                      ),
                      if (!widget.applicationMode) ...[
                        const SizedBox(height: AppSpacing.space3),
                        RikiInfoBanner(
                          key: const Key(
                            'mentor_profile_account_readonly_banner',
                          ),
                          message: l10n.mentorProfileAccountReadOnlyNote,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),

                // 2. Expertise & Verification
                ProfileFormSection(
                  title: l10n.mentorApplicationExpertise,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (p.isPending) ...[
                        RikiWarningBanner(
                          key: const Key('mentor_profile_pending_lock_banner'),
                          message: l10n.mentorProfilePendingLockedNotice,
                          icon: Icons.lock_clock_outlined,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ] else if (isLockedForApproved) ...[
                        RikiInfoBanner(
                          key: const Key('mentor_profile_approved_lock_banner'),
                          message: l10n.mentorProfileApprovedLockedNotice,
                          icon: Icons.verified_outlined,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ] else if (p.isRejected &&
                          (p.rejectionReason?.trim().isNotEmpty ?? false)) ...[
                        RikiErrorBanner(
                          title: l10n.mentorVerificationRejected,
                          message: l10n.mentorVerificationRejectionReason(
                            p.rejectionReason!.trim(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ] else if (p.isChangesRequested &&
                          (p.reviewNotes?.trim().isNotEmpty ?? false)) ...[
                        RikiWarningBanner(
                          title: l10n.mentorVerificationChangesRequested,
                          message: l10n.mentorVerificationReviewNotes(
                            p.reviewNotes!.trim(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ],

                      // Bio (multiline TextField styled consistently)
                      Text(
                        widget.applicationMode
                            ? l10n.mentorApplicationBioRequired
                            : l10n.mentorProfileBioLabel,
                        style: AppTypography.inputLabel,
                      ),
                      const SizedBox(height: AppSpacing.fieldLabelGap),
                      TextField(
                        key: const Key('mentor_profile_bio_input'),
                        controller: _bioController,
                        maxLines: 3,
                        enabled: !p.isPending && !isBusy,
                        decoration: InputDecoration(
                          hintText: l10n.mentorProfileBioHint,
                          errorText: _bioError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),

                      // Expertise
                      RikiTextField(
                        key: const Key('mentor_profile_expertise_input'),
                        label: widget.applicationMode
                            ? l10n.mentorApplicationExpertiseRequired
                            : l10n.mentorProfileExpertiseLabel,
                        hintText: l10n.mentorProfileExpertiseHint,
                        controller: _expertiseController,
                        errorText: _expertiseError,
                        enabled: canEditAllExpertise && !isBusy,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),

                      // JLPT Level
                      Text(
                        widget.applicationMode
                            ? l10n.mentorApplicationJlptRequired
                            : l10n.mentorProfileJlptLabel,
                        style: AppTypography.inputLabel,
                      ),
                      const SizedBox(height: AppSpacing.fieldLabelGap),
                      DropdownButtonFormField<String>(
                        key: const Key('mentor_profile_jlpt_input'),
                        isExpanded: true,
                        initialValue: _selectedJlpt,
                        decoration: InputDecoration(errorText: _jlptError),
                        items: [
                          const DropdownMenuItem(
                            value: 'N1',
                            child: Text('JLPT N1'),
                          ),
                          const DropdownMenuItem(
                            value: 'N2',
                            child: Text('JLPT N2'),
                          ),
                          const DropdownMenuItem(
                            value: 'N3',
                            child: Text('JLPT N3'),
                          ),
                          DropdownMenuItem(
                            value: 'Native',
                            child: Text(l10n.mentorProfileJlptNativeOption),
                          ),
                        ],
                        onChanged: (!canEditAllExpertise || isBusy)
                            ? null
                            : (val) => setState(() {
                                _selectedJlpt = val;
                                _jlptError = null;
                                _isDirty = _hasUnsavedChanges();
                              }),
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),

                      // Years of Experience
                      RikiTextField(
                        key: const Key('mentor_profile_exp_input'),
                        label: l10n.mentorProfileExpLabel,
                        hintText: l10n.mentorProfileExpHint,
                        controller: _expController,
                        errorText: _expError,
                        enabled: canEditAllExpertise && !isBusy,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),

                      // Workplace
                      RikiTextField(
                        key: const Key('mentor_profile_workplace_input'),
                        label: l10n.mentorProfileWorkplaceLabel,
                        hintText: l10n.mentorProfileWorkplaceHint,
                        controller: _workplaceController,
                        enabled: canEditAllExpertise && !isBusy,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),

                      // Video URL
                      RikiTextField(
                        key: const Key('mentor_profile_video_input'),
                        label: l10n.mentorProfileVideoLabel,
                        hintText: 'https://...',
                        controller: _videoUrlController,
                        errorText: _videoError,
                        enabled: !p.isPending && !isBusy,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: AppSpacing.space5),

                      // Verification Document Section
                      Text(
                        l10n.mentorProfileCertificateSection,
                        style: AppTypography.inputLabel,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  p.hasVerificationDocument
                                      ? Icons.check_circle
                                      : Icons.upload_file,
                                  color: p.hasVerificationDocument
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.space2),
                                Expanded(
                                  child: Text(
                                    p.hasVerificationDocument
                                        ? (widget.applicationMode
                                              ? l10n.mentorApplicationDocumentUploaded
                                              : l10n.mentorProfileDocumentUploadedNote)
                                        : (widget.applicationMode
                                              ? l10n.mentorApplicationDocumentRequired
                                              : l10n.mentorProfileDocumentRequiredNote),
                                    style: AppTypography.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            if (p.hasVerificationDocument) ...[
                              const SizedBox(height: AppSpacing.space2),
                              OutlinedButton.icon(
                                key: const Key(
                                  'mentor_view_verification_document_button',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                ),
                                onPressed: isBusy
                                    ? null
                                    : _viewUploadedDocument,
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: Text(l10n.mentorProfileViewDocument),
                              ),
                              if (canEditAllExpertise) ...[
                                const SizedBox(height: AppSpacing.space1),
                                TextButton.icon(
                                  key: const Key(
                                    'mentor_upload_verification_document_button',
                                  ),
                                  onPressed: isBusy ? null : _uploadDocument,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _isUploadingDocument
                                        ? l10n.mentorApplicationUploading
                                        : l10n.mentorProfileDocumentReplace,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      if (!p.hasVerificationDocument &&
                          canEditAllExpertise) ...[
                        const SizedBox(height: AppSpacing.space2),
                        RikiSecondaryButton(
                          key: const Key(
                            'mentor_upload_verification_document_button',
                          ),
                          label: _isUploadingDocument
                              ? l10n.mentorApplicationUploading
                              : l10n.mentorApplicationUpload,
                          onPressed: isBusy ? null : _uploadDocument,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space5),

                      // Primary / Secondary Action Buttons
                      if (canEditAllExpertise) ...[
                        if (!widget.applicationMode) ...[
                          RikiSecondaryButton(
                            key: const Key('mentor_profile_save_draft_button'),
                            label: _isSaving
                                ? l10n.mentorProfileSavingButton
                                : l10n.mentorProfileSaveDraftButton,
                            leadingIcon: Icons.save_outlined,
                            onPressed: isBusy ? null : _saveProfileOnly,
                          ),
                          const SizedBox(height: AppSpacing.space3),
                        ],
                        RikiPrimaryButton(
                          key: const Key('mentor_submit_verification_button'),
                          label: l10n.mentorApplicationSubmit,
                          loadingLabel: l10n.mentorApplicationSubmitting,
                          isLoading: _isSubmitting,
                          onPressed: isBusy ? null : _submitVerification,
                        ),
                      ] else if (p.isPending) ...[
                        RikiPrimaryButton(
                          key: const Key('mentor_submit_verification_button'),
                          label: l10n.mentorApplicationPending,
                          onPressed: null,
                        ),
                      ] else ...[
                        RikiPrimaryButton(
                          key: const Key('mentor_profile_save_button'),
                          label: _isSaving
                              ? l10n.mentorProfileSavingButton
                              : l10n.mentorProfileSaveButton,
                          leadingIcon: Icons.save_outlined,
                          isLoading: _isSaving,
                          onPressed: isBusy ? null : _saveProfileOnly,
                        ),
                      ],
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyPersonalRow extends StatelessWidget {
  const _ReadOnlyPersonalRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
