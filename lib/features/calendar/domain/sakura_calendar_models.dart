import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

enum SakuraCalendarViewMode {
  agenda('agenda', 'Lịch biểu', Icons.view_agenda_outlined),
  day('day', 'Ngày', Icons.view_day_outlined),
  week('week', 'Tuần', Icons.view_week_outlined),
  month('month', 'Tháng', Icons.calendar_view_month_outlined),
  year('year', 'Năm', Icons.calendar_today_outlined);

  const SakuraCalendarViewMode(this.id, this.labelVi, this.icon);

  final String id;
  final String labelVi;
  final IconData icon;
}

enum SakuraCalendarEventType {
  consultation('consultation', 'Tư vấn 1-1'),
  availableSlot('availableSlot', 'Lịch tư vấn còn trống'),
  studySession('studySession', 'Học tập'),
  srsReview('srsReview', 'Ôn tập'),
  learningPlan('learningPlan', 'Bài học'),
  practiceTest('practiceTest', 'Luyện đề');

  const SakuraCalendarEventType(this.id, this.labelVi);

  final String id;
  final String labelVi;

  IconData get icon => switch (this) {
    SakuraCalendarEventType.consultation => Icons.forum_outlined,
    SakuraCalendarEventType.availableSlot => Icons.event_available_outlined,
    SakuraCalendarEventType.studySession ||
    SakuraCalendarEventType.learningPlan => Icons.menu_book_outlined,
    SakuraCalendarEventType.srsReview => Icons.style_outlined,
    SakuraCalendarEventType.practiceTest => Icons.assignment_outlined,
  };
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
    this.sourceProvider,
    this.sourceEntityId,
    this.navigationTarget,
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
  final String? sourceProvider;
  final String? sourceEntityId;
  final String? navigationTarget;

  Duration get duration => endTime.difference(startTime);
  int get durationMinutes => duration.inMinutes;

  /// Category Identity Styling Tokens (Sakura Pink - Independent of Status)
  static const Color mentorConsultationDotColor = Color(0xFFE5577F);
  static const Color mentorConsultationTextColor = Color(0xFFD94672);
  static const Color mentorConsultationBgColor = Color(0xFFFFF1F5);
  static const Color mentorAvatarBgColor = Color(0xFFFCE7EF);
  static const Color mentorAvatarBorderColor = Color(0xFFF8C7D8);
  static const Color mentorAvatarFgColor = Color(0xFFE5577F);

