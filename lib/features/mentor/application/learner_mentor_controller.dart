import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_repository.dart';

final learnerMentorRepositoryProvider = Provider<LearnerMentorRepository>(
  (ref) => ApiLearnerMentorRepository(ref.watch(apiClientProvider)),
);

final learnerMentorListControllerProvider =
    AsyncNotifierProvider<LearnerMentorListController, List<BookableMentor>>(
      LearnerMentorListController.new,
      retry: (_, _) => null,
    );

final learnerMentorPublicProfileProvider = FutureProvider.autoDispose
    .family<BookableMentor?, int>((ref, mentorId) async {
      return ref
          .watch(learnerMentorRepositoryProvider)
          .loadPublicProfile(mentorId);
    });

class LearnerMentorListController extends AsyncNotifier<List<BookableMentor>> {
  @override
  Future<List<BookableMentor>> build() {
    return ref.watch(learnerMentorRepositoryProvider).loadMentors();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<BookableMentor>>();
    state = await AsyncValue.guard(build);
  }
}
