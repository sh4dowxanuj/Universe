import 'package:just_audio/just_audio.dart';

class AudioPlatformHelperImpl {
  AudioPlatformHelperImpl._();

  static dynamic createEqualizer() {
    return null;
  }

  static AudioPlayer createPlayer({required bool withPipeline, dynamic equalizer}) {
    return AudioPlayer();
  }

  static AudioSource? getFileSource(String path, {dynamic tag}) {
    return null;
  }

  static Future<Map> getEqualizerParams(dynamic equalizer) async {
    return {};
  }

  static void setBandGain(dynamic equalizer, int bandIdx, double gain) {}

  static void setEqualizerEnabled(dynamic equalizer, bool enabled) {}
}
