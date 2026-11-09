import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// A dated status must come from a daily activity source, never a streak total.
enum LearningDayStatus { completed, inProgress, missed, noData, future }

class SakuraDayTracker extends StatefulWidget {
  const SakuraDayTracker({
    this.statusesByDate = const {},
    this.onDateSelected,
    this.today,
    this.compact = false,
    super.key,
  });

  /// Keys are local calendar dates in yyyy-MM-dd form.
  final Map<String, LearningDayStatus> statusesByDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? today;
  final bool compact;

  @override
  State<SakuraDayTracker> createState() => _SakuraDayTrackerState();
}

class _SakuraDayTrackerState extends State<SakuraDayTracker>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.today ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final japanese = Localizations.localeOf(context).languageCode == 'ja';
    final compact = widget.compact;
    final circleSize = compact ? 19.0 : 28.0;
    final iconSize = compact ? 12.0 : 17.0;
    final labels = japanese
        ? const ['月', '火', '水', '木', '金', '土', '日']
        : const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Row(
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final key = _dateKey(date);
        final isToday = date == today;
        final status = date.isAfter(today)
            ? LearningDayStatus.future
            : widget.statusesByDate[key] ?? LearningDayStatus.noData;
        final (icon, foreground, background) = switch (status) {
          LearningDayStatus.completed => (
            Icons.check_rounded,
            AppColors.success,
            AppColors.successBackgroundSoft,
          ),
          LearningDayStatus.inProgress => (
            Icons.access_time_rounded,
            AppColors.warningText,
            AppColors.warningBackground,
          ),
          LearningDayStatus.missed => (
            Icons.close_rounded,
            AppColors.errorText,
            AppColors.errorBackground,
          ),
          LearningDayStatus.noData || LearningDayStatus.future => (
            Icons.circle_outlined,
            AppColors.textMuted,
            AppColors.surfaceMuted,
          ),
        };
        final statusLabel = japanese
            ? switch (status) {
                LearningDayStatus.completed => '完了',
                LearningDayStatus.inProgress => '学習中',
                LearningDayStatus.missed => '未達成',
                LearningDayStatus.noData => 'データなし',
                LearningDayStatus.future => '未来',
              }
            : switch (status) {
                LearningDayStatus.completed => 'Đã hoàn thành',
                LearningDayStatus.inProgress => 'Đang học',
                LearningDayStatus.missed => 'Chưa hoàn thành',
                LearningDayStatus.noData => 'Chưa có dữ liệu',
                LearningDayStatus.future => 'Chưa đến ngày',
              };
        final dateLabel = MaterialLocalizations.of(
          context,
        ).formatMediumDate(date);
        final tooltip = '$dateLabel · $statusLabel';

        return Expanded(
          child: Semantics(
            button: widget.onDateSelected != null,
            label: '$tooltip. ${japanese ? 'カレンダーを開く' : 'Mở lịch học'}',
            child: Tooltip(
              message: tooltip,
              child: InkWell(
                key: ValueKey('learning_day_$key'),
                onTap: widget.onDateSelected == null
                    ? null
                    : () => widget.onDateSelected!(date),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 2 : 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: circleSize,
                        height: circleSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: background,
                          shape: BoxShape.circle,
                          border: isToday
                              ? Border.all(
                                  color: AppColors.brandPrimary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Icon(icon, size: iconSize, color: foreground),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                          color: isToday ? AppColors.brandPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
