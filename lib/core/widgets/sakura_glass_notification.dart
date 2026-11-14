import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/sakura_loading.dart';

/// Unified semantic type for [SakuraGlassNotification].
typedef SakuraGlassNotificationType = RikiToastType;

/// Shared design tokens for the unified Sakura Glass notification surface.
///
/// All notification states share the exact same frosted-glass background,
/// border, typography, and blossom chrome; only the embedded status glyph,
/// title, and description vary by state.
abstract final class SakuraGlassNotificationTokens {
  static const double blurSigma = 12.0;
  static const double borderRadius = 22.0;
  static const double celebrationBorderRadius = 24.0;
  static const double borderWidth = 1.25;
  static const double emblemSize = 52.0;

  static const Color glassFill = Color(0xC8FFF7F9);
  static const Color glassBorder = Color(0xFFD69EAC);
  static const Color titleColor = Color(0xFF211417);
  static const Color descriptionColor = Color(0xFF49383E);
  static const Color closeIconColor = Color(0xFF534047);

  static const Color blossomCenterPink = Color(0xFFFF7DA3);
  static const Color blossomMidPink = Color(0xFFFF9EBB);
  static const Color blossomOuterPink = Color(0xFFFFC5D7);
  static const Color blossomTipPink = Color(0xFFFFDCE7);
  static const Color blossomOutline = Color(0xFFE57598);
  static const Color blossomCrease = Color(0x4AD45D83);
  static const Color blossomShadow = Color(0x3CD95D82);
  static const Color glyphColor = Color(0xFFFFFFFF);
  static const Color glyphShadow = Color(0x54AE315B);
}

/// Shared Sakura Glass notification card rendered across Learner and Mentor
/// experiences.
class SakuraGlassNotification extends StatelessWidget {
  const SakuraGlassNotification({
    required this.type,
    required this.title,
    this.description,
    this.onClose,
    this.showCloseButton = true,
    this.cardKey,
    this.surfaceKey,
    this.iconKey,
    this.closeButtonKey,
    this.blurSigma = SakuraGlassNotificationTokens.blurSigma,
    this.borderRadius = SakuraGlassNotificationTokens.borderRadius,
    this.centered = false,
    super.key,
  });

  final SakuraGlassNotificationType type;
  final String title;
  final String? description;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final Key? cardKey;
  final Key? surfaceKey;
  final Key? iconKey;
  final Key? closeButtonKey;
  final double blurSigma;
  final double borderRadius;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final trimmedDescription = description?.trim();
    final hasDescription =
        trimmedDescription != null && trimmedDescription.isNotEmpty;
    final effectiveSurfaceKey =
        surfaceKey ?? const ValueKey<String>('sakura_glass_surface');
    final effectiveIconKey =
        iconKey ?? ValueKey<String>('riki_toast_icon_${type.name}');
    final radius = BorderRadius.circular(borderRadius);

