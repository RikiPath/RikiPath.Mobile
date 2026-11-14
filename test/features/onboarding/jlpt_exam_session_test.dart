import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/onboarding/domain/jlpt_exam_session.dart';

void main() {
  test('estimated July and December dates are the first Sunday', () {
    expect(
      JlptExamCalendar.estimatedDate(2027, DateTime.july),
      DateTime(2027, 7, 4),
    );
    expect(
      JlptExamCalendar.estimatedDate(2027, DateTime.december),
      DateTime(2027, 12, 5),
    );
    expect(
      JlptExamCalendar.estimatedDate(2028, DateTime.july).weekday,
      DateTime.sunday,
    );
  });

  test('Vietnam date boundary does not follow device local timezone', () {
    expect(
      JlptExamCalendar.vietnamToday(DateTime.utc(2027, 7, 3, 18)),
      DateTime(2027, 7, 4),
    );
    expect(
      JlptExamCalendar.vietnamToday(DateTime.utc(2027, 7, 3, 16)),
      DateTime(2027, 7, 3),
    );
  });

  test('past sessions are removed, including the current exam day', () {
    expect(
      JlptExamCalendar.futureSessions(2027, DateTime.utc(2027, 7, 3, 17)),
      hasLength(1),
    );
    expect(
      JlptExamCalendar.futureSessions(2027, DateTime.utc(2027, 12, 4, 17)),
      isEmpty,
    );
    expect(
      JlptExamCalendar.availableYears(DateTime.utc(2027, 12, 4, 17)).first,
      2028,
    );
  });

  test('saved date is only recognized when it matches a supported session', () {
    expect(
      JlptExamCalendar.fromStoredDate(DateTime(2027, 12, 5))?.month,
      DateTime.december,
    );
    expect(JlptExamCalendar.fromStoredDate(DateTime(2027, 12, 6)), isNull);
    expect(JlptExamCalendar.fromStoredDate(DateTime(2027, 8, 1)), isNull);
    expect(JlptExamCalendar.fromStoredDate(null), isNull);
  });
}
