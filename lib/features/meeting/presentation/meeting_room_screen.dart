import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_controller.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_pip_controller.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_realtime_client.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_connection_state.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_message.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_pip_policy.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';
import 'package:rikipath_mobile/features/meeting/presentation/widgets/meeting_pip_compact_view.dart';
import 'package:rikipath_mobile/features/meeting/presentation/widgets/meeting_video_tile.dart';

class MeetingRoomScreen extends ConsumerStatefulWidget {
  const MeetingRoomScreen({required this.room, super.key});

  final MeetingRoomReference room;

  @override
  ConsumerState<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends ConsumerState<MeetingRoomScreen>
    with WidgetsBindingObserver {
  late final MeetingPipController _pipController;
  StreamSubscription<void>? _pipDismissalSubscription;
  bool _allowPop = false;
  bool _hasExplicitlyLeft = false;
  bool _isLeaving = false;
  bool _meetingPausedByLifecycle = false;
  bool? _lastPipEligibility;
  bool _isAuxiliarySheetOpen = false;
  bool _isAuxiliarySheetDismissScheduled = false;
  int _backgroundTransition = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pipController = ref.read(meetingPipControllerProvider);
    _pipDismissalSubscription = _pipController.dismissals.listen((_) {
      unawaited(_handlePipDismissed());
    });
    unawaited(_pipController.initialize());
  }

  @override
  void dispose() {
    _backgroundTransition += 1;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_pipDismissalSubscription?.cancel());
    unawaited(_pipController.setEligible(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(meetingControllerProvider(widget.room));
    switch (state) {
      case AppLifecycleState.resumed:
        _backgroundTransition += 1;
        unawaited(_handleResumed(controller));
      case AppLifecycleState.inactive:
        // Transient system UI (including permission dialogs) must not alter
        // the active media state.
        return;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(_handleBackgrounded(controller));
      case AppLifecycleState.detached:
        _hasExplicitlyLeft = true;
        unawaited(_pipController.setEligible(false));
        unawaited(controller.leave());
    }
  }

  Future<void> _handleBackgrounded(MeetingController controller) async {
    final transition = ++_backgroundTransition;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || transition != _backgroundTransition) return;
    await _pipController.refreshMode();
    if (!mounted || transition != _backgroundTransition) return;
    if (_pipController.state.isInPip) return;
    _meetingPausedByLifecycle = true;
    await controller.pause();
  }

  Future<void> _handleResumed(MeetingController controller) async {
    final transition = _backgroundTransition;
    await _pipController.refreshMode();
    if (!mounted || transition != _backgroundTransition) return;
    if (!_meetingPausedByLifecycle) return;
    _meetingPausedByLifecycle = false;
    await controller.resume();
  }

  Future<void> _handlePipDismissed() async {
    if (_hasExplicitlyLeft || _isLeaving) return;
    await _leaveAndClose();
  }

  Future<void> _leaveAndClose() async {
    if (_isLeaving) return;
    _isLeaving = true;
    _hasExplicitlyLeft = true;
    _lastPipEligibility = false;
    await _pipController.setEligible(false);
    await ref.read(meetingControllerProvider(widget.room)).leave();
    if (!mounted) return;
    setState(() => _allowPop = true);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _requestLeave() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B2930),
        title: Text(
          context.l10n.meetingNativeLeaveTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          context.l10n.meetingNativeLeaveDescription,
          style: const TextStyle(color: Color(0xFFD5D1D7)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const Key('meeting_stay_button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D282A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.pop(false),
                    child: Text(context.l10n.meetingNativeStay),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const Key('meeting_confirm_leave_button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD93C4B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.pop(true),
                    child: Text(context.l10n.meetingNativeLeave),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (shouldLeave != true || !mounted) return;
    await _leaveAndClose();
  }

  Future<void> _openBrowserFallback() async {
    final controller = ref.read(meetingControllerProvider(widget.room));
    final opened = await controller.openBrowserFallback();
    if (!opened || !mounted) return;
    await _leaveAndClose();
  }

  Future<void> _enterPip() async {
    await _pipController.enter();
  }

  void _syncPipEligibility(bool eligible) {
    if (_lastPipEligibility == eligible) return;
    _lastPipEligibility = eligible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_pipController.setEligible(eligible));
    });
  }

