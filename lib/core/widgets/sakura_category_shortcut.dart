import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';

/// A colorful category shortcut button matching the Sakura Home showcase.
class SakuraCategoryShortcut extends StatefulWidget {
  const SakuraCategoryShortcut({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.icon3d,
    this.badge,
    this.borderColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final Sakura3DIconType? icon3d;
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
    final illustration = widget.icon3d;

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
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.cardSoft,
                  border: Border.all(
                    color: AppColors.cardBorderSubtle,
                    width: 1,
                  ),
                ),
                child: illustration != null
                    ? Sakura3DIcon(
                        type: illustration,
                        size: 46,
                        fallbackColor: widget.foregroundColor,
                      )
                    : Icon(
                        widget.icon,
                        color: widget.foregroundColor,
                        size: 28,
                      ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                widget.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
