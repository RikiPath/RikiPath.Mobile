import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.child,
    this.compact = false,
    this.animateEntrance = true,
    super.key,
  });

  final Widget child;
  final bool compact;
  final bool animateEntrance;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _entrance = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.easeOutCubic,
  );
  bool _hasStartedEntrance = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (!widget.animateEntrance || reduceMotion) {
      _entranceController.value = 1;
      _hasStartedEntrance = true;
    } else if (!_hasStartedEntrance) {
      _hasStartedEntrance = true;
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = widget.compact
        ? AppSpacing.screenHorizontalCompact
        : AppSpacing.screenHorizontal;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
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
                  child: FadeTransition(
                    key: const ValueKey<String>('auth_page_entrance'),
                    opacity: _entrance,
                    child: AnimatedBuilder(
                      animation: _entrance,
                      child: IntrinsicHeight(child: widget.child),
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, 10 * (1 - _entrance.value)),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthTipCard extends StatelessWidget {
  const AuthTipCard({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Container(
        key: const ValueKey<String>('auth_tip_card'),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.authTipBackground,
          border: Border.all(color: AppColors.authTipBorder),
          borderRadius: BorderRadius.circular(AppRadius.banner),
          boxShadow: AppShadows.cardSoft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.lightbulb_outline,
                size: 19,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        Flexible(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ),
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
