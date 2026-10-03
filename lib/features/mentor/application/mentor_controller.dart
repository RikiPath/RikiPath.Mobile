import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';

final mentorRepositoryProvider = Provider<MentorRepository>(
  (ref) => ApiMentorRepository(ref.watch(apiClientProvider)),
);

final mentorAvailabilityControllerProvider =
    AsyncNotifierProvider<
      MentorAvailabilityController,
      List<MentorAvailabilitySlot>
    >(MentorAvailabilityController.new, retry: (_, _) => null);

final mentorMeetingsControllerProvider =
    AsyncNotifierProvider<MentorMeetingsController, List<MentorMeetingSummary>>(
      MentorMeetingsController.new,
      retry: (_, _) => null,
    );

class MentorAvailabilityController
    extends AsyncNotifier<List<MentorAvailabilitySlot>> {
  @override
  Future<List<MentorAvailabilitySlot>> build() {
    return ref.watch(mentorRepositoryProvider).loadAvailability();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<MentorAvailabilitySlot>>();
    state = await AsyncValue.guard(build);
  }
}

class MentorMeetingsController
    extends AsyncNotifier<List<MentorMeetingSummary>> {
  @override
  Future<List<MentorMeetingSummary>> build() {
    return ref.watch(mentorRepositoryProvider).loadMeetings();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<MentorMeetingSummary>>();
    state = await AsyncValue.guard(build);
  }
}

Future<void> refreshMentorReadModels(WidgetRef ref) async {
  Future<void> settle(Future<Object?> request) async {
    try {
      await request;
    } catch (_) {
      // Each read model owns and renders its failure independently.
    }
  }

  await Future.wait(<Future<void>>[
    settle(ref.refresh(mentorAvailabilityControllerProvider.future)),
    settle(ref.refresh(mentorMeetingsControllerProvider.future)),
  ]);
}
