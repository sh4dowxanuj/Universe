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
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class YtDlpService {
  static final YtDlpService instance = YtDlpService._internal();
  factory YtDlpService() => instance;
  YtDlpService._internal();

  /// Base URL for the ytdlp bridge API
  /// On web, we use a server-side bridge to execute yt-dlp
  // static const String bridgeUrl = 'https://ytdlp-bridge.sangwan5688.workers.dev';
  static const String bridgeUrl = 'http://localhost:8000'; // Update this after deployment

  /// Get audio stream URL and metadata for a YouTube video
  Future<Map<String, dynamic>?> getAudioStream(String videoId,
      {String quality = 'High',}) async {
    try {
      final response = await http.get(Uri.parse('$bridgeUrl/getAudioStream?videoId=$videoId&quality=$quality'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } else {
        Logger.root.warning('YtDlpService.getAudioStream returned ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.root.severe('Error in YtDlpService.getAudioStream (Web): $e');
      return null;
    }
  }

  /// Get video information without extracting stream URL (faster)
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      final response = await http.get(Uri.parse('$bridgeUrl/getVideoInfo?videoId=$videoId'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } else {
        Logger.root.warning('YtDlpService.getVideoInfo returned ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.root.severe('Error in YtDlpService.getVideoInfo (Web): $e');
      return null;
    }
  }

  /// Search YouTube videos
  Future<List<Map<String, dynamic>>> searchVideos(
    String query, {
    int maxResults = 10,
  }) async {
    try {
      final response = await http.get(Uri.parse('$bridgeUrl/searchVideos?query=${Uri.encodeComponent(query)}&maxResults=$maxResults'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result is List) {
          return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      } else {
        Logger.root.warning('YtDlpService.searchVideos returned ${response.statusCode}: ${response.body}');
      }
      return [];
    } catch (e) {
      Logger.root.severe('Error in YtDlpService.searchVideos (Web): $e');
      return [];
    }
  }

  /// Get playlist information and its entries
  Future<Map<String, dynamic>?> getPlaylistInfo(String playlistId) async {
    try {
      final response = await http.get(Uri.parse('$bridgeUrl/getPlaylistInfo?playlistId=$playlistId'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } else {
        Logger.root.warning('YtDlpService.getPlaylistInfo returned ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.root.severe('Error in YtDlpService.getPlaylistInfo (Web): $e');
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
