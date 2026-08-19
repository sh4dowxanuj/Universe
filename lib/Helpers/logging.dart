import 'dart:developer';

import 'package:logging/logging.dart';
import 'package:universe/Helpers/log_writer_io.dart' if (dart.library.html) 'log_writer_web.dart';
import 'package:universe/Helpers/platform_check.dart';

Future<void> initializeLogging() async {
  final writer = LogWriter();
  await writer.init();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) async {
    final String message;
    if (record.level.name != 'INFO') {
      message =
          '${record.level.name}: ${record.time}: record.message: ${record.message}\nrecord.error: ${record.error}\nrecord.stackTrace: ${record.stackTrace}\n\n';
    } else {
      message =
          '${record.level.name}: ${record.time}: record.message: ${record.message}\n\n';
    }

    log(message);

    if (!PlatformCheck.isWeb) {
      await writer.write(message);
    }
  });
}
