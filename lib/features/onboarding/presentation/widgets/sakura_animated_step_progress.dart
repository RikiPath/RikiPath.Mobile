import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Animated Sakura progress bar shared across the four-step onboarding flow.
///
/// Smoothly interpolates forward and backward from the current rendered fraction
/// without resetting to zero or overflowing the track, while honoring reduced
/// motion preferences.
class SakuraAnimatedStepProgress extends StatefulWidget {
  const SakuraAnimatedStepProgress({
    required this.currentStep,
    required this.semanticsLabel,
    this.totalSteps = 4,
    this.height = 7,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeInOutCubic,
    super.key,
  }) : assert(totalSteps > 0),
       assert(currentStep >= 1 && currentStep <= totalSteps);

  final int currentStep;
  final int totalSteps;
  final String semanticsLabel;
  final double height;
  final Duration duration;
  final Curve curve;

  double get targetFraction =>
      (currentStep / totalSteps).clamp(0.0, 1.0).toDouble();

  @override
  State<SakuraAnimatedStepProgress> createState() =>
      _SakuraAnimatedStepProgressState();
}

class _SakuraAnimatedStepProgressState extends State<SakuraAnimatedStepProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curvedAnimation;
  late Tween<double> _progressTween;
  bool _reduceMotion = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    final initialFraction = widget.targetFraction;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _controller.addStatusListener(_handleAnimationStatus);
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _progressTween = Tween<double>(
      begin: initialFraction,
      end: initialFraction,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    _reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  @override
  void didUpdateWidget(covariant SakuraAnimatedStepProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) {
      _curvedAnimation.curve = widget.curve;
    }

    final nextTarget = widget.targetFraction;
    final previousTarget = oldWidget.targetFraction;
    if ((nextTarget - previousTarget).abs() < 0.0001) {
      return;
    }

    final currentValue = _progressTween
        .evaluate(_curvedAnimation)
        .clamp(0.0, 1.0)
        .toDouble();
    _progressTween = Tween<double>(begin: currentValue, end: nextTarget);

    if (_reduceMotion || (nextTarget - currentValue).abs() < 0.0001) {
      _isTransitioning = false;
      _controller.value = 1.0;
      return;
    }

    _isTransitioning = true;
    _controller.forward(from: 0.0);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      if (_isTransitioning) {
        setState(() => _isTransitioning = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetPercent = (widget.targetFraction * 100).round();
    return Semantics(
      label: widget.semanticsLabel,
      value: '$targetPercent%',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey<String>('sakura_progress_track'),
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.progressTrack,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.borderSubtlePink.withValues(alpha: 0.65),
            width: 0.6,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final value = _progressTween
                  .evaluate(_curvedAnimation)
                  .clamp(0.0, 1.0)
                  .toDouble();
              final sheenStrength = (_isTransitioning && !_reduceMotion)
                  ? math.sin(_controller.value * math.pi).clamp(0.0, 1.0)
                  : 0.0;
              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  key: const ValueKey<String>('sakura_progress_fill'),
                  widthFactor: value,
                  heightFactor: 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: <Color>[
                          AppColors.sakura500,
                          AppColors.sakura400,
                        ],
                      ),
                    ),
                    child: sheenStrength > 0.01
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: const <double>[0.55, 0.85, 1.0],
                                colors: <Color>[
                                  Colors.transparent,
                                  Colors.white.withValues(
                                    alpha: 0.28 * sheenStrength,
                                  ),
                                  Colors.white.withValues(
                                    alpha: 0.14 * sheenStrength,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
