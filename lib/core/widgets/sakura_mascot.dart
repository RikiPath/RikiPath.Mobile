import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';

/// Poses supported by the original Riki-chan Sakura mascot.
enum SakuraMascotPose {
  /// Welcoming pose with a friendly wave.
  greeting,

  /// Inquisitive study pose with an open scroll / notebook.
  studying,

  /// Joyful jumping pose with sparkles and petals.
  celebrating,

  /// Attentive mentor pose with a gentle guiding pointer.
  guiding,
}

/// Zero-dependency, lightweight procedural vector widget rendering Riki-chan.
///
/// Designed to provide infinite crisp resolution at all screen densities,
/// without adding raster asset bloat or network overhead.
class SakuraMascot extends StatelessWidget {
  const SakuraMascot({
    this.pose = SakuraMascotPose.greeting,
    this.size = 56,
    super.key,
  });

  final SakuraMascotPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Riki-chan Mascot ($pose)',
      child: CustomPaint(
        size: Size(size, size),
        painter: SakuraMascotPainter(pose: pose),
      ),
    );
  }
}

/// CustomPainter rendering Riki-chan's Neo-Japoniste vector geometry.
class SakuraMascotPainter extends CustomPainter {
  const SakuraMascotPainter({required this.pose});

  final SakuraMascotPose pose;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale, scale);

    final inkPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final furPaint = Paint()
      ..color = AppColors.cardWarmPorcelain
      ..style = PaintingStyle.fill;

    final sakuraPaint = Paint()
      ..color = AppColors.brandPrimary
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = AppColors.brandSecondary.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final earInnerPaint = Paint()
      ..color = AppColors.sakura100
      ..style = PaintingStyle.fill;

    final bellyPaint = Paint()
      ..color = AppColors.brandTint
      ..style = PaintingStyle.fill;

    // 1. Tail
    final tailPath = Path();
    if (pose == SakuraMascotPose.celebrating) {
      tailPath
        ..moveTo(165, 155)
        ..cubicTo(200, 140, 220, 105, 210, 80)
        ..cubicTo(202, 65, 180, 72, 172, 90)
        ..cubicTo(162, 110, 155, 140, 165, 155)
        ..close();
    } else {
      tailPath
        ..moveTo(165, 170)
        ..cubicTo(195, 160, 215, 130, 205, 105)
        ..cubicTo(198, 88, 175, 92, 165, 110)
        ..cubicTo(155, 125, 155, 155, 165, 170)
        ..close();
    }
    canvas.drawPath(tailPath, furPaint);
    canvas.drawPath(tailPath, inkPaint);

    // Tail Sakura Dip
    final tailDip = Path()
      ..moveTo(190, 120)
      ..cubicTo(205, 105, 205, 95, 195, 90)
      ..cubicTo(185, 85, 175, 92, 170, 102)
      ..cubicTo(178, 112, 185, 116, 190, 120)
      ..close();
    canvas.drawPath(tailDip, sakuraPaint);

    // 2. Body
    final bodyCenterY = pose == SakuraMascotPose.celebrating ? 155.0 : 165.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(120, bodyCenterY), width: 92, height: 80),
      furPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(120, bodyCenterY), width: 92, height: 80),
      inkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(120, bodyCenterY + 5), width: 60, height: 52),
      bellyPaint,
    );

    // 3. Feet
    final feetY = pose == SakuraMascotPose.celebrating ? 188.0 : 195.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(92, feetY), width: 32, height: 20),
      furPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(92, feetY), width: 32, height: 20),
      inkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(148, feetY), width: 32, height: 20),
      furPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(148, feetY), width: 32, height: 20),
      inkPaint,
    );

    // 4. Ears
    final headCenterY = pose == SakuraMascotPose.celebrating ? 100.0 : 105.0;
    final earYOffset = pose == SakuraMascotPose.celebrating ? -5.0 : 0.0;

    // Left Ear
    final leftEar = Path()
      ..moveTo(80, 92 + earYOffset)
      ..lineTo(62, 45 + earYOffset)
      ..lineTo(102, 75 + earYOffset)
      ..close();
    canvas.drawPath(leftEar, furPaint);
    canvas.drawPath(leftEar, inkPaint);

    final leftEarInner = Path()
      ..moveTo(78, 82 + earYOffset)
      ..lineTo(68, 52 + earYOffset)
      ..lineTo(94, 72 + earYOffset)
      ..close();
    canvas.drawPath(leftEarInner, earInnerPaint);

    final leftEarTip = Path()
      ..moveTo(68, 52 + earYOffset)
      ..lineTo(62, 45 + earYOffset)
      ..lineTo(74, 40 + earYOffset)
      ..close();
    canvas.drawPath(leftEarTip, sakuraPaint);

    // Right Ear
    final rightEar = Path()
      ..moveTo(160, 92 + earYOffset)
      ..lineTo(178, 45 + earYOffset)
      ..lineTo(138, 75 + earYOffset)
      ..close();
    canvas.drawPath(rightEar, furPaint);
    canvas.drawPath(rightEar, inkPaint);

    final rightEarInner = Path()
      ..moveTo(162, 82 + earYOffset)
      ..lineTo(172, 52 + earYOffset)
      ..lineTo(146, 72 + earYOffset)
      ..close();
    canvas.drawPath(rightEarInner, earInnerPaint);

    final rightEarTip = Path()
      ..moveTo(172, 52 + earYOffset)
      ..lineTo(178, 45 + earYOffset)
      ..lineTo(166, 40 + earYOffset)
      ..close();
    canvas.drawPath(rightEarTip, sakuraPaint);

    // 5. Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(120, headCenterY), width: 104, height: 92),
      furPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(120, headCenterY), width: 104, height: 92),
      inkPaint,
    );

    // 6. Forehead Sakura Blossom Crest
    _drawSakuraCrest(canvas, 120, headCenterY - 27);

    // 7. Rosy Cheeks
    canvas.drawOval(
      Rect.fromCenter(center: Offset(88, headCenterY + 11), width: 18, height: 11),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(152, headCenterY + 11), width: 18, height: 11),
      blushPaint,
    );

    // 8. Eyes & Expression
    final eyePaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    if (pose == SakuraMascotPose.celebrating) {
      // Curved happy eyes (^ ^)
      final eyeL = Path()
        ..moveTo(90, headCenterY - 2)
        ..quadraticBezierTo(98, headCenterY - 10, 106, headCenterY - 2);
      final eyeR = Path()
        ..moveTo(134, headCenterY - 2)
        ..quadraticBezierTo(142, headCenterY - 10, 150, headCenterY - 2);
      canvas.drawPath(eyeL, eyePaint);
      canvas.drawPath(eyeR, eyePaint);
    } else if (pose == SakuraMascotPose.studying) {
      // Focused eyes with pupil highlight
      final fillEye = Paint()..color = AppColors.textPrimary;
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(100, headCenterY + 1), width: 10, height: 12),
        fillEye,
      );
      canvas.drawCircle(Offset(102, headCenterY - 1), 2.0, whitePaint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(140, headCenterY + 1), width: 10, height: 12),
        fillEye,
      );
      canvas.drawCircle(Offset(142, headCenterY - 1), 2.0, whitePaint);
    } else {
      // Smiling crescent eyes
      final eyeL = Path()
        ..moveTo(92, headCenterY - 1)
        ..quadraticBezierTo(100, headCenterY - 6, 108, headCenterY - 1);
      final eyeR = Path()
        ..moveTo(132, headCenterY - 1)
        ..quadraticBezierTo(140, headCenterY - 6, 148, headCenterY - 1);
      canvas.drawPath(eyeL, eyePaint);
      canvas.drawPath(eyeR, eyePaint);
    }

    // 9. Cute Nose & Mouth
    final nosePath = Path()
      ..moveTo(120, headCenterY + 8)
      ..lineTo(117, headCenterY + 5)
      ..lineTo(123, headCenterY + 5)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = AppColors.textPrimary);

    final mouthPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (pose == SakuraMascotPose.celebrating) {
      final mouth = Path()
        ..moveTo(114, headCenterY + 10)
        ..quadraticBezierTo(120, headCenterY + 22, 126, headCenterY + 10)
        ..close();
      canvas.drawPath(mouth, sakuraPaint);
      canvas.drawPath(mouth, mouthPaint);
    } else {
      final mouth = Path()
        ..moveTo(116, headCenterY + 12)
        ..quadraticBezierTo(118, headCenterY + 15, 120, headCenterY + 12)
        ..quadraticBezierTo(122, headCenterY + 15, 124, headCenterY + 12);
      canvas.drawPath(mouth, mouthPaint);
    }

    // 10. Paws & Pose-specific Props
    if (pose == SakuraMascotPose.studying) {
      // Open study scroll
      final bookRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(85, 148, 70, 42),
        const Radius.circular(4),
      );
      canvas.drawRRect(bookRect, Paint()..color = Colors.white);
      canvas.drawRRect(
        bookRect,
        Paint()
          ..color = AppColors.textPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      // Divider line
      canvas.drawLine(
        const Offset(120, 148),
        const Offset(120, 190),
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 2,
      );
      // Paws holding notebook
      canvas.drawOval(
        const Rect.fromLTWH(81, 153, 14, 18),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(81, 153, 14, 18),
        inkPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(145, 153, 14, 18),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(145, 153, 14, 18),
        inkPaint,
      );
    } else if (pose == SakuraMascotPose.celebrating) {
      // Raised joyful paws
      canvas.drawOval(
        const Rect.fromLTWH(76, 114, 18, 28),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(76, 114, 18, 28),
        inkPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(146, 114, 18, 28),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(146, 114, 18, 28),
        inkPaint,
      );
    } else if (pose == SakuraMascotPose.guiding) {
      // Resting left paw
      canvas.drawOval(
        const Rect.fromLTWH(88, 146, 16, 24),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(88, 146, 16, 24),
        inkPaint,
      );
      // Guiding right paw with pointer
      final pointerPaint = Paint()
        ..color = AppColors.featureAmberPressed
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(148, 152), const Offset(183, 122), pointerPaint);
      canvas.drawCircle(Offset(183, 122), 3.5, Paint()..color = AppColors.warning);
      canvas.drawOval(
        const Rect.fromLTWH(138, 142, 18, 24),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(138, 142, 18, 24),
        inkPaint,
      );
    } else {
      // Resting left paw
      canvas.drawOval(
        const Rect.fromLTWH(90, 143, 16, 24),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(90, 143, 16, 24),
        inkPaint,
      );
      // Waving right paw
      canvas.drawOval(
        const Rect.fromLTWH(139, 132, 18, 26),
        furPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(139, 132, 18, 26),
        inkPaint,
      );
      // Small floating petal
      final petal = Path()
        ..moveTo(172, 128)
        ..cubicTo(176, 122, 184, 124, 182, 130)
        ..cubicTo(180, 136, 172, 138, 170, 134)
        ..close();
      canvas.drawPath(petal, sakuraPaint);
    }

    canvas.restore();
  }

  void _drawSakuraCrest(Canvas canvas, double cx, double cy) {
    final petalPaint = Paint()
      ..color = AppColors.brandPrimary
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = AppColors.warning
      ..style = PaintingStyle.fill;

    const r = 6.0;
    const dist = 7.0;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72.0 - 90.0) * (math.pi / 180.0);
      final px = cx + dist * math.cos(angle);
      final py = cy + dist * math.sin(angle);
      canvas.drawCircle(Offset(px, py), r, petalPaint);
    }
    canvas.drawCircle(Offset(cx, cy), 3.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant SakuraMascotPainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}
