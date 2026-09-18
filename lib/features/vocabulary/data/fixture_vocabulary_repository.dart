import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary_repository.dart';

/// Typed visual-development data derived from the approved C11 Stitch screens.
///
/// Route keys and enrichment fields in this repository are never represented
/// as backend vocabulary IDs or response fields.
class FixtureVocabularyRepository implements VocabularyRepository {
  const FixtureVocabularyRepository();

  static const String keikenRouteKey = 'fixture-keiken';
  static const String junbiRouteKey = 'fixture-junbi';

  @override
  Future<VocabularyPage> search(VocabularyQuery query) async {
    final keyword = query.keyword.trim().toLowerCase();
    final filtered = entries
        .where((entry) {
          final matchesLevel =
              query.level == null || entry.level == query.level;
          final matchesKeyword =
              keyword.isEmpty ||
              entry.word.toLowerCase().contains(keyword) ||
              entry.reading.toLowerCase().contains(keyword) ||
              entry.meaning.toLowerCase().contains(keyword);
          return matchesLevel && matchesKeyword;
        })
        .toList(growable: false);

    final pageSize = query.pageSize < 1 ? 20 : query.pageSize;
    final page = query.page < 1 ? 1 : query.page;
    final start = (page - 1) * pageSize;
    final pageItems = start >= filtered.length
        ? const <VocabularyEntry>[]
        : filtered.sublist(start, (start + pageSize).clamp(0, filtered.length));
    final totalPages = filtered.isEmpty
        ? 0
        : (filtered.length / pageSize).ceil();

    return VocabularyPage(
      items: pageItems,
      page: page,
      pageSize: pageSize,
      totalCount: filtered.length,
      totalPages: totalPages,
      source: VocabularyDataSource.fixture,
    );
  }

  @override
  Future<VocabularyEntry> loadDetail(String routeKey) async {
    return entries.firstWhere(
      (entry) => entry.routeKey == routeKey,
      orElse: () => throw StateError('Unknown fixture vocabulary route key.'),
    );
  }

  static const List<VocabularyEntry> entries = <VocabularyEntry>[
    VocabularyEntry(
      routeKey: keikenRouteKey,
      remoteId: null,
      word: '経験',
      reading: 'けいけん',
      meaning: 'Kinh nghiệm, trải nghiệm thực tế',
      partOfSpeech: 'Danh từ / する',
      exampleSentence: '日本で働いた経験があります。',
      level: JlptLevel.n3,
      source: VocabularyDataSource.fixture,
      isSaved: false,
      enrichment: VocabularyEnrichment(
        sinoVietnamese: 'KINH NGHIỆM',
        definition:
            'Việc tự mình trải qua, tiếp xúc hoặc thực hành để tích lũy sự hiểu biết và kỹ năng.',
        frequencyLabel: 'Rất hay gặp',
        examples: <VocabularyExample>[
          VocabularyExample(
            sentence: '日本で働いた経験があります。',
            translation: 'Tôi có kinh nghiệm từng làm việc tại Nhật Bản.',
          ),
          VocabularyExample(
            sentence: '経験を積むことで、自信がつきます。',
            translation: 'Tích lũy kinh nghiệm giúp ta tự tin hơn.',
          ),
        ],
        collocations: <VocabularyCollocation>[
          VocabularyCollocation(
            phrase: '経験を積む',
            meaning: 'Tích lũy kinh nghiệm',
          ),
          VocabularyCollocation(
            phrase: '経験が浅い',
            meaning: 'Ít kinh nghiệm / Non nớt',
          ),
        ],
        nuance:
            '経験 nói về kiến thức hoặc kỹ năng tích lũy theo thời gian; 体験 thường là một trải nghiệm cụ thể, ngắn hạn.',
        kanji: <VocabularyKanjiPart>[
          VocabularyKanjiPart(
            character: '経',
            sinoVietnamese: 'KINH',
            meaning: 'Trải qua, kinh tuyến, quản lý',
            onReading: 'ケイ、キョウ',
          ),
          VocabularyKanjiPart(
            character: '験',
            sinoVietnamese: 'NGHIỆM',
            meaning: 'Thử thách, kiểm tra, chứng thực',
            onReading: 'ケン、ゲン',
          ),
        ],
        relatedLessons: <VocabularyRelatedLesson>[
          VocabularyRelatedLesson(
            routeId: FixtureLessonRepository.lesson19RouteId,
            number: 19,
            title: 'Ngữ pháp ～たことがある',
            subtitle: 'Nói về kinh nghiệm trong quá khứ',
          ),
        ],
      ),
    ),
    VocabularyEntry(
      routeKey: 'fixture-kaizen',
      remoteId: null,
      word: '改善',
      reading: 'かいぜん',
      meaning: 'Cải thiện, cải tiến chất lượng',
      partOfSpeech: 'Danh từ / する',
      level: JlptLevel.n3,
      source: VocabularyDataSource.fixture,
      isSaved: false,
      enrichment: VocabularyEnrichment(sinoVietnamese: 'CẢI THIỆN'),
    ),
    VocabularyEntry(
      routeKey: junbiRouteKey,
      remoteId: null,
      word: '準備',
      reading: 'じゅんび',
      meaning: 'Chuẩn bị, sắp xếp sẵn sàng',
      partOfSpeech: 'Danh từ / する',
      level: JlptLevel.n4,
      source: VocabularyDataSource.fixture,
      isSaved: true,
      enrichment: VocabularyEnrichment(sinoVietnamese: 'CHUẨN BỊ'),
    ),
    VocabularyEntry(
      routeKey: 'fixture-yakusoku',
      remoteId: null,
      word: '約束',
      reading: 'やくそく',
      meaning: 'Lời hứa, cuộc hẹn gặp',
      partOfSpeech: 'Danh từ / する',
      level: JlptLevel.n4,
      source: VocabularyDataSource.fixture,
      isSaved: false,
      enrichment: VocabularyEnrichment(sinoVietnamese: 'ƯỚC THÚC'),
    ),
    VocabularyEntry(
      routeKey: 'fixture-annai',
      remoteId: null,
      word: '案内',
      reading: 'あんない',
      meaning: 'Hướng dẫn, dẫn đường, thông báo',
      partOfSpeech: 'Danh từ / する',
      level: JlptLevel.n4,
      source: VocabularyDataSource.fixture,
      isSaved: false,
      enrichment: VocabularyEnrichment(sinoVietnamese: 'ÁN NỘI'),
    ),
    VocabularyEntry(
      routeKey: 'fixture-gakusei',
      remoteId: null,
      word: '学生',
      reading: 'がくせい',
      meaning: 'Học sinh, sinh viên',
      partOfSpeech: 'Danh từ',
      level: JlptLevel.n5,
      source: VocabularyDataSource.fixture,
      isSaved: false,
      enrichment: VocabularyEnrichment(sinoVietnamese: 'HỌC SINH'),
    ),
  ];
}
