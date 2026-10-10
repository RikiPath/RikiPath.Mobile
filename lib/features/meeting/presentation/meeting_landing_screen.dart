import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class MeetingLandingScreen extends StatelessWidget {
  const MeetingLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('meeting_landing_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(context.l10n.meetingTitle),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            RikiCard(
              boxShadow: AppShadows.cardSoft,
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: const Icon(
                        Icons.videocam_outlined,
                        color: AppColors.brandPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    context.l10n.meetingJoinTitle,
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    context.l10n.meetingLandingDescription,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space5),
                  RikiPrimaryButton(
                    key: const ValueKey<String>('meeting_landing_join_button'),
                    label: context.l10n.meetingJoinAction,
                    leadingIcon: Icons.link,
                    trailingIcon: Icons.arrow_forward,
                    onPressed: () => context.push(AppRoutes.meetingJoin),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            RikiInfoBanner(
              icon: Icons.lock_outline,
              message: context.l10n.meetingAuthorizationNotice,
            ),
          ],
        ),
      ),
    );
  }
}
