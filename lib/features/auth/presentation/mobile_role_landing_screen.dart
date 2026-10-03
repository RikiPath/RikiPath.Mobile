import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/core/widgets/riki_language_switcher.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

class UnsupportedRoleScreen extends ConsumerWidget {
  const UnsupportedRoleScreen({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _RoleLandingScaffold(
      key: const Key('unsupported_role_screen'),
      icon: Icons.shield_outlined,
      title: context.l10n.unsupportedRoleTitle,
      description: context.l10n.unsupportedRoleDescription(role),
      actionLabel: context.l10n.logout,
      onAction: () => ref.read(authSessionControllerProvider).signOut(),
    );
  }
}

class _RoleLandingScaffold extends StatelessWidget {
  const _RoleLandingScaffold({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [RikiBrandLockup(), RikiLanguageSwitcher()],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.brandTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: AppColors.brandPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              RikiPrimaryButton(
                key: const Key('role_landing_logout_button'),
                label: actionLabel,
                leadingIcon: Icons.logout,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
