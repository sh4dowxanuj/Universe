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
import 'package:flutter/services.dart';

class YtDlpService {
  static final YtDlpService instance = YtDlpService._internal();
  factory YtDlpService() => instance;
  YtDlpService._internal();

  static const MethodChannel _channel = MethodChannel('ytdlp_channel');

  /// Get audio stream URL and metadata for a YouTube video
  Future<Map<String, dynamic>?> getAudioStream(String videoId,
      {String quality = 'High',}) async {
    try {
      final result = await _channel.invokeMethod('getAudioStream', {
        'videoId': videoId,
        'quality': quality,
      });

      if (result is Map) {
        final data = Map<String, dynamic>.from(result);
        return data;
      }
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get video information without extracting stream URL (faster)
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      final result = await _channel.invokeMethod('getVideoInfo', {
        'videoId': videoId,
      });

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Search YouTube videos
  Future<List<Map<String, dynamic>>> searchVideos(
    String query, {
    int maxResults = 10,
  }) async {
    try {
      final result = await _channel.invokeMethod('searchVideos', {
        'query': query,
        'maxResults': maxResults,
      });

      if (result is List) {
        return result
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } on PlatformException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get playlist information and its entries
  Future<Map<String, dynamic>?> getPlaylistInfo(String playlistId) async {
    try {
      final result = await _channel.invokeMethod('getPlaylistInfo', {
        'playlistId': playlistId,
      });

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Format video data for compatibility with existing YouTube service
  Map<String, dynamic> formatVideoData(
      Map<String, dynamic> ytdlpData, String videoId,) {
    return {
      'id': videoId,
      'title': ytdlpData['title'] ?? 'Unknown Title',
      'artist': ytdlpData['uploader'] ?? 'Unknown',
      'image': ytdlpData['thumbnail'] ?? '',
      'duration': ytdlpData['duration'] ?? 0,
      'url': 'https://www.youtube.com/watch?v=$videoId',
      'source': 'YouTube',
      'quality': '${ytdlpData['bitrate'] ?? 128} kbps',
    };
  }
}
