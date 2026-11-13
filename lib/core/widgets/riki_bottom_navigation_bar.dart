import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

/// Sakura Floating Curved Navigation Bar.
///
/// Designed in accordance with the Sakura Design System and PO directive:
/// - Warm white navigation surface flush with the bottom edge (including safe area)
/// - Symmetrical dynamic curved dome that glides horizontally to the active tab
/// - Floating circular active indicator in Sakura Coral Pink gradient with soft glow
/// - White active icon inside the floating circle
/// - Neutral grey inactive icons and labels with smooth crossfade
/// - Bold Sakura Pink active label on a shared baseline
/// - Zero clipping at edge tabs (Tab 0 and Tab 4)
/// - Accessible button semantics for all five learner destinations
class RikiBottomNavigationBar extends StatefulWidget {
  const RikiBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  }) : assert(selectedIndex >= 0 && selectedIndex < destinationCount);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const int destinationCount = 5;

  @override
  State<RikiBottomNavigationBar> createState() =>
      _RikiBottomNavigationBarState();
}

class _RikiBottomNavigationBarState extends State<RikiBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _indicatorDiameter = 48.0;
  static const _maximumMotionVelocity = 18.0; // Tab widths per second.

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
      value: widget.selectedIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant RikiBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final targetPosition = widget.selectedIndex.toDouble();
      final mediaQuery = MediaQuery.maybeOf(context);
      final disableAnimations =
          (mediaQuery?.disableAnimations ?? false) ||
          (mediaQuery?.accessibleNavigation ?? false);
      if (disableAnimations) {
        _controller.stop();
        _controller.value = targetPosition;
      } else {
        // Re-target the same simulation from its current position and velocity.
        // No completion callback may overwrite a newer tab selection.
        final distance = (targetPosition - _controller.value).abs();
        final spring = SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: distance >= 3
              ? 150
              : distance >= 1.5
              ? 190
              : 230,
          ratio: 0.87,
        );
        _controller.animateWith(
          SpringSimulation(
            spring,
            _controller.value,
            targetPosition,
            _controller.velocity.clamp(
              -_maximumMotionVelocity,
              _maximumMotionVelocity,
            ),
            tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledLabelSize = textScaler.scale(11);
    final largeText = scaledLabelSize >= 17;

    // Dimensions
    final bumpHeight = largeText ? 12.0 : 15.0;
    final baselineOffset = largeText ? 14.0 : 18.0;
    const circleRadius = _indicatorDiameter / 2;
    final circleCenterY = baselineOffset + 4.0;

    final navigationHeight = largeText
        ? 112.0
        : 64.0 + (scaledLabelSize - 11).clamp(0.0, 6.0) * 4;
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final totalHeight = navigationHeight + safeAreaBottom;

    final l10n = context.l10n;
    final destinations = <RikiNavigationDestination>[
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

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / RikiBottomNavigationBar.destinationCount;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final animPos = _controller.value.clamp(
                0.0,
                (RikiBottomNavigationBar.destinationCount - 1).toDouble(),
              );
              final reduceMotion =
                  MediaQuery.disableAnimationsOf(context) ||
                  MediaQuery.accessibleNavigationOf(context);
              final velocity = _controller.isAnimating && !reduceMotion
                  ? _controller.velocity
                  : 0.0;
              final activeCenterX = (animPos + 0.5) * itemWidth;
              final motionAmount = (velocity.abs() * itemWidth / 850).clamp(
                0.0,
                1.0,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Curved Background with top ambient shadow
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: SakuraCurvedNavigationPainter(
                          activePosition: animPos,
                          velocity: velocity,
                          itemCount: RikiBottomNavigationBar.destinationCount,
                          backgroundColor: AppColors.cardWarmWhite,
                          bumpHeight: bumpHeight,
                          baselineOffset: baselineOffset,
                          bumpHalfWidth: 36.0,
                          shadowColor: const Color(0x18000000),
                        ),
                      ),
                    ),
                  ),

                  // 2. Tab Items Row (Touch targets, inactive icons, and labels)
                  Positioned(
                    top: baselineOffset,
                    left: 0,
                    right: 0,
                    bottom: safeAreaBottom,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List<Widget>.generate(destinations.length, (
                        index,
                      ) {
                        final destination = destinations[index];
                        final isSelected = widget.selectedIndex == index;
                        final distance = (animPos - index).abs();
                        final iconOpacity = (distance * 1.6).clamp(0.0, 1.0);

                        return Expanded(
                          child: _NavigationTabItem(
                            destination: destination,
                            isSelected: isSelected,
                            iconOpacity: iconOpacity,
                            selectionProgress: (1 - distance).clamp(0.0, 1.0),
                            largeText: largeText,
                            onPressed: () =>
                                widget.onDestinationSelected(index),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 3. Floating Active Circle Indicator
                  Positioned(
                    left: activeCenterX - circleRadius,
                    top: circleCenterY - circleRadius,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scaleX: 1 + 0.035 * motionAmount,
                        scaleY: 1 - 0.025 * motionAmount,
                        child: Container(
                          key: const ValueKey<String>(
                            'sakura_floating_active_indicator',
                          ),
                          width: _indicatorDiameter,
                          height: _indicatorDiameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.sakura400, // Toned-down sakura coral (Color(0xFFEE6F8E))
                                AppColors.brandPrimary, // Signature brand sakura rose (Color(0xFFE05A7A))
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x33E05A7A),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                              const BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.82,
                                      end: 1.0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Icon(
                                destinations[widget.selectedIndex].selectedIcon,
                                key: ValueKey<int>(widget.selectedIndex),
                                color: Colors.white,
                                size: 24,
                              ),
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

/// A curved surface whose leading edge stretches with the circle's velocity.
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
  });

  final double activePosition;
  final double velocity;
  final int itemCount;
  final Color backgroundColor;
  final double bumpHeight;
  final double baselineOffset;
  final double bumpHalfWidth;
  final Color shadowColor;

  SakuraNotchGeometry geometryFor(Size size) {
    final itemWidth = size.width / itemCount;
    final centerX = ((activePosition + 0.5) * itemWidth).clamp(0.0, size.width);
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
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.bumpHeight != bumpHeight ||
        oldDelegate.baselineOffset != baselineOffset ||
        oldDelegate.bumpHalfWidth != bumpHalfWidth ||
        oldDelegate.shadowColor != shadowColor;
  }
}

/// Destination data container.
class RikiNavigationDestination {
  const RikiNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Individual navigation tab item containing the touch area, inactive icon, and label.
class _NavigationTabItem extends StatelessWidget {
  const _NavigationTabItem({
    required this.destination,
    required this.isSelected,
    required this.iconOpacity,
    required this.selectionProgress,
    required this.largeText,
    required this.onPressed,
  });

  final RikiNavigationDestination destination;
  final bool isSelected;
  final double iconOpacity;
  final double selectionProgress;
  final bool largeText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labelColor = Color.lerp(
      AppColors.textSecondary,
      AppColors.brandPrimary,
      selectionProgress,
    )!;

    return Semantics(
      key: ValueKey<String>('bottom_navigation_item_${destination.label}'),
      button: true,
      selected: isSelected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onPressed,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          splashColor: AppColors.brandTint.withValues(alpha: 0.3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Inactive Icon area (fades out when active circle glides on top)
              SizedBox(
                height: largeText ? 22 : 28,
                child: iconOpacity > 0.01
                    ? Opacity(
                        opacity: iconOpacity,
                        child: Icon(
                          destination.icon,
                          color: AppColors.textSecondary,
                          size: largeText ? 20 : 23,
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
                      FontWeight.w600,
                      FontWeight.w700,
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
    );
  }
}
