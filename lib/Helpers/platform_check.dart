import 'package:flutter/foundation.dart';
import 'package:universe/Helpers/platform_check/platform_check_io.dart'
    if (dart.library.html) 'platform_check/platform_check_web.dart';

class PlatformCheck {
  PlatformCheck._();

  static bool get isWeb => kIsWeb;
  static bool get isAndroid => PlatformCheckImplementation.isAndroid;
  static bool get isIOS => PlatformCheckImplementation.isIOS;
  static bool get isWindows => PlatformCheckImplementation.isWindows;
  static bool get isLinux => PlatformCheckImplementation.isLinux;
  static bool get isMacOS => PlatformCheckImplementation.isMacOS;
  static bool get isMobile => PlatformCheckImplementation.isMobile;
  static bool get isDesktop => PlatformCheckImplementation.isDesktop;
  static String get operatingSystem =>
      PlatformCheckImplementation.operatingSystem;
  static String get localeName => PlatformCheckImplementation.localeName;
}
