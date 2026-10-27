import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Pure-Flutter decorative Sakura blossom and petal painters.
///
/// Resolution-independent, vector-based, and performant: provides the Japanese
/// cherry blossom aesthetic without requiring external image assets or heavy
/// runtime dependencies.
class SakuraPetalPainter extends CustomPainter {
  const SakuraPetalPainter({
    this.primaryColor = AppColors.brandSecondary,
    this.accentColor = AppColors.brandPrimary,
    this.opacity = 0.35,
  });

  final Color primaryColor;
  final Color accentColor;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint1 = Paint()
      ..color = primaryColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = accentColor.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.fill;

    // Top-right cluster
    _drawPetal(canvas, Offset(size.width * 0.88, size.height * 0.22), 16, 28, 0.45, paint1);
    _drawPetal(canvas, Offset(size.width * 0.95, size.height * 0.12), 11, 20, 0.85, paint2);
    _drawPetal(canvas, Offset(size.width * 0.82, size.height * 0.38), 9, 16, -0.2, paint1);

    // Bottom-left subtle petal
    _drawPetal(canvas, Offset(size.width * 0.08, size.height * 0.78), 10, 18, -0.6, paint2);
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, -height / 2);
    // Left lobe with characteristic Sakura notch
    path.cubicTo(
      -width * 0.9, -height * 0.2,
      -width * 0.7, height * 0.4,
      0, height / 2,
    );
    // Right lobe
    path.cubicTo(
      width * 0.7, height * 0.4,
      width * 0.9, -height * 0.2,
      0, -height / 2,
    );
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SakuraPetalPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.opacity != opacity;
  }
}

/// A subtle decorative container with embedded Sakura petal vector accents.
class SakuraDecorativeCorner extends StatelessWidget {
  const SakuraDecorativeCorner({
    this.width = 90,
    this.height = 70,
    this.opacity = 0.4,
    super.key,
  });

  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: SakuraPetalPainter(opacity: opacity),
        ),
      ),
    );
  }
}

/// A five-petaled Sakura blossom icon/seal drawn with Flutter vector paths.
class SakuraBlossomMark extends StatelessWidget {
  const SakuraBlossomMark({
    this.size = 28,
    this.color = AppColors.brandPrimary,
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FivePetalBlossomPainter(color: color),
      ),
    );
  }
}

class _FivePetalBlossomPainter extends CustomPainter {
  const _FivePetalBlossomPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final petalLength = radius * 0.85;
    final petalWidth = radius * 0.52;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path();
      path.moveTo(0, 0);
      path.cubicTo(-petalWidth * 0.6, -petalLength * 0.4, -petalWidth * 0.8, -petalLength * 0.85, -petalWidth * 0.25, -petalLength);
      // Small notch on tip
      path.lineTo(0, -petalLength * 0.88);
      path.lineTo(petalWidth * 0.25, -petalLength);
      path.cubicTo(petalWidth * 0.8, -petalLength * 0.85, petalWidth * 0.6, -petalLength * 0.4, 0, 0);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    // Center pistil dot
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _FivePetalBlossomPainter oldDelegate) =>
      oldDelegate.color != color;
}
