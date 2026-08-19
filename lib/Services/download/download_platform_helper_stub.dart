class DownloadPlatformHelper {
  static Future<void> requestStoragePermission() async => throw UnimplementedError();
  static Future<void> requestManageExternalStoragePermission() async => throw UnimplementedError();
  static Future<bool> directoryExists(String path) async => throw UnimplementedError();
  static Future<void> createDirectory(String path) async => throw UnimplementedError();
  static Future<bool> fileExists(String path) async => throw UnimplementedError();
  static Future<String> createFile(String path) async => throw UnimplementedError();
  static Future<void> writeFileBytes(String path, List<int> bytes) async => throw UnimplementedError();
  static Future<List<int>> fetchImageBytes(String url) async => throw UnimplementedError();
  static Future<void> saveImage(String url, String path) async => throw UnimplementedError();
  static Future<void> writeTags({
    required String filePath,
    required Map data,
    required String imagePath,
    required String lyrics,
    required List<int> imageBytes,
  }) async => throw UnimplementedError();
  static Future<String?> getTempDir() async => throw UnimplementedError();
  static Future<String?> getDownloadsDir() async => throw UnimplementedError();
  static Future<String?> getExternalStoragePath({
    required String dirName,
    required bool writeAccess,
  }) async => throw UnimplementedError();
  static void deleteFile(String path) => throw UnimplementedError();
}
