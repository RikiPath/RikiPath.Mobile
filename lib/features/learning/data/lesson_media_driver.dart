import 'dart:async';

import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:video_player/video_player.dart';

/// Playback engine boundary used by the lesson application controller.
///
/// C10 uses [FixtureLessonMediaDriver] because no verified media URL is
/// available. [VideoPlayerLessonMediaDriver] is the package-backed adapter for
/// a future repository-provided URL; it never creates or hardcodes a URL.
abstract interface class LessonMediaDriver {
  VideoPlayerController? get videoController;

  Future<void> initialize({
    required LessonMediaSource source,
    required Duration resumePosition,
  });

  Future<void> play();

  Future<void> pause();

  void dispose();
}

class FixtureLessonMediaDriver implements LessonMediaDriver {
  const FixtureLessonMediaDriver();

  @override
  VideoPlayerController? get videoController => null;

  @override
  Future<void> initialize({
    required LessonMediaSource source,
    required Duration resumePosition,
  }) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  void dispose() {}
}

class VideoPlayerLessonMediaDriver implements LessonMediaDriver {
  VideoPlayerController? _controller;

  @override
  VideoPlayerController? get videoController => _controller;

  @override
  Future<void> initialize({
    required LessonMediaSource source,
    required Duration resumePosition,
  }) async {
    final uri = source.uri;
    if (source.type != LessonMediaSourceType.network || uri == null) {
      throw StateError('A verified network media URL is required.');
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    await controller.initialize();
    await controller.seekTo(resumePosition);
  }

  @override
  Future<void> play() async {
    await _requiredController.play();
  }

  @override
  Future<void> pause() async {
    await _requiredController.pause();
  }

  VideoPlayerController get _requiredController {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('The lesson video is not initialized.');
    }
    return controller;
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
  }
}
