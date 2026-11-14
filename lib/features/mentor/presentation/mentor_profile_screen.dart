import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/core/widgets/sakura_scroll_scaffold.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_edit_profile_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_components.dart';

class MentorProfileScreen extends ConsumerWidget {
  const MentorProfileScreen({this.applicationMode = false, super.key});

  final bool applicationMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (applicationMode) {
      return const MentorEditProfileScreen(applicationMode: true);
    }

    final l10n = context.l10n;
    final state = ref.watch(mentorProfileControllerProvider);

    return SakuraScrollScaffold(
      key: const Key('mentor_profile_screen'),
      backgroundColor: AppColors.profileBackground,
      appBarBuilder: (context, isScrolled) => SakuraAppHeader(
        isScrolled: isScrolled,
        showStreak: false,
        calendarTooltip: l10n.mentorNavCalendar,
        onNotificationsPressed: () =>
            mentorNavigate(context, AppRoutes.notifications),
        onCalendarPressed: () =>
            mentorNavigate(context, AppRoutes.mentorCalendar),
      ),
      bottomNavigationBar: MentorShellScope.hasShell(context)
          ? null
          : const MentorBottomNavigationBar(selectedIndex: 4),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const ProfileSkeleton(
            key: Key('mentor_profile_loading'),
          ),
          AsyncError(:final error) => _MentorProfileErrorView(
            title: l10n.mentorProfileErrorLoad,
            message: appErrorMessage(error, l10n),
            onRetry: () =>
                ref.read(mentorProfileControllerProvider.notifier).retry(),
          ),
          AsyncData(:final value) => _MentorProfileHomeView(profile: value),
        },
      ),
    );
  }
}

class _MentorProfileHomeView extends ConsumerWidget {
  const _MentorProfileHomeView({required this.profile});

