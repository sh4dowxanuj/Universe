import 'package:universe/Helpers/platform_utils_base.dart';
import 'package:universe/Helpers/platform_utils_io.dart' if (dart.library.html) 'platform_utils_web.dart';

PlatformUtils get platform => getPlatformUtils();
