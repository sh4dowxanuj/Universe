import 'dart:io' show Platform;

import 'package:universe/Helpers/platform_utils_base.dart';

class IoPlatformUtils implements PlatformUtils {
  @override
  bool get isWeb => false;

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  bool get isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  @override
  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  String get localeName => Platform.localeName;
}

PlatformUtils getPlatformUtils() => IoPlatformUtils();
