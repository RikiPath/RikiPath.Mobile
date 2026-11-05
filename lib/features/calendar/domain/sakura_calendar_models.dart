import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

enum SakuraCalendarViewMode {
  agenda('agenda', 'Lịch biểu', Icons.view_agenda_outlined),
  day('day', 'Ngày', Icons.view_day_outlined),
  threeDay('threeDay', '3 ngày', Icons.view_column_outlined),
  week('week', 'Tuần', Icons.view_week_outlined),
  month('month', 'Tháng', Icons.calendar_view_month_outlined);

  const SakuraCalendarViewMode(this.id, this.labelVi, this.icon);

  final String id;
  final String labelVi;
  final IconData icon;
}

enum SakuraCalendarEventType {
  consultation('consultation', 'Tư vấn JLPT'),
  availableSlot('availableSlot', 'Khung giờ trống'),
  studySession('studySession', 'Học tập');

  const SakuraCalendarEventType(this.id, this.labelVi);

  final String id;
  final String labelVi;
}

@immutable
class SakuraCalendarEvent {
  const SakuraCalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.subtitle,
    this.status,
    this.statusLabel,
    this.participantName,
    this.participantRole,
    this.jlptLevel,
    this.meetingLink,
    this.roomId,
    this.bookingId,
    this.availabilityId,
    this.notes,
    this.isAllDay = false,
    this.customColor,
    this.customBackgroundColor,
  });

  final String id;
  final String title;
  final String? subtitle;
  final DateTime startTime;
  final DateTime endTime;
  final SakuraCalendarEventType type;
  final MentorMeetingStatus? status;
  final String? statusLabel;
  final String? participantName;
  final String? participantRole;
  final String? jlptLevel;
  final String? meetingLink;
  final String? roomId;
  final int? bookingId;
  final int? availabilityId;
  final String? notes;
  final bool isAllDay;

  final Color? customColor;
  final Color? customBackgroundColor;

  Duration get duration => endTime.difference(startTime);
  int get durationMinutes => duration.inMinutes;

  Color get primaryColor {
    final c = customColor;
    if (c != null) return c;
    switch (type) {
      case SakuraCalendarEventType.consultation:
        if (status == MentorMeetingStatus.completed) {
          return const Color(0xFF64748B); // Slate
        } else if (status == MentorMeetingStatus.cancelled) {
          return const Color(0xFF9CA3AF); // Gray
        } else if (status == MentorMeetingStatus.awaitingPayment ||
            status == MentorMeetingStatus.pendingAssignment) {
          return AppColors.warning; // #F59E0B
        }
        return AppColors.success; // #079D47 Confirmed
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFF2563EB); // Royal Blue
      case SakuraCalendarEventType.studySession:
        return AppColors.primary; // Sakura Pink
    }
  }

  Color get backgroundColor {
    final c = customBackgroundColor;
    if (c != null) return c;
    switch (type) {
      case SakuraCalendarEventType.consultation:
        if (status == MentorMeetingStatus.completed) {
          return const Color(0xFFF1F5F9);
        } else if (status == MentorMeetingStatus.cancelled) {
          return const Color(0xFFF3F4F6);
        } else if (status == MentorMeetingStatus.awaitingPayment ||
            status == MentorMeetingStatus.pendingAssignment) {
          return const Color(0xFFFFFBEB); // Amber light
        }
        return const Color(0xFFF0FDF4); // Emerald light
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFFEFF6FF); // Blue light
      case SakuraCalendarEventType.studySession:
        return const Color(0xFFFFF0F3); // Sakura light
    }
  }

  Color get borderColor {
    switch (type) {
      case SakuraCalendarEventType.consultation:
        if (status == MentorMeetingStatus.completed) {
          return const Color(0xFFCBD5E1);
        } else if (status == MentorMeetingStatus.cancelled) {
          return const Color(0xFFE5E7EB);
        } else if (status == MentorMeetingStatus.awaitingPayment ||
            status == MentorMeetingStatus.pendingAssignment) {
          return const Color(0xFFFDE68A);
        }
        return const Color(0xFFBBF7D0);
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFFBFDBFE);
      case SakuraCalendarEventType.studySession:
        return const Color(0xFFFFCCD5);
    }
  }

  bool isSameDay(DateTime date) {
    return startTime.year == date.year &&
        startTime.month == date.month &&
        startTime.day == date.day;
  }

  bool intersectsWith(DateTime start, DateTime end) {
    return startTime.isBefore(end) && endTime.isAfter(start);
  }

  /// Authoritative supported JLPT levels for 1-on-1 mentor consultations (N5, N4, N3, N2 only; N1 disallowed).
  static const supportedConsultationLevels = {'N5', 'N4', 'N3', 'N2'};

  static bool isSupportedConsultationLevel(String? level) {
    if (level == null) return false;
    final normalized = level.replaceAll('JLPT', '').replaceAll(' ', '').toUpperCase();
    return supportedConsultationLevels.contains(normalized);
  }

  static String? normalizeConsultationLevel(String? level) {
    if (level == null) return null;
    final normalized = level.replaceAll('JLPT', '').replaceAll(' ', '').toUpperCase();
    if (supportedConsultationLevels.contains(normalized)) {
      return normalized;
    }
    return null;
  }

  SakuraCalendarEvent copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? startTime,
    DateTime? endTime,
    SakuraCalendarEventType? type,
    MentorMeetingStatus? status,
    String? statusLabel,
    String? participantName,
    String? participantRole,
    String? jlptLevel,
    String? meetingLink,
    String? roomId,
    int? bookingId,
    int? availabilityId,
    String? notes,
    bool? isAllDay,
    Color? customColor,
    Color? customBackgroundColor,
  }) {
    return SakuraCalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      participantName: participantName ?? this.participantName,
      participantRole: participantRole ?? this.participantRole,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      meetingLink: meetingLink ?? this.meetingLink,
      roomId: roomId ?? this.roomId,
      bookingId: bookingId ?? this.bookingId,
      availabilityId: availabilityId ?? this.availabilityId,
      notes: notes ?? this.notes,
      isAllDay: isAllDay ?? this.isAllDay,
      customColor: customColor ?? customColor,
      customBackgroundColor: customBackgroundColor ?? customBackgroundColor,
    );
  }
}
