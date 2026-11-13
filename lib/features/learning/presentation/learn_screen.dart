import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/core/widgets/sakura_scroll_scaffold.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_library_home.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/personalized_roadmap_home.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';

enum _LearningTab { roadmap, library }

/// Lộ trình AI và thư viện bài học/tài nguyên là hai điểm vào độc lập.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  _LearningTab _tab = _LearningTab.roadmap;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(learnerAnalyticsControllerProvider);
    final notificationState = ref.watch(notificationControllerProvider);
    final analytics = analyticsState.value;
    final liveStreak = analytics?.isAvailable(AnalyticsSection.streak) == true
        ? analytics?.streakDays
        : null;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SakuraScrollScaffold(
      backgroundColor: AppColors.learnerBackground,
      appBarBuilder: (context, isScrolled) => SakuraAppHeader(
        isScrolled: isScrolled,
        streakDays: liveStreak,
        isStreakLoading: analyticsState.isLoading,
        unreadNotificationCount: notificationState.value?.unreadCount,
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
        onCalendarPressed: () => context.push(AppRoutes.calendar),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _LearningTabSwitcher(
                selected: _tab,
                reduceMotion: reduceMotion,
                onSelect: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: PageStorage(
                bucket: _pageStorageBucket,
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: switch (_tab) {
                      _LearningTab.roadmap => PersonalizedRoadmapHome(
                        onShowLessons: () =>
                            setState(() => _tab = _LearningTab.library),
                      ),
                      _LearningTab.library => const LearningLibraryHome(),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningTabSwitcher extends StatelessWidget {
  const _LearningTabSwitcher({
    required this.selected,
    required this.reduceMotion,
    required this.onSelect,
  });

  final _LearningTab selected;
  final bool reduceMotion;
  final ValueChanged<_LearningTab> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1.0);
      final height = textScale > 1.15
          ? (48.0 * textScale.clamp(1.0, 1.35)).clamp(48.0, 56.0)
          : 48.0;
      final motionDuration = reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 250);
      const motionCurve = Curves.easeInOutCubic;
      final halfWidth = constraints.maxWidth / 2;
      const indicatorPadding = 3.0;

      return Container(
        key: const ValueKey('learning_section_tabs'),
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1EDEF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: motionDuration,
              curve: motionCurve,
              top: indicatorPadding,
              bottom: indicatorPadding,
              left: selected == _LearningTab.roadmap
                  ? indicatorPadding
                  : halfWidth,
              width: halfWidth - indicatorPadding,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (final entry in const [
                  (_LearningTab.roadmap, 'Lộ trình', Icons.map_outlined),
                  (_LearningTab.library, 'Thư viện', Icons.inventory_2_outlined),
                ])
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: selected == entry.$1,
                      child: InkWell(
                        onTap: () => onSelect(entry.$1),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<Color?>(
                                    duration: motionDuration,
                                    curve: motionCurve,
                                    tween: ColorTween(
                                      end: selected == entry.$1
                                          ? AppColors.brandPrimary
                                          : AppColors.textSecondary,
                                    ),
                                    builder: (context, color, _) => Icon(
                                      entry.$3,
                                      size: 17,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AnimatedDefaultTextStyle(
                                    duration: motionDuration,
                                    curve: motionCurve,
                                    style: TextStyle(
                                      color: selected == entry.$1
                                          ? AppColors.brandPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      letterSpacing: -0.1,
                                    ),
                                    child: Text(entry.$2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
