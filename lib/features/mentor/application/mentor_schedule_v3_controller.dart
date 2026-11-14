import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_schedule_v3_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_schedule_v3.dart';

final mentorScheduleV3RepositoryProvider = Provider<MentorScheduleV3Repository>(
  (ref) => ApiMentorScheduleV3Repository(ref.watch(apiClientProvider)),
);

final mentorScheduleV3ControllerProvider =
    AsyncNotifierProvider.autoDispose<
      MentorScheduleV3Controller,
      MentorScheduleV3
    >(MentorScheduleV3Controller.new);

class MentorScheduleV3Controller extends AsyncNotifier<MentorScheduleV3> {
  @override
  Future<MentorScheduleV3> build() async {
    ref.watch(authenticatedUserIdProvider);
    return ref.watch(mentorScheduleV3RepositoryProvider).loadSchedule();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<MentorScheduleV3> updateSchedule(
    UpdateMentorScheduleV3Request request,
  ) async {
    final updated = await ref
        .read(mentorScheduleV3RepositoryProvider)
        .updateSchedule(request);
    state = AsyncData(updated);
    return updated;
  }

  Future<MentorSlotPreviewResult> previewSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return ref
        .read(mentorScheduleV3RepositoryProvider)
        .previewSlots(startDate: startDate, endDate: endDate);
  }

  Future<MentorPublishSlotsResult> publishSlots({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await ref
        .read(mentorScheduleV3RepositoryProvider)
        .publishSlots(startDate: startDate, endDate: endDate);
    ref.invalidateSelf();
    ref.invalidate(mentorAvailabilityControllerProvider);
    return result;
  }

  Future<void> disableSlot(int slotId, {String? reason}) async {
    await ref
        .read(mentorScheduleV3RepositoryProvider)
        .disableSlot(slotId, reason: reason);
    ref.invalidate(mentorAvailabilityControllerProvider);
  }

  Future<void> deleteAvailability(int availabilityId) async {
    await ref
        .read(mentorScheduleV3RepositoryProvider)
        .deleteAvailability(availabilityId);
    ref.invalidate(mentorAvailabilityControllerProvider);
  }

  Future<void> requestCancelAvailabilities(
    List<int> ids, {
    String? reason,
  }) async {
    await ref
        .read(mentorScheduleV3RepositoryProvider)
        .requestCancelAvailabilities(ids, reason: reason);
    ref.invalidate(mentorAvailabilityControllerProvider);
  }

  Future<void> requestSlotChange(int slotId, String reason) async {
    await ref
        .read(mentorScheduleV3RepositoryProvider)
        .requestSlotChange(slotId, reason);
    ref.invalidate(mentorAvailabilityControllerProvider);
  }
}
