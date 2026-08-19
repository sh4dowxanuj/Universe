/*
 *  This file is part of Universe (https://github.com/SH4DOWXANUJ/Universe).
 * 
 * Universe is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Universe is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Universe.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, SH4DOWXANUJ
 */

import 'package:permission_handler/permission_handler.dart';
import 'package:universe/Helpers/platform_check.dart';
import 'package:universe/Services/ext_storage_helper_io.dart'
    if (dart.library.html) 'ext_storage_helper_web.dart';

// ignore: avoid_classes_with_only_static_members
class ExtStorageProvider {
  // asking for permission
  static Future<bool> requestPermission(Permission permission) async {
    if (PlatformCheck.isWeb) return true;
    if (await permission.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  // getting external storage path
  static Future<String?> getExtStorage({
    required String dirName,
    required bool writeAccess,
  }) async {
    return ExtStorageHelper.getExtStorage(
      dirName: dirName,
      writeAccess: writeAccess,
    );
  }
}
