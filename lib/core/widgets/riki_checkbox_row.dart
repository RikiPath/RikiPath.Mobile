import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiCheckboxRow extends StatelessWidget {
  const RikiCheckboxRow({
    required this.value,
    required this.onChanged,
    required this.child,
    this.compact = false,
    this.centerChild = false,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Widget child;
  final bool compact;
  final bool centerChild;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(AppRadius.compact),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 0 : AppSpacing.space1,
        ),
        child: Row(
          crossAxisAlignment: centerChild
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: compact ? 32 : 44,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: compact
                    ? MaterialTapTargetSize.shrinkWrap
                    : null,
                visualDensity: compact ? VisualDensity.compact : null,
              ),
            ),
            SizedBox(width: compact ? AppSpacing.space1 : AppSpacing.space2),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: centerChild
                      ? 0
                      : compact
                      ? AppSpacing.space1 / 2
                      : AppSpacing.space3,
                ),
                child: Transform.translate(
                  offset: centerChild ? const Offset(0, -1) : Offset.zero,
                  child: DefaultTextStyle(
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
