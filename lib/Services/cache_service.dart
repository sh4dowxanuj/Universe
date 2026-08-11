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

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

/// Centralized caching service with TTL support
class CacheService {
  final Logger _logger = Logger('CacheService');
  static const Duration _defaultTTL = Duration(minutes: 30);

  /// Get cached data with TTL check
  T? get<T>(String key, {String boxName = 'cache'}) {
    try {
      final box = Hive.box(boxName);
      final cached = box.get(key);

      if (cached is Map && cached.containsKey('data') && cached.containsKey('timestamp')) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp'] as int);
        final ttl = (cached['ttl'] as int?) ?? _defaultTTL.inMilliseconds;

        if (DateTime.now().difference(timestamp).inMilliseconds < ttl) {
          return cached['data'] as T;
        } else {
          // Expired, remove from cache
          box.delete(key);
        }
      }

      return cached as T?;
    } catch (e) {
      _logger.warning('Error retrieving cache for key: $key', e);
      return null;
    }
  }

  /// Set cached data with TTL
  Future<void> set<T>(String key, T data, {
    String boxName = 'cache',
    Duration? ttl,
  }) async {
    try {
      final box = Hive.box(boxName);
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': (ttl ?? _defaultTTL).inMilliseconds,
      };
      await box.put(key, cacheEntry);
    } catch (e) {
      _logger.warning('Error setting cache for key: $key', e);
    }
  }

  /// Check if key exists and is not expired
  bool has(String key, {String boxName = 'cache'}) {
    try {
      final box = Hive.box(boxName);
      final cached = box.get(key);

      if (cached is Map && cached.containsKey('timestamp')) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp'] as int);
        final ttl = (cached['ttl'] as int?) ?? _defaultTTL.inMilliseconds;
        return DateTime.now().difference(timestamp).inMilliseconds < ttl;
      }

      return cached != null;
    } catch (e) {
      return false;
    }
  }

  /// Remove cached data
  Future<void> remove(String key, {String boxName = 'cache'}) async {
    try {
      final box = Hive.box(boxName);
      await box.delete(key);
    } catch (e) {
      _logger.warning('Error removing cache for key: $key', e);
    }
  }

  /// Clear all cached data
  Future<void> clear({String boxName = 'cache'}) async {
    try {
      final box = Hive.box(boxName);
      await box.clear();
    } catch (e) {
      _logger.warning('Error clearing cache', e);
    }
  }

  /// Get cache size
  int size({String boxName = 'cache'}) {
    try {
      final box = Hive.box(boxName);
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clean expired entries
  Future<void> cleanExpired({String boxName = 'cache'}) async {
    try {
      final box = Hive.box(boxName);
      final keysToRemove = <String>[];

      for (final key in box.keys) {
        final cached = box.get(key);
        if (cached is Map &&
            cached.containsKey('timestamp') &&
            cached.containsKey('ttl')) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp'] as int);
          final ttl = cached['ttl'] as int;
          if (DateTime.now().difference(timestamp).inMilliseconds >= ttl) {
            keysToRemove.add(key as String);
          }
        }
      }

      for (final key in keysToRemove) {
        await box.delete(key);
      }

      if (keysToRemove.isNotEmpty) {
        _logger.info('Cleaned ${keysToRemove.length} expired cache entries');
      }
    } catch (e) {
      _logger.warning('Error cleaning expired cache entries', e);
    }
  }
}
