import 'dart:async';

class SharedMediaFile {
  SharedMediaFile(this.path);
  final String path;
}

class ReceiveSharingIntent {
  static Stream<String> getTextStream() => const Stream.empty();
  static Future<String?> getInitialText() async => null;
  static Stream<List<SharedMediaFile>> getMediaStream() => const Stream.empty();
  static Future<List<SharedMediaFile>> getInitialMedia() async => <SharedMediaFile>[];
}
