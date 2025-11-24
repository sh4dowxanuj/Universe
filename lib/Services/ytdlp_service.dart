import 'dart:async';
import 'package:flutter/services.dart';

class YtDlpService {
  static final YtDlpService instance = YtDlpService._internal();
  factory YtDlpService() => instance;
  YtDlpService._internal();

  static const MethodChannel _channel = MethodChannel('ytdlp_channel');

  /// Get audio stream URL and metadata for a YouTube video
  Future<Map<String, dynamic>?> getAudioStream(String videoId) async {
    try {
      print('YtDlp: Fetching audio stream for $videoId');
      final result = await _channel.invokeMethod('getAudioStream', {
        'videoId': videoId,
      });
      
      if (result is Map) {
        final data = Map<String, dynamic>.from(result);
        print('YtDlp: Got stream URL: ${data['url']?.substring(0, 100)}...');
        return data;
      }
      return null;
    } on PlatformException catch (e) {
      print('YtDlp Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('YtDlp Error: $e');
      return null;
    }
  }

  /// Get video information without extracting stream URL (faster)
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      print('YtDlp: Fetching info for $videoId');
      final result = await _channel.invokeMethod('getVideoInfo', {
        'videoId': videoId,
      });
      
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print('YtDlp Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('YtDlp Error: $e');
      return null;
    }
  }

  /// Search YouTube videos
  Future<List<Map<String, dynamic>>> searchVideos(
    String query, {
    int maxResults = 10,
  }) async {
    try {
      print('YtDlp: Searching for "$query"');
      final result = await _channel.invokeMethod('searchVideos', {
        'query': query,
        'maxResults': maxResults,
      });
      
      if (result is List) {
        return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return [];
    } on PlatformException catch (e) {
      print('YtDlp Error: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      print('YtDlp Error: $e');
      return [];
    }
  }

  /// Format video data for compatibility with existing YouTube service
  Map<String, dynamic> formatVideoData(Map<String, dynamic> ytdlpData, String videoId) {
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
