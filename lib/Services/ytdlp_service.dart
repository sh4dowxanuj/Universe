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
