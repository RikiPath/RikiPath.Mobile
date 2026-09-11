import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/home/data/fixture_home_repository.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/home/domain/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const FixtureHomeRepository(),
);

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeDashboard>(HomeController.new);

class HomeController extends AsyncNotifier<HomeDashboard> {
  @override
  Future<HomeDashboard> build() {
    return ref.watch(homeRepositoryProvider).loadDashboard();
  }

  Future<void> retry() async {
    state = const AsyncLoading<HomeDashboard>();
    state = await AsyncValue.guard(
      ref.read(homeRepositoryProvider).loadDashboard,
    );
  }
}
