class MetadataGod {
  static void initialize() {}

  static Future<void> writeMetadata({
    required String file,
    required Metadata metadata,
  }) async {}
}

class Metadata {
  Metadata({
    required this.title,
    required this.artist,
    required this.albumArtist,
    required this.album,
    required this.genre,
    required this.year,
    required this.durationMs,
    required this.fileSize,
    required this.picture,
  });

  final String title;
  final String artist;
  final String albumArtist;
  final String album;
  final String genre;
  final int year;
  final int durationMs;
  final int fileSize;
  final Picture picture;
}

class Picture {
  Picture({
    required this.data,
    required this.mimeType,
  });

  final List<int> data;
  final String mimeType;
}
