import 'package:flutter/widgets.dart';

/// Reusable Sakura motion tokens and conventions.
///
/// Designed to provide snappy, responsive feedback while respecting system
/// reduced-motion and accessibility settings.
abstract final class AppMotion {
  /// Snappy response for buttons, taps, and scale feedback (80–140 ms).
  static const Duration fast = Duration(milliseconds: 110);

  /// Moderate response for tab indicators and small card expansion (140–220 ms).
  static const Duration medium = Duration(milliseconds: 200);

  /// Relaxed response for content transitions and entrance (220–340 ms).
  static const Duration relaxed = Duration(milliseconds: 300);

  /// Extended duration for progress indicators and celebration arcs.
  static const Duration slow = Duration(milliseconds: 550);

  /// Standard smooth curve for state transitions.
  static const Curve curveStandard = Curves.easeInOutCubic;

  /// Expressive deceleration curve for touch and entrance.
  static const Curve curveExpressive = Curves.easeOutCubic;

  /// Soft springy curve for badges and completion states.
  static const Curve curveBounce = Curves.easeOutBack;

  /// Returns true when user accessibility settings request reduced motion.
  static bool isReducedMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
  }

  /// Returns [Duration.zero] if reduced motion is requested, otherwise [duration].
  static Duration duration(BuildContext context, Duration duration) {
    return isReducedMotion(context) ? Duration.zero : duration;
  }
}
