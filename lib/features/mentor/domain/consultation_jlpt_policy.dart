const List<String> supportedConsultationJlptLevels = <String>[
  'N5',
  'N4',
  'N3',
  'N2',
];

String normalizeConsultationJlptLevel(String? raw) {
  return (raw ?? '').trim().toUpperCase();
}

bool isSupportedConsultationJlptLevel(String? raw) {
  final normalized = normalizeConsultationJlptLevel(raw);
  return supportedConsultationJlptLevels.contains(normalized);
}

String? validateBookingJlptEligibility({
  required String? selectedJlptLevel,
  required List<String> mentorQualifiedLevels,
  required int availableTicketsForLevel,
  required bool requireTicketNow,
}) {
  final normalized = normalizeConsultationJlptLevel(selectedJlptLevel);
  if (!isSupportedConsultationJlptLevel(normalized)) {
    return 'Hệ thống tư vấn 1-1 chỉ hỗ trợ trình độ JLPT N5, N4, N3 và N2 (không hỗ trợ N1).';
  }
  if (mentorQualifiedLevels.isNotEmpty &&
      !mentorQualifiedLevels
          .map(normalizeConsultationJlptLevel)
          .contains(normalized)) {
    return 'Cố vấn chưa được cấp quyền hướng dẫn trình độ JLPT $normalized.';
  }
  if (requireTicketNow && availableTicketsForLevel <= 0) {
    return 'Bạn chưa có vé tư vấn khả dụng cho trình độ JLPT $normalized. Vui lòng mua gói cùng trình độ.';
  }
  return null;
}