  Color get primaryColor {
    final c = customColor;
    if (c != null) return c;
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFF3B82F6); // Confirmed accent: Blue (#3B82F6)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFF22C55E); // Completed accent: Green (#22C55E)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFF43F5E); // Cancelled accent: Red (#F43F5E)
    }
    if (status == MentorMeetingStatus.assigned) {
      return const Color(0xFFE11D48); // Assigned accent: Rose (#E11D48)
    }
    switch (type) {
      case SakuraCalendarEventType.consultation:
        return AppColors.primary;
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFF94A3B8); // Available slot accent: Slate (#94A3B8)
      case SakuraCalendarEventType.studySession:
        return AppColors.primary;
      case SakuraCalendarEventType.srsReview:
        return const Color(0xFFF59E0B); // SRS accent: Amber (#F59E0B)
      case SakuraCalendarEventType.learningPlan:
        return const Color(0xFF22C55E); // Completed lesson accent: Green (#22C55E)
      case SakuraCalendarEventType.practiceTest:
        return const Color(0xFF3B82F6); // Practice test accent: Blue (#3B82F6)
    }
  }

  Color get backgroundColor {
    final c = customBackgroundColor;
    if (c != null) return c;
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFFEEF6FF); // Confirmed card background: Blue (#EEF6FF)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFFECFDF5); // Completed card background: Green (#ECFDF5)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFFFF1F2); // Cancelled card background: Red (#FFF1F2)
    }
    if (status == MentorMeetingStatus.assigned) {
      return const Color(0xFFFFF1F2); // Assigned card background: Soft Rose (#FFF1F2)
    }
    switch (type) {
      case SakuraCalendarEventType.consultation:
        return const Color(0xFFFFF1F2);
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFFF8FAFC); // Available slot background: Neutral (#F8FAFC)
      case SakuraCalendarEventType.studySession:
        return const Color(0xFFFFF1F2);
      case SakuraCalendarEventType.srsReview:
        return const Color(0xFFFFFBEB); // SRS background: Amber (#FFFBEB)
      case SakuraCalendarEventType.learningPlan:
        return const Color(0xFFECFDF5); // Completed lesson background: Green (#ECFDF5)
      case SakuraCalendarEventType.practiceTest:
        return const Color(0xFFEEF6FF);
    }
  }

  Color get borderColor {
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFFBFDBFE); // Confirmed border: Blue (#BFDBFE)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFFA7E5C4); // Completed border: Green (#A7E5C4)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFFECDD3); // Cancelled border: Red (#FECDD3)
    }
    if (status == MentorMeetingStatus.assigned) {
      return const Color(0xFFFFE4E6); // Assigned border: Rose (#FFE4E6)
    }
    switch (type) {
      case SakuraCalendarEventType.consultation:
        return const Color(0xFFFFE4E6);
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFFE2E8F0); // Available slot border: Neutral (#E2E8F0)
      case SakuraCalendarEventType.studySession:
        return const Color(0xFFFFE4E6);
      case SakuraCalendarEventType.srsReview:
        return const Color(0xFFFDE68A); // SRS border: Amber (#FDE68A)
      case SakuraCalendarEventType.learningPlan:
        return const Color(0xFFA7E5C4); // Completed lesson border: Green (#A7E5C4)
      case SakuraCalendarEventType.practiceTest:
        return const Color(0xFFBFDBFE);
    }
  }

  Color get statusBadgeTextColor {
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFF2563EB); // Confirmed badge text: Blue (#2563EB)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFF059669); // Completed badge text: Green (#059669)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFBE123C); // Cancelled badge text: Red (#BE123C)
    }
    if (status == MentorMeetingStatus.assigned) {
      return const Color(0xFFBE123C); // Assigned badge text: Rose (#BE123C)
    }
    switch (type) {
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFF475569); // Available slot badge text: Slate (#475569)
      case SakuraCalendarEventType.srsReview:
        return const Color(0xFF92400E); // SRS badge text: Amber (#92400E)
      case SakuraCalendarEventType.learningPlan:
        return const Color(0xFF059669); // Completed lesson badge text: Green (#059669)
      case SakuraCalendarEventType.practiceTest:
        return const Color(0xFF2563EB);
      case SakuraCalendarEventType.consultation:
      case SakuraCalendarEventType.studySession:
        return const Color(0xFFFFFFFF);
    }
  }

  Color get statusBadgeBgColor {
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFFDBEAFE); // Confirmed badge background: Blue (#DBEAFE)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFFD1FAE5); // Completed badge background: Green (#D1FAE5)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFFFE4E6); // Cancelled badge background: Red (#FFE4E6)
    }
    if (status == MentorMeetingStatus.assigned) {
      return const Color(0xFFFFE4E6); // Assigned badge background: Rose (#FFE4E6)
    }
    switch (type) {
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFFE2E8F0); // Available slot badge background: Neutral (#E2E8F0)
      case SakuraCalendarEventType.srsReview:
        return const Color(0xFFFEF3C7); // SRS badge background: Amber (#FEF3C7)
      case SakuraCalendarEventType.learningPlan:
        return const Color(0xFFD1FAE5); // Completed lesson badge background: Green (#D1FAE5)
      case SakuraCalendarEventType.practiceTest:
        return const Color(0xFFDBEAFE);
      case SakuraCalendarEventType.consultation:
      case SakuraCalendarEventType.studySession:
        return AppColors.primary;
    }
  }

  Color get statusBadgeBorderColor {
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFFBFDBFE); // Confirmed badge border: Blue (#BFDBFE)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFFA7E5C4); // Completed badge border: Green (#A7E5C4)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFFECDD3); // Cancelled badge border: Red (#FECDD3)
    }
    if (status == MentorMeetingStatus.assigned) {
      return const Color(0xFFFFE4E6); // Assigned badge border: Rose (#FFE4E6)
    }
    switch (type) {
      case SakuraCalendarEventType.availableSlot:
        return const Color(0xFFCBD5E1); // Available slot badge border: Slate (#CBD5E1)
      case SakuraCalendarEventType.srsReview:
        return const Color(0xFFFDE68A); // SRS badge border: Amber (#FDE68A)
      case SakuraCalendarEventType.learningPlan:
        return const Color(0xFFA7E5C4); // Completed lesson badge border: Green (#A7E5C4)
      case SakuraCalendarEventType.practiceTest:
        return const Color(0xFFBFDBFE);
      case SakuraCalendarEventType.consultation:
      case SakuraCalendarEventType.studySession:
        return AppColors.primary;
    }
  }

  IconData? get statusBadgeIcon {
    if (status == MentorMeetingStatus.accepted) {
      return Icons.check;
    }
    if (status == MentorMeetingStatus.completed) {
      return Icons.check;
    }
    if (status == MentorMeetingStatus.cancelled) {
      return Icons.close;
    }
    if (type == SakuraCalendarEventType.learningPlan) {
      return Icons.check;
    }
    return null;
  }

  /// JLPT Level Chip Background Color (harmonized with Event Card status)
  Color get levelChipBgColor {
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFFEFF6FF); // Confirmed chip background (#EFF6FF)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFFECFDF5); // Completed chip background (#ECFDF5)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFFFF1F2); // Cancelled chip background (#FFF1F2)
    }
    if (type == SakuraCalendarEventType.availableSlot) {
      return const Color(0xFFF8FAFC); // Available chip background (#F8FAFC)
    }
    if (type == SakuraCalendarEventType.srsReview) {
      return const Color(0xFFFFFBEB); // SRS chip background (#FFFBEB)
    }
    return const Color(0xFFF8FAFC);
  }

  /// JLPT Level Chip Border Color (harmonized with Event Card status)
  Color get levelChipBorderColor {
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFF93C5FD); // Confirmed chip border (#93C5FD)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFF86EFAC); // Completed chip border (#86EFAC)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFFDA4AF); // Cancelled chip border (#FDA4AF)
    }
    if (type == SakuraCalendarEventType.availableSlot) {
      return const Color(0xFFCBD5E1); // Available chip border (#CBD5E1)
    }
    if (type == SakuraCalendarEventType.srsReview) {
      return const Color(0xFFFDE68A); // SRS chip border (#FDE68A)
    }
    return const Color(0xFFCBD5E1);
  }

  /// JLPT Level Chip Text Color (harmonized with Event Card status)
  Color get levelChipTextColor {
    if (status == MentorMeetingStatus.accepted) {
      return const Color(0xFF2563EB); // Confirmed chip text (#2563EB)
    }
    if (status == MentorMeetingStatus.completed) {
      return const Color(0xFF059669); // Completed chip text (#059669)
    }
    if (status == MentorMeetingStatus.cancelled) {
      return const Color(0xFFBE123C); // Cancelled chip text (#BE123C)
    }
    if (type == SakuraCalendarEventType.availableSlot) {
      return const Color(0xFF475569); // Available chip text (#475569)
    }
    if (type == SakuraCalendarEventType.srsReview) {
      return const Color(0xFF92400E); // SRS chip text (#92400E)
    }
    return const Color(0xFF475569);
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
    final normalized = level
        .replaceAll('JLPT', '')
        .replaceAll(' ', '')
        .toUpperCase();
    return supportedConsultationLevels.contains(normalized);
  }

  static String? normalizeConsultationLevel(String? level) {
    if (level == null) return null;
    final normalized = level
        .replaceAll('JLPT', '')
        .replaceAll(' ', '')
        .toUpperCase();
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
    String? sourceProvider,
    String? sourceEntityId,
    String? navigationTarget,
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
      customColor: customColor ?? this.customColor,
      customBackgroundColor:
          customBackgroundColor ?? this.customBackgroundColor,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      sourceEntityId: sourceEntityId ?? this.sourceEntityId,
      navigationTarget: navigationTarget ?? this.navigationTarget,
    );
  }
}
