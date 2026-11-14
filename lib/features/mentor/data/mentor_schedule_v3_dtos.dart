import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_schedule_v3.dart';

class MentorScheduleV3Dto {
  MentorScheduleV3Dto._();

  static MentorScheduleV3 fromJson(Map<String, Object?> json) {
    final rawRules = json['rules'];
    final rules = <MentorScheduleRule>[];
    if (rawRules is List<Object?>) {
      for (final raw in rawRules) {
        final item = readMapOrEmpty(raw);
        if (item.isEmpty) continue;
        rules.add(ruleFromJson(item));
      }
    }
    return MentorScheduleV3(
      scheduleId: readIntOrZero(json, 'scheduleId'),
      mentorId: readIntOrZero(json, 'mentorId'),
      mentorName: readStringOrEmpty(json, 'mentorName'),
      policyVersion: readOptionalInt(json, 'policyVersion') ?? 3,
      timeZoneId: readOptionalString(json, 'timeZoneId') ?? 'Asia/Ho_Chi_Minh',
      autoPublish: readBoolOrFalse(json, 'autoPublish'),
      effectiveFrom:
          readOptionalDateOnly(json, 'effectiveFrom') ?? DateTime.now(),
      generatedThrough: readOptionalDateOnly(json, 'generatedThrough'),
      createdAtUtc: readRequiredTimestamp(json, 'createdAtUtc'),
      rules: rules,
    );
  }

  static MentorScheduleRule ruleFromJson(Map<String, Object?> json) {
    return MentorScheduleRule(
      id: readIntOrZero(json, 'id'),
      scheduleId: readIntOrZero(json, 'scheduleId'),
      weekday: readIntOrZero(json, 'weekday'),
      weekdayName: readStringOrEmpty(json, 'weekdayName'),
      daypart: MentorDaypart.fromApiValue(
        readStringOrEmpty(json, 'daypartCode'),
      ),
      localStart: readStringOrEmpty(json, 'localStart'),
      localEnd: readStringOrEmpty(json, 'localEnd'),
      effectiveFrom:
          readOptionalDateOnly(json, 'effectiveFrom') ?? DateTime.now(),
      effectiveTo: readOptionalDateOnly(json, 'effectiveTo'),
    );
  }

  static Map<String, Object?> updateToJson(
    UpdateMentorScheduleV3Request request,
  ) {
    return {
      'timeZoneId': request.timeZoneId,
      'autoPublish': request.autoPublish,
      'effectiveFrom': formatDateOnly(request.effectiveFrom),
      'rules': request.rules
          .map(
            (rule) => {
              'weekday': rule.weekday,
              'daypartCode': rule.daypart.apiValue,
              'localStart': rule.localStart,
              'localEnd': rule.localEnd,
              'effectiveFrom': formatDateOnly(rule.effectiveFrom),
              if (rule.effectiveTo != null)
                'effectiveTo': formatDateOnly(rule.effectiveTo!),
            },
          )
          .toList(growable: false),
    };
  }

  static MentorSlotPreviewResult previewFromJson(Map<String, Object?> json) {
    final rawSlots = json['slots'];
    final slots = <MentorSlotPreviewItem>[];
    if (rawSlots is List<Object?>) {
      for (final raw in rawSlots) {
        final item = readMapOrEmpty(raw);
        if (item.isEmpty) continue;
        slots.add(
          MentorSlotPreviewItem(
            localDate: readRequiredDateOnly(item, 'localDate'),
            daypart: MentorDaypart.fromApiValue(
              readStringOrEmpty(item, 'daypartCode'),
            ),
            startUtc: readRequiredTimestamp(item, 'startUtc'),
            endUtc: readRequiredTimestamp(item, 'endUtc'),
            localStart: readStringOrEmpty(item, 'localStart'),
            localEnd: readStringOrEmpty(item, 'localEnd'),
            generationKey: readStringOrEmpty(item, 'generationKey'),
            isExisting: readBoolOrFalse(item, 'isExisting'),
            hasConflict: readBoolOrFalse(item, 'hasConflict'),
            conflictReason: readOptionalString(item, 'conflictReason'),
          ),
        );
      }
    }
    return MentorSlotPreviewResult(
      totalCandidateSlots: readIntOrZero(json, 'totalCandidateSlots'),
      existingSlotsCount: readIntOrZero(json, 'existingSlotsCount'),
      newSlotsCount: readIntOrZero(json, 'newSlotsCount'),
      conflictSlotsCount: readIntOrZero(json, 'conflictSlotsCount'),
      startDate: readRequiredDateOnly(json, 'startDate'),
      endDate: readRequiredDateOnly(json, 'endDate'),
      slots: slots,
    );
  }

  static MentorPublishSlotsResult publishFromJson(Map<String, Object?> json) {
    final rawSlots = json['publishedSlots'];
    final slots = <MentorPublishedSlotItem>[];
    if (rawSlots is List<Object?>) {
      for (final raw in rawSlots) {
        final item = readMapOrEmpty(raw);
        if (item.isEmpty) continue;
        slots.add(
          MentorPublishedSlotItem(
            availabilityId: readIntOrZero(item, 'availabilityId'),
            localDate: readRequiredDateOnly(item, 'localDate'),
            daypart: MentorDaypart.fromApiValue(
              readStringOrEmpty(item, 'daypartCode'),
            ),
            startTimeUtc: readRequiredTimestamp(item, 'startTimeUtc'),
            endTimeUtc: readRequiredTimestamp(item, 'endTimeUtc'),
            localStart: readStringOrEmpty(item, 'localStart'),
            localEnd: readStringOrEmpty(item, 'localEnd'),
            generationKey: readStringOrEmpty(item, 'generationKey'),
            isApproved: readBoolOrFalse(item, 'isApproved'),
          ),
        );
      }
    }
    return MentorPublishSlotsResult(
      createdCount: readIntOrZero(json, 'createdCount'),
      skippedExistingCount: readIntOrZero(json, 'skippedExistingCount'),
      totalSlotsProcessed: readIntOrZero(json, 'totalSlotsProcessed'),
      generatedThrough: readRequiredDateOnly(json, 'generatedThrough'),
      publishedSlots: slots,
    );
  }
}
