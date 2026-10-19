import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/data/api_jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/data/jlpt_catalog_api_paths.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/catalog/presentation/jlpt_catalog_filter_chips.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  group('live JLPT catalog repository', () {
    test(
      'preserves Backend IDs, codes, metadata, and response order',
      () async {
        final client = _CatalogApiClient(
          _envelope(<Object?>[
            _levelJson(id: 71, code: 'N4', sortOrder: 2),
            _levelJson(id: 35, code: 'N5', sortOrder: 1, description: null),
          ]),
        );

        final levels = await ApiJlptCatalogRepository(client).loadLevels();

        expect(client.calls, <String>['GET ${JlptCatalogApiPaths.levels}']);
        expect(levels.map((item) => item.id), <int>[71, 35]);
        expect(levels.map((item) => item.code), <String>['N4', 'N5']);
        expect(levels.last.description, isNull);
        expect(levels.map((item) => item.sortOrder), <int>[2, 1]);
      },
    );

    test('maps the complete N5 through N1 catalog', () async {
      final client = _CatalogApiClient(
        _envelope(<Object?>[
          _levelJson(id: 1, code: 'N5', sortOrder: 1),
          _levelJson(id: 2, code: 'N4', sortOrder: 2),
          _levelJson(id: 3, code: 'N3', sortOrder: 3),
          _levelJson(id: 4, code: 'N2', sortOrder: 4),
          _levelJson(id: 5, code: 'N1', sortOrder: 5),
        ]),
      );

      final levels = await ApiJlptCatalogRepository(client).loadLevels();

      expect(levels.map((item) => item.level.label), <String>[
        'N5',
        'N4',
        'N3',
        'N2',
        'N1',
      ]);
    });

    test('keeps a successful empty catalog empty', () async {
      final levels = await ApiJlptCatalogRepository(
        _CatalogApiClient(_envelope(const <Object?>[])),
      ).loadLevels();

      expect(levels, isEmpty);
    });

    test('maps malformed catalog data to a controlled typed error', () async {
      await expectLater(
        ApiJlptCatalogRepository(
          _CatalogApiClient(
            _envelope(<Object?>[
              _levelJson(id: 1, code: 'UNKNOWN', sortOrder: 1),
            ]),
          ),
        ).loadLevels(),
        throwsA(isA<UnknownError>()),
      );
    });
  });

  test('controller exposes retry without a fixture fallback', () async {
    final repository = _RetryCatalogRepository();
    final container = ProviderContainer(
      overrides: [jlptCatalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(jlptCatalogControllerProvider.future),
      throwsA(isA<NetworkError>()),
    );
    await container.read(jlptCatalogControllerProvider.notifier).retry();

    final levels = container.read(jlptCatalogControllerProvider).requireValue;
    expect(repository.calls, 2);
    expect(levels.single.id, 84);
  });

  testWidgets('filter renders valid empty and retryable error states', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _TestApp(
        child: JlptCatalogFilterChips(
          catalog: const AsyncData(<JlptLevelCatalogItem>[]),
          selected: null,
          onSelected: (_) {},
          onRetry: () => retries++,
          keyPrefix: 'catalog_test',
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('catalog_test_empty')), findsOne);

    await tester.pumpWidget(
      _TestApp(
        child: JlptCatalogFilterChips(
          catalog: AsyncError<List<JlptLevelCatalogItem>>(
            const NetworkError(),
            StackTrace.empty,
          ),
          selected: null,
          onSelected: (_) {},
          onRetry: () => retries++,
          keyPrefix: 'catalog_test',
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('catalog_test_error')), findsOne);
    await tester.tap(find.text('Thử lại'));
    expect(retries, 1);
  });
}

Map<String, Object?> _envelope(List<Object?> levels) => <String, Object?>{
  'statusCode': 200,
  'isSuccess': true,
  'result': levels,
};

Map<String, Object?> _levelJson({
  required int id,
  required String code,
  required int sortOrder,
  String? description = 'JLPT level',
}) => <String, Object?>{
  'id': id,
  'code': code,
  'description': description,
  'sortOrder': sortOrder,
};

JlptLevelCatalogItem _level(int id, String code, int sortOrder) =>
    JlptLevelCatalogItem(
      id: id,
      code: code,
      level: switch (code) {
        'N5' => JlptLevel.n5,
        'N4' => JlptLevel.n4,
        'N3' => JlptLevel.n3,
        'N2' => JlptLevel.n2,
        'N1' => JlptLevel.n1,
        _ => throw ArgumentError.value(code),
      },
      sortOrder: sortOrder,
    );

class _CatalogApiClient extends ApiClient {
  _CatalogApiClient(this.body) : super(Dio(), const ApiErrorMapper());

  final Object? body;
  final List<String> calls = <String>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add('GET $path');
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: body as T,
    );
  }
}

class _RetryCatalogRepository implements JlptCatalogRepository {
  int calls = 0;

  @override
  Future<List<JlptLevelCatalogItem>> loadLevels() async {
    calls++;
    if (calls == 1) throw const NetworkError();
    return <JlptLevelCatalogItem>[_level(84, 'N4', 2)];
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
