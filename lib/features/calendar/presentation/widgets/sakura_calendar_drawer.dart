import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';

class SakuraCalendarDrawer extends StatelessWidget {
  const SakuraCalendarDrawer({
    super.key,
    required this.currentMode,
    required this.visibleEventTypes,
    required this.onSelectMode,
    required this.onToggleEventType,
    this.roleName = 'Học viên RikiPath',
  });

  final SakuraCalendarViewMode currentMode;
  final Set<SakuraCalendarEventType> visibleEventTypes;
  final ValueChanged<SakuraCalendarViewMode> onSelectMode;
  final ValueChanged<SakuraCalendarEventType> onToggleEventType;
  final String roleName;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Brand Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space3,
              ),
              child: Row(
                children: [
                  const Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RikiBrandLockup(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lịch học',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Section 1: View Modes (Google Calendar style)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space2,
                    ),
                    child: Text(
                      'CHẾ ĐỘ XEM',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final mode in SakuraCalendarViewMode.values) ...[
                    _ViewModeTile(
                      mode: mode,
                      isSelected: mode == currentMode,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectMode(mode);
                      },
                    ),
                  ],

                  const SizedBox(height: AppSpacing.space3),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.space2),

                  // Section 2: Calendars & Layer Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space2,
                    ),
                    child: Text(
                      'LỊCH CỦA TÔI',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _CalendarFilterTile(
                    key: const Key('drawer_layer_consultation'),
                    label: 'Tư vấn JLPT 1-1',
                    color: AppColors.success,
                    isChecked: visibleEventTypes.contains(
                      SakuraCalendarEventType.consultation,
                    ),
                    onToggle: () => onToggleEventType(
                      SakuraCalendarEventType.consultation,
                    ),
                  ),
                  _CalendarFilterTile(
                    label: 'Khung giờ trống / Lịch dạy',
                    color: const Color(0xFF2563EB),
                    isChecked: visibleEventTypes.contains(
                      SakuraCalendarEventType.availableSlot,
                    ),
                    onToggle: () => onToggleEventType(
                      SakuraCalendarEventType.availableSlot,
                    ),
                  ),
                  _CalendarFilterTile(
                    label: 'Học tập & Ôn tập',
                    color: AppColors.primary,
                    isChecked: visibleEventTypes.contains(
                      SakuraCalendarEventType.studySession,
                    ),
                    onToggle: () => onToggleEventType(
                      SakuraCalendarEventType.studySession,
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      roleName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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

class _ViewModeTile extends StatelessWidget {
  const _ViewModeTile({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final SakuraCalendarViewMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      child: Material(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          key: Key('drawer_view_mode_${mode.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Icon(
                  mode.icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.space4),
                Text(
                  mode.labelVi,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarFilterTile extends StatelessWidget {
  const _CalendarFilterTile({
    super.key,
    required this.label,
    required this.color,
    required this.isChecked,
    required this.onToggle,
  });

  final String label;
  final Color color;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isChecked,
      onChanged: (_) => onToggle(),
      activeColor: color,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
      ),
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
