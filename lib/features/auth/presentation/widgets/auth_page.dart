import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/sakura_auth_background.dart';

export 'sakura_auth_background.dart' show SakuraAuthBackgroundVariant;

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.child,
    this.compact = false,
    this.animateEntrance = true,
    this.topContentOffset = 0,
    this.backgroundVariant = SakuraAuthBackgroundVariant.standard,
    super.key,
  });

  final Widget child;
  final bool compact;
  final bool animateEntrance;
  final double topContentOffset;
  final SakuraAuthBackgroundVariant backgroundVariant;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final effectiveTopOffset = keyboardInset > 0
        ? 0.0
        : widget.topContentOffset;
    final topPadding = AppSpacing.space5 + effectiveTopOffset;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      // Keep the background locked to the full viewport so software keyboards
      // never squash or jump the top/bottom Sakura artwork behind inputs.
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SakuraAuthBackground(variant: widget.backgroundVariant),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final verticalPadding = topPadding + AppSpacing.space5;
                final minimumHeight = math.max(
                  0.0,
                  constraints.maxHeight - verticalPadding - keyboardInset,
                );

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    AppSpacing.space5 + keyboardInset,
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
        ],
      ),
    );
  }
}

class AuthNavigationPrompt extends StatelessWidget {
  const AuthNavigationPrompt({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    this.actionKey,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onPressed;
  final Key? actionKey;

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
          key: actionKey,
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
