import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_radius.dart';
import 'package:rikipath_mobile/app/theme/app_shadows.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';
import 'package:rikipath_mobile/core/widgets/riki_card.dart';
import 'package:rikipath_mobile/core/widgets/sakura_mascot.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';

/// Palette tokens specific to the Sakura Gamified Learning Journey.
abstract final class SakuraJourneyColors {
  static const Color primarySakura = Color(0xFFE5577F);
  static const Color primarySakuraDark = Color(0xFFC73D65);
  static const Color softPink = Color(0xFFFCE7EF);
  static const Color palePink = Color(0xFFFFF1F5);
  static const Color warmCream = Color(0xFFFFF9F5);
  static const Color lavender = Color(0xFFEEE9FF);
  static const Color lavenderBorder = Color(0xFFD6CEF8);
  static const Color primaryText = Color(0xFF302B33);
  static const Color secondaryText = Color(0xFF746D75);
  static const Color completedGreen = Color(0xFF27A66B);
  static const Color completedGreenDark = Color(0xFF1E8455);
  static const Color completedBg = Color(0xFFE8F8F0);
  static const Color availableLesson = Color(0xFF8B80C9);
  static const Color availableLessonDark = Color(0xFF6E63B0);
  static const Color locked = Color(0xFFBCC1CA);
  static const Color achievementAmber = Color(0xFFF3B649);
  static const Color pathUpcoming = Color(0xFFE2DCFC);
}

/// The full Gamified Standard Learning Journey Map.
///
/// Lays out lessons along an S-curve road with custom bezier connectors,
/// interactive milestone checkpoints, Riki-chan mascot companions,
/// and distinct states (Completed, Current/Hero, Upcoming).
class SakuraLearningJourneyMap extends StatefulWidget {
  const SakuraLearningJourneyMap({
    required this.lessons,
    required this.currentStudyLevelName,
    required this.onOpenLesson,
    this.nextLessonId,
    this.targetJlptLevelName,
    super.key,
  });

  final List<StandardRoadmapLesson> lessons;
  final String currentStudyLevelName;
  final ValueChanged<String> onOpenLesson;
  final int? nextLessonId;
  final String? targetJlptLevelName;

  @override
  State<SakuraLearningJourneyMap> createState() =>
      _SakuraLearningJourneyMapState();
}

class _SakuraLearningJourneyMapState extends State<SakuraLearningJourneyMap> {
  static const _pageSize = 8;
  int _visibleStart = 0;
  int _visibleEnd = 0;

  @override
  void initState() {
    super.initState();
    _resetWindow();
  }

  @override
  void didUpdateWidget(covariant SakuraLearningJourneyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idsChanged =
        oldWidget.lessons.length != widget.lessons.length ||
        List.generate(
          widget.lessons.length,
          (i) => widget.lessons[i].lessonId,
        ).asMap().entries.any(
          (entry) => oldWidget.lessons[entry.key].lessonId != entry.value,
        );
    if (idsChanged) {
      _resetWindow();
      return;
    }
    final activeIndex = _activeIndex();
    if (activeIndex >= 0 &&
        (activeIndex < _visibleStart || activeIndex >= _visibleEnd)) {
      _resetWindow();
    }
  }

  int _activeIndex() {
    final explicit = widget.nextLessonId;
    final explicitIndex = widget.lessons.indexWhere(
      (lesson) => lesson.lessonId == explicit && !lesson.isCompleted,
    );
    if (explicitIndex >= 0) return explicitIndex;
    return widget.lessons.indexWhere((lesson) => !lesson.isCompleted);
  }

