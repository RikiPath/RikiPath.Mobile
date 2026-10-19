import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/catalog/data/api_jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_catalog_repository.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

final jlptCatalogRepositoryProvider = Provider<JlptCatalogRepository>((ref) {
  return ApiJlptCatalogRepository(ref.watch(apiClientProvider));
});

final jlptCatalogControllerProvider =
    AsyncNotifierProvider<JlptCatalogController, List<JlptLevelCatalogItem>>(
      JlptCatalogController.new,
      retry: (_, _) => null,
    );

class JlptCatalogController extends AsyncNotifier<List<JlptLevelCatalogItem>> {
  @override
  Future<List<JlptLevelCatalogItem>> build() {
    return ref.watch(jlptCatalogRepositoryProvider).loadLevels();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<JlptLevelCatalogItem>>();
    state = await AsyncValue.guard(build);
  }
}
