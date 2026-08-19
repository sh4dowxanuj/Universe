import 'package:just_audio/just_audio.dart';
import 'package:universe/Services/audio_service/audio_platform_helper_io.dart'
    if (dart.library.html) 'package:universe/Services/audio_service/audio_platform_helper_web.dart';

class AudioPlatformHelper {
  AudioPlatformHelper._();

  static AudioPlayer createPlayer({required bool withPipeline, dynamic equalizer}) =>
      AudioPlatformHelperImpl.createPlayer(withPipeline: withPipeline, equalizer: equalizer);

  static AudioSource? getFileSource(String path, {dynamic tag}) =>
      AudioPlatformHelperImpl.getFileSource(path, tag: tag);

  static Future<Map> getEqualizerParams(dynamic equalizer) =>
      AudioPlatformHelperImpl.getEqualizerParams(equalizer);

  static void setBandGain(dynamic equalizer, int bandIdx, double gain) =>
      AudioPlatformHelperImpl.setBandGain(equalizer, bandIdx, gain);

  static void setEqualizerEnabled(dynamic equalizer, bool enabled) =>
      AudioPlatformHelperImpl.setEqualizerEnabled(equalizer, enabled);

  static dynamic createEqualizer() => AudioPlatformHelperImpl.createEqualizer();
}
