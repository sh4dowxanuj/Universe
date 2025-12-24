import 'package:universe/Helpers/platform_utils_base.dart';

class WebPlatformUtils implements PlatformUtils {
  @override
  bool get isWeb => true;

  @override
  bool get isAndroid => false;

  @override
  bool get isIOS => false;

  @override
  bool get isDesktop => false;

  @override
  bool get isMobile => false;

  @override
  String get localeName => 'en';
}

PlatformUtils getPlatformUtils() => WebPlatformUtils();
