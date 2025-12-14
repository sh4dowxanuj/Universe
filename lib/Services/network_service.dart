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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:universe/Services/cache_service.dart';
import 'package:universe/main.dart';

/// Centralized network service with retry logic and caching
class NetworkService {
  final Logger _logger = Logger('NetworkService');
  final http.Client _client = http.Client();

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  /// Make HTTP GET request with retry logic
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool useCache = false,
  }) async {
    return _executeRequest(
      () => _client.get(url, headers: headers),
      url.toString(),
      timeout: timeout,
      useCache: useCache,
    );
  }

  /// Make HTTP POST request with retry logic
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool useCache = false,
  }) async {
    return _executeRequest(
      () => _client.post(url, headers: headers, body: body),
      url.toString(),
      timeout: timeout,
      useCache: useCache,
    );
  }

  /// Execute request with retry logic
  Future<http.Response> _executeRequest(
    Future<http.Response> Function() request,
    String url, {
    Duration? timeout,
    bool useCache = false,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;

    // Check cache first if enabled
    if (useCache) {
      final cacheKey = 'http_${url.hashCode}';
      final cached = locator<CacheService>().get<String>(cacheKey);
      if (cached != null) {
        try {
          final responseData = jsonDecode(cached);
          return http.Response(
            responseData['body'] as String,
            responseData['statusCode'] as int,
            headers: Map<String, String>.from((responseData['headers'] as Map?) ?? {}),
            request: http.Request('GET', Uri.parse(url)),
          );
        } catch (e) {
          _logger.warning('Failed to parse cached response', e);
        }
      }
    }

    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        _logger.fine('HTTP Request attempt ${attempt + 1}/$_maxRetries: $url');

        final response = await request().timeout(effectiveTimeout);

        // Cache successful responses if enabled
        if (useCache && response.statusCode == 200) {
          final cacheKey = 'http_${url.hashCode}';
          final cacheData = {
            'body': response.body,
            'statusCode': response.statusCode,
            'headers': response.headers,
          };
          await locator<CacheService>().set(cacheKey, jsonEncode(cacheData));
        }

        return response;
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          _logger.severe('Request timeout after $_maxRetries attempts: $url', e);
          rethrow;
        }
        await Future.delayed(_retryDelay * attempt);
      } on SocketException catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          _logger.severe('Network error after $_maxRetries attempts: $url', e);
          rethrow;
        }
        await Future.delayed(_retryDelay * attempt);
      } catch (e) {
        _logger.severe('Request failed: $url', e);
        rethrow;
      }
    }

    throw Exception('Request failed after $_maxRetries attempts');
  }

  /// Check network connectivity
  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}
