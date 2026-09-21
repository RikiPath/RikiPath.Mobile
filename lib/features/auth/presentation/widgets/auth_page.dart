import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({required this.child, this.compact = false, super.key});

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(message, style: AppTypography.bodySmall),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            maximumSize: const Size(100, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
            textStyle: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(actionLabel, maxLines: 1),
        ),
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
        const Icon(Icons.shield_outlined, size: 17, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.space2),
        Flexible(
          child: Text(
            context.l10n.securityFooter,
            textAlign: TextAlign.center,
            style: AppTypography.metadata.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class AuthHelpFooter extends StatelessWidget {
  const AuthHelpFooter({this.prefix, this.actionLabel, super.key});

  final String? prefix;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedPrefix = prefix ?? context.l10n.helpDirectPrefix;
    final resolvedActionLabel = actionLabel ?? context.l10n.helpSensei;
    return Semantics(
      label: '$resolvedPrefix $resolvedActionLabel',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$resolvedPrefix '),
            TextSpan(
              text: resolvedActionLabel,
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
