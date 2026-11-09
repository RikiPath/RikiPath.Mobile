import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

/// The 5 diurnal time slots mapped to Sakura landscape artworks.
enum SakuraTimeSlot {
  /// 05:00 - 10:59: Sunrise, fresh morning energy
  morning,

  /// 11:00 - 13:59: Midday, bright afternoon sun
  noon,

  /// 14:00 - 17:59: Golden afternoon, serene lakeside
  afternoon,

  /// 18:00 - 21:59: Twilight / dusk, glowing lanterns
  evening,

  /// 22:00 - 04:59: Deep night, calm starry sky
  lateNight;

  /// Determines the active [SakuraTimeSlot] from a local [DateTime].
  static SakuraTimeSlot fromDateTime(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 5 && hour < 11) {
      return SakuraTimeSlot.morning;
    } else if (hour >= 11 && hour < 14) {
      return SakuraTimeSlot.noon;
    } else if (hour >= 14 && hour < 18) {
      return SakuraTimeSlot.afternoon;
    } else if (hour >= 18 && hour < 22) {
      return SakuraTimeSlot.evening;
    } else {
      return SakuraTimeSlot.lateNight;
    }
  }

  /// Calculates the exact next boundary when the time slot changes.
  static DateTime nextBoundary(DateTime dt) {
    final hour = dt.hour;
    final year = dt.year;
    final month = dt.month;
    final day = dt.day;

    if (hour < 5) {
      return DateTime(year, month, day, 5, 0, 0);
    } else if (hour < 11) {
      return DateTime(year, month, day, 11, 0, 0);
    } else if (hour < 14) {
      return DateTime(year, month, day, 14, 0, 0);
    } else if (hour < 18) {
      return DateTime(year, month, day, 18, 0, 0);
    } else if (hour < 22) {
      return DateTime(year, month, day, 22, 0, 0);
    } else {
      // 22:00 or later -> next boundary is 05:00 tomorrow
      final tomorrow = dt.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 0, 0);
    }
  }

  /// Relative asset path for the corresponding WebP artwork.
  String get assetPath => switch (this) {
    SakuraTimeSlot.morning => 'assets/images/time_banners/sakura_morning.webp',
    SakuraTimeSlot.noon => 'assets/images/time_banners/sakura_noon.webp',
    SakuraTimeSlot.afternoon =>
      'assets/images/time_banners/sakura_afternoon.webp',
    SakuraTimeSlot.evening => 'assets/images/time_banners/sakura_evening.webp',
    SakuraTimeSlot.lateNight =>
      'assets/images/time_banners/sakura_late_night.webp',
  };

  /// Whether this scene has a dark background requiring light typography.
  bool get isDarkTheme =>
      this == SakuraTimeSlot.evening || this == SakuraTimeSlot.lateNight;
}

/// Real-Time Sakura Hero Banner with full-bleed responsive layout,
/// time-of-day awareness, smooth crossfade, and localized typography.
class SakuraHeroBanner extends StatefulWidget {
  const SakuraHeroBanner({
    this.onTap,
    this.nowOverride,
    this.forcedSlot,
    super.key,
  });

  /// Optional tap callback to launch learning or roadmap.
  final VoidCallback? onTap;

  /// Optional clock provider for testing time transitions.
  final DateTime Function()? nowOverride;

  /// Optional slot override for testing or manual preview.
  final SakuraTimeSlot? forcedSlot;

  @override
  State<SakuraHeroBanner> createState() => _SakuraHeroBannerState();
}

