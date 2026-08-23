/*
 *  This file is part of Universe (https://github.com/SH4DOWXANUJ/Universe).
 *
 * Universe is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * Universe is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Universe. If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (c) 2021-2023, SH4DOWXANUJ
 */

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:universe/Helpers/platform_check.dart';

// ignore: avoid_classes_with_only_static_members
class Picker {
  static Future<String> selectFolder({
    required BuildContext context,
    String? message,
  }) async {
    final String? path = await getDirectoryPath();

    Logger.root.info('Selected folder: $path');

    return (path == '/' || path == null) ? '' : path;
  }

  static Future<String> selectFile({
    required BuildContext context,
    String? message,
  }) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Files',
    );

    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );

    if (file == null) {
      return '';
    }

    if (PlatformCheck.isWeb) {
      return file.name;
    }

    final String path = file.path;

    if (path.isEmpty) {
      return '';
    }

    final File localFile = File(path);

    return localFile.path == '/' ? '' : localFile.path;
  }
}
