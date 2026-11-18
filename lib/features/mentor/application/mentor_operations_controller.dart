import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_operations_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';

final mentorOperationsRepositoryProvider = Provider<MentorOperationsRepository>(
  (ref) => ApiMentorOperationsRepository(ref.watch(apiClientProvider)),
);

/// Room readiness / access check (`GET /api/mentor-meetings/rooms/{roomId}/access`).
final mentorRoomAccessProvider =
    FutureProvider.autoDispose.family<MentorRoomAccessStatus, String>((
      ref,
      roomId,
    ) {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(mentorOperationsRepositoryProvider).checkRoomAccess(
            roomId,
          );
    }, retry: (_, _) => null);
