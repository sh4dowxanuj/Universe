import 'package:just_audio/just_audio.dart';
import 'package:universe/Helpers/platform_check.dart';

class AudioPlatformHelperImpl {
  AudioPlatformHelperImpl._();

  static dynamic createEqualizer() {
    if (PlatformCheck.isAndroid) {
      return AndroidEqualizer();
    }
    return null;
  }

  static AudioPlayer createPlayer({required bool withPipeline, dynamic equalizer}) {
    if (withPipeline && PlatformCheck.isAndroid && equalizer is AndroidEqualizer) {
      final AudioPipeline pipeline = AudioPipeline(
        androidAudioEffects: [
          equalizer,
        ],
      );
      return AudioPlayer(audioPipeline: pipeline);
    }
    return AudioPlayer();
  }

  static AudioSource? getFileSource(String path, {dynamic tag}) {
    return AudioSource.uri(Uri.file(path), tag: tag);
  }

  static Future<Map> getEqualizerParams(dynamic equalizer) async {
    if (equalizer is AndroidEqualizer) {
      final params = await equalizer.parameters;
      final List<AndroidEqualizerBand> bands = params.bands;
      final List<Map> bandList = bands
          .map(
            (e) => {
              'centerFrequency': e.centerFrequency,
              'gain': e.gain,
              'index': e.index,
            },
          )
          .toList();

      return {
        'maxDecibels': params.maxDecibels,
        'minDecibels': params.minDecibels,
        'bands': bandList,
      };
    }
    return {};
  }

  static void setBandGain(dynamic equalizer, int bandIdx, double gain) {
    if (equalizer is AndroidEqualizer) {
      equalizer.parameters.then((params) {
        params.bands[bandIdx].setGain(gain);
      });
    }
  }

  static void setEqualizerEnabled(dynamic equalizer, bool enabled) {
    if (equalizer is AndroidEqualizer) {
      equalizer.setEnabled(enabled);
    }
  }
}
