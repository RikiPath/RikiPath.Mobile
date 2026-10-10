import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_join_target.dart';

final meetingJoinIntentControllerProvider =
    NotifierProvider<MeetingJoinIntentController, MeetingJoinIntentState>(
      MeetingJoinIntentController.new,
    );

@immutable
class MeetingJoinIntentState {
  const MeetingJoinIntentState({
    this.rawLink = '',
    this.target,
    this.validationError,
  });

  final String rawLink;
  final MeetingJoinTarget? target;
  final MeetingLinkValidationError? validationError;

  bool get hasPendingTarget => target != null;
}

class MeetingJoinIntentController extends Notifier<MeetingJoinIntentState> {
  @override
  MeetingJoinIntentState build() {
    ref.keepAlive();
    final session = ref.read(authSessionControllerProvider);
    var hadAuthenticatedSession =
        session.value == AuthSessionState.authenticated;

    void handleSessionChange() {
      if (session.value == AuthSessionState.authenticated) {
        hadAuthenticatedSession = true;
      } else if (session.value == AuthSessionState.unauthenticated &&
          hadAuthenticatedSession) {
        hadAuthenticatedSession = false;
        state = const MeetingJoinIntentState();
      }
    }

    session.addListener(handleSessionChange);
    ref.onDispose(() => session.removeListener(handleSessionChange));
    return const MeetingJoinIntentState();
  }

  void updateRawLink(String value) {
    state = MeetingJoinIntentState(rawLink: value);
  }

  bool submit(String value) {
    final result = MeetingJoinTarget.parse(value);
    state = MeetingJoinIntentState(
      rawLink: value.trim(),
      target: result.target,
      validationError: result.error,
    );
    return result.target != null;
  }

  void clearValidation() {
    if (state.validationError == null) return;
    state = MeetingJoinIntentState(rawLink: state.rawLink);
  }

  void clear() => state = const MeetingJoinIntentState();
}
