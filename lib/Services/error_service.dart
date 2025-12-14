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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Global error handling service
class ErrorService {
  final Logger _logger = Logger('ErrorService');

  /// Handle Flutter framework errors
  void handleFlutterError(FlutterErrorDetails details) {
    _logger.severe('Flutter Error', details.exception, details.stack);
    // In production, you might want to send this to a crash reporting service
  }

  /// Handle platform dispatcher errors
  void handlePlatformError(Object error, StackTrace? stack) {
    _logger.severe('Platform Error', error, stack);
  }

  /// Handle API errors with user-friendly messages
  String getErrorMessage(dynamic error) {
    if (error is Exception) {
      if (error.toString().contains('SocketException')) {
        return 'Network connection error. Please check your internet connection.';
      }
      if (error.toString().contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Report non-critical errors
  void reportError(String context, dynamic error, [StackTrace? stack]) {
    _logger.warning('Error in $context', error, stack);
  }
}
