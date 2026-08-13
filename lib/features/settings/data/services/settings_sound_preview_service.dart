import 'package:audioplayers/audioplayers.dart';

class SettingsSoundPreviewService {
  final AudioPlayer _player = AudioPlayer();

  SettingsSoundPreviewService() {
    _player.audioCache = AudioCache(
      prefix: 'lib/features/settings/assets/sounds/',
    );
  }

  Future<void> play(String assetFileName) async {
    // Stop an existing preview before starting another sound.
    await _player.stop();
    await _player.play(AssetSource(assetFileName));
  }

  Future<void> stop() {
    return _player.stop();
  }

  Future<void> dispose() {
    return _player.dispose();
  }
}
