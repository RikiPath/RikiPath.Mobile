/// Kỳ thi dự kiến theo quy tắc sản phẩm, không phải lịch thi chính thức.
class JlptExamSession {
  const JlptExamSession({
    required this.year,
    required this.month,
    required this.date,
  });

  final int year;
  final int month;
  final DateTime date;

  bool get isJuly => month == DateTime.july;
}

abstract final class JlptExamCalendar {
  static const int planningYears = 5;
  static const List<int> months = <int>[DateTime.july, DateTime.december];

  static DateTime vietnamToday(DateTime nowUtc) {
    final vietnam = nowUtc.toUtc().add(const Duration(hours: 7));
    return DateTime(vietnam.year, vietnam.month, vietnam.day);
  }

  /// Ảnh Web mô tả Chủ nhật đầu tiên; source Web hiện chưa có picker này.
  static DateTime estimatedDate(int year, int month) {
    if (!months.contains(month)) throw ArgumentError.value(month, 'month');
    final first = DateTime(year, month);
    final offset = (DateTime.sunday - first.weekday + 7) % 7;
    return first.add(Duration(days: offset));
  }

  static List<JlptExamSession> futureSessions(int year, DateTime nowUtc) {
    final today = vietnamToday(nowUtc);
    return months
        .map(
          (month) => JlptExamSession(
            year: year,
            month: month,
            date: estimatedDate(year, month),
          ),
        )
        .where((session) => session.date.isAfter(today))
        .toList(growable: false);
  }

  static List<int> availableYears(DateTime nowUtc) {
    final firstYear = vietnamToday(nowUtc).year;
    return <int>[
      for (var year = firstYear; year <= firstYear + planningYears; year++)
        if (futureSessions(year, nowUtc).isNotEmpty) year,
    ];
  }

  /// Chỉ gán nhãn kỳ nếu ngày đã lưu đúng một ngày dự kiến hợp lệ.
  static JlptExamSession? fromStoredDate(DateTime? value) {
    if (value == null || !months.contains(value.month)) return null;
    final expected = estimatedDate(value.year, value.month);
    if (expected.year != value.year ||
        expected.month != value.month ||
        expected.day != value.day) {
      return null;
    }
    return JlptExamSession(
      year: value.year,
      month: value.month,
      date: expected,
    );
  }
}
