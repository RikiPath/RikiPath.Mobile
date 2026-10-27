import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// 7-day study streak week tracker matching the Sakura showcase.
class SakuraDayTracker extends StatelessWidget {
  const SakuraDayTracker({
    required this.streakDays,
    this.todayWeekday,
    super.key,
  });

  /// Current consecutive streak in days.
  final int streakDays;

  /// 1 for Mon, 7 for Sun. Defaults to today's weekday if null.
  final int? todayWeekday;

  @override
  Widget build(BuildContext context) {
    final currentDay = todayWeekday ?? DateTime.now().weekday; // 1..7
    final isJapanese = Localizations.localeOf(context).languageCode == 'ja';
    final dayLabels = isJapanese
        ? const <String>['月', '火', '水', '木', '金', '土', '日']
        : const <String>['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    // If streak is positive, mark up to streakDays recent days as active.
    final activeCount = streakDays.clamp(0, 7);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(7, (index) {
        final dayIndex = index + 1; // 1..7 (Mon..Sun)
        final isToday = dayIndex == currentDay;
        // Mark active if within the streak leading up to today
        final daysFromToday = (currentDay - dayIndex);
        final isActive = streakDays > 0 &&
            daysFromToday >= 0 &&
            daysFromToday < activeCount;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.brandPrimary
                      : isToday
                          ? AppColors.brandTint
                          : AppColors.surfaceMuted,
                  border: isToday && !isActive
                      ? Border.all(color: AppColors.brandPrimary, width: 1.5)
                      : null,
                ),
                child: isActive
                    ? const Icon(
                        Icons.check,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 2),
              Text(
                dayLabels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isToday
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
