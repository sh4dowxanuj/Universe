/// Platform abstraction to centralize platform checks.
abstract class PlatformUtils {
  bool get isWeb;
  bool get isAndroid;
  bool get isIOS;
  bool get isDesktop;
  bool get isMobile;
  String get localeName;
}
