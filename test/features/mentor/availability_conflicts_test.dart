import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mentor/domain/availability_conflicts.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

LearnerMentorAvailability slot(
  int id,
  String start,
  String end, {
  int mentor = 7,
}) => LearnerMentorAvailability(
  id: id,
  mentorId: mentor,
  mentorName: 'Mentor',
  startTime: MentorTimestamp.parse(start),
  endTime: MentorTimestamp.parse(end),
  isBooked: false,
);

void main() {
  test(
    'different IDs for the same interval show once and cannot be booked',
    () {
      final view = AvailabilityConflictView([
        slot(11, '2026-11-02T09:00:00Z', '2026-11-02T09:50:00Z'),
        slot(12, '2026-11-02T09:00:00Z', '2026-11-02T09:50:00Z'),
        slot(13, '2026-11-02T10:00:00Z', '2026-11-02T10:50:00Z'),
      ]);
      expect(view.displaySlots.map((item) => item.id), [11, 13]);
      expect(view.conflictingIds, {11, 12});
      expect(view.canBook(view.slots[0]), isFalse);
      expect(view.canBook(view.slots[2]), isTrue);
    },
  );

  test('overlaps are blocked but adjacent slots are allowed', () {
    final view = AvailabilityConflictView([
      slot(1, '2026-11-02T09:00:00Z', '2026-11-02T09:50:00Z'),
      slot(2, '2026-11-02T09:30:00Z', '2026-11-02T10:20:00Z'),
      slot(3, '2026-11-02T10:20:00Z', '2026-11-02T11:10:00Z'),
    ]);
    expect(view.conflictingIds, {1, 2});
    expect(view.canBook(view.slots[2]), isTrue);
  });

  test('identical repeated response ID does not invent a conflict', () {
    final first = slot(1, '2026-11-02T09:00:00Z', '2026-11-02T09:50:00Z');
    final view = AvailabilityConflictView([first, first]);
    expect(view.displaySlots, hasLength(1));
    expect(view.canBook(view.slots.single), isTrue);
  });
}