class _SakuraHeroBannerState extends State<SakuraHeroBanner>
    with WidgetsBindingObserver {
  late SakuraTimeSlot _currentSlot;
  Timer? _transitionTimer;

  DateTime get _now => widget.nowOverride != null ? widget.nowOverride!() : DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentSlot = widget.forcedSlot ?? SakuraTimeSlot.fromDateTime(_now);
    _scheduleNextTransition();
  }

  @override
  void didUpdateWidget(covariant SakuraHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forcedSlot != null && widget.forcedSlot != _currentSlot) {
      setState(() => _currentSlot = widget.forcedSlot!);
    } else if (widget.nowOverride != oldWidget.nowOverride) {
      _checkAndUpdateSlot();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transitionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateSlot();
    }
  }

  void _checkAndUpdateSlot() {
    if (widget.forcedSlot != null) return;
    final newSlot = SakuraTimeSlot.fromDateTime(_now);
    if (newSlot != _currentSlot && mounted) {
      setState(() {
        _currentSlot = newSlot;
      });
    }
    _scheduleNextTransition();
  }

  void _scheduleNextTransition() {
    _transitionTimer?.cancel();
    if (widget.forcedSlot != null) return;

    final now = _now;
    final next = SakuraTimeSlot.nextBoundary(now);
    final duration = next.difference(now) + const Duration(milliseconds: 150);

    if (duration > Duration.zero) {
      _transitionTimer = Timer(duration, () {
        if (mounted) _checkAndUpdateSlot();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.forcedSlot ?? _currentSlot;
    final l10n = context.l10n;
    final reduceMotion = AppMotion.isReducedMotion(context);

    final (title, subtitle) = switch (slot) {
      SakuraTimeSlot.morning => (
        l10n.heroBannerMorningTitle,
        l10n.heroBannerMorningSubtitle,
      ),
      SakuraTimeSlot.noon => (
        l10n.heroBannerNoonTitle,
        l10n.heroBannerNoonSubtitle,
      ),
      SakuraTimeSlot.afternoon => (
        l10n.heroBannerAfternoonTitle,
        l10n.heroBannerAfternoonSubtitle,
      ),
      SakuraTimeSlot.evening => (
        l10n.heroBannerEveningTitle,
        l10n.heroBannerEveningSubtitle,
      ),
      SakuraTimeSlot.lateNight => (
        l10n.heroBannerLateNightTitle,
        l10n.heroBannerLateNightSubtitle,
      ),
    };

    final isDark = slot.isDarkTheme;
    final titleColor = isDark ? Colors.white : const Color(0xFF2C1E20);
    final subtitleColor =
        isDark ? const Color(0xFFE2D6DC) : const Color(0xFF5A3E42);
    final tagBg =
        isDark
            ? Colors.black.withValues(alpha: 0.38)
            : Colors.white.withValues(alpha: 0.88);
    final tagFg = isDark ? const Color(0xFFFF8DA1) : const Color(0xFFC73659);
    final scrimColors =
        isDark
            ? [
              Colors.black.withValues(alpha: 0.60),
              Colors.black.withValues(alpha: 0.30),
              Colors.transparent,
            ]
            : [
              Colors.white.withValues(alpha: 0.70),
              Colors.white.withValues(alpha: 0.35),
              Colors.transparent,
            ];

    return Semantics(
      button: widget.onTap != null,
      label: '$title, $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: AppColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: AppColors.brandPrimary.withValues(alpha: 0.06),
          child: AspectRatio(
            // Original asset aspect ratio: 2048 x 682 (~3.003:1)
            aspectRatio: 2048 / 682,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.25),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                // Crossfade background artwork
                AnimatedSwitcher(
                  duration:
                      reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 450),
                  child: Image.asset(
                    slot.assetPath,
                    key: ValueKey<String>(slot.assetPath),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [Color(0xFF1E1A29), Color(0xFF332A3D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : AppColors.sakuraHeroGradient,
                        ),
                      );
                    },
                  ),
                ),

                // Subtle horizontal legibility gradient on the left side
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.48, 1.0],
                        colors: scrimColors,
                      ),
                    ),
                  ),
                ),

                // Left-aligned localized headline & subtitle with Japanese pill
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space2,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxTextWidth = (constraints.maxWidth * 0.62).clamp(
                          180.0,
                          340.0,
                        );
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxTextWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Japanese Motivational Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tagBg,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.15,
                                              )
                                              : AppColors.borderSubtlePink,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.heroBannerTag,
                                    style: TextStyle(
                                      color: tagFg,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Main Title
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Subtitle
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
