import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_success_illustration.dart';

class RegisterSuccessCelebration extends StatelessWidget {
  const RegisterSuccessCelebration({
    required this.animation,
    required this.icon,
    super.key,
  });

  final Animation<double> animation;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: 160,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final progress = animation.value;
            return CustomPaint(
              foregroundPainter: _CelebrationPainter(progress),
              child: Transform.scale(scale: _iconScale(progress), child: child),
            );
          },
          child: AuthSuccessIllustration(icon: icon, animate: false),
        ),
      ),
    );
  }

  double _iconScale(double progress) {
    final localProgress = (progress / 0.30).clamp(0.0, 1.0);
    if (localProgress <= 0.68) {
      final eased = Curves.easeOutCubic.transform(localProgress / 0.68);
      return 0.85 + ((1.08 - 0.85) * eased);
    }

    final eased = Curves.easeOut.transform((localProgress - 0.68) / (1 - 0.68));
    return 1.08 + ((1 - 1.08) * eased);
  }
}

class SuccessContentEntrance extends StatelessWidget {
  const SuccessContentEntrance({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.translationY = 12,
    super.key,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final double translationY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final intervalProgress = ((animation.value - start) / (end - start))
            .clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(intervalProgress);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, translationY * (1 - eased)),
            child: child,
          ),
        );
      },
    );
  }
}

enum _SparkleShape { circle, diamond, star }

class _SparkleParticle {
  const _SparkleParticle({
    required this.angle,
    required this.distance,
    required this.delay,
    required this.size,
    required this.rotation,
    required this.color,
    required this.shape,
  });

  final double angle;
  final double distance;
  final double delay;
  final double size;
  final double rotation;
  final Color color;
  final _SparkleShape shape;
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter(this.progress);

  static const double _particleDuration = 0.50;
  static const List<_SparkleParticle> _particles = [
    _SparkleParticle(
      angle: -2.86,
      distance: 70,
      delay: 0.08,
      size: 3.6,
      rotation: 0.15,
      color: AppColors.brandPrimary,
      shape: _SparkleShape.star,
    ),
    _SparkleParticle(
      angle: -2.34,
      distance: 66,
      delay: 0.19,
      size: 3.0,
      rotation: 0.45,
      color: AppColors.brandSecondary,
      shape: _SparkleShape.diamond,
    ),
    _SparkleParticle(
      angle: -1.82,
      distance: 72,
      delay: 0.12,
      size: 2.8,
      rotation: 0,
      color: Color(0xFFF6C453),
      shape: _SparkleShape.circle,
    ),
    _SparkleParticle(
      angle: -1.22,
      distance: 69,
      delay: 0.27,
      size: 3.5,
      rotation: 0.20,
      color: AppColors.success,
      shape: _SparkleShape.star,
    ),
    _SparkleParticle(
      angle: -0.58,
      distance: 73,
      delay: 0.15,
      size: 3.2,
      rotation: 0.62,
      color: AppColors.brandPrimary,
      shape: _SparkleShape.diamond,
    ),
    _SparkleParticle(
      angle: 0.10,
      distance: 68,
      delay: 0.31,
      size: 2.6,
      rotation: 0,
      color: Color(0xFFF6C453),
      shape: _SparkleShape.circle,
    ),
    _SparkleParticle(
      angle: 0.74,
      distance: 71,
      delay: 0.21,
      size: 3.4,
      rotation: 0.35,
      color: AppColors.brandSecondary,
      shape: _SparkleShape.star,
    ),
    _SparkleParticle(
      angle: 1.39,
      distance: 67,
      delay: 0.10,
      size: 2.8,
      rotation: 0.78,
      color: AppColors.success,
      shape: _SparkleShape.diamond,
    ),
    _SparkleParticle(
      angle: 2.02,
      distance: 72,
      delay: 0.29,
      size: 3.0,
      rotation: 0,
      color: AppColors.brandPrimary,
      shape: _SparkleShape.circle,
    ),
    _SparkleParticle(
      angle: 2.55,
      distance: 68,
      delay: 0.23,
      size: 3.5,
      rotation: 0.25,
      color: Color(0xFFF6C453),
      shape: _SparkleShape.star,
    ),
  ];

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    _drawPulseRing(canvas, center, start: 0.02);
    _drawPulseRing(canvas, center, start: 0.14);

    for (final particle in _particles) {
      _drawParticle(canvas, center, particle);
    }
  }

  void _drawPulseRing(Canvas canvas, Offset center, {required double start}) {
    const duration = 0.67;
    final localProgress = ((progress - start) / duration).clamp(0.0, 1.0);
    if (localProgress <= 0 || localProgress >= 1) return;

    final eased = Curves.easeOutCubic.transform(localProgress);
    final radius = 42 * (1 + (0.36 * eased));
    final opacity = 0.25 * (1 - localProgress);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.success.withValues(alpha: opacity),
    );
  }

  void _drawParticle(Canvas canvas, Offset center, _SparkleParticle particle) {
    final localProgress = ((progress - particle.delay) / _particleDuration)
        .clamp(0.0, 1.0);
    if (localProgress <= 0 || localProgress >= 1) return;

    final travel = Curves.easeOutCubic.transform(localProgress);
    final distance = 44 + ((particle.distance - 44) * travel);
    final position = Offset(
      center.dx + (math.cos(particle.angle) * distance),
      center.dy + (math.sin(particle.angle) * distance),
    );
    final visibility = math.sin(math.pi * localProgress);
    final paint = Paint()
      ..color = particle.color.withValues(alpha: 0.82 * visibility);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(particle.rotation + (localProgress * 0.45));
    canvas.scale(visibility);
    switch (particle.shape) {
      case _SparkleShape.circle:
        canvas.drawCircle(Offset.zero, particle.size * 0.55, paint);
        break;
      case _SparkleShape.diamond:
        canvas.drawPath(_diamondPath(particle.size), paint);
        break;
      case _SparkleShape.star:
        canvas.drawPath(_starPath(particle.size), paint);
        break;
    }
    canvas.restore();
  }

  Path _diamondPath(double size) {
    return Path()
      ..moveTo(0, -size)
      ..lineTo(size * 0.72, 0)
      ..lineTo(0, size)
      ..lineTo(-size * 0.72, 0)
      ..close();
  }

  Path _starPath(double size) {
    final path = Path();
    for (var index = 0; index < 8; index += 1) {
      final radius = index.isEven ? size : size * 0.28;
      final angle = (-math.pi / 2) + (index * math.pi / 4);
      final point = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
