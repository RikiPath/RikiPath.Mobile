import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';

/// One entry per availability ID. Conflicting intervals are never bookable.
class AvailabilityConflictView {
  AvailabilityConflictView(List<LearnerMentorAvailability> slots)
    : slots = _uniqueById(slots),
      conflictingIds = _conflictingIds(_uniqueById(slots));

  final List<LearnerMentorAvailability> slots;
  final Set<int> conflictingIds;

  /// Collapse repeated response rows into one display item per mentor/time.
  /// A distinct AvailabilityId still marks that item as unbookable.
  List<LearnerMentorAvailability> get displaySlots {
    final seen = <String>{};
    return slots
        .where(
          (slot) => seen.add(
            '${slot.mentorId}|${slot.startTime.value.toUtc().toIso8601String()}|${slot.endTime.value.toUtc().toIso8601String()}',
          ),
        )
        .toList(growable: false);
  }

  bool canBook(LearnerMentorAvailability slot) =>
      !slot.isBooked && !conflictingIds.contains(slot.id);

  static List<LearnerMentorAvailability> _uniqueById(
    List<LearnerMentorAvailability> slots,
  ) => <int, LearnerMentorAvailability>{
    for (final slot in slots) slot.id: slot,
  }.values.toList(growable: false);

  static Set<int> _conflictingIds(List<LearnerMentorAvailability> slots) {
    final conflicts = <int>{};
    for (var i = 0; i < slots.length; i++) {
      final first = slots[i];
      for (var j = i + 1; j < slots.length; j++) {
        final second = slots[j];
        if (first.mentorId != second.mentorId) continue;
        if (first.startTime.value.isBefore(second.endTime.value) &&
            second.startTime.value.isBefore(first.endTime.value)) {
          conflicts.add(first.id);
          conflicts.add(second.id);
        }
      }
    }
    return conflicts;
  }
}
