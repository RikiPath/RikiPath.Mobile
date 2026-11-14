import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Backward-compatible alias preserved for existing Learner call sites/tests.
typedef RikiBottomNavigationBar = SakuraBottomNavigation;

/// Semantic alias matching the shared [SakuraBottomNavigation] component name.
typedef SakuraNavigationDestination = RikiNavigationDestination;

/// Sakura Floating Curved Navigation Bar shared across Learner and Mentor roles.
///
/// Role destinations, icons, and labels are injected via [destinations] (e.g.
/// `LearnerNavigationConfiguration` / `MentorNavigationConfiguration`) so this
/// shared presentation component holds zero role-specific route tables.
///
/// Features:
/// - Warm white navigation surface flush with bottom SafeArea
/// - Smoothly damped curved dome + coral-pink gradient floating circle
/// - Compact circle & icon sizing aligned cleanly on the active tab center
/// - Non-overlapping active/inactive icon handoff (never shows duplicate icons
///   for the same tab) and synchronized label color/weight transitions
/// - Responsive equal-width item geometry bounded safely within 360dp / 393dp / 412dp+
/// - Accessible >= 48dp tap targets, reduced-motion snap, and 2x text-scale expansion
class SakuraBottomNavigation extends StatefulWidget {
  const SakuraBottomNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.activeIconColor = Colors.white,
    this.inactiveIconColor = AppColors.textSecondary,
    this.activeLabelColor = AppColors.brandPrimary,
    this.inactiveLabelColor = AppColors.textSecondary,
    this.activeIndicatorGradient = const [
      AppColors.sakura400,
      AppColors.brandPrimary,
    ],
    this.backgroundColor = AppColors.cardWarmWhite,
    this.shadowColor = const Color(0x18000000),
    super.key,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final List<RikiNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color activeIconColor;
  final Color inactiveIconColor;
  final Color activeLabelColor;
  final Color inactiveLabelColor;
  final List<Color> activeIndicatorGradient;
  final Color backgroundColor;
  final Color shadowColor;

  @override
  State<SakuraBottomNavigation> createState() => _SakuraBottomNavigationState();
}