    return Material(
      key: cardKey,
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1E361923),
              blurRadius: 20,
              spreadRadius: 0,
              offset: Offset(0, 7),
            ),
            BoxShadow(
              color: Color(0x18E05A7A),
              blurRadius: 12,
              spreadRadius: -3,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: DecoratedBox(
              key: effectiveSurfaceKey,
              decoration: BoxDecoration(
                color: SakuraGlassNotificationTokens.glassFill,
                borderRadius: radius,
                border: Border.all(
                  color: SakuraGlassNotificationTokens.glassBorder,
                  width: SakuraGlassNotificationTokens.borderWidth,
                ),
              ),
              child: centered
                  ? _buildCenteredContent(
                      hasDescription: hasDescription,
                      description: trimmedDescription,
                      effectiveIconKey: effectiveIconKey,
                    )
                  : _buildStandardContent(
                      context,
                      hasDescription: hasDescription,
                      description: trimmedDescription,
                      effectiveIconKey: effectiveIconKey,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingEmblem(Key effectiveIconKey, {double size = 52}) {
    if (type == RikiToastType.loading) {
      return KeyedSubtree(
        key: effectiveIconKey,
        child: SakuraLoadingIndicator(size: size),
      );
    }
    return CustomPaint(
      key: effectiveIconKey,
      size: Size.square(size),
      painter: SakuraGlassBlossomPainter(type: type),
    );
  }

  Widget _buildStandardContent(
    BuildContext context, {
    required bool hasDescription,
    required String? description,
    required Key effectiveIconKey,
  }) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3 + 2,
            showCloseButton
                ? AppSpacing.space8 + AppSpacing.space2
                : AppSpacing.space4,
            AppSpacing.space3 + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(child: _buildLeadingEmblem(effectiveIconKey)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle.copyWith(
                        color: SakuraGlassNotificationTokens.titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        height: 1.28,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: SakuraGlassNotificationTokens
                              .descriptionColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 13.5,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showCloseButton)
          Positioned(
            top: 6,
            right: 6,
            child: Semantics(
              button: true,
              label: context.l10n.close,
              child: IconButton(
                key: closeButtonKey,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 19),
                color: SakuraGlassNotificationTokens.closeIconColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCenteredContent({
    required bool hasDescription,
    required String? description,
    required Key effectiveIconKey,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: _buildLeadingEmblem(effectiveIconKey, size: 54),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle.copyWith(
              color: SakuraGlassNotificationTokens.titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasDescription) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: SakuraGlassNotificationTokens.descriptionColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Paints the signature five-petal notched Sakura blossom with a crisp white
/// centered status glyph inside it.
class SakuraGlassBlossomPainter extends CustomPainter {
  const SakuraGlassBlossomPainter({required this.type});

  final SakuraGlassNotificationType type;

  static const int _petalCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.shortestSide;
    final length = unit * 0.468;
    final width = length * 0.80;

    final blossomPath = _buildUnifiedBlossomPath(
      center: center,
      unit: unit,
      length: length,
      width: width,
    );

    // Subtle rose drop shadow directly behind the blossom silhouette.
    canvas.drawPath(
      blossomPath.shift(Offset(0, unit * 0.032)),
      Paint()
        ..color = SakuraGlassNotificationTokens.blossomShadow
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, unit * 0.06),
    );

    // Soft pastel Sakura radial fill anchored with slightly richer rose center
    // so the white centered status symbol reads clearly across all backgrounds.
    final bounds = Rect.fromCircle(center: center, radius: length * 1.02);
    canvas.drawPath(
      blossomPath,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            SakuraGlassNotificationTokens.blossomCenterPink,
            SakuraGlassNotificationTokens.blossomMidPink,
            SakuraGlassNotificationTokens.blossomOuterPink,
            SakuraGlassNotificationTokens.blossomTipPink,
          ],
          stops: <double>[0.0, 0.40, 0.78, 1.0],
        ).createShader(bounds),
    );

    // Subtle cleft creases strictly in the outer valley region so the central
    // glyph stays completely unobstructed.
    final creasePaint = Paint()
      ..color = SakuraGlassNotificationTokens.blossomCrease
      ..style = PaintingStyle.stroke
      ..strokeWidth = (unit * 0.018).clamp(0.8, 1.2)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _petalCount; i++) {
      final valleyAngle = -math.pi / 2 + math.pi / 5 + i * 2 * math.pi / 5;
      final dir = Offset(math.cos(valleyAngle), math.sin(valleyAngle));
      canvas.drawLine(
        center + dir * (unit * 0.175),
        center + dir * (unit * 0.255),
        creasePaint,
      );
    }

    // Crisp outer blossom contour stroke matching the reference flower edge.
    canvas.drawPath(
      blossomPath,
      Paint()
        ..color = SakuraGlassNotificationTokens.blossomOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = (unit * 0.024).clamp(1.0, 1.45)
        ..strokeJoin = StrokeJoin.round,
    );

    _paintStatusGlyph(canvas, center: center, unit: unit);
  }

  Path _buildUnifiedBlossomPath({
    required Offset center,
    required double unit,
    required double length,
    required double width,
  }) {
    final singlePetal = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        -width * 0.72,
        -length * 0.28,
        -width * 0.78,
        -length * 0.86,
        -width * 0.25,
        -length * 0.99,
      )
      ..quadraticBezierTo(-width * 0.11, -length * 1.02, 0, -length * 0.80)
      ..quadraticBezierTo(width * 0.11, -length * 1.02, width * 0.25, -length * 0.99)
      ..cubicTo(
        width * 0.78,
        -length * 0.86,
        width * 0.72,
        -length * 0.28,
        0,
        0,
      )
      ..close();

    var united = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: unit * 0.14));
    for (var i = 0; i < _petalCount; i++) {
      final angle = i * 2 * math.pi / _petalCount;
      final rotated = singlePetal.transform(Matrix4.rotationZ(angle).storage);
      united = Path.combine(PathOperation.union, united, rotated);
    }
    return united.shift(center);
  }

  void _paintStatusGlyph(
    Canvas canvas, {
    required Offset center,
    required double unit,
  }) {
    final shadowPaint = Paint()
      ..color = SakuraGlassNotificationTokens.glyphShadow
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, unit * 0.026);
    final shadowFillPaint = Paint()
      ..color = SakuraGlassNotificationTokens.glyphShadow
      ..style = PaintingStyle.fill
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, unit * 0.026);

    final glyphStrokePaint = Paint()
      ..color = SakuraGlassNotificationTokens.glyphColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final glyphFillPaint = Paint()
      ..color = SakuraGlassNotificationTokens.glyphColor
      ..style = PaintingStyle.fill;

    final shadowOffset = Offset(0, unit * 0.020);

    switch (type) {
      case RikiToastType.success:
      case RikiToastType.celebration:
      case RikiToastType.loading:
        final stroke = unit * 0.074;
        final path = Path()
          ..moveTo(center.dx - 0.140 * unit, center.dy + 0.015 * unit)
          ..lineTo(center.dx - 0.035 * unit, center.dy + 0.120 * unit)
          ..lineTo(center.dx + 0.160 * unit, center.dy - 0.105 * unit);
        canvas.drawPath(
          path.shift(shadowOffset),
          shadowPaint..strokeWidth = stroke,
        );
        canvas.drawPath(path, glyphStrokePaint..strokeWidth = stroke);
      case RikiToastType.error:
        final stroke = unit * 0.072;
        final path = Path()
          ..moveTo(center.dx - 0.105 * unit, center.dy - 0.105 * unit)
          ..lineTo(center.dx + 0.105 * unit, center.dy + 0.105 * unit)
          ..moveTo(center.dx + 0.105 * unit, center.dy - 0.105 * unit)
          ..lineTo(center.dx - 0.105 * unit, center.dy + 0.105 * unit);
        canvas.drawPath(
          path.shift(shadowOffset),
          shadowPaint..strokeWidth = stroke,
        );
        canvas.drawPath(path, glyphStrokePaint..strokeWidth = stroke);
      case RikiToastType.warning:
        final stroke = unit * 0.074;
        final linePath = Path()
          ..moveTo(center.dx, center.dy - 0.145 * unit)
          ..lineTo(center.dx, center.dy + 0.035 * unit);
        final dotCenter = Offset(center.dx, center.dy + 0.145 * unit);
        final dotRadius = unit * 0.044;
        canvas.drawPath(
          linePath.shift(shadowOffset),
          shadowPaint..strokeWidth = stroke,
        );
        canvas.drawCircle(
          dotCenter + shadowOffset,
          dotRadius,
          shadowFillPaint,
        );
        canvas.drawPath(linePath, glyphStrokePaint..strokeWidth = stroke);
        canvas.drawCircle(dotCenter, dotRadius, glyphFillPaint);
      case RikiToastType.info:
        final stroke = unit * 0.072;
        final dotCenter = Offset(center.dx, center.dy - 0.135 * unit);
        final dotRadius = unit * 0.044;
        final stemPath = Path()
          ..moveTo(center.dx, center.dy - 0.025 * unit)
          ..lineTo(center.dx, center.dy + 0.145 * unit);
        canvas.drawCircle(
          dotCenter + shadowOffset,
          dotRadius,
          shadowFillPaint,
        );
        canvas.drawPath(
          stemPath.shift(shadowOffset),
          shadowPaint..strokeWidth = stroke,
        );
        canvas.drawCircle(dotCenter, dotRadius, glyphFillPaint);
        canvas.drawPath(stemPath, glyphStrokePaint..strokeWidth = stroke);
      case RikiToastType.confirmation:
        final stroke = unit * 0.068;
        final curvePath = Path()
          ..moveTo(center.dx - 0.085 * unit, center.dy - 0.065 * unit)
          ..cubicTo(
            center.dx - 0.085 * unit,
            center.dy - 0.170 * unit,
            center.dx + 0.095 * unit,
            center.dy - 0.170 * unit,
            center.dx + 0.095 * unit,
            center.dy - 0.065 * unit,
          )
          ..cubicTo(
            center.dx + 0.095 * unit,
            center.dy + 0.005 * unit,
            center.dx,
            center.dy + 0.005 * unit,
            center.dx,
            center.dy + 0.060 * unit,
          );
        final dotCenter = Offset(center.dx, center.dy + 0.150 * unit);
        final dotRadius = unit * 0.038;
        canvas.drawPath(
          curvePath.shift(shadowOffset),
          shadowPaint..strokeWidth = stroke,
        );
        canvas.drawCircle(
          dotCenter + shadowOffset,
          dotRadius,
          shadowFillPaint,
        );
        canvas.drawPath(curvePath, glyphStrokePaint..strokeWidth = stroke);
        canvas.drawCircle(dotCenter, dotRadius, glyphFillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SakuraGlassBlossomPainter oldDelegate) =>
      oldDelegate.type != type;
}
