import 'dart:io';

import 'package:blackhole/Services/youtube_audio_source.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('uses a browser user agent for YouTube requests', () {
    final userAgent = YouTubeServices.headers['User-Agent'];

    expect(userAgent, isNotNull);
    expect(userAgent, contains('Mozilla/5.0'));
    expect(userAgent, contains('Chrome/'));
  });

  test(
    'fetches a YouTube audio manifest without a 403 response',
    () async {
      const videoId = 'dQw4w9WgXcQ';

      try {
        final streams = await YouTubeServices.instance.getStreamInfo(videoId);
        expect(streams, isNotEmpty);
      } catch (error) {
        fail('YouTube manifest request failed: $error');
      }
    },
    skip: Platform.environment['RUN_YOUTUBE_INTEGRATION_TESTS'] != '1'
        ? 'Set RUN_YOUTUBE_INTEGRATION_TESTS=1 to run the live YouTube check.'
        : false,
  );

  test(
    'YouTube audio stream accepts direct playback requests',
    () async {
      const videoId = 'dQw4w9WgXcQ';
      final streams = await YouTubeServices.instance.getStreamInfo(videoId);
      expect(streams, isNotEmpty);

      final response = await http.get(
        Uri.parse(streams.first.url.toString()),
        headers: {
          'Range': 'bytes=0-1023',
        },
      );

      expect(response.statusCode, anyOf(200, 206));
      expect(response.bodyBytes, isNotEmpty);
    },
    skip: Platform.environment['RUN_YOUTUBE_INTEGRATION_TESTS'] != '1'
        ? 'Set RUN_YOUTUBE_INTEGRATION_TESTS=1 to run the live playback check.'
        : false,
  );

  test(
    'Dart-backed playback source serves an audio range',
    () async {
      const videoId = 'dQw4w9WgXcQ';
      final streams = await YouTubeServices.instance.getStreamInfo(videoId);
      expect(streams, isNotEmpty);

      final source = YouTubeAudioSource(streams.first.url);
      final response = await source.request(0, 1024);
      final bytes = await response.stream.fold<int>(
        0,
        (total, chunk) => total + chunk.length,
      );

      expect(bytes, greaterThan(0));
      expect(response.offset, 0);
    },
    skip: Platform.environment['RUN_YOUTUBE_INTEGRATION_TESTS'] != '1'
        ? 'Set RUN_YOUTUBE_INTEGRATION_TESTS=1 to run the live source check.'
        : false,
  );
}
