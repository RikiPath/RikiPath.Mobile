import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

void main() {
  group('Mentor Weekly Schedule Contract Tests', () {
    test('Friday 18:00 Vietnam is the exact registration cutoff', () {
      final state = MentorWeeklyScheduleState(
        selectedWeekMonday: DateTime(2026, 11, 2),
        currentWeekMonday: DateTime(2026, 10, 26),
        registeredPeriods: const {},
        publishedSlots: const [],
        isLoading: false,
        isSaving: false,
      );

      expect(
        state.isRegistrationOpenAt(DateTime.utc(2026, 10, 30, 10, 59)),
        isTrue,
      );
      expect(
        state.isRegistrationOpenAt(DateTime.utc(2026, 10, 30, 11)),
        isFalse,
      );
    });

    test(
      '1. weekly schedule path serializes weekStart date in YYYY-MM-DD format',
      () {
        final monday = DateTime(2026, 11, 2);
        expect(
          MentorApiPaths.weeklyScheduleUrl(monday),
          '/api/mentor-schedule/weekly?weekStart=2026-11-02',
        );
      },
    );

    test('2. WeeklyAvailabilityDto maps exact Backend response fields', () {
      final json = {
        'id': 105,
        'mentorId': 900002,
        'mentorName': 'Mentor One',
        'date': '2026-11-02',
        'period': 'Morning',
      };

      final dto = WeeklyAvailabilityDto.fromJson(json);
      expect(dto.id, 105);
      expect(dto.mentorId, 900002);
      expect(dto.mentorName, 'Mentor One');
      expect(dto.date.year, 2026);
      expect(dto.date.month, 11);
      expect(dto.date.day, 2);
      expect(dto.period, 'Morning');

      final domain = dto.toDomain();
      expect(domain.formattedDate, '2026-11-02');
      expect(domain.key, '2026-11-02#Morning');
    });

    test('3. WeeklyPeriodItem equality and key generation', () {
      final p1 = WeeklyPeriodItem(
        date: DateTime(2026, 11, 2),
        period: 'Morning',
      );
      final p2 = WeeklyPeriodItem(
        date: DateTime(2026, 11, 2),
        period: 'Morning',
      );
      final p3 = WeeklyPeriodItem(
        date: DateTime(2026, 11, 2),
        period: 'Afternoon',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.key, '2026-11-02#Morning');
    });

    test(
      '4. MentorAvailabilitySlot supports isApproved and bookedCount safely',
      () {
        final slot1 = MentorAvailabilitySlot(
          id: 990020,
          startTime: MentorTimestamp.parse('2026-11-02T09:00:00Z'),
          endTime: MentorTimestamp.parse('2026-11-02T09:50:00Z'),
          isBooked: false,
          isApproved: true,
          bookedCount: 0,
        );

        expect(slot1.isApproved, isTrue);
        expect(slot1.bookedCount, 0);

        final slot2 = MentorAvailabilitySlot(
          id: 990021,
          startTime: MentorTimestamp.parse('2026-11-02T10:00:00Z'),
          endTime: MentorTimestamp.parse('2026-11-02T10:50:00Z'),
          isBooked: true,
          isApproved: true,
          bookedCount: 1,
        );

        expect(slot2.isBooked, isTrue);
        expect(slot2.bookedCount, 1);
      },
    );
  });
}