  void _resetWindow() {
    final count = widget.lessons.length;
    final active = _activeIndex();
    _visibleStart = active < 0
        ? math.max(0, count - _pageSize)
        : math.max(0, active - 2);
    _visibleEnd = math.min(count, _visibleStart + _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lessons.isEmpty) return const SizedBox.shrink();

    final activeIndex = _activeIndex();
    final visibleLessons = widget.lessons.sublist(_visibleStart, _visibleEnd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Thematic Japanese Journey Header Banner
        SakuraJourneyMilestoneHeader(
          levelName: widget.currentStudyLevelName,
          completedCount: widget.lessons.where((l) => l.isCompleted).length,
          totalCount: widget.lessons.length,
        ),
        const SizedBox(height: AppSpacing.space2),
        if (_visibleStart > 0)
          TextButton.icon(
            key: const ValueKey('journey_show_earlier'),
            onPressed: () => setState(() {
              _visibleStart = math.max(0, _visibleStart - _pageSize);
            }),
            icon: const Icon(Icons.expand_less_rounded),
            label: const Text('Xem các bài học trước'),
          ),

        // 2. Interactive Gamified S-Curve Road
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            const double nodeDiameter = 48.0;
            const double heroNodeDiameter = 54.0;
            const double nodeVerticalSpacing = 128.0;

            // Chỉ dựng một vùng bài học mỗi lần để lộ trình dài vẫn mượt.
            final nodePositions = <Offset>[];
            for (var i = 0; i < visibleLessons.length; i++) {
              final xRatio = _xRatioForIndex(_visibleStart + i);
              final x = totalWidth * xRatio;
              final y = (i * nodeVerticalSpacing) + 38.0;
              nodePositions.add(Offset(x, y));
            }

            final totalHeight =
                (visibleLessons.length * nodeVerticalSpacing) + 22.0;

            return RepaintBoundary(
              child: SizedBox(
                width: totalWidth,
                height: totalHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/learning/sakura_garden.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            ColoredBox(
                              color: Colors.white.withValues(alpha: 0.57),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // S-Curve Path Connector Layer
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: SakuraJourneyPathPainter(
                            nodePositions: nodePositions,
                            completedLessonStates: [
                              for (final lesson in visibleLessons)
                                lesson.isCompleted,
                            ],
                            activeIndex: activeIndex - _visibleStart,
                          ),
                        ),
                      ),
                    ),

                    // Các node được bố trí theo vùng; đường nối nằm sau nhãn.
                    for (
                      var index = 0;
                      index < visibleLessons.length;
                      index++
                    ) ...[
                      ..._buildPositionedNodeElements(
                        lesson: visibleLessons[index],
                        center: nodePositions[index],
                        isCurrent: _visibleStart + index == activeIndex,
                        nodeDiameter: _visibleStart + index == activeIndex
                            ? heroNodeDiameter
                            : nodeDiameter,
                        totalWidth: totalWidth,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        if (_visibleEnd < widget.lessons.length)
          TextButton.icon(
            key: const ValueKey('journey_show_more'),
            onPressed: () => setState(() {
              _visibleEnd = math.min(
                widget.lessons.length,
                _visibleEnd + _pageSize,
              );
            }),
            icon: const Icon(Icons.expand_more_rounded),
            label: const Text('Xem thêm bài học'),
          ),
      ],
    );
  }

  /// Calculates horizontal normalized position (0.0 to 1.0) along S-curve.
  static double _xRatioForIndex(int index) {
    // Alternating pattern: Center (0.50) -> Left (0.24) -> Center (0.50) -> Right (0.76)
    final cycle = index % 4;
    switch (cycle) {
      case 0:
        return 0.50;
      case 1:
        return 0.23;
      case 2:
        return 0.50;
      case 3:
        return 0.77;
      default:
        return 0.50;
    }
  }

  List<Widget> _buildPositionedNodeElements({
    required StandardRoadmapLesson lesson,
    required Offset center,
    required bool isCurrent,
    required double nodeDiameter,
    required double totalWidth,
  }) {
    const double nodeColWidth = 112.0;
    final nodeLeft = (center.dx - (nodeColWidth / 2)).clamp(
      4.0,
      totalWidth - nodeColWidth - 4.0,
    );
    final nodeTop = center.dy - (nodeDiameter / 2);

    final elements = <Widget>[
      // 1. The interactive node and label below it
      Positioned(
        left: nodeLeft,
        top: nodeTop,
        width: nodeColWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SakuraJourneyNodeButton(
              lesson: lesson,
              isCurrent: isCurrent,
              diameter: nodeDiameter,
              onTap: () => widget.onOpenLesson(lesson.lessonId.toString()),
            ),
            const SizedBox(height: 6),
            _NodeLabel(lesson: lesson, isCurrent: isCurrent),
          ],
        ),
      ),
    ];

    return elements;
  }
}

/// Thematic milestone banner reflecting Japanese cultural environments by level.
class SakuraJourneyMilestoneHeader extends StatelessWidget {
  const SakuraJourneyMilestoneHeader({
    required this.levelName,
    required this.completedCount,
    required this.totalCount,
    super.key,
  });

  final String levelName;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final normalizedLevel = levelName.trim().toUpperCase();

