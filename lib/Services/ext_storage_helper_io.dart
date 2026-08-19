import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universe/Services/ext_storage_provider.dart';

class ExtStorageHelper {
  ExtStorageHelper._();

  static Future<String?> getExtStorage({
    required String dirName,
    required bool writeAccess,
  }) async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        if (await ExtStorageProvider.requestPermission(Permission.storage)) {
          directory = await getExternalStorageDirectory();

          final String newPath = directory!.path
              .replaceFirst('Android/data/com.shadow.universe/files', dirName);

          directory = Directory(newPath);

          if (!await directory.exists()) {
            await ExtStorageProvider.requestPermission(Permission.manageExternalStorage);
            await directory.create(recursive: true);
          }
          if (await directory.exists()) {
            try {
              if (writeAccess) {
                await ExtStorageProvider.requestPermission(Permission.manageExternalStorage);
              }
              return newPath;
            } catch (e) {
              rethrow;
            }
          }
        } else {
          throw 'something went wrong';
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        directory = await getApplicationDocumentsDirectory();
        final finalDirName = dirName.replaceAll('Universe/', '');
        return '${directory.path}/$finalDirName';
      } else {
        directory = await getDownloadsDirectory();
        return '${directory!.path}/$dirName';
      }
    } catch (e) {
      rethrow;
    }
    return directory.path;
  }
}
