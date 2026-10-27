import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiCard extends StatefulWidget {
  const RikiCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.boxShadow = AppShadows.cardSoft,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow> boxShadow;
  final VoidCallback? onTap;

  @override
  State<RikiCard> createState() => _RikiCardState();
}

class _RikiCardState extends State<RikiCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    final content = Padding(padding: widget.padding, child: widget.child);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: widget.borderColor),
        borderRadius: radius,
        boxShadow: widget.boxShadow,
      ),
      child: widget.onTap == null
          ? content
          : ClipRRect(
              borderRadius: radius,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: radius,
                  onHighlightChanged: _setPressed,
                  onTap: widget.onTap,
                  child: content,
                ),
              ),
            ),
    );

    if (widget.onTap == null) return card;

    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    return AnimatedScale(
      key: const ValueKey<String>('riki_card_press_scale'),
      scale: _isPressed ? 0.985 : 1,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: card,
    );
  }
}
