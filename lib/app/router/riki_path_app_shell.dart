import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/navigation_configuration.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';

/// Shared application tab shell parameterized by [RikiPathNavigationConfiguration].
///
/// Used by both Learner (`MainShell`) and Mentor (`MentorShell`) so bottom
/// navigation geometry, spring motion, reduced-motion handling, and system
/// back-to-home tab behavior behave identically across roles.
class RikiPathAppShell extends StatelessWidget {
  const RikiPathAppShell({
    required this.navigationShell,
    required this.configuration,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final RikiPathNavigationConfiguration configuration;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = configuration.destinations(context.l10n);
    final currentIndex = navigationShell.currentIndex.clamp(
      0,
      destinations.length - 1,
    );

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        // When the user sits at the root of any secondary tab (index != 0)
        // and no nested route popped first, step smoothly back to Tab 0.
        final router = GoRouter.maybeOf(context);
        if (currentIndex != 0 && !(router?.canPop() ?? false)) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: SakuraBottomNavigation(
          key: configuration.bottomNavigationKey,
          destinations: destinations,
          selectedIndex: currentIndex,
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }
}

/// Shared `StatefulShellRoute.navigatorContainerBuilder` providing a light,
/// non-destructive cross-fade between tab branches while preserving every
/// branch's element identity, state, and scroll offset (identical to `IndexedStack`).
Widget sakuraShellBranchContainerBuilder(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  return SakuraShellBranchContainer(
    currentIndex: navigationShell.currentIndex,
    children: children,
  );
}

class SakuraShellBranchContainer extends StatefulWidget {
  const SakuraShellBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<SakuraShellBranchContainer> createState() =>
      _SakuraShellBranchContainerState();
}

class _SakuraShellBranchContainerState extends State<SakuraShellBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  int? _previousIndex;

  static const _transitionDuration = Duration(milliseconds: 240);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _previousIndex != null) {
        setState(() => _previousIndex = null);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SakuraShellBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final mediaQuery = MediaQuery.maybeOf(context);
      final reduceMotion =
          (mediaQuery?.disableAnimations ?? false) ||
          (mediaQuery?.accessibleNavigation ?? false);
      if (reduceMotion) {
        _previousIndex = null;
        _controller.value = 1;
      } else {
        _previousIndex = oldWidget.currentIndex;
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final t = _curve.value;
        final isAnimating = _controller.isAnimating && _previousIndex != null;
        return Stack(
          fit: StackFit.expand,
          children: List<Widget>.generate(widget.children.length, (index) {
            final isTarget = index == widget.currentIndex;
            final isOutgoing = isAnimating && index == _previousIndex;
            final isOffstage = !isTarget && !isOutgoing;
            final opacity = isTarget
                ? (isAnimating ? t : 1.0)
                : (isOutgoing ? 1.0 : 0.0);

            // Preserve the exact widget wrapper shape around each branch at a
            // fixed stack slot so Flutter never recreates branch Elements.
            return Offstage(
              offstage: isOffstage,
              child: TickerMode(
                enabled: isTarget,
                child: IgnorePointer(
                  ignoring: !isTarget,
                  child: Opacity(
                    opacity: opacity,
                    child: widget.children[index],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
