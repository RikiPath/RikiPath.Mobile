import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/data/profile_avatar_picker.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_components.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  String? _fullNameError;
  bool _initialized = false;
  bool _isDirty = false;
  String _baselineFullName = '';

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_syncDirty);
  }

  void _syncDirty() {
    if (!_initialized) return;
    final dirty = _fullNameController.text.trim() != _baselineFullName;
    if (dirty != _isDirty && mounted) {
      setState(() => _isDirty = dirty);
    }
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_syncDirty);
    _fullNameController.dispose();
    super.dispose();
  }

  void _initialize(UserProfile profile) {
    _baselineFullName = profile.fullName.trim();
    if (_initialized) return;
    _fullNameController.text = profile.fullName;
    _initialized = true;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final fullName = _fullNameController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    setState(() {
      _fullNameError = fullName.isEmpty
          ? (Localizations.localeOf(context).languageCode == 'ja'
                ? '氏名を入力してください。'
                : 'Vui lòng nhập họ và tên.')
          : null;
    });
    if (_fullNameError != null) return;

    await ref
        .read(userProfileControllerProvider.notifier)
        .updateName(fullName: fullName);
  }

  Future<void> _pickAvatar() async {
    try {
      final upload = await ref
          .read(profileAvatarPickerProvider)
          .pickFromGallery();
      if (!mounted || upload == null) return;
      final confirmed = await _confirmAvatar(upload.bytes);
      if (!mounted || !confirmed) return;

      await ref
          .read(userProfileControllerProvider.notifier)
          .uploadAvatar(upload);
    } on UnsupportedAvatarTypeException {
      _showError(ref.read(appLocalizationsProvider).avatarUnsupportedType);
    } on AvatarTooLargeException {
      _showError(ref.read(appLocalizationsProvider).avatarTooLarge);
    } catch (_) {
      _showError(ref.read(appLocalizationsProvider).avatarPickerFailed);
    }
  }

  Future<bool> _confirmAvatar(Uint8List bytes) async {
    return showProfileConfirmationSheet(
      context: context,
      icon: Icons.photo_camera_outlined,
      title: context.l10n.confirmAvatarTitle,
      message: context.l10n.confirmAvatarMessage,
      confirmLabel: context.l10n.confirmUpload,
      cancelLabel: context.l10n.cancel,
      confirmKey: const ValueKey<String>('avatar_confirm_upload'),
      preview: ClipOval(
        child: Image.memory(
          bytes,
          key: const ValueKey<String>('avatar_preview'),
          width: 112,
          height: 112,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    final l10n = ref.read(appLocalizationsProvider);
    ref
        .read(rikiToastServiceProvider.notifier)
        .error(title: l10n.toastActionFailedTitle, description: message);
  }

  @override
  Widget build(BuildContext context) {
    final profileValue = ref.watch(userProfileControllerProvider);
    final mutation = profileValue.value?.activeMutation;
    final loadedProfile = profileValue.value?.profile;
    final hasUnsavedChanges =
        _initialized &&
        loadedProfile != null &&
        mutation == null &&
        _fullNameController.text.trim() != loadedProfile.fullName.trim();
    final canPopRoute =
        !hasUnsavedChanges &&
        (GoRouter.maybeOf(context)?.canPop() ??
            (ModalRoute.of(context)?.canPop ?? true));
    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          handleProtectedBackNavigation(
            context: context,
            hasUnsavedChanges: hasUnsavedChanges,
            fallbackRoute: AppRoutes.profileAccount,
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            backgroundColor: AppColors.profileBackground,
            appBar: ProfileDetailHeader(
              title: context.l10n.profileEdit,
              onBack: () => handleProtectedBackNavigation(
                context: context,
                hasUnsavedChanges: hasUnsavedChanges,
                fallbackRoute: AppRoutes.profileAccount,
              ),
            ),
      body: profileValue.when(
        loading: () => const ProfileDetailSkeleton(
          key: ValueKey<String>('profile_edit_loading_view'),
          groupCount: 1,
          rowsPerGroup: 2,
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RikiErrorBanner(
                  title: context.l10n.profileLoadFailedTitle,
                  message: userProfileErrorMessage(error, context.l10n),
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiSecondaryButton(
                  label: context.l10n.retry,
                  onPressed: () =>
                      ref.read(userProfileControllerProvider.notifier).retry(),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          _initialize(state.profile);
          final isSaving = state.activeMutation == ProfileMutation.profile;
          final isUploading = state.activeMutation == ProfileMutation.avatar;
          final isBusy = state.activeMutation != null;

          return ProfileAnimatedEntrance(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space3,
                AppSpacing.space4,
                AppSpacing.space8,
              ),
              children: [
                ProfileSurface(
                  backgroundColor: AppColors.profileAccentSurface,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.96,
                                      end: 1,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: KeyedSubtree(
                              key: ValueKey<String?>(state.profile.avatarUrl),
                              child: ProfileAvatar(
                                avatarUrl: state.profile.avatarUrl,
                                radius: 52,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Material(
                              color: AppColors.brandPrimary,
                              shape: const CircleBorder(),
                              child: IconButton(
                                key: const ValueKey<String>(
                                  'profile_avatar_action',
                                ),
                                tooltip: context.l10n.editAvatar,
                                color: AppColors.surface,
                                onPressed: isBusy ? null : _pickAvatar,
                                icon: isUploading
                                    ? RikiInlineLoader(
                                        size: 20,
                                        color: AppColors.surface,
                                        semanticsLabel:
                                            context.l10n.uploadingAvatar,
                                      )
                                    : const Icon(Icons.photo_camera_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      Text(
                        state.profile.fullName,
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        state.profile.email,
                        textAlign: TextAlign.center,
                        style: AppTypography.metadata,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      TextButton.icon(
                        onPressed: isBusy ? null : _pickAvatar,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(context.l10n.chooseAvatar),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                ProfileFormSection(
                  title: context.l10n.profileNameSection,
                  child: RikiTextField(
                    key: const ValueKey<String>('profile_full_name_field'),
                    label: context.l10n.fullName,
                    hintText: context.l10n.fullNameHint,
                    controller: _fullNameController,
                    errorText: _fullNameError,
                    enabled: !isBusy,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    onChanged: (_) {
                      if (_fullNameError != null) {
                        setState(() => _fullNameError = null);
                      }
                    },
                    onSubmitted: (_) {
                      if (!isBusy) _submit();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                RikiPrimaryButton(
                  key: const ValueKey<String>('profile_save_button'),
                  label: context.l10n.saveChanges,
                  loadingLabel: context.l10n.savingChanges,
                  isLoading: isSaving,
                  onPressed: isBusy ? null : _submit,
                ),
              ],
            ),
          );
        },
      ),
        ),
        AppLoadingOverlay(
          visible: mutation != null,
          title: mutation == ProfileMutation.avatar
              ? context.l10n.uploadingAvatar
              : context.l10n.loadingOverlaySavingTitle,
          subtitle: context.l10n.loadingOverlayUpdatingSubtitle,
        ),
      ],
      ),
    );
  }
}
