import 'package:logging/logging.dart';

class DownloadPlatformHelper {
  static Future<void> requestStoragePermission() async {
    Logger.root.info('Web: No storage permission needed');
  }

  static Future<void> requestManageExternalStoragePermission() async {
    Logger.root.info('Web: No manage external storage permission needed');
  }

  static Future<bool> directoryExists(String path) async {
    return false;
  }

  static Future<void> createDirectory(String path) async {
    Logger.root.info('Web: Cannot create directory $path');
  }

  static Future<bool> fileExists(String path) async {
    return false;
  }

  static Future<String> createFile(String path) async {
    Logger.root.info('Web: Cannot create file $path');
    return path;
  }

  static Future<void> writeFileBytes(String path, List<int> bytes) async {
    Logger.root.info('Web: Cannot write file bytes to $path');
  }

  static Future<List<int>> fetchImageBytes(String url) async {
    Logger.root.info('Web: fetchImageBytes $url');
    return [];
  }

  static Future<void> saveImage(String url, String path) async {
    Logger.root.info('Web: Cannot save image $url to $path');
  }

  static Future<void> writeTags({
    required String filePath,
    required Map data,
    required String imagePath,
    required String lyrics,
    required List<int> imageBytes,
  }) async {
    Logger.root.info('Web: Skipping tagging');
  }

  static Future<String?> getTempDir() async {
    return null;
  }

  static Future<String?> getDownloadsDir() async {
    return null;
  }

  static Future<String?> getExternalStoragePath({
    required String dirName,
    required bool writeAccess,
  }) async {
    return null;
  }

  static void deleteFile(String path) {
    Logger.root.info('Web: Cannot delete file $path');
  }
}
