import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// A colorful category shortcut button matching the Sakura Home showcase.
class SakuraCategoryShortcut extends StatefulWidget {
  const SakuraCategoryShortcut({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.badge,
    this.borderColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final String? badge;
  final Color? borderColor;

  @override
  State<SakuraCategoryShortcut> createState() => _SakuraCategoryShortcutState();
}

class _SakuraCategoryShortcutState extends State<SakuraCategoryShortcut> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.isReducedMotion(context);

    return Semantics(
      button: true,
      label: widget.label,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: _setPressed,
        borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: reduceMotion ? Duration.zero : AppMotion.fast,
          curve: AppMotion.curveExpressive,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
                  border: Border.all(
                    color: widget.borderColor ?? widget.backgroundColor,
                    width: 1,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x082D282A),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.foregroundColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
