import 'package:just_audio/just_audio.dart';

abstract interface class KanjiAudioPlayer {
  Future<void> play(Uri source);

  Future<void> dispose();
}

class JustAudioKanjiPlayer implements KanjiAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(Uri source) async {
    await _player.setUrl(source.toString());
    await _player.play();
  }

  @override
  Future<void> dispose() => _player.dispose();
}