class _SakuraBottomNavigationState extends State<SakuraBottomNavigation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _previousIndex;
  late int _displayedTargetIndex;
  late double _transitionStartPos;

  static const _indicatorDiameter = 40.0;
  static const _maximumMotionVelocity = 18.0; // Tab widths per second.

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _displayedTargetIndex = widget.selectedIndex;
    _transitionStartPos = widget.selectedIndex.toDouble();
    _controller = AnimationController.unbounded(
      vsync: this,
      value: widget.selectedIndex.toDouble(),
    )..addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    if (!mounted) {
      return;
    }
    final targetPos = widget.selectedIndex.toDouble();
    if (_previousIndex != widget.selectedIndex ||
        _displayedTargetIndex != widget.selectedIndex ||
        _transitionStartPos != targetPos) {
      setState(() {
        _previousIndex = widget.selectedIndex;
        _displayedTargetIndex = widget.selectedIndex;
        _transitionStartPos = targetPos;
      });
    }
  }

  double _transitionProgressFor(double animPos) {
    if (_previousIndex == _displayedTargetIndex) {
      return 1.0;
    }
    final delta = _displayedTargetIndex - _transitionStartPos;
    if (delta.abs() < 0.05) {
      return 1.0;
    }
    return ((animPos - _transitionStartPos) / delta).clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant SakuraBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxIndex = (widget.destinations.length - 1).toDouble();
    final targetPosition = widget.selectedIndex.toDouble().clamp(0.0, maxIndex);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.destinations.length != widget.destinations.length) {
      final currentPos = _controller.value.clamp(0.0, maxIndex);
      final currentProgress = _transitionProgressFor(currentPos);
      final mediaQuery = MediaQuery.maybeOf(context);
      final disableAnimations =
          (mediaQuery?.disableAnimations ?? false) ||
          (mediaQuery?.accessibleNavigation ?? false);
      if (disableAnimations) {
        _controller.stop();
        _controller.value = targetPosition;
        _previousIndex = widget.selectedIndex;
        _displayedTargetIndex = widget.selectedIndex;
        _transitionStartPos = targetPosition;
      } else {
        // Keep the icon currently visible inside the floating circle as the
        // outgoing index so rapid reversals never spawn duplicate icons.
        final currentCircleIndex =
            currentProgress < 0.48 ? _previousIndex : _displayedTargetIndex;
        _previousIndex = currentCircleIndex.clamp(
          0,
          widget.destinations.length - 1,
        );
        _displayedTargetIndex = widget.selectedIndex;
        _transitionStartPos = currentPos;

        // Critically damped glide settles cleanly onto the exact tab center
        // without bounce or overshooting past edge items.
        final distance = (targetPosition - currentPos).abs();
        final spring = SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: distance >= 3
              ? 280
              : distance >= 1.5
              ? 310
              : 340,
          ratio: 1.0,
        );
        _controller.animateWith(
          SpringSimulation(
            spring,
            currentPos,
            targetPosition,
            _controller.isAnimating
                ? _controller.velocity.clamp(
                    -_maximumMotionVelocity,
                    _maximumMotionVelocity,
                  )
                : 0.0,
            tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = widget.destinations;
    final itemCount = destinations.length;
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledLabelSize = textScaler.scale(11);
    final largeText = scaledLabelSize >= 17;

    // Compact shared visual geometry matching Learner & Mentor 1:1.
    // Keeps the 40dp active circle and dome strictly inside navigationHeight.
    final bumpHeight = largeText ? 10.0 : 12.0;
    final baselineOffset = largeText ? 12.0 : 14.0;
    const circleRadius = _indicatorDiameter / 2;
    final circleCenterY = baselineOffset + 9.0;

    final navigationHeight = largeText
        ? 112.0
        : 64.0 + (scaledLabelSize - 11).clamp(0.0, 6.0) * 4;
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final totalHeight = navigationHeight + safeAreaBottom;

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / itemCount;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final maxIndex = (itemCount - 1).toDouble();
              final reduceMotion =
                  MediaQuery.disableAnimationsOf(context) ||
                  MediaQuery.accessibleNavigationOf(context);
              final isAnimating = _controller.isAnimating && !reduceMotion;
              final animPos = (isAnimating
                      ? _controller.value
                      : widget.selectedIndex.toDouble())
                  .clamp(0.0, maxIndex);
              final velocity = isAnimating ? _controller.velocity : 0.0;
              final edgeInset = width >= _indicatorDiameter ? circleRadius : 0.0;
              final activeCenterX = ((animPos + 0.5) * itemWidth).clamp(
                edgeInset,
                width - edgeInset,
              );

              final isSettled =
                  !isAnimating || _previousIndex == _displayedTargetIndex;
              final progress = isSettled ? 1.0 : _transitionProgressFor(animPos);
              final showingOutgoing = !isSettled && progress < 0.48;
              final int circleIconIndex = (showingOutgoing
                      ? _previousIndex
                      : _displayedTargetIndex)
                  .clamp(0, itemCount - 1);
              final double circleIconOpacity = isSettled
                  ? 1.0
                  : showingOutgoing
                  ? Curves.easeOut.transform(
                      ((0.48 - progress) / 0.28).clamp(0.0, 1.0),
                    )
                  : Curves.easeIn.transform(
                      ((progress - 0.48) / 0.28).clamp(0.0, 1.0),
                    );

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Curved surface with soft top ambient shadow
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: SakuraCurvedNavigationPainter(
                          activePosition: animPos,
                          velocity: velocity,
                          itemCount: itemCount,
                          backgroundColor: widget.backgroundColor,
                          bumpHeight: bumpHeight,
                          baselineOffset: baselineOffset,
                          bumpHalfWidth: 34.0,
                          shadowColor: widget.shadowColor,
                          minEdgeInset: edgeInset,
                        ),
                      ),
                    ),
                  ),

                  // 2. Equal-width tab targets (>= 48dp height) + labels + inactive icons
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: safeAreaBottom,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List<Widget>.generate(itemCount, (index) {
                        final destination = destinations[index];
                        final isSelected = widget.selectedIndex == index;
                        final distance = (animPos - index).abs();
                        final proximityOpacity = Curves.easeInOutCubic
                            .transform(((distance - 0.15) / 0.65).clamp(0.0, 1.0));

                        // Strict mutual exclusion: never render a tab's inactive
                        // icon while that tab's active icon can be visible inside
                        // the floating circle (including mid-transition).
                        final double handoffOpacity;
                        if (isSettled) {
                          handoffOpacity = isSelected ? 0.0 : 1.0;
                        } else if (index == _displayedTargetIndex) {
                          handoffOpacity = (1.0 - (progress - 0.05) / 0.30)
                              .clamp(0.0, 1.0);
                        } else if (index == _previousIndex) {
                          handoffOpacity = ((progress - 0.55) / 0.30).clamp(
                            0.0,
                            1.0,
                          );
                        } else {
                          handoffOpacity = 1.0;
                        }

                        final iconOpacity = (proximityOpacity * handoffOpacity)
                            .clamp(0.0, 1.0);
                        final selectionProgress = Curves.easeInOutCubic
                            .transform((1 - distance).clamp(0.0, 1.0));

                        return Expanded(
                          child: _NavigationTabItem(
                            destination: destination,
                            isSelected: isSelected,
                            iconOpacity: iconOpacity,
                            selectionProgress: selectionProgress,
                            baselineOffset: baselineOffset,
                            largeText: largeText,
                            activeLabelColor: widget.activeLabelColor,
                            inactiveLabelColor: widget.inactiveLabelColor,
                            inactiveIconColor: widget.inactiveIconColor,
                            onPressed: () =>
                                widget.onDestinationSelected(index),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 3. Compact Floating Active Circle Indicator (fixed scale, exact center)
                  Positioned(
                    left: activeCenterX - circleRadius,
                    top: circleCenterY - circleRadius,
                    child: IgnorePointer(
                      child: Container(
                        key: const ValueKey<String>(
                          'sakura_floating_active_indicator',
                        ),
                        width: _indicatorDiameter,
                        height: _indicatorDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.activeIndicatorGradient,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33E05A7A),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: circleIconOpacity,
                            child: Icon(
                              destinations[circleIconIndex].selectedIcon,
                              color: widget.activeIconColor,
                              size: largeText ? 18 : 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Geometry shared by the notch path and its focused motion tests.
class SakuraNotchGeometry {
  const SakuraNotchGeometry({
    required this.centerX,
    required this.leftStart,
    required this.rightEnd,
    required this.pull,
  });

  final double centerX;
  final double leftStart;
  final double rightEnd;
  final double pull;
}

/// A curved surface whose leading edge stretches softly with the circle's velocity.
class SakuraCurvedNavigationPainter extends CustomPainter {
  const SakuraCurvedNavigationPainter({
    required this.activePosition,
    required this.velocity,
    required this.itemCount,
    required this.backgroundColor,
    required this.bumpHeight,
    required this.baselineOffset,
    required this.bumpHalfWidth,
    required this.shadowColor,
    this.minEdgeInset = 0.0,
  });

  final double activePosition;
  final double velocity;
  final int itemCount;
  final Color backgroundColor;
  final double bumpHeight;
  final double baselineOffset;
  final double bumpHalfWidth;
  final Color shadowColor;
  final double minEdgeInset;

  SakuraNotchGeometry geometryFor(Size size) {
    final itemWidth = size.width / itemCount;
    final edgeInset = size.width >= minEdgeInset * 2 ? minEdgeInset : 0.0;
    final centerX = ((activePosition + 0.5) * itemWidth).clamp(
      edgeInset,
      size.width - edgeInset,
    );
    // Velocity, not a separate timeline, stretches the leading edge. The
    // shape is exactly symmetrical once the floating circle settles.
    final pull = (velocity * itemWidth / 850).clamp(-1.0, 1.0);
    final leftRadius = (bumpHalfWidth - pull * 5.5).clamp(0.0, centerX);
    final rightRadius = (bumpHalfWidth + pull * 5.5).clamp(
      0.0,
      size.width - centerX,
    );
    return SakuraNotchGeometry(
      centerX: centerX,
      leftStart: centerX - leftRadius,
      rightEnd: centerX + rightRadius,
      pull: pull,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final geometry = geometryFor(size);
    final centerX = geometry.centerX;
    final leftStart = geometry.leftStart;
    final rightEnd = geometry.rightEnd;
    final apexY = baselineOffset - bumpHeight;

    final path = Path();
    path.moveTo(0, baselineOffset);

    if (leftStart > 0) {
      path.lineTo(leftStart, baselineOffset);
    }

    // Smooth cubic curve rising to apex
    final c1x = leftStart + (centerX - leftStart) * 0.38;
    final c1y = baselineOffset;
    final c2x = centerX - (centerX - leftStart) * 0.38;
    final c2y = apexY;
    path.cubicTo(c1x, c1y, c2x, c2y, centerX, apexY);

    // Smooth cubic curve descending from apex
    final c3x = centerX + (rightEnd - centerX) * 0.38;
    final c3y = apexY;
    final c4x = rightEnd - (rightEnd - centerX) * 0.38;
    final c4y = baselineOffset;
    path.cubicTo(c3x, c3y, c4x, c4y, rightEnd, baselineOffset);

    if (rightEnd < size.width) {
      path.lineTo(size.width, baselineOffset);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // 1. Draw subtle upward ambient shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, shadowPaint);

    // 2. Draw solid surface
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant SakuraCurvedNavigationPainter oldDelegate) {
    return oldDelegate.activePosition != activePosition ||
        oldDelegate.velocity != velocity ||
        oldDelegate.itemCount != itemCount ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.bumpHeight != bumpHeight ||
        oldDelegate.baselineOffset != baselineOffset ||
        oldDelegate.bumpHalfWidth != bumpHalfWidth ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.minEdgeInset != minEdgeInset;
  }
}

/// Destination metadata container consumed by [SakuraBottomNavigation].
class RikiNavigationDestination {
  const RikiNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? tooltip;
}

/// Individual navigation tab item containing the >=48dp touch area, inactive icon,
/// and synchronized Sakura label transition.
class _NavigationTabItem extends StatelessWidget {
  const _NavigationTabItem({
    required this.destination,
    required this.isSelected,
    required this.iconOpacity,
    required this.selectionProgress,
    required this.baselineOffset,
    required this.largeText,
    required this.activeLabelColor,
    required this.inactiveLabelColor,
    required this.inactiveIconColor,
    required this.onPressed,
  });

  final RikiNavigationDestination destination;
  final bool isSelected;
  final double iconOpacity;
  final double selectionProgress;
  final double baselineOffset;
  final bool largeText;
  final Color activeLabelColor;
  final Color inactiveLabelColor;
  final Color inactiveIconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labelColor = Color.lerp(
      inactiveLabelColor,
      activeLabelColor,
      selectionProgress,
    )!;

    return Semantics(
      key: ValueKey<String>('bottom_navigation_item_${destination.label}'),
      button: true,
      selected: isSelected,
      label: destination.tooltip ?? destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onPressed,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          splashColor: AppColors.brandTint.withValues(alpha: 0.3),
          child: Padding(
            padding: EdgeInsets.only(top: baselineOffset),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Inactive Icon area (cleanly hidden whenever the active circle
                // covers or displays this tab)
                SizedBox(
                  height: largeText ? 22 : 26,
                  child: iconOpacity > 0.01
                      ? Opacity(
                          opacity: iconOpacity,
                          child: Icon(
                            destination.icon,
                            color: inactiveIconColor,
                            size: largeText ? 18 : 20,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                SizedBox(height: largeText ? 1 : 3),

                // Destination Label
                Flexible(
                  child: Text(
                    destination.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.badgeText.copyWith(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.lerp(
                        FontWeight.w500,
                        FontWeight.w600,
                        selectionProgress,
                      ),
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
