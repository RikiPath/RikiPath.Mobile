import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

/// Policy v3 dayparts matching `RikiPath.Domain.MentorScheduling.MentorDaypart`.
enum MentorDaypart {
  morning('Morning', '07:00', '11:00'),
  noon('Noon', '11:00', '13:00'),
  afternoon('Afternoon', '13:00', '18:00'),
  evening('Evening', '18:00', '22:00');

  const MentorDaypart(this.apiValue, this.defaultStart, this.defaultEnd);

  final String apiValue;
  final String defaultStart;
  final String defaultEnd;

  static MentorDaypart fromApiValue(String raw) {
    final normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'morning' => MentorDaypart.morning,
      'noon' => MentorDaypart.noon,
      'afternoon' => MentorDaypart.afternoon,
      'evening' => MentorDaypart.evening,
      _ => MentorDaypart.morning,
    };
  }
}

class MentorScheduleRule {
  const MentorScheduleRule({
    required this.id,
    required this.scheduleId,
    required this.weekday,
    required this.weekdayName,
    required this.daypart,
    required this.localStart,
    required this.localEnd,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  final int id;
  final int scheduleId;

  /// `0` (Sunday) to `6` (Saturday) matching Backend `.NET DayOfWeek`.
  final int weekday;
  final String weekdayName;
  final MentorDaypart daypart;
  final String localStart;
  final String localEnd;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
}

class MentorScheduleV3 {
  const MentorScheduleV3({
    required this.scheduleId,
    required this.mentorId,
    required this.mentorName,
    required this.policyVersion,
    required this.timeZoneId,
    required this.autoPublish,
    required this.effectiveFrom,
    required this.createdAtUtc,
    required this.rules,
    this.generatedThrough,
  });

  final int scheduleId;
  final int mentorId;
  final String mentorName;
  final int policyVersion;
  final String timeZoneId;
  final bool autoPublish;
  final DateTime effectiveFrom;
  final DateTime? generatedThrough;
  final MentorTimestamp createdAtUtc;
  final List<MentorScheduleRule> rules;
}

class MentorScheduleRuleDraft {
  const MentorScheduleRuleDraft({
    required this.weekday,
    required this.daypart,
    required this.localStart,
    required this.localEnd,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  final int weekday;
  final MentorDaypart daypart;
  final String localStart;
  final String localEnd;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
}

class UpdateMentorScheduleV3Request {
  const UpdateMentorScheduleV3Request({
    required this.timeZoneId,
    required this.autoPublish,
    required this.effectiveFrom,
    required this.rules,
  });

  final String timeZoneId;
  final bool autoPublish;
  final DateTime effectiveFrom;
  final List<MentorScheduleRuleDraft> rules;
}

class MentorSlotPreviewItem {
  const MentorSlotPreviewItem({
    required this.localDate,
    required this.daypart,
    required this.startUtc,
    required this.endUtc,
    required this.localStart,
    required this.localEnd,
    required this.generationKey,
    required this.isExisting,
    required this.hasConflict,
    this.conflictReason,
  });

  final DateTime localDate;
  final MentorDaypart daypart;
  final MentorTimestamp startUtc;
  final MentorTimestamp endUtc;
  final String localStart;
  final String localEnd;
  final String generationKey;
  final bool isExisting;
  final bool hasConflict;
  final String? conflictReason;
}

class MentorSlotPreviewResult {
  const MentorSlotPreviewResult({
    required this.totalCandidateSlots,
    required this.existingSlotsCount,
    required this.newSlotsCount,
    required this.conflictSlotsCount,
    required this.startDate,
    required this.endDate,
    required this.slots,
  });

  final int totalCandidateSlots;
  final int existingSlotsCount;
  final int newSlotsCount;
  final int conflictSlotsCount;
  final DateTime startDate;
  final DateTime endDate;
  final List<MentorSlotPreviewItem> slots;
}

class MentorPublishedSlotItem {
  const MentorPublishedSlotItem({
    required this.availabilityId,
    required this.localDate,
    required this.daypart,
    required this.startTimeUtc,
    required this.endTimeUtc,
    required this.localStart,
    required this.localEnd,
    required this.generationKey,
    required this.isApproved,
  });

  final int availabilityId;
  final DateTime localDate;
  final MentorDaypart daypart;
  final MentorTimestamp startTimeUtc;
  final MentorTimestamp endTimeUtc;
  final String localStart;
  final String localEnd;
  final String generationKey;
  final bool isApproved;
}

class MentorPublishSlotsResult {
  const MentorPublishSlotsResult({
    required this.createdCount,
    required this.skippedExistingCount,
    required this.totalSlotsProcessed,
    required this.generatedThrough,
    required this.publishedSlots,
  });

  final int createdCount;
  final int skippedExistingCount;
  final int totalSlotsProcessed;
  final DateTime generatedThrough;
  final List<MentorPublishedSlotItem> publishedSlots;
}

class MentorTeachingConflictItem {
  const MentorTeachingConflictItem({
    required this.code,
    this.sessionNumber,
    required this.proposedStartUtc,
    required this.proposedEndUtc,
    required this.commitmentKind,
    this.cohortId,
    this.cohortName,
    this.commitmentStartUtc,
    this.commitmentEndUtc,
    required this.message,
  });

  final String code;
  final int? sessionNumber;
  final DateTime proposedStartUtc;
  final DateTime proposedEndUtc;
  final String commitmentKind;
  final int? cohortId;
  final String? cohortName;
  final DateTime? commitmentStartUtc;
  final DateTime? commitmentEndUtc;
  final String message;
}

class MentorTeachingConflictReport {
  const MentorTeachingConflictReport({
    required this.isValid,
    required this.conflicts,
  });

  final bool isValid;
  final List<MentorTeachingConflictItem> conflicts;
}
