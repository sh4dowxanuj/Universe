import 'dart:async';

import 'package:blackhole/Services/youtube_services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class YouTubeAudioSource extends StreamAudioSource {
  YouTubeAudioSource(this.url, {super.tag});

  final Uri url;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end == null ? '' : '${end - 1}';
    final requestUrl = url.queryParameters['c'] == 'ANDROID'
        ? url
        : url.replace(
            queryParameters: {
              ...url.queryParameters,
              'range': '$from-$to',
            },
          );
    final request = http.Request('GET', requestUrl);
    request.headers.addAll(YouTubeServices.headers);
    if (url.queryParameters['c'] == 'ANDROID') {
      request.headers['Range'] = 'bytes=$from-$to';
    }

    final client = http.Client();
    final response = await client.send(request);
    if (response.statusCode != 200 && response.statusCode != 206) {
      client.close();
      throw StateError('YouTube stream returned HTTP ${response.statusCode}');
    }

    final contentRange = response.headers['content-range'];
    final sourceLength = _sourceLength(contentRange) ??
        int.tryParse(response.headers['content-length'] ?? '');
    final offset = start ?? _rangeStart(contentRange) ?? 0;
    final controller = StreamController<List<int>>();
    response.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        client.close();
        controller.close();
      },
      cancelOnError: true,
    );

    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: int.tryParse(response.headers['content-length'] ?? ''),
      offset: offset,
      contentType: response.headers['content-type'] ?? 'audio/mp4',
      stream: controller.stream,
    );
  }

  int? _rangeStart(String? value) {
    final match = RegExp(r'bytes (\d+)-').firstMatch(value ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  int? _sourceLength(String? value) {
    final match = RegExp(r'/([0-9]+)$').firstMatch(value ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
