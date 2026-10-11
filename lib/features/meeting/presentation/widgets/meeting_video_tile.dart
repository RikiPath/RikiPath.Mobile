import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MeetingVideoTile extends StatefulWidget {
  const MeetingVideoTile({
    required this.stream,
    required this.name,
    required this.initials,
    required this.isCameraOn,
    required this.isMicOn,
    this.isLocal = false,
    this.isHandRaised = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    super.key,
  });

  final MediaStream? stream;
  final String name;
  final String initials;
  final bool isCameraOn;
  final bool isMicOn;
  final bool isLocal;
  final bool isHandRaised;
  final BorderRadius borderRadius;

  @override
  State<MeetingVideoTile> createState() => _MeetingVideoTileState();
}

class _MeetingVideoTileState extends State<MeetingVideoTile> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _renderer.initialize();
    if (!mounted) {
      await _renderer.dispose();
      return;
    }
    _renderer.srcObject = widget.stream;
    setState(() => _initialized = true);
  }

  @override
  void didUpdateWidget(covariant MeetingVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream && _initialized) {
      _renderer.srcObject = widget.stream;
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _renderer.srcObject = null;
      unawaited(_renderer.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showVideo =
        _initialized &&
        widget.stream != null &&
        widget.isCameraOn &&
        widget.stream!.getVideoTracks().isNotEmpty;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: ColoredBox(
        color: const Color(0xFF25242A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_initialized && widget.stream != null)
              Opacity(
                opacity: showVideo ? 1 : 0,
                child: RTCVideoView(
                  _renderer,
                  mirror: widget.isLocal,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            if (!showVideo)
              Center(
                child: CircleAvatar(
                  radius: widget.isLocal ? 26 : 42,
                  backgroundColor: const Color(0xFF4C4757),
                  child: Text(
                    widget.initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: widget.isLocal ? 16 : 24,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                      ),
                    ),
                  ),
                  if (widget.isHandRaised) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.back_hand_rounded,
                      color: Color(0xFFF6C453),
                      size: 17,
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    widget.isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: widget.isMicOn
                        ? Colors.white
                        : const Color(0xFFFF8A9F),
                    size: 17,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
