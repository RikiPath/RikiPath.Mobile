import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.child,
    this.compact = false,
    super.key,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact
        ? AppSpacing.screenHorizontalCompact
        : AppSpacing.screenHorizontal;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const verticalPadding = AppSpacing.space5 * 2;
            final minimumHeight = math.max(
              0.0,
              constraints.maxHeight - verticalPadding,
            );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.space5,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minimumHeight,
                    maxWidth: 560,
                  ),
                  child: IntrinsicHeight(child: child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthNavigationPrompt extends StatelessWidget {
  const AuthNavigationPrompt({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          message,
          style: AppTypography.bodySmall,
        ),
        RikiTextButton(label: actionLabel, onPressed: onPressed),
      ],
    );
  }
}

class AuthSecurityFooter extends StatelessWidget {
  const AuthSecurityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 17,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.space2),
        Flexible(
          child: Text(
            'Bảo mật chuẩn mã hóa Riki Learning',
            textAlign: TextAlign.center,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthHelpFooter extends StatelessWidget {
  const AuthHelpFooter({
    this.prefix = 'Cần trợ giúp trực tiếp?',
    this.actionLabel = 'Liên hệ Sensei hỗ trợ',
    super.key,
  });

  final String prefix;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$prefix $actionLabel',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$prefix '),
            TextSpan(
              text: actionLabel,
              style: AppTypography.metadata.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: AppTypography.metadata,
      ),
    );
  }
}
