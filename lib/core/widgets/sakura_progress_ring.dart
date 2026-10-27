import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// An elegant circular progress indicator matching the Sakura visual showcase.
class SakuraProgressRing extends StatelessWidget {
  const SakuraProgressRing({
    required this.progress,
    this.size = 52,
    this.strokeWidth = 5.5,
    this.progressColor = AppColors.brandPrimary,
    this.trackColor = AppColors.progressTrack,
    this.showPercentage = true,
    this.centerWidget,
    super.key,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;
  final bool showPercentage;
  final Widget? centerWidget;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final reduceMotion = AppMotion.isReducedMotion(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: reduceMotion ? Duration.zero : AppMotion.slow,
      curve: AppMotion.curveExpressive,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: animatedValue,
                  strokeWidth: strokeWidth,
                  progressColor: progressColor,
                  trackColor: trackColor,
                ),
              ),
              if (centerWidget != null)
                centerWidget!
              else if (showPercentage)
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress Arc with rounded cap
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
