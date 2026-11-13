import 'package:flutter/material.dart';
import 'package:rikipath_mobile/core/widgets/sakura_menu_icon_painter.dart';

/// Biểu tượng màu dành cho tiện ích và mục điều hướng; không dùng cho nút điều khiển.
enum SakuraColorfulIconType {
  streak('🔥'),
  trophy('🏆'),
  notifications('🔔'),
  calendar('🗓️'),
  learningGoal('🎯'),
  placementTest('📋'),
  learningProgress('📊'),
  consultation('🧑‍🏫'),
  mentorApplication('🎓'),
  editProfile('🪪'),
  settings('⚙️'),
  logout('↪️'),
  security('🛡️'),
  password('🔐'),
  language('🌐'),
  email('📨'),
  examDate('📆'),
  studyTime('⏱️');

  const SakuraColorfulIconType(this.glyph);

  final String glyph;

  bool get emojiOnly => this == streak || this == trophy || this == calendar;
}

/// Header và menu có thể dùng emoji đã duyệt; Đăng xuất dùng vector mũi tên.
/// Label truy cập được cung cấp bởi nút hoặc tile bao ngoài, tránh đọc lặp icon.
class SakuraColorfulIcon extends StatelessWidget {
  const SakuraColorfulIcon({
    required this.type,
    this.size = 28,
    this.fontSize,
    this.useEmoji = false,
    super.key,
  });

  final SakuraColorfulIconType type;
  final double size;
  final double? fontSize;
  final bool useEmoji;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: (useEmoji || type.emojiOnly)
            ? Center(
                child: Text(
                  type.glyph,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: fontSize ?? (size * 0.94),
                    height: 1,
                  ),
                ),
              )
            : CustomPaint(painter: SakuraMenuIconPainter(type)),
      ),
    );
  }
}