  void _dismissAuxiliarySheetForPip(bool isInPip) {
    if (!isInPip ||
        !_isAuxiliarySheetOpen ||
        _isAuxiliarySheetDismissScheduled) {
      return;
    }
    _isAuxiliarySheetDismissScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (mounted && _isAuxiliarySheetOpen) {
          await Navigator.of(context).maybePop();
        }
      } finally {
        _isAuxiliarySheetDismissScheduled = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(meetingControllerProvider(widget.room));
    final pipController = ref.watch(meetingPipControllerProvider);
    final state = controller.state;
    final pipState = pipController.state;
    final isPipEligible = MeetingPipPolicy.isEligible(
      status: state.status,
      hasExplicitlyLeft: _hasExplicitlyLeft,
    );
    _syncPipEligibility(isPipEligible);
    _dismissAuxiliarySheetForPip(pipState.isInPip);
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestLeave());
      },
      child: Scaffold(
        key: const Key('native_meeting_room_screen'),
        backgroundColor: const Color(0xFF17161B),
        body: pipState.isInPip
            ? MeetingPipCompactView(
                snapshot: state,
                remoteStreamFor: controller.media.remoteStreamFor,
              )
            : SafeArea(
                child: Column(
                  children: [
                    _MeetingHeader(
                      participantCount:
                          state.participants.length +
                          (state.self == null ? 0 : 1),
                      canEnterPip:
                          pipState.isSupported && isPipEligible && !_isLeaving,
                      onEnterPip: _enterPip,
                      onLeave: _requestLeave,
                    ),
                    if (state.mediaWarning != null)
                      _MediaWarning(code: state.mediaWarning!),
                    Expanded(
                      child: _MeetingStage(
                        controller: controller,
                        snapshot: state,
                        onOpenWeb: _openBrowserFallback,
                      ),
                    ),
                    _MeetingControls(
                      snapshot: state,
                      onMic: controller.toggleMicrophone,
                      onCamera: controller.toggleCamera,
                      onRaiseHand: controller.toggleRaiseHand,
                      onChat: () => _showChat(context),
                      onParticipants: () => _showParticipants(context),
                      onLeave: _requestLeave,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showChat(BuildContext context) {
    _isAuxiliarySheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF242229),
      showDragHandle: true,
      builder: (_) => _ChatSheet(room: widget.room),
    ).whenComplete(() => _isAuxiliarySheetOpen = false);
  }

  void _showParticipants(BuildContext context) {
    _isAuxiliarySheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF242229),
      showDragHandle: true,
      builder: (_) => _ParticipantsSheet(room: widget.room),
    ).whenComplete(() => _isAuxiliarySheetOpen = false);
  }
}

enum _MeetingHeaderAction { enterPip }

class _MeetingHeader extends StatelessWidget {
  const _MeetingHeader({
    required this.participantCount,
    required this.canEnterPip,
    required this.onEnterPip,
    required this.onLeave,
  });

