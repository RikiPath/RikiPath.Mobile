import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

@immutable
class HomeDashboard {
  const HomeDashboard({
    required this.learnerName,
    required this.initials,
    this.jlptTarget,
    this.streakDays,
    this.hasUnreadNotifications,
    this.journeyStatus,
    this.goalStatus,
    this.firstLesson,
    this.roadmap,
    this.setup,
    this.tools = const <HomeToolSummary>[],
  });

  final String learnerName;
  final String initials;
  final JlptLevel? jlptTarget;
  final int? streakDays;
  final bool? hasUnreadNotifications;
  final String? journeyStatus;
  final String? goalStatus;
  final HomeLessonSummary? firstLesson;
  final HomeRoadmapSummary? roadmap;
  final HomeSetupSummary? setup;
  final List<HomeToolSummary> tools;
}

@immutable
class HomeLessonSummary {
  const HomeLessonSummary({
    required this.eyebrow,
    required this.badge,
    required this.title,
    required this.description,
    required this.completedParts,
    required this.totalParts,
  });

  final String eyebrow;
  final String badge;
  final String title;
  final String description;
  final int completedParts;
  final int totalParts;

  double get progress => totalParts == 0 ? 0 : completedParts / totalParts;
}

@immutable
class HomeRoadmapSummary {
  const HomeRoadmapSummary({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.stageCount,
  });

  final String title;
  final String subtitle;
  final String description;
  final int stageCount;
}

@immutable
class HomeSetupSummary {
  const HomeSetupSummary({
    required this.completedCount,
    required this.totalCount,
    required this.items,
  });

  final int completedCount;
  final int totalCount;
  final List<HomeSetupItem> items;
}

@immutable
class HomeSetupItem {
  const HomeSetupItem({
    required this.title,
    required this.description,
    required this.isComplete,
    this.actionLabel,
  });

  final String title;
  final String description;
  final bool isComplete;
  final String? actionLabel;
}

enum HomeToolDestination { notebook, practice }

@immutable
class HomeToolSummary {
  const HomeToolSummary({
    required this.title,
    required this.description,
    required this.destination,
  });

  final String title;
  final String description;
  final HomeToolDestination destination;
}
