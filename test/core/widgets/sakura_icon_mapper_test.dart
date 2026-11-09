import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';
import 'package:rikipath_mobile/core/widgets/sakura_icon_mapper.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

void main() {
  group('SakuraIconMapper.iconForLesson', () {
    test('resolves greetings & conversation titles to conversation icon', () {
      expect(
        SakuraIconMapper.iconForLesson(title: 'Bài 1: Chào hỏi & Hán tự'),
        Sakura3DIconType.conversation,
      );
      expect(
        SakuraIconMapper.iconForLesson(title: 'Hội thoại giao tiếp sơ cấp'),
        Sakura3DIconType.conversation,
      );
      expect(
        SakuraIconMapper.iconForLesson(title: 'Daily Aisatsu & Greeting'),
        Sakura3DIconType.conversation,
      );
    });

    test('resolves kana/alphabet titles to kana icon', () {
      expect(
        SakuraIconMapper.iconForLesson(title: 'Bảng chữ cái Hiragana'),
        Sakura3DIconType.kana,
      );
      expect(
        SakuraIconMapper.iconForLesson(title: 'Katakana cơ bản'),
        Sakura3DIconType.kana,
      );
    });

    test('resolves kanji titles without greetings to kanji icon', () {
      expect(
        SakuraIconMapper.iconForLesson(title: 'Hán tự N5 cơ bản'),
        Sakura3DIconType.kanji,
      );
      expect(
        SakuraIconMapper.iconForLesson(title: 'Bộ thủ Kanji thông dụng'),
        Sakura3DIconType.kanji,
      );
    });

    test('resolves vocabulary titles to vocabulary icon', () {
      expect(
        SakuraIconMapper.iconForLesson(title: 'Từ vựng chủ đề gia đình'),
        Sakura3DIconType.vocabulary,
      );
    });

    test('resolves grammar titles to grammar icon', () {
      expect(
        SakuraIconMapper.iconForLesson(title: 'Mẫu câu ngữ pháp V-te kudasai'),
        Sakura3DIconType.grammar,
      );
    });

    test('resolves listening titles to speech icon', () {
      expect(
        SakuraIconMapper.iconForLesson(title: 'Luyện nghe phản xạ N5'),
        Sakura3DIconType.speech,
      );
    });

    test('resolves generic lessons to dedicated lesson textbook icon', () {
      expect(
        SakuraIconMapper.iconForLesson(title: 'Bài 12'),
        Sakura3DIconType.lesson,
      );
      expect(
        SakuraIconMapper.iconForLesson(title: 'Tổng hợp kiến thức'),
        Sakura3DIconType.lesson,
      );
      expect(
        SakuraIconMapper.iconForLesson(),
        Sakura3DIconType.lesson,
      );
    });

    test('NEVER returns roadmap icon (preventing collision with Home shortcut)', () {
      final sampleTitles = [
        'Bài 1: Chào hỏi & Hán tự',
        'Lộ trình bài 2',
        'Roadmap lesson',
        'Bài học 5',
        '',
      ];
      for (final title in sampleTitles) {
        expect(
          SakuraIconMapper.iconForLesson(title: title),
          isNot(Sakura3DIconType.roadmap),
        );
      }
    });
  });

  group('SakuraIconMapper.iconForNotebookCollection', () {
    test('resolves by NotebookContentType enum when available', () {
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Custom list',
          contentType: NotebookContentType.vocabulary,
        ),
        Sakura3DIconType.vocabulary,
      );
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Grammar list',
          contentType: NotebookContentType.grammar,
        ),
        Sakura3DIconType.grammar,
      );
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Kanji list',
          contentType: NotebookContentType.kanji,
        ),
        Sakura3DIconType.kanji,
      );
    });

    test('resolves by semantic name/routeKey when contentType is manual/unknown', () {
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Từ vựng N4 hay quên',
          routeKey: 'vocab-n4',
        ),
        Sakura3DIconType.vocabulary,
      );
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Ngữ pháp mẫu câu',
          routeKey: 'grammar-patterns',
        ),
        Sakura3DIconType.grammar,
      );
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Hán tự N3',
          routeKey: 'kanji-n3',
        ),
        Sakura3DIconType.kanji,
      );
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Thẻ ghi nhớ từ mới',
          routeKey: 'flashcards-1',
        ),
        Sakura3DIconType.flashcards,
      );
      expect(
        SakuraIconMapper.iconForNotebookCollection(
          name: 'Đã lưu từ bài học',
          routeKey: 'fixture-learning-saved',
        ),
        Sakura3DIconType.notebook,
      );
    });
  });
}