  final int participantCount;
  final bool canEnterPip;
  final Future<void> Function() onEnterPip;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      child: Row(
        children: [
          const Icon(Icons.videocam_rounded, color: Color(0xFFE05A7A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.meetingTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.meetingNativeParticipantsCount(participantCount),
                  style: const TextStyle(
                    color: Color(0xFFAAA5AE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (canEnterPip)
            PopupMenuButton<_MeetingHeaderAction>(
              key: const Key('meeting_more_actions_button'),
              tooltip: context.l10n.meetingNativeMoreActions,
              color: const Color(0xFF2B2930),
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (action) {
                if (action == _MeetingHeaderAction.enterPip) {
                  unawaited(onEnterPip());
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<_MeetingHeaderAction>(
                  key: const Key('meeting_enter_pip_action'),
                  value: _MeetingHeaderAction.enterPip,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.picture_in_picture_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.meetingNativeMinimize,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            tooltip: context.l10n.meetingNativeLeave,
            onPressed: onLeave,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MeetingStage extends StatelessWidget {
  const _MeetingStage({
    required this.controller,
    required this.snapshot,
    required this.onOpenWeb,
  });

  final MeetingController controller;
  final MeetingRealtimeSnapshot snapshot;
  final Future<void> Function() onOpenWeb;

  @override
  Widget build(BuildContext context) {
    if (snapshot.status == MeetingConnectionStatus.failed) {
      return _ConnectionFailure(
        errorCode: snapshot.error,
        hasWebFallback: controller.room.webUri != null,
        onRetry: controller.retry,
        onOpenWeb: onOpenWeb,
      );
    }

    final participants = snapshot.participants;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: participants.isEmpty
              ? _WaitingParticipant(
                  isConnected:
                      snapshot.status == MeetingConnectionStatus.connected,
                )
              : GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: participants.length == 1 ? 1 : 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: participants.length == 1 ? 0.78 : 0.72,
                  ),
                  itemCount: participants.length.clamp(0, 4),
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    return MeetingVideoTile(
                      key: ValueKey('remote-${participant.connectionId}'),
                      stream: controller.media.remoteStreamFor(
                        participant.connectionId,
                      ),
                      name: participant.name,
                      initials: participant.initials,
                      isCameraOn: participant.isCameraOn,
                      isMicOn: participant.isMicOn,
                      isHandRaised: participant.isHandRaised,
                    );
                  },
                ),
        ),
        Positioned(
          top: 16,
          right: 24,
          width: 104,
          height: 142,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 12),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MeetingVideoTile(
                  stream: controller.media.localStream,
                  name: context.l10n.meetingNativeYou,
                  initials: snapshot.self?.initials ?? 'RP',
                  isCameraOn: snapshot.isCameraOn,
                  isMicOn: snapshot.isMicOn,
                  isLocal: true,
                  isHandRaised: snapshot.isHandRaised,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: context.l10n.meetingNativeSwitchCamera,
                      onPressed: snapshot.isCameraOn
                          ? controller.switchCamera
                          : null,
                      iconSize: 18,
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (snapshot.status != MeetingConnectionStatus.connected)
          _ConnectionOverlay(status: snapshot.status),
      ],
    );
  }
}

class _WaitingParticipant extends StatelessWidget {
  const _WaitingParticipant({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF222127),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_2_outlined,
              color: Colors.white38,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              isConnected
                  ? context.l10n.meetingNativeNoParticipants
                  : context.l10n.meetingNativeConnecting,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD5D1D7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionOverlay extends StatelessWidget {
  const _ConnectionOverlay({required this.status});

  final MeetingConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      MeetingConnectionStatus.joining => context.l10n.meetingNativeJoining,
      MeetingConnectionStatus.reconnecting =>
        context.l10n.meetingNativeReconnecting,
      _ => context.l10n.meetingNativeConnecting,
    };
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black45,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2930),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE05A7A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionFailure extends StatelessWidget {
  const _ConnectionFailure({
    required this.errorCode,
    required this.hasWebFallback,
    required this.onRetry,
    required this.onOpenWeb,
  });

  final String? errorCode;
  final bool hasWebFallback;
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenWeb;

  @override
  Widget build(BuildContext context) {
    final description = switch (errorCode) {
      'authRequired' => context.l10n.meetingErrorAuthRequired,
      'notAuthorized' => context.l10n.meetingErrorNotAuthorized,
      'roomNotFound' => context.l10n.meetingErrorRoomNotFound,
      'networkError' => context.l10n.meetingErrorNetwork,
      _ => context.l10n.meetingNativeFailedDescription,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFFF8A9F),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.meetingNativeFailedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFBEB9C2), height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('meeting_retry_button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.meetingNativeRetry),
            ),
            if (hasWebFallback)
              TextButton.icon(
                key: const Key('meeting_web_fallback_button'),
                onPressed: onOpenWeb,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(context.l10n.meetingNativeOpenWeb),
              ),
          ],
        ),
      ),
    );
  }
}

class _MeetingControls extends StatelessWidget {
  const _MeetingControls({
    required this.snapshot,
    required this.onMic,
    required this.onCamera,
    required this.onRaiseHand,
    required this.onChat,
    required this.onParticipants,
    required this.onLeave,
  });

  final MeetingRealtimeSnapshot snapshot;
  final Future<void> Function() onMic;
  final Future<void> Function() onCamera;
  final Future<void> Function() onRaiseHand;
  final VoidCallback onChat;
  final VoidCallback onParticipants;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF211F25),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _ControlButton(
            key: const Key('meeting_microphone_control'),
            icon: snapshot.isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: context.l10n.meetingNativeMicrophone,
            isEmphasized: !snapshot.isMicOn,
            onPressed: onMic,
          ),
          _ControlButton(
            key: const Key('meeting_camera_control'),
            icon: snapshot.isCameraOn
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: context.l10n.meetingNativeCamera,
            isEmphasized: !snapshot.isCameraOn,
            onPressed: onCamera,
          ),
          _ControlButton(
            icon: Icons.back_hand_rounded,
            label: snapshot.isHandRaised
                ? context.l10n.meetingNativeLowerHand
                : context.l10n.meetingNativeRaiseHand,
            isEmphasized: snapshot.isHandRaised,
            emphasisColor: const Color(0xFFF6C453),
            onPressed: onRaiseHand,
          ),
          _ControlButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: context.l10n.meetingNativeChat,
            onPressed: onChat,
          ),
          _ControlButton(
            icon: Icons.people_outline_rounded,
            label: context.l10n.meetingNativeParticipants,
            onPressed: onParticipants,
          ),
          _ControlButton(
            key: const Key('meeting_leave_control'),
            icon: Icons.call_end_rounded,
            label: context.l10n.meetingNativeLeave,
            backgroundColor: const Color(0xFFD93C4B),
            onPressed: onLeave,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isEmphasized = false,
    this.emphasisColor = const Color(0xFFE05A7A),
    this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isEmphasized;
  final Color emphasisColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color =
        backgroundColor ??
        (isEmphasized
            ? emphasisColor.withValues(alpha: 0.24)
            : const Color(0xFF38353D));
    return SizedBox(
      width: 66,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  color: isEmphasized && backgroundColor == null
                      ? emphasisColor
                      : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC9C4CC), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MediaWarning extends StatelessWidget {
  const _MediaWarning({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final message = switch (code) {
      'cameraDenied' ||
      'cameraUnavailable' => context.l10n.meetingNativeCameraDenied,
      'microphoneDenied' => context.l10n.meetingNativeMicrophoneDenied,
      'permissionPermanentlyDenied' ||
      'cameraAndMicrophoneDenied' => context.l10n.meetingNativePermissionDenied,
      _ => context.l10n.meetingNativeMediaUnavailable,
    };
    return Container(
      width: double.infinity,
      color: const Color(0xFF4A391D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF6C453),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFFE4AA), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsSheet extends ConsumerWidget {
  const _ParticipantsSheet({required this.room});

  final MeetingRoomReference room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meetingControllerProvider(room)).state;
    final entries = <MeetingParticipant>[
      if (state.self != null) state.self!,
      ...state.participants,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.meetingNativeParticipants,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final participant = entries[index];
                  final isSelf = index == 0 && state.self != null;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4C4757),
                      child: Text(
                        participant.initials,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      isSelf
                          ? '${participant.name} (${context.l10n.meetingNativeYou})'
                          : participant.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      participant.role == MeetingParticipantRole.mentor
                          ? context.l10n.meetingNativeMentor
                          : context.l10n.meetingNativeLearner,
                      style: const TextStyle(color: Color(0xFFAAA5AE)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (participant.isHandRaised)
                          const Icon(
                            Icons.back_hand_rounded,
                            color: Color(0xFFF6C453),
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          participant.isMicOn
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          color: participant.isMicOn
                              ? Colors.white70
                              : const Color(0xFFFF8A9F),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          participant.isCameraOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          color: participant.isCameraOn
                              ? Colors.white70
                              : const Color(0xFFFF8A9F),
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSheet extends ConsumerStatefulWidget {
  const _ChatSheet({required this.room});

  final MeetingRoomReference room;

  @override
  ConsumerState<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<_ChatSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref
        .read(meetingControllerProvider(widget.room))
        .sendChatMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref
        .watch(meetingControllerProvider(widget.room))
        .state
        .messages;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.meetingNativeChat,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.meetingNativeChatEmpty,
                        style: const TextStyle(color: Color(0xFFAAA5AE)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          _MessageBubble(message: messages[index]),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 2000,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: context.l10n.meetingNativeChatHint,
                      hintStyle: const TextStyle(color: Color(0xFF918B95)),
                      filled: true,
                      fillColor: const Color(0xFF343139),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: context.l10n.meetingNativeSend,
                  onPressed: _send,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE05A7A),
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final MeetingMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isSelf
              ? const Color(0xFFE05A7A)
              : const Color(0xFF39363E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${message.sender} · ${message.timestamp}',
              style: TextStyle(
                color: message.isSelf
                    ? Colors.white70
                    : const Color(0xFFBEB9C2),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            Text(message.text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
