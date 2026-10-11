import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiFeatureIcon extends StatelessWidget {
  const RikiFeatureIcon({
    required this.icon,
    required this.tone,
    this.extent = 48,
    this.iconSize = 24,
    super.key,
  });

  final IconData icon;
  final RikiFeatureTone tone;
  final double extent;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: extent,
        height: extent,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(
            extent <= 40 ? AppRadius.compact : AppRadius.input,
          ),
        ),
        child: Icon(icon, size: iconSize, color: tone.foreground),
      ),
    );
  }
}

class RikiStatusPill extends StatelessWidget {
  const RikiStatusPill({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final RikiFeatureTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                ExcludeSemantics(
                  child: Icon(icon, size: 14, color: tone.foreground),
                ),
                const SizedBox(width: AppSpacing.space1),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badgeText.copyWith(
                    color: tone.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
