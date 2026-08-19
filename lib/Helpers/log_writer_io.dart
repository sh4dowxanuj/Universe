import 'dart:io';
import 'dart:developer';
import 'package:path_provider/path_provider.dart';

class LogWriter {
  File? _logFile;

  Future<void> init() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      _logFile = File('${tempDir.path}/logs/logs.txt');
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
      await _logFile!.writeAsString('');
    } catch (e) {
      log('Error initializing log file: $e');
    }
  }

  Future<void> write(String message) async {
    if (_logFile == null) return;
    try {
      await _logFile!.writeAsString(
        message,
        mode: FileMode.append,
      );
    } catch (e) {
      log('Error writing to log file: $e');
    }
  }
}
