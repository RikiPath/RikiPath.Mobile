import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Tập hợp 21 biểu tượng 3D chính thức của RikiPath.
///
/// Mỗi biểu tượng dùng một ảnh trong `assets/images/icons_3d/`, có nền trong suốt
/// và màu sắc hài hòa với giao diện Sakura.
enum Sakura3DIconType {
  streak(
    assetPath: 'assets/images/icons_3d/streak_flame.webp',
    fallbackIcon: Icons.local_fire_department_rounded,
    defaultLabel: 'Streak',
  ),
  kana(
    assetPath: 'assets/images/icons_3d/kana.webp',
    fallbackIcon: Icons.translate_rounded,
    defaultLabel: 'Kana',
  ),
  grammar(
    assetPath: 'assets/images/icons_3d/grammar_book.webp',
    fallbackIcon: Icons.menu_book_rounded,
    defaultLabel: 'Grammar',
  ),
  vocabulary(
    assetPath: 'assets/images/icons_3d/vocabulary_book.webp',
    fallbackIcon: Icons.auto_stories_rounded,
    defaultLabel: 'Vocabulary',
  ),
  kanji(
    assetPath: 'assets/images/icons_3d/kanji_tile.webp',
    fallbackIcon: Icons.translate_rounded,
    defaultLabel: 'Kanji',
  ),
  brush(
    assetPath: 'assets/images/icons_3d/kanji_brush.webp',
    fallbackIcon: Icons.brush_rounded,
    defaultLabel: 'Calligraphy Brush',
  ),
  essay(
    assetPath: 'assets/images/icons_3d/essay_writing.webp',
    fallbackIcon: Icons.edit_note_rounded,
    defaultLabel: 'Essay Writing',
  ),
  flashcards(
    assetPath: 'assets/images/icons_3d/flashcards.webp',
    fallbackIcon: Icons.style_rounded,
    defaultLabel: 'Flashcards',
  ),
  srs(
    assetPath: 'assets/images/icons_3d/srs.webp',
    fallbackIcon: Icons.inventory_2_rounded,
    defaultLabel: 'SRS Review',
  ),
  mockExam(
    assetPath: 'assets/images/icons_3d/mock_exam.webp',
    fallbackIcon: Icons.quiz_rounded,
    defaultLabel: 'Mock Exam',
  ),
  notebook(
    assetPath: 'assets/images/icons_3d/notebook.webp',
    fallbackIcon: Icons.book_rounded,
    defaultLabel: 'Notebook',
  ),
  roadmap(
    assetPath: 'assets/images/icons_3d/roadmap.webp',
    fallbackIcon: Icons.map_rounded,
    defaultLabel: 'Roadmap',
  ),
  calendar(
    assetPath: 'assets/images/icons_3d/calendar.webp',
    fallbackIcon: Icons.calendar_month_rounded,
    defaultLabel: 'Calendar',
  ),
  mentor(
    assetPath: 'assets/images/icons_3d/mentor.webp',
    fallbackIcon: Icons.support_agent_rounded,
    defaultLabel: 'Mentor',
  ),
  classroom(
    assetPath: 'assets/images/icons_3d/classroom.webp',
    fallbackIcon: Icons.videocam_rounded,
    defaultLabel: 'Classroom',
  ),
  speech(
    assetPath: 'assets/images/icons_3d/speech.webp',
    fallbackIcon: Icons.mic_rounded,
    defaultLabel: 'Speech',
  ),
  ocr(
    assetPath: 'assets/images/icons_3d/ocr.webp',
    fallbackIcon: Icons.document_scanner_rounded,
    defaultLabel: 'OCR Scanner',
  ),
  achievement(
    assetPath: 'assets/images/icons_3d/achievement.webp',
    fallbackIcon: Icons.emoji_events_rounded,
    defaultLabel: 'Achievement',
  ),
  lesson(
    assetPath: 'assets/images/icons_3d/lesson_book.webp',
    fallbackIcon: Icons.menu_book_rounded,
    defaultLabel: 'Lesson',
  ),
  conversation(
    assetPath: 'assets/images/icons_3d/conversation.webp',
    fallbackIcon: Icons.forum_rounded,
    defaultLabel: 'Conversation',
  ),
  notification(
    assetPath: 'assets/images/icons_3d/notification_bell.webp',
    fallbackIcon: Icons.notifications_rounded,
    defaultLabel: 'Notification',
  );

  const Sakura3DIconType({
    required this.assetPath,
    required this.fallbackIcon,
    required this.defaultLabel,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String defaultLabel;
}

/// Reusable widget that renders a Premium 3D Realistic RikiPath icon asset
/// with transparent background, resolution-aware image caching, accessibility
/// semantics, and a graceful Material icon fallback if the asset fails to load.
class Sakura3DIcon extends StatelessWidget {
  const Sakura3DIcon({
    required this.type,
    this.size = 32,
    this.semanticLabel,
    this.excludeFromSemantics = true,
    this.fallbackColor,
    super.key,
  });

  final Sakura3DIconType type;
  final double size;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final targetCacheSize = (size * dpr).round().clamp(48, 256);

    final image = Image.asset(
      type.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
      cacheWidth: targetCacheSize,
      cacheHeight: targetCacheSize,
      excludeFromSemantics: excludeFromSemantics,
      semanticLabel: excludeFromSemantics
          ? null
          : (semanticLabel ?? type.defaultLabel),
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          type.fallbackIcon,
          size: size * 0.78,
          color: fallbackColor ?? AppColors.brandPrimary,
        );
      },
    );

    if (excludeFromSemantics) {
      return ExcludeSemantics(
        child: SizedBox.square(dimension: size, child: image),
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? type.defaultLabel,
      child: SizedBox.square(dimension: size, child: image),
    );
  }
}
