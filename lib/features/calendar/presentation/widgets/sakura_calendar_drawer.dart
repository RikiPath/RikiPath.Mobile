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
    this.isMentor = false,
  });

  final SakuraCalendarViewMode currentMode;
  final Set<SakuraCalendarEventType> visibleEventTypes;
  final ValueChanged<SakuraCalendarViewMode> onSelectMode;
  final ValueChanged<SakuraCalendarEventType> onToggleEventType;
  final String roleName;
  final bool isMentor;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
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
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE4E6)),
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
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space2,
                ),
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
                    color: const Color(0xFFE11D48),
                    isChecked: visibleEventTypes.contains(
                      SakuraCalendarEventType.consultation,
                    ),
                    onToggle: () =>
                        onToggleEventType(SakuraCalendarEventType.consultation),
                  ),
                  _CalendarFilterTile(
                    label: isMentor
                        ? 'Lịch trống đã đăng ký'
                        : 'Lịch tư vấn còn trống',
                    color: const Color(0xFF64748B),
                    isChecked: visibleEventTypes.contains(
                      SakuraCalendarEventType.availableSlot,
                    ),
                    onToggle: () => onToggleEventType(
                      SakuraCalendarEventType.availableSlot,
                    ),
                  ),
                  if (!isMentor) ...[
                    _CalendarFilterTile(
                      label: 'Ôn tập',
                      color: const Color(0xFFD97706),
                      isChecked: visibleEventTypes.contains(
                        SakuraCalendarEventType.srsReview,
                      ),
                      onToggle: () =>
                          onToggleEventType(SakuraCalendarEventType.srsReview),
                    ),
                    _CalendarFilterTile(
                      label: 'Bài học đã hoàn thành',
                      color: const Color(0xFF15803D),
                      isChecked: visibleEventTypes.contains(
                        SakuraCalendarEventType.learningPlan,
                      ),
                      onToggle: () => onToggleEventType(
                        SakuraCalendarEventType.learningPlan,
                      ),
                    ),
                  ],
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
        horizontal: AppSpacing.space3,
        vertical: 3,
      ),
      child: Material(
        color: isSelected ? const Color(0xFFFFF1F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('drawer_view_mode_${mode.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Icon(
                  mode.icon,
                  size: 21,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF334155),
                ),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  mode.labelVi,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
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
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
