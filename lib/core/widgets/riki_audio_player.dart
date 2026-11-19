import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Shared network audio player backed by `just_audio`, lazily loading on user
/// tap so unit/widget tests do not touch platform audio channels during build.
class RikiNetworkAudioPlayer extends StatefulWidget {
  const RikiNetworkAudioPlayer({
    required this.audioUrl,
    this.title = 'Nghe đoạn hội thoại JLPT',
    super.key,
  });

  final String audioUrl;
  final String title;

  @override
  State<RikiNetworkAudioPlayer> createState() => _RikiNetworkAudioPlayerState();
}

class _RikiNetworkAudioPlayerState extends State<RikiNetworkAudioPlayer> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  bool _loading = false;
  bool _playing = false;
  bool _loaded = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void didUpdateWidget(covariant RikiNetworkAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      unawaited(_resetPlayer());
    }
  }

  Future<void> _resetPlayer() async {
    await _stateSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    _stateSub = null;
    _posSub = null;
    _durSub = null;
    final previous = _player;
    _player = null;
    await _disposePlayerSafely(previous);
    if (mounted) {
      setState(() {
        _loading = false;
        _playing = false;
        _loaded = false;
        _error = null;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_stateSub?.cancel());
    unawaited(_posSub?.cancel());
    unawaited(_durSub?.cancel());
    unawaited(_disposePlayerSafely(_player));
    super.dispose();
  }

  static Future<void> _disposePlayerSafely(AudioPlayer? player) async {
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {
      // Ignore platform channel disposal failures in headless test environments.
    }
  }

  Future<void> _togglePlay() async {
    if (_loading) return;
    final uri = Uri.tryParse(widget.audioUrl.trim());
    if (uri == null || !uri.hasScheme) {
      setState(() => _error = 'Đường dẫn âm thanh không hợp lệ.');
      return;
    }

    try {
      var player = _player;
      if (player == null) {
        setState(() {
          _loading = true;
          _error = null;
        });
        player = AudioPlayer();
        _player = player;
        _stateSub = player.playerStateStream.listen((state) {
          if (!mounted) return;
          final completed =
              state.processingState == ProcessingState.completed;
          setState(() {
            _playing = state.playing && !completed;
            if (completed) {
              _position = Duration.zero;
            }
          });
          if (completed) {
            unawaited(player!.seek(Duration.zero));
            unawaited(player.pause());
          }
        });
        _posSub = player.positionStream.listen((pos) {
          if (mounted) setState(() => _position = pos);
        });
        _durSub = player.durationStream.listen((dur) {
          if (mounted && dur != null) setState(() => _duration = dur);
        });
      }

      if (!_loaded) {
        setState(() {
          _loading = true;
          _error = null;
        });
        await player.setUrl(uri.toString()).timeout(const Duration(seconds: 8));
        _loaded = true;
      }

      if (!mounted) return;
      setState(() => _loading = false);

      if (_playing) {
        await player.pause().timeout(const Duration(seconds: 4));
      } else {
        await player.play().timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      final stale = _player;
      _player = null;
      _loaded = false;
      unawaited(_stateSub?.cancel());
      unawaited(_posSub?.cancel());
      unawaited(_durSub?.cancel());
      _stateSub = null;
      _posSub = null;
      _durSub = null;
      unawaited(_disposePlayerSafely(stale));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = false;
        _error = 'Không phát được âm thanh. Nhấn nút phát để thử lại.';
      });
    }
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.borderSubtlePink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _togglePlay,
                icon: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: AppColors.brandPrimary,
                        size: 34,
                      ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _error ??
                          (_playing
                              ? 'Đang phát (${_fmt(_position)}${totalMs > 0 ? ' / ${_fmt(_duration)}' : ''})'
                              : _loaded && totalMs > 0
                              ? 'Tạm dừng (${_fmt(_position)} / ${_fmt(_duration)})'
                              : 'Bấm phát để nghe đoạn hội thoại'),
                      style: AppTypography.bodySmall.copyWith(
                        color: _error != null
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_loaded && totalMs > 0)
            Slider(
              value: posMs.toDouble(),
              max: totalMs.toDouble(),
              activeColor: AppColors.brandPrimary,
              onChanged: (v) {
                unawaited(_player?.seek(Duration(milliseconds: v.round())));
              },
            ),
        ],
      ),
    );
  }
}
