import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';

@immutable
class SubscriptionPlanOffer {
  const SubscriptionPlanOffer({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.aiUses,
    required this.isPopular,
    required this.kind,
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final int durationDays;
  final int aiUses;
  final bool isPopular;
  final String kind;

  String get kindLabel => switch (kind) {
    'speaking' => 'Luyện nói AI',
    'writing' => 'Luyện viết AI',
    'ai_grading' => 'Chấm bài AI',
    'learning_path' => 'Lộ trình học AI',
    _ => 'Tự học tổng hợp',
  };
}

@immutable
class PurchasedSubscriptionRecord {
  const PurchasedSubscriptionRecord({
    required this.id,
    required this.planId,
    required this.planName,
    required this.amountPaid,
    required this.active,
    required this.aiUsesRemaining,
    this.startDate,
    this.endDate,
  });

  final int id;
  final int planId;
  final String planName;
  final double amountPaid;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
  final int aiUsesRemaining;
}

@immutable
class StudyAccessStatus {
  const StudyAccessStatus({
    required this.active,
    required this.speaking,
    required this.writing,
    required this.aiGradingUsesRemaining,
    required this.speakingUsesRemaining,
    required this.writingUsesRemaining,
    required this.learningPathUsesRemaining,
    required this.purchases,
    this.planName,
    this.selfStudyExpiresAt,
    this.selfStudyDaysRemaining,
  });

  final bool active;
  final String? planName;
  final bool speaking;
  final bool writing;
  final int aiGradingUsesRemaining;
  final int speakingUsesRemaining;
  final int writingUsesRemaining;
  final int learningPathUsesRemaining;
  final DateTime? selfStudyExpiresAt;
  final int? selfStudyDaysRemaining;
  final List<PurchasedSubscriptionRecord> purchases;
}

@immutable
class SubscriptionCheckoutResult {
  const SubscriptionCheckoutResult({
    required this.purchaseId,
    required this.checkoutUrl,
  });

  final int purchaseId;
  final String checkoutUrl;
}

bool isSubscriptionOrAiGateError(Object error) =>
    error is ApiError &&
    const {
      'SELF_STUDY_PACKAGE_REQUIRED',
      'AI_CREDIT_REQUIRED',
      'WRITING_PACKAGE_REQUIRED',
    }.contains(error.errorCode);
