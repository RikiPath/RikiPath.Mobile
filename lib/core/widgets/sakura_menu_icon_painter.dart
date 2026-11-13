import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';

/// Một họ vector 2D đa sắc thống nhất cho menu Profile và Settings.
class SakuraMenuIconPainter extends CustomPainter {
  const SakuraMenuIconPainter(this.type);

  final SakuraColorfulIconType type;

  static const coral = Color(0xFFE05A7A);
  static const red = Color(0xFFD9555D);
  static const blue = Color(0xFF568ED9);
  static const teal = Color(0xFF45AFA5);
  static const violet = Color(0xFF9275C6);
  static const gold = Color(0xFFF2B447);
  static const ink = Color(0xFF3C4857);
  static const cream = Color(0xFFFFF7EA);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);

    Paint fill(Color color) => Paint()..color = color;
    Paint stroke(Color color, [double width = 3]) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void circle(double x, double y, double radius, Color color) =>
        canvas.drawCircle(Offset(x, y), radius, fill(color));
    void rounded(
      double x,
      double y,
      double w,
      double h,
      double r,
      Color color,
    ) => canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      fill(color),
    );
    void line(
      double x1,
      double y1,
      double x2,
      double y2,
      Color color, [
      double width = 3,
    ]) => canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stroke(color, width));
    void path(
      List<Offset> points,
      Color color, {
      bool close = true,
      double? width,
    }) {
      final p = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        p.lineTo(point.dx, point.dy);
      }
      if (close) p.close();
      canvas.drawPath(p, width == null ? fill(color) : stroke(color, width));
    }

    switch (type) {
      case SakuraColorfulIconType.learningGoal:
        circle(23, 25, 19, coral);
        circle(23, 25, 13, Colors.white);
        circle(23, 25, 8, coral);
        circle(23, 25, 3, gold);
        line(24, 24, 40, 8, blue, 3.5);
        path([
          const Offset(36, 6),
          const Offset(43, 5),
          const Offset(42, 12),
        ], blue);
      case SakuraColorfulIconType.placementTest:
        rounded(9, 8, 30, 36, 4, blue);
        rounded(12, 11, 24, 30, 2, cream);
        rounded(17, 5, 14, 7, 3, coral);
        for (final y in [19.0, 27.0, 35.0]) {
          line(22, y, 32, y, blue, 2);
          path(
            [Offset(15, y), Offset(17, y + 2), Offset(20, y - 2)],
            teal,
            close: false,
            width: 2.3,
          );
        }
      case SakuraColorfulIconType.learningProgress:
        line(7, 41, 42, 41, ink, 2.2);
        rounded(10, 28, 7, 13, 1.5, gold);
        rounded(21, 21, 7, 20, 1.5, teal);
        rounded(32, 12, 7, 29, 1.5, blue);
        path(
          [const Offset(12, 24), const Offset(24, 16), const Offset(36, 8)],
          coral,
          close: false,
          width: 2.5,
        );
        circle(36, 8, 2.5, coral);
      case SakuraColorfulIconType.consultation:
        rounded(12, 7, 31, 22, 8, violet);
        path([
          const Offset(31, 27),
          const Offset(33, 34),
          const Offset(38, 27),
        ], violet);
        for (final x in [21.0, 28.0, 35.0]) {
          circle(x, 18, 2, Colors.white);
        }
        circle(13, 30, 6, coral);
        rounded(4, 37, 18, 7, 4, teal);
      case SakuraColorfulIconType.mentorApplication:
        path([
          const Offset(4, 18),
          const Offset(24, 9),
          const Offset(44, 18),
          const Offset(24, 27),
        ], violet);
        rounded(13, 25, 22, 9, 4, blue);
        line(39, 20, 39, 36, gold, 2.7);
        circle(39, 38, 3, gold);
        rounded(18, 36, 12, 5, 2, coral);
      case SakuraColorfulIconType.editProfile:
        circle(18, 17, 8, blue);
        rounded(7, 29, 22, 12, 6, teal);
        canvas.save();
        canvas.translate(32, 33);
        canvas.rotate(-math.pi / 4);
        rounded(-4, -12, 8, 20, 2, coral);
        rounded(-4, -12, 8, 4, 1, gold);
        path([
          const Offset(-4, 8),
          const Offset(4, 8),
          const Offset(0, 14),
        ], gold);
        canvas.restore();
      case SakuraColorfulIconType.settings:
        final gear = <Offset>[];
        for (var i = 0; i < 24; i++) {
          final angle = i * math.pi / 12 - math.pi / 2;
          final radius = i % 3 == 0 || i % 3 == 1 ? 20.0 : 15.0;
          gear.add(
            Offset(
              24 + radius * math.cos(angle),
              24 + radius * math.sin(angle),
            ),
          );
        }
        path(gear, violet);
        circle(24, 24, 9, Colors.white);
        circle(24, 24, 5, teal);
      case SakuraColorfulIconType.logout:
        final frame = Path()
          ..moveTo(22, 7)
          ..lineTo(11, 7)
          ..quadraticBezierTo(7, 7, 7, 11)
          ..lineTo(7, 37)
          ..quadraticBezierTo(7, 41, 11, 41)
          ..lineTo(22, 41);
        canvas.drawPath(frame, stroke(red, 4));
        line(18, 24, 39, 24, coral, 4);
        path(
          [const Offset(32, 17), const Offset(40, 24), const Offset(32, 31)],
          coral,
          close: false,
          width: 4,
        );
      case SakuraColorfulIconType.security:
        path([
          const Offset(24, 4),
          const Offset(41, 11),
          const Offset(38, 30),
          const Offset(24, 44),
          const Offset(10, 30),
          const Offset(7, 11),
        ], blue);
        path(
          [const Offset(16, 24), const Offset(22, 30), const Offset(33, 18)],
          Colors.white,
          close: false,
          width: 4,
        );
        circle(34, 11, 3, teal);
      case SakuraColorfulIconType.password:
        final shackle = Path()
          ..moveTo(14, 22)
          ..lineTo(14, 16)
          ..arcToPoint(const Offset(34, 16), radius: const Radius.circular(10))
          ..lineTo(34, 22);
        canvas.drawPath(shackle, stroke(blue, 4));
        rounded(9, 21, 30, 23, 5, gold);
        circle(24, 31, 3, ink);
        rounded(22.5, 32, 3, 6, 1, ink);
      case SakuraColorfulIconType.language:
        circle(24, 24, 20, blue);
        circle(24, 24, 17, const Color(0xFFD8F5F5));
        canvas.drawOval(Rect.fromLTWH(15, 7, 18, 34), stroke(teal, 2.3));
        line(7, 24, 41, 24, blue, 2.3);
        line(10, 16, 38, 16, teal, 1.8);
        line(10, 32, 38, 32, teal, 1.8);
      case SakuraColorfulIconType.email:
        rounded(5, 11, 38, 27, 5, blue);
        path(
          [const Offset(7, 14), const Offset(24, 27), const Offset(41, 14)],
          Colors.white,
          close: false,
          width: 3.2,
        );
        circle(37, 35, 6, coral);
      case SakuraColorfulIconType.examDate:
        rounded(6, 8, 36, 34, 4, blue);
        rounded(9, 18, 30, 21, 1, Colors.white);
        rounded(6, 8, 36, 12, 4, coral);
        line(15, 5, 15, 14, gold, 3.2);
        line(33, 5, 33, 14, gold, 3.2);
        for (final x in [17.0, 25.0, 33.0]) {
          for (final y in [26.0, 33.0]) {
            circle(x, y, 2, teal);
          }
        }
      case SakuraColorfulIconType.studyTime:
        circle(24, 24, 20, teal);
        circle(24, 24, 16, Colors.white);
        line(24, 24, 24, 13, blue, 3.4);
        line(24, 24, 33, 29, blue, 3.4);
        circle(24, 24, 2.5, gold);
      case SakuraColorfulIconType.notifications:
        final bell = Path()
          ..moveTo(11, 34)
          ..lineTo(15, 28)
          ..lineTo(15, 19)
          ..arcToPoint(const Offset(33, 19), radius: const Radius.circular(9))
          ..lineTo(33, 28)
          ..lineTo(37, 34)
          ..close();
        canvas.drawPath(bell, fill(gold));
        rounded(8, 34, 32, 4, 2, blue);
        circle(24, 41, 3, coral);
      case SakuraColorfulIconType.streak:
      case SakuraColorfulIconType.trophy:
      case SakuraColorfulIconType.calendar:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SakuraMenuIconPainter oldDelegate) =>
      oldDelegate.type != type;
}
