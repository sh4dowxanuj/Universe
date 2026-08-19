import 'dart:io';
import 'dart:typed_data';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universe/Services/ext_storage_provider.dart';

class DownloadPlatformHelper {
  static Future<void> requestStoragePermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      Logger.root.info('Requesting storage permission');
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        Logger.root.info('Request denied');
        await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
      }
      status = await Permission.storage.status;
      if (status.isPermanentlyDenied) {
        Logger.root.info('Request permanently denied');
        await openAppSettings();
      }
    }
  }

  static Future<void> requestManageExternalStoragePermission() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.manageExternalStorage.status;
      if (status.isDenied) {
        Logger.root.info(
          'ManageExternalStorage permission is denied, requesting permission',
        );
        await [
          Permission.manageExternalStorage,
        ].request();
      }
      status = await Permission.manageExternalStorage.status;
      if (status.isPermanentlyDenied) {
        Logger.root.info(
          'ManageExternalStorage Request is permanently denied, opening settings',
        );
        await openAppSettings();
      }
    }
  }

  static Future<bool> directoryExists(String path) async {
    return Directory(path).exists();
  }

  static Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  static Future<String> createFile(String path) async {
    final file = await File(path).create(recursive: true);
    return file.path;
  }

  static Future<void> writeFileBytes(String path, List<int> bytes) async {
    await File(path).writeAsBytes(bytes);
  }

  static Future<List<int>> fetchImageBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }

  static Future<void> saveImage(String url, String path) async {
    final bytes = await fetchImageBytes(url);
    await File(path).writeAsBytes(bytes);
  }

  static Future<void> writeTags({
    required String filePath,
    required Map data,
    required String imagePath,
    required String lyrics,
    required List<int> imageBytes,
  }) async {
    if (Platform.isAndroid) {
      try {
        final Tag tag = Tag(
          title: data['title'].toString(),
          artist: data['artist'].toString(),
          albumArtist: data['album_artist']?.toString() ??
              data['artist']?.toString().split(', ')[0] ??
              '',
          artwork: imagePath,
          album: data['album'].toString(),
          genre: data['language'].toString(),
          year: data['year'].toString(),
          lyrics: lyrics,
          comment: 'Universe',
        );
        Logger.root.info('Started tag editing');
        final tagger = Audiotagger();
        await tagger.writeTags(
          path: filePath,
          tag: tag,
        );
      } catch (e) {
        Logger.root.severe('Error editing tags: $e');
      }
    } else {
      if (data['language'].toString() == 'YouTube') {
        final file = File(filePath);
        await MetadataGod.writeMetadata(
          file: filePath,
          metadata: Metadata(
            title: data['title'].toString(),
            artist: data['artist'].toString(),
            albumArtist: data['album_artist']?.toString() ??
                data['artist']?.toString().split(', ')[0] ??
                '',
            album: data['album'].toString(),
            genre: data['language'].toString(),
            year: int.parse(data['year'].toString()),
            durationMs: int.parse(data['duration'].toString()) * 1000,
            fileSize: file.lengthSync(),
            picture: Picture(
              data: Uint8List.fromList(imageBytes),
              mimeType: 'image/jpeg',
            ),
          ),
        );
      }
    }
  }

  static Future<String?> getTempDir() async {
    return (await getTemporaryDirectory()).path;
  }

  static Future<String?> getDownloadsDir() async {
    return (await getDownloadsDirectory())?.path;
  }

  static Future<String?> getExternalStoragePath({
    required String dirName,
    required bool writeAccess,
  }) async {
    return ExtStorageProvider.getExtStorage(
      dirName: dirName,
      writeAccess: writeAccess,
    );
  }

  static void deleteFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
