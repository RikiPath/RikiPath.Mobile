import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiCheckboxRow extends StatelessWidget {
  const RikiCheckboxRow({
    required this.value,
    required this.onChanged,
    required this.child,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(AppRadius.compact),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 44,
              child: Checkbox(value: value, onChanged: onChanged),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space3),
                child: DefaultTextStyle(
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