    // Determine cultural theme by level
    final (
      icon,
      themeTitle,
      themeSubtitle,
      themeBadgeBg,
      themeBadgeFg,
    ) = switch (normalizedLevel) {
      'N5' => (
        '🌸',
        'Vườn hoa Sakura',
        'Khởi đầu lộ trình tiếng Nhật căn bản',
        SakuraJourneyColors.palePink,
        SakuraJourneyColors.primarySakuraDark,
      ),
      'N4' => (
        '🏮',
        'Phố cổ Edo',
        'Tự tin giao tiếp và sinh hoạt thường ngày',
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
      ),
      'N3' => (
        '⛩️',
        'Đường đền linh thiêng',
        'Luyện đọc hiểu hội thoại trung cấp',
        const Color(0xFFF3E5F5),
        const Color(0xFF6A1B9A),
      ),
      'N2' => (
        '🗻',
        'Đỉnh núi Phú Sĩ',
        'Chinh phục tiếng Nhật nâng cao & công việc',
        const Color(0xFFE1F5FE),
        const Color(0xFF0277BD),
      ),
      _ => (
        '🌸',
        'Hành trình Sakura',
        'Lộ trình học chuẩn RikiPath',
        SakuraJourneyColors.palePink,
        SakuraJourneyColors.primarySakuraDark,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardWarmWhite,
        borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
        border: Border.all(color: AppColors.borderSubtlePink, width: 1.2),
        boxShadow: AppShadows.sakuraSubtle,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: themeBadgeBg,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        themeTitle,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: themeBadgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        levelName,
                        style: TextStyle(
                          color: themeBadgeFg,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  themeSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.metadata.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: completedCount == totalCount && totalCount > 0
                  ? SakuraJourneyColors.completedBg
                  : SakuraJourneyColors.softPink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$completedCount/$totalCount',
              style: TextStyle(
                color: completedCount == totalCount && totalCount > 0
                    ? SakuraJourneyColors.completedGreen
                    : SakuraJourneyColors.primarySakuraDark,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// S-Curve Cubic Bezier Path Painter connecting lesson nodes smoothly.
class SakuraJourneyPathPainter extends CustomPainter {
  const SakuraJourneyPathPainter({
    required this.nodePositions,
    required this.completedLessonStates,
    required this.activeIndex,
  });

  final List<Offset> nodePositions;
  final List<bool> completedLessonStates;
  final int activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    // Background dashed/pale path for all future segments
    final backgroundPaint = Paint()
      ..color = SakuraJourneyColors.pathUpcoming
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final completedPaint = Paint()
      ..color = SakuraJourneyColors.completedGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = SakuraJourneyColors.primarySakura
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    // Draw segment by segment
    for (var i = 0; i < nodePositions.length - 1; i++) {
      final p0 = nodePositions[i];
      final p1 = nodePositions[i + 1];

      final segmentPath = Path();
      segmentPath.moveTo(p0.dx, p0.dy);

      final dy = p1.dy - p0.dy;
      // Smooth cubic curve control points
      segmentPath.cubicTo(
        p0.dx,
        p0.dy + (dy * 0.5),
        p1.dx,
        p1.dy - (dy * 0.5),
        p1.dx,
        p1.dy,
      );

      // Determine segment coloring
      final bothCompleted =
          completedLessonStates[i] && completedLessonStates[i + 1];
      if (bothCompleted) {
        canvas.drawPath(segmentPath, completedPaint);
      } else if (i + 1 == activeIndex && completedLessonStates[i]) {
        canvas.drawPath(segmentPath, activePaint);
      } else {
        canvas.drawPath(segmentPath, backgroundPaint);
      }

      // Draw subtle decorative stepping stones / sakura dots along the curve
      _drawSteppingDots(canvas, p0, p1, bothCompleted);
    }
  }

  void _drawSteppingDots(
    Canvas canvas,
    Offset p0,
    Offset p1,
    bool isCompleted,
  ) {
    final dotPaint = Paint()
      ..color = isCompleted
          ? SakuraJourneyColors.completedGreen.withValues(alpha: 0.6)
          : SakuraJourneyColors.lavenderBorder
      ..style = PaintingStyle.fill;

    const steps = 3;
    final dy = p1.dy - p0.dy;
    for (var s = 1; s <= steps; s++) {
      final t = s / (steps + 1);
      // Cubic bezier evaluation
      final cy1 = p0.dy + (dy * 0.5);
      final cy2 = p1.dy - (dy * 0.5);

      final oneMinusT = 1.0 - t;
      final x =
          (math.pow(oneMinusT, 3) * p0.dx) +
          (3 * math.pow(oneMinusT, 2) * t * p0.dx) +
          (3 * oneMinusT * math.pow(t, 2) * p1.dx) +
          (math.pow(t, 3) * p1.dx);
      final y =
          (math.pow(oneMinusT, 3) * p0.dy) +
          (3 * math.pow(oneMinusT, 2) * t * cy1) +
          (3 * oneMinusT * math.pow(t, 2) * cy2) +
          (math.pow(t, 3) * p1.dy);

      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SakuraJourneyPathPainter oldDelegate) {
    return !listEquals(
          oldDelegate.completedLessonStates,
          completedLessonStates,
        ) ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.nodePositions != nodePositions;
  }
}

/// Physical gamified tactile node button using RikiCard for 100% test compatibility.
class SakuraJourneyNodeButton extends StatelessWidget {
  const SakuraJourneyNodeButton({
    required this.lesson,
    required this.isCurrent,
    required this.diameter,
    required this.onTap,
    super.key,
  });

  final StandardRoadmapLesson lesson;
  final bool isCurrent;
  final double diameter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.isCompleted;

    // Color decisions
    final Color topColor;
    final Color borderColor;
    final Color iconColor;
    final IconData nodeIcon;

    if (isCompleted) {
      topColor = SakuraJourneyColors.completedGreen;
      borderColor = SakuraJourneyColors.completedGreenDark;
      iconColor = Colors.white;
      nodeIcon = Icons.check_rounded;
    } else if (isCurrent) {
      topColor = SakuraJourneyColors.primarySakura;
      borderColor = SakuraJourneyColors.primarySakuraDark;
      iconColor = Colors.white;
      nodeIcon = Icons.menu_book_rounded;
    } else {
      topColor = Colors.white;
      borderColor = SakuraJourneyColors.lavenderBorder;
      iconColor = SakuraJourneyColors.availableLesson;
      nodeIcon = Icons.menu_book_outlined;
    }

    return Semantics(
      button: true,
      label:
          'Bài học ${lesson.title}, ${isCompleted ? "Đã hoàn thành" : (isCurrent ? "Đang học" : "Chưa học")}',
      child: SizedBox(
        width: diameter + 16,
        height: diameter + 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Halo for Current Hero Node
            if (isCurrent)
              Container(
                width: diameter + 14,
                height: diameter + 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SakuraJourneyColors.primarySakura.withValues(
                    alpha: 0.16,
                  ),
                  border: Border.all(
                    color: SakuraJourneyColors.primarySakura.withValues(
                      alpha: 0.35,
                    ),
                    width: 2.5,
                  ),
                ),
              ),

            // Progress is Backend-owned for every lesson, including 0%.
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: (lesson.progressPercent / 100).clamp(0.0, 1.0),
                end: (lesson.progressPercent / 100).clamp(0.0, 1.0),
              ),
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => SizedBox(
                width: diameter + 8,
                height: diameter + 8,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: SakuraJourneyColors.lavenderBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? SakuraJourneyColors.completedGreen
                        : SakuraJourneyColors.primarySakura,
                  ),
                ),
              ),
            ),

            // RikiCard wraps the node for 100% test compatibility and physical press
            RikiCard(
              key: ValueKey<String>('standard_lesson_${lesson.lessonId}'),
              onTap: onTap,
              padding: EdgeInsets.zero,
              backgroundColor: topColor,
              borderColor: borderColor,
              borderRadius: 999,
              boxShadow: [
                BoxShadow(
                  color: (isCompleted
                      ? SakuraJourneyColors.completedGreenDark
                      : (isCurrent
                            ? SakuraJourneyColors.primarySakuraDark
                            : SakuraJourneyColors.lavenderBorder)),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color:
                      (isCompleted
                              ? SakuraJourneyColors.completedGreen
                              : (isCurrent
                                    ? SakuraJourneyColors.primarySakura
                                    : Colors.black))
                          .withValues(alpha: 0.16),
                  offset: const Offset(0, 5),
                  blurRadius: 6,
                ),
              ],
              child: SizedBox.square(
                dimension: diameter,
                child: Center(
                  child: Icon(
                    nodeIcon,
                    color: iconColor,
                    size: isCurrent ? 32 : 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact textual label beneath each journey node.
class _NodeLabel extends StatelessWidget {
  const _NodeLabel({required this.lesson, required this.isCurrent});

  final StandardRoadmapLesson lesson;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrent) ...[
            Text(
              'Bài tiếp theo',
              style: AppTypography.metadata.copyWith(
                color: SakuraJourneyColors.primarySakura,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 1),
          ],
          Text(
            lesson.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.badgeText.copyWith(
              color: isCurrent
                  ? SakuraJourneyColors.primarySakura
                  : (lesson.isCompleted
                        ? SakuraJourneyColors.completedGreenDark
                        : SakuraJourneyColors.primaryText),
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isCurrent
                  ? SakuraJourneyColors.softPink
                  : (lesson.isCompleted
                        ? SakuraJourneyColors.completedBg
                        : AppColors.surfaceSubtle),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isCurrent
                    ? SakuraJourneyColors.primarySakura.withValues(alpha: 0.3)
                    : (lesson.isCompleted
                          ? SakuraJourneyColors.completedGreen.withValues(
                              alpha: 0.25,
                            )
                          : AppColors.border),
                width: 0.8,
              ),
            ),
            child: Text(
              lesson.isCompleted
                  ? 'Hoàn thành'
                  : (isCurrent
                        ? (lesson.progressPercent > 0
                              ? 'Đang học • ${lesson.progressPercent}%'
                              : 'Đang học')
                        : 'Chưa học'),
              style: TextStyle(
                color: isCurrent
                    ? SakuraJourneyColors.primarySakuraDark
                    : (lesson.isCompleted
                          ? SakuraJourneyColors.completedGreen
                          : SakuraJourneyColors.secondaryText),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Learning Journey Preview for the Learning Home screen.
///
/// Shows a mini 3-node connected S-curve preview with Riki-chan,
/// motivating the learner to open the full Standard Roadmap.
class SakuraJourneyPreviewWidget extends StatelessWidget {
  const SakuraJourneyPreviewWidget({
    required this.lessons,
    required this.onOpenRoadmap,
    super.key,
  });

  final List<StandardRoadmapLesson> lessons;
  final VoidCallback onOpenRoadmap;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    // Take first 3 lessons for the compact preview
    final previewLessons = lessons.take(3).toList();
    final firstIncompleteIndex = previewLessons.indexWhere(
      (l) => !l.isCompleted,
    );
    final activeIndex = firstIncompleteIndex >= 0 ? firstIncompleteIndex : 0;

    return RikiCard(
      onTap: onOpenRoadmap,
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.borderSubtlePink,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SakuraJourneyColors.softPink,
                  borderRadius: BorderRadius.circular(AppRadius.compact),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 18,
                  color: SakuraJourneyColors.primarySakura,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hành trình bài học',
                      style: AppTypography.cardTitle.copyWith(fontSize: 15),
                    ),
                    Text(
                      'Bản đồ học tập chuẩn Gamified',
                      style: AppTypography.metadata.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                'Mở bản đồ ›',
                style: AppTypography.badgeText.copyWith(
                  color: SakuraJourneyColors.primarySakura,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Mini 3-Node Interactive Preview Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: SakuraJourneyColors.palePink.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
              border: Border.all(color: SakuraJourneyColors.softPink, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < previewLessons.length; i++) ...[
                  _MiniPreviewNode(
                    lesson: previewLessons[i],
                    isCurrent: i == activeIndex,
                  ),
                  if (i < previewLessons.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: previewLessons[i].isCompleted
                              ? SakuraJourneyColors.completedGreen
                              : SakuraJourneyColors.pathUpcoming,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPreviewNode extends StatelessWidget {
  const _MiniPreviewNode({required this.lesson, required this.isCurrent});

  final StandardRoadmapLesson lesson;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.isCompleted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? SakuraJourneyColors.completedGreen
                    : (isCurrent
                          ? SakuraJourneyColors.primarySakura
                          : Colors.white),
                border: Border.all(
                  color: isCompleted
                      ? SakuraJourneyColors.completedGreenDark
                      : (isCurrent
                            ? SakuraJourneyColors.primarySakuraDark
                            : SakuraJourneyColors.lavenderBorder),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isCompleted
                                ? SakuraJourneyColors.completedGreen
                                : (isCurrent
                                      ? SakuraJourneyColors.primarySakura
                                      : Colors.black))
                            .withValues(alpha: 0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : (isCurrent
                            ? Icons.menu_book_rounded
                            : Icons.menu_book_outlined),
                  color: isCompleted || isCurrent
                      ? Colors.white
                      : SakuraJourneyColors.availableLesson,
                  size: 18,
                ),
              ),
            ),
            if (isCurrent)
              const Positioned(
                top: -10,
                right: -10,
                child: SakuraMascot(pose: SakuraMascotPose.greeting, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: Text(
            lesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? SakuraJourneyColors.primarySakura
                  : SakuraJourneyColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
