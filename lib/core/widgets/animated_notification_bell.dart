import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';

/// Physics-inspired notification bell for the Sakura App Header.
///
/// Preserves the approved golden bell icon (`🔔`) and swings from a top-crown
/// pivot (`Alignment(0, -0.78)`) with damped pendulum inertia:
/// `0° → -12° → +9° → -7° → +4° → -2° → 0°` over 840ms.
class AnimatedNotificationBell extends StatefulWidget {
  const AnimatedNotificationBell({
    required this.onPressed,
    this.unreadCount,
    this.ringSequence = 0,
    this.consumedSequence = 0,
    this.onRingConsumed,
    super.key,
  });

  final VoidCallback onPressed;
  final int? unreadCount;

  /// Monotonically increasing sequence token emitted only when a genuinely new
  /// notification arrives.
  final int ringSequence;

  /// Latest sequence token already consumed by the session so newly mounted
  /// headers on other tabs do not replay an old swing.
  final int consumedSequence;

  /// Called once the widget has observed and handled [ringSequence].
  final ValueChanged<int>? onRingConsumed;

  static const Duration swingDuration = Duration(milliseconds: 840);
  static const Alignment bellPivotAlignment = Alignment(0.0, -0.78);

  static String formatBadgeCount(int count) {
    if (count > 99) return '99+';
    return '$count';
  }

  @override
  State<AnimatedNotificationBell> createState() =>
      _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<AnimatedNotificationBell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final Animation<double> _angleAnimation;
  late final Animation<double> _settleScaleAnimation;
  late final Animation<double> _ringPulseScale;
  late final Animation<double> _ringPulseOpacity;

  int _handledSequence = 0;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  static double _degToRad(double degrees) => degrees * math.pi / 180.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    _controller = AnimationController(
      vsync: this,
      duration: AnimatedNotificationBell.swingDuration,
    );

    _angleAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.0,
          end: _degToRad(-12.0),
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 16,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _degToRad(-12.0),
          end: _degToRad(9.0),
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 22,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _degToRad(9.0),
          end: _degToRad(-7.0),
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _degToRad(-7.0),
          end: _degToRad(4.0),
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 17,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _degToRad(4.0),
          end: _degToRad(-2.0),
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 14,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _degToRad(-2.0),
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 11,
      ),
    ]).animate(_controller);

    _settleScaleAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 18,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.05,
          end: 0.99,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 56,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.99,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 26,
      ),
    ]).animate(_controller);

    _ringPulseScale = Tween<double>(begin: 0.72, end: 1.32).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    _ringPulseOpacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.26),
        weight: 18,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.26, end: 0.0),
        weight: 82,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.62, curve: Curves.easeOut),
      ),
    );

    _handledSequence = widget.consumedSequence;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeSwingForSequence(widget.ringSequence);
  }

  @override
  void didUpdateWidget(covariant AnimatedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.consumedSequence > _handledSequence) {
      _handledSequence = widget.consumedSequence;
    }
    if (widget.ringSequence < _handledSequence &&
        widget.consumedSequence == 0 &&
        widget.ringSequence == 0) {
      // Session reset (e.g. logout/account switch).
      _handledSequence = 0;
    }
    if (widget.ringSequence != oldWidget.ringSequence) {
      _maybeSwingForSequence(widget.ringSequence);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state != AppLifecycleState.resumed && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  void _maybeSwingForSequence(int sequence) {
    if (sequence <= _handledSequence) return;
    _handledSequence = sequence;

    final callback = widget.onRingConsumed;
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) callback(sequence);
      });
    }

    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isForeground = _lifecycleState == AppLifecycleState.resumed;

    if (disableAnimations || !isForeground) {
      _controller.stop();
      _controller.value = 0.0;
      return;
    }

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = widget.unreadCount ?? 0;
    final hasUnread = unread > 0;
    final badgeLabel = hasUnread
        ? AnimatedNotificationBell.formatBadgeCount(unread)
        : null;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final baseSemanticLabel = context.l10n.notifications;
    final semanticLabel = hasUnread
        ? '$baseSemanticLabel, $badgeLabel chưa đọc'
        : baseSemanticLabel;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        key: const ValueKey<String>('home_notification_bell_button'),
        onTap: widget.onPressed,
        radius: 24,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
          child: SizedBox(
            width: 44,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final pulseAlpha = disableAnimations
                        ? 0.0
                        : _ringPulseOpacity.value;
                    final angle = disableAnimations
                        ? 0.0
                        : _angleAnimation.value;
                    final scale = disableAnimations
                        ? 1.0
                        : _settleScaleAnimation.value;

                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        if (pulseAlpha > 0.005)
                          Transform.scale(
                            scale: _ringPulseScale.value,
                            child: Container(
                              key: const ValueKey<String>(
                                'notification_bell_highlight_ring',
                              ),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.brandPrimary.withValues(
                                    alpha: pulseAlpha,
                                  ),
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                        Transform.rotate(
                          key: const ValueKey<String>(
                            'notification_bell_swing_transform',
                          ),
                          angle: angle,
                          alignment:
                              AnimatedNotificationBell.bellPivotAlignment,
                          child: Transform.scale(scale: scale, child: child),
                        ),
                      ],
                    );
                  },
                  child: const SakuraColorfulIcon(
                    type: SakuraColorfulIconType.notifications,
                    size: 24,
                    useEmoji: true,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    key: const ValueKey<String>(
                      'home_notification_unread_badge',
                    ),
                    top: 6,
                    right: 2,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<String>('unread_badge_scale_$badgeLabel'),
                      tween: Tween<double>(
                        begin: disableAnimations ? 1.0 : 0.78,
                        end: 1.0,
                      ),
                      duration: disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, badgeChild) =>
                          Transform.scale(scale: scale, child: badgeChild),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badgeLabel!,
                          textScaler: TextScaler.noScaling,
                          style: AppTypography.badgeText.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
