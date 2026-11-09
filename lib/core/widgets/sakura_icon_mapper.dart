import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

/// Centralized semantic resolver for Sakura 3D Icons across RikiPath.
///
/// Ensures consistent, deterministic visual semantics while preventing
/// confusing icon duplications on the same screen (such as the Home study
/// category shortcut colliding with the active lesson card).
class SakuraIconMapper {
  const SakuraIconMapper._();

  /// Resolves the semantic 3D icon for a lesson based on its title,
  /// topic keywords, or content category.
  ///
  /// Guarantees:
  /// - Deterministic mapping (same lesson always receives the exact same icon).
  /// - Never returns [Sakura3DIconType.roadmap] (which is strictly reserved
  ///   for the overall Study Journey / Roadmap category).
  static Sakura3DIconType iconForLesson({
    String? title,
    String? topic,
    String? contentType,
  }) {
    final combined =
        '${topic ?? ''} ${title ?? ''} ${contentType ?? ''}'.toLowerCase();

    // 1. Greetings & Conversation (e.g. "Chào hỏi & Hán tự", "Hội thoại", "Giao tiếp")
    if (combined.contains('chào') ||
        combined.contains('hội thoại') ||
        combined.contains('giao tiếp') ||
        combined.contains('conversation') ||
        combined.contains('greeting') ||
        combined.contains('aisatsu') ||
        combined.contains('あいさつ') ||
        combined.contains('会話')) {
      return Sakura3DIconType.conversation;
    }

    // 2. Hiragana / Katakana / Kana / Alphabets
    if (combined.contains('hiragana') ||
        combined.contains('katakana') ||
        combined.contains('kana') ||
        combined.contains('bảng chữ cái') ||
        combined.contains('chữ cái') ||
        combined.contains('alphabet')) {
      return Sakura3DIconType.kana;
    }

    // 3. Kanji / Chinese characters / Stroke order
    if (combined.contains('hán tự') ||
        combined.contains('kanji') ||
        combined.contains('bộ thủ') ||
        combined.contains('chữ hán')) {
      return Sakura3DIconType.kanji;
    }

    // 4. Vocabulary / Word lists
    if (combined.contains('từ vựng') ||
        combined.contains('vocabulary') ||
        combined.contains('tango') ||
        combined.contains('単語') ||
        combined.contains('kotoba')) {
      return Sakura3DIconType.vocabulary;
    }

    // 5. Grammar / Sentence patterns
    if (combined.contains('ngữ pháp') ||
        combined.contains('grammar') ||
        combined.contains('bunpou') ||
        combined.contains('文法') ||
        combined.contains('mẫu câu')) {
      return Sakura3DIconType.grammar;
    }

    // 6. Listening / Pronunciation / Audio
    if (combined.contains('luyện nghe') ||
        combined.contains('nghe') ||
        combined.contains('listening') ||
        combined.contains('choukai') ||
        combined.contains('phát âm') ||
        combined.contains('audio')) {
      return Sakura3DIconType.speech;
    }

    // 7. Reading comprehension
    if (combined.contains('đọc hiểu') ||
        combined.contains('đọc') ||
        combined.contains('reading') ||
        combined.contains('dokkai')) {
      return Sakura3DIconType.notebook;
    }

    // 8. Exam / Test / Practice
    if (combined.contains('luyện đề') ||
        combined.contains('thi thử') ||
        combined.contains('mock') ||
        combined.contains('exam') ||
        combined.contains('test')) {
      return Sakura3DIconType.mockExam;
    }

    // Default canonical lesson icon: Open study textbook with pencil
    return Sakura3DIconType.lesson;
  }

  /// Resolves the semantic 3D icon for a notebook collection.
  static Sakura3DIconType iconForNotebookCollection({
    required String name,
    String? routeKey,
    NotebookContentType? contentType,
  }) {
    if (contentType != null) {
      switch (contentType) {
        case NotebookContentType.vocabulary:
          return Sakura3DIconType.vocabulary;
        case NotebookContentType.grammar:
          return Sakura3DIconType.grammar;
        case NotebookContentType.kanji:
          return Sakura3DIconType.kanji;
        case NotebookContentType.manual:
        case NotebookContentType.unknown:
          break;
      }
    }

    final combined = '$name ${routeKey ?? ''}'.toLowerCase();
    if (combined.contains('vocab') ||
        combined.contains('từ vựng') ||
        combined.contains('tango') ||
        combined.contains('単語')) {
      return Sakura3DIconType.vocabulary;
    }
    if (combined.contains('grammar') ||
        combined.contains('ngữ pháp') ||
        combined.contains('bunpou') ||
        combined.contains('文法')) {
      return Sakura3DIconType.grammar;
    }
    if (combined.contains('kanji') ||
        combined.contains('hán tự') ||
        combined.contains('chữ hán') ||
        combined.contains('漢字')) {
      return Sakura3DIconType.kanji;
    }
    if (combined.contains('kana') ||
        combined.contains('hiragana') ||
        combined.contains('katakana')) {
      return Sakura3DIconType.kana;
    }
    if (combined.contains('flashcard') || combined.contains('thẻ')) {
      return Sakura3DIconType.flashcards;
    }

    return Sakura3DIconType.notebook;
  }
}
