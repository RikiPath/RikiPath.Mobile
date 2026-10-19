import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar_repository.dart';

/// Typed, isolated visual-development data for the approved C13 Stitch UI.
///
/// Fixture keys and enrichment are never sent to or represented as backend IDs.
class FixtureGrammarRepository implements GrammarRepository {
  const FixtureGrammarRepository();

  static const String tariRouteKey = 'fixture-tari-tari';

  @override
  Future<GrammarPage> search(GrammarQuery query) async {
    final keyword = query.keyword.trim().toLowerCase();
    final filtered = entries
        .where((entry) {
          final matchesLevel =
              query.level == null || entry.level == query.level!.level;
          final matchesKeyword =
              keyword.isEmpty ||
              entry.title.toLowerCase().contains(keyword) ||
              entry.structure.toLowerCase().contains(keyword) ||
              (entry.explanation?.toLowerCase().contains(keyword) ?? false);
          return matchesLevel && matchesKeyword;
        })
        .toList(growable: false);

    final page = query.page < 1 ? 1 : query.page;
    final pageSize = query.pageSize < 1 ? 20 : query.pageSize.clamp(1, 100);
    final start = (page - 1) * pageSize;
    final pageItems = start >= filtered.length
        ? const <GrammarEntry>[]
        : filtered.sublist(start, (start + pageSize).clamp(0, filtered.length));

    return GrammarPage(
      items: pageItems,
      page: page,
      pageSize: pageSize,
      totalCount: filtered.length,
      totalPages: filtered.isEmpty ? 0 : (filtered.length / pageSize).ceil(),
      source: GrammarDataSource.fixture,
    );
  }

  @override
  Future<GrammarEntry> loadDetail(String routeKey) async {
    return entries.firstWhere(
      (entry) => entry.routeKey == routeKey,
      orElse: () => throw StateError('Unknown fixture grammar route key.'),
    );
  }

  static const List<GrammarEntry> entries = <GrammarEntry>[
    GrammarEntry(
      routeKey: tariRouteKey,
      remoteId: null,
      title: '～たり～たりする',
      structure: 'V(た) + り、V(た) + りする',
      explanation: 'Liệt kê một số hành động hoặc trạng thái tiêu biểu.',
      exampleSentence: '週末は映画を見たり、本を読んだりします。',
      level: JlptLevel.n4,
      source: GrammarDataSource.fixture,
      enrichment: GrammarEnrichment(
        examples: <GrammarExample>[
          GrammarExample(
            sentence: '週末は映画を見たり、本を読んだりします。',
            translation:
                'Cuối tuần tôi thường xem phim, đọc sách và làm những việc tương tự.',
          ),
          GrammarExample(
            sentence: '昨日は雨が降ったり、やんだりしていました。',
            translation: 'Hôm qua trời lúc mưa lúc tạnh.',
          ),
        ],
        usageNotes: <String>[
          'Động từ chia ở thể quá khứ (thể た) rồi gắn với り.',
          'Thì của cả câu được quyết định bởi động từ する ở cuối câu.',
        ],
        cautions: <String>[
          'Không dùng để diễn tả chuỗi hành động bắt buộc theo đúng thứ tự.',
          'Thông thường liệt kê từ hai hành động tiêu biểu.',
        ],
        related: <RelatedGrammar>[
          RelatedGrammar(
            routeKey: 'fixture-shi-shi',
            title: '～し～し',
            summary: 'Liệt kê nhiều lý do hoặc đặc điểm.',
            level: JlptLevel.n4,
          ),
          RelatedGrammar(
            routeKey: 'fixture-nagara',
            title: '～ながら',
            summary: 'Hai hành động diễn ra đồng thời.',
            level: JlptLevel.n4,
          ),
        ],
      ),
    ),
    GrammarEntry(
      routeKey: 'fixture-wake-dewa-nai',
      remoteId: null,
      title: '～わけではない',
      structure: '[V/A/Na/N] thể thông thường + わけではない',
      explanation: 'Không hẳn là; không có nghĩa là.',
      exampleSentence: '嫌いなわけではない。',
      level: JlptLevel.n3,
      source: GrammarDataSource.fixture,
    ),
    GrammarEntry(
      routeKey: 'fixture-koto-ni-naru',
      remoteId: null,
      title: '～ことになる',
      structure: 'Vる / Vない + ことになる',
      explanation: 'Được quyết định là; trở thành quy định.',
      exampleSentence: '来月、日本へ行くことになりました。',
      level: JlptLevel.n3,
      source: GrammarDataSource.fixture,
    ),
    GrammarEntry(
      routeKey: 'fixture-shi-shi',
      remoteId: null,
      title: '～し～し',
      structure: '[Thể thông thường] + し、～し',
      explanation: 'Vừa… lại vừa…; liệt kê lý do hoặc đặc điểm.',
      exampleSentence: 'この店は安いし、美味しいし、便利です。',
      level: JlptLevel.n4,
      source: GrammarDataSource.fixture,
    ),
    GrammarEntry(
      routeKey: 'fixture-nagara',
      remoteId: null,
      title: '～ながら',
      structure: 'V (bỏ ます) + ながら',
      explanation: 'Vừa làm A vừa làm B; hai hành động đồng thời.',
      exampleSentence: '音楽を聞きながら、勉強します。',
      level: JlptLevel.n4,
      source: GrammarDataSource.fixture,
    ),
    GrammarEntry(
      routeKey: 'fixture-te-mo-ii',
      remoteId: null,
      title: '～てもいい',
      structure: 'Vて + もいい',
      explanation: 'Được phép làm một việc.',
      exampleSentence: 'ここで写真を撮ってもいいです。',
      level: JlptLevel.n5,
      source: GrammarDataSource.fixture,
    ),
    GrammarEntry(
      routeKey: 'fixture-te-wa-ikenai',
      remoteId: null,
      title: '～てはいけない',
      structure: 'Vて + はいけない',
      explanation: 'Không được phép làm một việc.',
      exampleSentence: 'ここで泳いではいけません。',
      level: JlptLevel.n5,
      source: GrammarDataSource.fixture,
    ),
  ];
}
