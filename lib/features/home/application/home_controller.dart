import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/home/data/profile_home_repository.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/home/domain/home_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => ProfileHomeRepository(
    ref.watch(userProfileRepositoryProvider).loadProfile,
  ),
);

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeDashboard>(HomeController.new);

class HomeController extends AsyncNotifier<HomeDashboard> {
  @override
  Future<HomeDashboard> build() {
    // A new learner can sign in without restarting the app. Drop the previous
    // learner's cached greeting as soon as the authenticated identity changes.
    ref.watch(authenticatedUserIdProvider);
    return ref.watch(homeRepositoryProvider).loadDashboard();
  }

  Future<void> retry() async {
    state = const AsyncLoading<HomeDashboard>();
    state = await AsyncValue.guard(
      ref.read(homeRepositoryProvider).loadDashboard,
    );
  }
}
