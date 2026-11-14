import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

/// Role-specific bottom navigation specification consumed by [RikiPathAppShell]
/// and [SakuraBottomNavigation].
abstract class RikiPathNavigationConfiguration {
  const RikiPathNavigationConfiguration();

  /// Ordered shell branch routes corresponding 1:1 with the destinations.
  List<String> get routes;

  /// Optional test/automation key applied to [SakuraBottomNavigation].
  Key? get bottomNavigationKey;

  /// Localized destinations for the active role.
  List<RikiNavigationDestination> destinations(AppLocalizations l10n);

  bool containsRoute(String location) => routes.contains(location);
}

/// Learner 5-tab navigation configuration (Trang chủ, Học tập, Luyện tập, Sổ từ, Cá nhân).
class LearnerNavigationConfiguration extends RikiPathNavigationConfiguration {
  const LearnerNavigationConfiguration();

  static const instance = LearnerNavigationConfiguration();

  static const int tabCount = 5;

  static const List<String> tabRoutes = <String>[
    AppRoutes.home,
    AppRoutes.learn,
    AppRoutes.practice,
    AppRoutes.notebook,
    AppRoutes.profile,
  ];

  static List<RikiNavigationDestination> buildDestinations(
    AppLocalizations l10n,
  ) => <RikiNavigationDestination>[
    RikiNavigationDestination(
      label: l10n.navigationHome,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    RikiNavigationDestination(
      label: l10n.navigationLearn,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    RikiNavigationDestination(
      label: l10n.navigationPractice,
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
    ),
    RikiNavigationDestination(
      label: l10n.navigationNotebook,
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
    ),
    RikiNavigationDestination(
      label: l10n.navigationProfile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  List<String> get routes => tabRoutes;

  @override
  Key? get bottomNavigationKey => const Key('learner_bottom_navigation_bar');

  @override
  List<RikiNavigationDestination> destinations(AppLocalizations l10n) =>
      buildDestinations(l10n);
}

/// Mentor 5-tab navigation configuration (Trang chủ, Lịch dạy, Buổi tư vấn, Lịch trống, Cá nhân).
class MentorNavigationConfiguration extends RikiPathNavigationConfiguration {
  const MentorNavigationConfiguration();

  static const instance = MentorNavigationConfiguration();

  static const int tabCount = 5;

  static const List<String> tabRoutes = <String>[
    AppRoutes.mentor,
    AppRoutes.mentorCalendar,
    AppRoutes.mentorMeetings,
    AppRoutes.mentorAvailability,
    AppRoutes.mentorProfile,
  ];

  static List<RikiNavigationDestination> buildDestinations(
    AppLocalizations l10n,
  ) => <RikiNavigationDestination>[
    RikiNavigationDestination(
      label: l10n.mentorNavHome,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    RikiNavigationDestination(
      label: l10n.mentorNavCalendar,
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    RikiNavigationDestination(
      label: l10n.mentorNavMeetings,
      icon: Icons.video_camera_front_outlined,
      selectedIcon: Icons.video_camera_front,
    ),
    RikiNavigationDestination(
      label: l10n.mentorNavAvailability,
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
    ),
    RikiNavigationDestination(
      label: l10n.mentorNavProfile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  List<String> get routes => tabRoutes;

  @override
  Key? get bottomNavigationKey => const Key('mentor_bottom_navigation_bar');

  @override
  List<RikiNavigationDestination> destinations(AppLocalizations l10n) =>
      buildDestinations(l10n);
}