  final MentorProfileData profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final displayName = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : l10n.mentorRoleBadge;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(mentorProfileControllerProvider.notifier).retry(),
      child: ListView(
        key: const Key('mentor_profile_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: [
          ProfileHeroCard(
            avatarUrl: profile.avatarUrl,
            displayName: displayName,
            email: profile.email,
            editIcon: Icons.edit_outlined,
            editTooltip: l10n.profileEdit,
            onEdit: () =>
                mentorNavigate(context, AppRoutes.mentorProfileEdit),
            badges: [
              ProfileStatusBadge(
                icon: Icons.school_outlined,
                label: l10n.mentorRoleBadge,
                foregroundColor: AppColors.brandPrimary,
                backgroundColor: AppColors.brandTint,
              ),
              _buildVerificationBadge(profile, l10n),
            ],
          ),
          const SizedBox(height: 30),

          // 1. Profile & Verification Status
          ProfileSection(
            title: l10n.mentorProfileSectionProfile,
            children: [
              ProfileActionTile(
                key: const Key('mentor_profile_edit_action'),
                icon: Icons.badge_outlined,
                colorfulIcon: SakuraColorfulIconType.editProfile,
                title: l10n.profileEdit,
                subtitle: l10n.mentorProfileEditSubtitle,
                onTap: () =>
                    mentorNavigate(context, AppRoutes.mentorProfileEdit),
              ),
              ProfileActionTile(
                key: const Key('mentor_profile_verification_status_action'),
                icon: Icons.verified_user_outlined,
                colorfulIcon: SakuraColorfulIconType.certificateMedal,
                title: l10n.mentorApplicationStatusLabel,
                subtitle: _verificationStatusDetail(profile, l10n),
                onTap: () => _showVerificationSummarySheet(context, profile),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 2. Mentoring Activity
          ProfileSection(
            title: l10n.mentorProfileSectionActivity,
            children: [
              ProfileActionTile(
                key: const Key('mentor_profile_chat_action'),
                icon: Icons.chat_bubble_outline_rounded,
                colorfulIcon: SakuraColorfulIconType.consultation,
                title: l10n.mentorChatThreadsTitle,
                subtitle: l10n.mentorProfileChatSubtitle,
                onTap: () => mentorNavigate(context, AppRoutes.mentorChat),
              ),
              ProfileActionTile(
                key: const Key('mentor_profile_reviews_action'),
                icon: Icons.star_outline_rounded,
                colorfulIcon: SakuraColorfulIconType.trophy,
                title: l10n.mentorReviewsTitle,
                subtitle: l10n.mentorProfileReviewsSubtitle,
                onTap: () => mentorNavigate(context, AppRoutes.mentorReviews),
              ),
              ProfileActionTile(
                key: const Key('mentor_profile_disputes_action'),
                icon: Icons.gavel_outlined,
                colorfulIcon: SakuraColorfulIconType.security,
                title: l10n.mentorDisputesTitle,
                subtitle: l10n.mentorProfileDisputesSubtitle,
                onTap: () => mentorNavigate(context, AppRoutes.mentorDisputes),
              ),
              ProfileActionTile(
                key: const Key('mentor_profile_prep_action'),
                icon: Icons.checklist_rtl_rounded,
                colorfulIcon: SakuraColorfulIconType.learningGoal,
                title: l10n.mentorPrepScreenTitle,
                subtitle: l10n.mentorProfilePrepSubtitle,
                onTap: () => mentorNavigate(context, AppRoutes.mentorPrep),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 3. Services & Payouts
          ProfileSection(
            title: l10n.mentorProfileSectionServices,
            children: [
              ProfileActionTile(
                key: const Key('mentor_profile_compensation_action'),
                icon: Icons.payments_outlined,
                colorfulIcon: SakuraColorfulIconType.learningProgress,
                title: l10n.mentorProfileEarningsTitle,
                subtitle: l10n.mentorProfileEarningsSubtitle,
                onTap: () =>
                    mentorNavigate(context, AppRoutes.mentorCompensation),
              ),
              ProfileActionTile(
                key: const Key('mentor_profile_bank_action'),
                icon: Icons.account_balance_outlined,
                colorfulIcon: SakuraColorfulIconType.mentorApplication,
                title: l10n.mentorProfileBankTitle,
                subtitle: l10n.mentorProfileBankSubtitle,
                onTap: () =>
                    mentorNavigate(context, AppRoutes.mentorBankAccount),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 4. Account (Settings & Logout — identical structure to Learner)
          ProfileSection(
            title: l10n.account,
            children: [
              ProfileActionTile(
                key: const Key('mentor_profile_settings_action'),
                icon: Icons.settings_outlined,
                colorfulIcon: SakuraColorfulIconType.settings,
                title: l10n.settings,
                subtitle: l10n.profileSettingsSubtitle,
                onTap: () => mentorNavigate(context, AppRoutes.mentorSettings),
              ),
              ProfileActionTile(
                key: const Key('mentor_profile_logout_action'),
                icon: Icons.logout_rounded,
                colorfulIcon: SakuraColorfulIconType.logout,
                title: l10n.logout,
                subtitle: l10n.profileLogoutSubtitle,
                destructive: true,
                onTap: () =>
                    confirmAndPerformMentorLogout(context: context, ref: ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

ProfileStatusBadge _buildVerificationBadge(
  MentorProfileData profile,
  AppLocalizations l10n,
) {
  if (profile.isApproved) {
    return ProfileStatusBadge(
      icon: Icons.verified_outlined,
      label: l10n.mentorVerificationApproved,
      foregroundColor: AppColors.success,
      backgroundColor: AppColors.successBackgroundSoft,
    );
  }
  if (profile.isPending) {
    return ProfileStatusBadge(
      icon: Icons.hourglass_top_rounded,
      label: l10n.mentorVerificationPending,
      foregroundColor: AppColors.warningText,
      backgroundColor: AppColors.warningBackground,
    );
  }
  if (profile.isChangesRequested) {
    return ProfileStatusBadge(
      icon: Icons.edit_note_rounded,
      label: l10n.mentorVerificationChangesRequested,
      foregroundColor: AppColors.warningText,
      backgroundColor: AppColors.warningBackground,
    );
  }
  if (profile.isRejected) {
    return ProfileStatusBadge(
      icon: Icons.cancel_outlined,
      label: l10n.mentorVerificationRejected,
      foregroundColor: AppColors.error,
      backgroundColor: AppColors.errorBackground,
    );
  }
  return ProfileStatusBadge(
    icon: Icons.pending_outlined,
    label: l10n.mentorVerificationUnverified,
    foregroundColor: AppColors.textSecondary,
    backgroundColor: AppColors.surfaceMuted,
  );
}

String _verificationStatusDetail(
  MentorProfileData profile,
  AppLocalizations l10n,
) {
  if (profile.isApproved) {
    return l10n.mentorVerificationApprovedDetail;
  }
  if (profile.isPending) {
    return l10n.mentorVerificationPending;
  }
  if (profile.isChangesRequested) {
    final notes = profile.reviewNotes?.trim();
    if (notes != null && notes.isNotEmpty) {
      return l10n.mentorVerificationReviewNotes(notes);
    }
    return l10n.mentorVerificationChangesRequested;
  }
  if (profile.isRejected) {
    final reason = profile.rejectionReason?.trim();
    if (reason != null && reason.isNotEmpty) {
      return l10n.mentorVerificationRejectionReason(reason);
    }
    return l10n.mentorVerificationRejected;
  }
  return l10n.mentorVerificationUnverified;
}

Future<void> _showVerificationSummarySheet(
  BuildContext context,
  MentorProfileData profile,
) async {
  final l10n = context.l10n;
  final rejectionReason = profile.rejectionReason?.trim();
  final reviewNotes = profile.reviewNotes?.trim();

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space4,
      ),
      child: Material(
        color: AppColors.cardWarmWhite,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mentorApplicationStatusLabel,
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildVerificationBadge(profile, l10n),
              ),
              const SizedBox(height: AppSpacing.space3),
              if (profile.isPending)
                RikiWarningBanner(
                  message: l10n.mentorVerificationPendingNote,
                  icon: Icons.hourglass_top_rounded,
                )
              else if (profile.isApproved)
                RikiInfoBanner(
                  message: l10n.mentorProfileApprovedLockedNotice,
                  icon: Icons.verified_outlined,
                )
              else if (profile.isRejected &&
                  rejectionReason != null &&
                  rejectionReason.isNotEmpty)
                RikiErrorBanner(
                  title: l10n.mentorVerificationRejected,
                  message: l10n.mentorVerificationRejectionReason(
                    rejectionReason,
                  ),
                )
              else if (profile.isChangesRequested &&
                  reviewNotes != null &&
                  reviewNotes.isNotEmpty)
                RikiWarningBanner(
                  title: l10n.mentorVerificationChangesRequested,
                  message: l10n.mentorVerificationReviewNotes(reviewNotes),
                )
              else
                RikiInfoBanner(
                  message: profile.hasVerificationDocument
                      ? l10n.mentorProfileDocumentUploadedNote
                      : l10n.mentorProfileDocumentRequiredNote,
                ),
              const SizedBox(height: AppSpacing.space4),
              RikiPrimaryButton(
                key: const Key('mentor_verification_sheet_edit_button'),
                label: l10n.profileEdit,
                leadingIcon: Icons.edit_outlined,
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  mentorNavigate(context, AppRoutes.mentorProfileEdit);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MentorProfileErrorView extends StatelessWidget {
  const _MentorProfileErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: RikiErrorState(
          title: title,
          message: message,
          actionLabel: l10n.retry,
          onAction: onRetry,
        ),
      ),
    );
  }
}
