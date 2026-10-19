import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji_repository.dart';

/// Typed visual-development data derived from the approved C12 Stitch screens.
///
/// Fixture route keys and enrichment never masquerade as backend IDs or fields.
class FixtureKanjiRepository implements KanjiRepository {
  const FixtureKanjiRepository();

  static const String kenRouteKey = 'fixture-ken';

  @override
  Future<KanjiPage> search(KanjiQuery query) async {
    final keyword = query.keyword.trim().toLowerCase();
    final filtered = entries
        .where((entry) {
          final matchesLevel =
              query.level == null || entry.level == query.level!.level;
          final matchesKeyword =
              keyword.isEmpty ||
              entry.character.toLowerCase().contains(keyword) ||
              entry.meaning.toLowerCase().contains(keyword);
          final matchesMinimum =
              query.minStrokeCount == null ||
              entry.strokeCount >= query.minStrokeCount!;
          final matchesMaximum =
              query.maxStrokeCount == null ||
              entry.strokeCount <= query.maxStrokeCount!;
          return matchesLevel &&
              matchesKeyword &&
              matchesMinimum &&
              matchesMaximum;
        })
        .toList(growable: false);

    final page = query.page < 1 ? 1 : query.page;
    final pageSize = query.pageSize < 1 ? 20 : query.pageSize.clamp(1, 100);
    final start = (page - 1) * pageSize;
    final pageItems = start >= filtered.length
        ? const <KanjiEntry>[]
        : filtered.sublist(start, (start + pageSize).clamp(0, filtered.length));
    final totalPages = filtered.isEmpty
        ? 0
        : (filtered.length / pageSize).ceil();

    return KanjiPage(
      items: pageItems,
      page: page,
      pageSize: pageSize,
      totalCount: filtered.length,
      totalPages: totalPages,
      source: KanjiDataSource.fixture,
    );
  }

  @override
  Future<KanjiEntry> loadDetail(String routeKey) async {
    return entries.firstWhere(
      (entry) => entry.routeKey == routeKey,
      orElse: () => throw StateError('Unknown fixture kanji route key.'),
    );
  }

  static const List<KanjiEntry> entries = <KanjiEntry>[
    KanjiEntry(
      routeKey: kenRouteKey,
      remoteId: null,
      character: '験',
      meaning: 'Kiểm nghiệm, thử thách, kinh nghiệm',
      onYomi: 'ケン・ゲン',
      kunYomi: 'あかし・ためす',
      sinoVietnamese: 'NGHIỆM',
      strokeCount: 18,
      level: JlptLevel.n3,
      source: KanjiDataSource.fixture,
      isSaved: false,
      enrichment: KanjiEnrichment(
        radical: '馬 (Mã)',
        mnemonic: 'Con ngựa 馬 vượt qua bài kiểm tra để chứng minh kinh nghiệm.',
        compounds: <KanjiCompound>[
          KanjiCompound(word: '経験', reading: 'けいけん', meaning: 'Kinh nghiệm'),
          KanjiCompound(
            word: '試験',
            reading: 'しけん',
            meaning: 'Kỳ thi, kiểm tra',
          ),
        ],
        example: KanjiExample(
          sentence: '日本で働いた経験があります。',
          translation: 'Tôi có kinh nghiệm từng làm việc tại Nhật Bản.',
        ),
        strokeSteps: <KanjiStrokeStep>[
          KanjiStrokeStep(number: 1, preview: '丨'),
          KanjiStrokeStep(number: 2, preview: '冂'),
          KanjiStrokeStep(number: 3, preview: '日'),
          KanjiStrokeStep(number: 4, preview: '目'),
          KanjiStrokeStep(number: 5, preview: '目丨'),
          KanjiStrokeStep(number: 6, preview: '馬'),
          KanjiStrokeStep(number: 7, preview: '馬'),
          KanjiStrokeStep(number: 8, preview: '馬'),
          KanjiStrokeStep(number: 9, preview: '馬'),
          KanjiStrokeStep(number: 10, preview: '馬'),
          KanjiStrokeStep(number: 11, preview: '馬人'),
          KanjiStrokeStep(number: 12, preview: '験'),
          KanjiStrokeStep(number: 13, preview: '験'),
          KanjiStrokeStep(number: 14, preview: '験'),
          KanjiStrokeStep(number: 15, preview: '験'),
          KanjiStrokeStep(number: 16, preview: '験'),
          KanjiStrokeStep(number: 17, preview: '験'),
          KanjiStrokeStep(number: 18, preview: '験'),
        ],
        strokeRules: <String>[
          'Viết từ trên xuống dưới, từ trái qua phải.',
          'Hoàn thành bộ 馬 bên trái trước phần bên phải.',
          'Nét ngang được viết trước nét sổ xuyên qua.',
        ],
      ),
    ),
    KanjiEntry(
      routeKey: 'fixture-kei',
      remoteId: null,
      character: '経',
      meaning: 'Trải qua, kinh tuyến, quản lý',
      onYomi: 'ケイ・キョウ',
      kunYomi: 'へる・たつ',
      sinoVietnamese: 'KINH',
      strokeCount: 11,
      level: JlptLevel.n3,
      source: KanjiDataSource.fixture,
      isSaved: false,
    ),
    KanjiEntry(
      routeKey: 'fixture-kai',
      remoteId: null,
      character: '会',
      meaning: 'Gặp gỡ, hội họp',
      onYomi: 'カイ・エ',
      kunYomi: 'あう',
      sinoVietnamese: 'HỘI',
      strokeCount: 6,
      level: JlptLevel.n4,
      source: KanjiDataSource.fixture,
      isSaved: false,
    ),
    KanjiEntry(
      routeKey: 'fixture-shoku',
      remoteId: null,
      character: '食',
      meaning: 'Ăn, thức ăn',
      onYomi: 'ショク・ジキ',
      kunYomi: 'たべる・くう',
      sinoVietnamese: 'THỰC',
      strokeCount: 9,
      level: JlptLevel.n5,
      source: KanjiDataSource.fixture,
      isSaved: false,
    ),
    KanjiEntry(
      routeKey: 'fixture-gaku',
      remoteId: null,
      character: '学',
      meaning: 'Học tập, học vấn',
      onYomi: 'ガク',
      kunYomi: 'まなぶ',
      sinoVietnamese: 'HỌC',
      strokeCount: 8,
      level: JlptLevel.n5,
      source: KanjiDataSource.fixture,
      isSaved: false,
    ),
    KanjiEntry(
      routeKey: 'fixture-nichi',
      remoteId: null,
      character: '日',
      meaning: 'Ngày, mặt trời',
      onYomi: 'ニチ・ジツ',
      kunYomi: 'ひ・か',
      sinoVietnamese: 'NHẬT',
      strokeCount: 4,
      level: JlptLevel.n5,
      source: KanjiDataSource.fixture,
      isSaved: false,
    ),
  ];
}
