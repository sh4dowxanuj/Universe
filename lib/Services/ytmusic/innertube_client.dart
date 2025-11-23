/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class InnertubeClient {
  static const String ytmDomain = 'music.youtube.com';
  static const String ytDomain = 'www.youtube.com';
  static const String baseApiEndpoint = '/youtubei/v1/';
  
  String? _apiKey;
  DateTime? _apiKeyExpiry;
  String? _visitorData;
  String? _clientVersion;
  
  static final InnertubeClient _instance = InnertubeClient._internal();
  
  factory InnertubeClient() {
    return _instance;
  }
  
  InnertubeClient._internal();
  
  Map<String, String> _getHeaders({bool isMusic = true}) {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Content-Type': 'application/json',
      'Origin': isMusic ? 'https://$ytmDomain' : 'https://$ytDomain',
      'Referer': isMusic ? 'https://$ytmDomain/' : 'https://$ytDomain/',
      'X-Goog-Visitor-Id': _visitorData ?? '',
    };
  }
  
  Future<void> _extractApiKey({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _apiKey != null && 
        _apiKeyExpiry != null && 
        DateTime.now().isBefore(_apiKeyExpiry!)) {
      return;
    }
    
    try {
      Logger.root.info('Extracting YouTube Music API key');
      final response = await http.get(
        Uri.https(ytmDomain, '/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      
      if (response.statusCode != 200) {
        Logger.root.warning('Failed to fetch YouTube Music homepage: ${response.statusCode}');
        _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'; // Fallback
        return;
      }
      
      // Extract API key
      final apiKeyMatch = RegExp(r'"INNERTUBE_API_KEY":"([^"]+)"').firstMatch(response.body);
      if (apiKeyMatch != null) {
        _apiKey = apiKeyMatch.group(1);
        Logger.root.info('API key extracted successfully');
      } else {
        Logger.root.warning('Could not extract API key, using fallback');
        // NOTE: This is a public YouTube API key used by the web client.
        // It's safe to include as a fallback because:
        // 1. It's publicly visible in YouTube's web client JavaScript
        // 2. YouTube changes these keys regularly
        // 3. It's not a secret authentication token
        // 4. Primary method extracts current key dynamically
        _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'; // Fallback
      }
      
      // Extract client version
      final versionMatch = RegExp(r'"clientVersion":"([^"]+)"').firstMatch(response.body);
      if (versionMatch != null) {
        _clientVersion = versionMatch.group(1);
      }
      
      // Extract visitor data
      final visitorMatch = RegExp(r'"VISITOR_DATA":"([^"]+)"').firstMatch(response.body);
      if (visitorMatch != null) {
        _visitorData = visitorMatch.group(1);
      }
      
      // Cache for 6 hours
      _apiKeyExpiry = DateTime.now().add(const Duration(hours: 6));
      
    } catch (e) {
      Logger.root.severe('Error extracting API key: $e');
      _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'; // Fallback
    }
  }
  
  Map<String, dynamic> _buildContext({
    required String clientName,
    String? clientVersion,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    return {
      'context': {
        'client': {
          'clientName': clientName,
          'clientVersion': clientVersion ?? _clientVersion ?? '1.$dateStr.01.00',
          'hl': 'en',
          'gl': 'IN',
          'visitorData': _visitorData ?? '',
        },
      },
    };
  }
  
  Future<Map<String, dynamic>> browse({
    required String browseId,
    Map<String, dynamic>? additionalParams,
  }) async {
    await _extractApiKey();
    
    try {
      final body = _buildContext(clientName: 'WEB_REMIX');
      body['browseId'] = browseId;
      
      if (additionalParams != null) {
        body.addAll(additionalParams);
      }
      
      final uri = Uri.https(
        ytmDomain,
        '${baseApiEndpoint}browse',
        {'key': _apiKey, 'prettyPrint': 'false'},
      );
      
      final response = await http.post(
        uri,
        headers: _getHeaders(isMusic: true),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Logger.root.severe('Innertube browse failed with status ${response.statusCode}');
        return {};
      }
    } catch (e) {
      Logger.root.severe('Error in Innertube browse: $e');
      return {};
    }
  }
  
  Future<Map<String, dynamic>> player({
    required String videoId,
    String? playlistId,
    int? signatureTimestamp,
  }) async {
    await _extractApiKey();
    
    try {
      final body = _buildContext(clientName: 'WEB_REMIX');
      body['videoId'] = videoId;
      
      if (playlistId != null) {
        body['playlistId'] = playlistId;
      }
      
      if (signatureTimestamp != null) {
        body['playbackContext'] = {
          'contentPlaybackContext': {
            'signatureTimestamp': signatureTimestamp,
          },
        };
      }
      
      final uri = Uri.https(
        ytmDomain,
        '${baseApiEndpoint}player',
        {'key': _apiKey, 'prettyPrint': 'false'},
      );
      
      final response = await http.post(
        uri,
        headers: _getHeaders(isMusic: true),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Logger.root.warning('WEB_REMIX player failed with status ${response.statusCode}, trying ANDROID fallback');
        return await _playerAndroidFallback(videoId);
      }
    } catch (e) {
      Logger.root.severe('Error in Innertube player: $e');
      return await _playerAndroidFallback(videoId);
    }
  }
  
  Future<Map<String, dynamic>> _playerAndroidFallback(String videoId) async {
    try {
      Logger.root.info('Using ANDROID client fallback for playback');
      
      final body = {
        'context': {
          'client': {
            'clientName': 'ANDROID',
            'clientVersion': '18.11.34',
            'androidSdkVersion': 30,
            'hl': 'en',
            'gl': 'IN',
          },
        },
        'videoId': videoId,
      };
      
      final uri = Uri.https(
        ytDomain,
        '${baseApiEndpoint}player',
        {'key': _apiKey ?? 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8', 'prettyPrint': 'false'},
      );
      
      final response = await http.post(
        uri,
        headers: _getHeaders(isMusic: false),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        Logger.root.info('ANDROID fallback successful');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Logger.root.severe('ANDROID fallback failed with status ${response.statusCode}');
        return {};
      }
    } catch (e) {
      Logger.root.severe('Error in ANDROID fallback: $e');
      return {};
    }
  }
  
  Future<Map<String, dynamic>> next({
    required String videoId,
    String? playlistId,
  }) async {
    await _extractApiKey();
    
    try {
      final body = _buildContext(clientName: 'WEB_REMIX');
      body['videoId'] = videoId;
      
      if (playlistId != null) {
        body['playlistId'] = playlistId;
      }
      
      final uri = Uri.https(
        ytmDomain,
        '${baseApiEndpoint}next',
        {'key': _apiKey, 'prettyPrint': 'false'},
      );
      
      final response = await http.post(
        uri,
        headers: _getHeaders(isMusic: true),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Logger.root.severe('Innertube next failed with status ${response.statusCode}');
        return {};
      }
    } catch (e) {
      Logger.root.severe('Error in Innertube next: $e');
      return {};
    }
  }
  
  Future<Map<String, dynamic>> search({
    required String query,
    String? params,
  }) async {
    await _extractApiKey();
    
    try {
      final body = _buildContext(clientName: 'WEB_REMIX');
      body['query'] = query;
      
      if (params != null) {
        body['params'] = params;
      }
      
      final uri = Uri.https(
        ytmDomain,
        '${baseApiEndpoint}search',
        {'key': _apiKey, 'prettyPrint': 'false'},
      );
      
      final response = await http.post(
        uri,
        headers: _getHeaders(isMusic: true),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Logger.root.severe('Innertube search failed with status ${response.statusCode}');
        return {};
      }
    } catch (e) {
      Logger.root.severe('Error in Innertube search: $e');
      return {};
    }
  }
}
