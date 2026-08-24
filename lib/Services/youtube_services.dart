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

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:universe/Services/app_state_service.dart';
import 'package:universe/Services/error_service.dart';
import 'package:universe/Services/innertube_service.dart';
import 'package:universe/Services/yt_music.dart';
import 'package:universe/Services/ytdlp_service.dart';
import 'package:universe/main.dart';

class YouTubeServices {
  static const String searchAuthority = 'www.youtube.com';
  static const Map paths = {
    'search': '/results',
    'channel': '/channel',
    'music': '/music',
    'playlist': '/playlist',
  };
  static const Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  };

  factory YouTubeServices() {
    return _instance;
  }

  YouTubeServices._privateConstructor();

  static final YouTubeServices _instance =
      YouTubeServices._privateConstructor();

  static YouTubeServices get instance {
    return _instance;
  }

  Future<List<Map>> getPlaylistSongs(String id) async {
    final Map<String, dynamic>? results = await YtDlpService.instance.getPlaylistInfo(id);
    return (results?['entries'] as List?)?.whereType<Map>().toList() ?? [];
  }

  Future<Map?> getVideoFromId(String id) async {
    try {
      final Map? result = await YtDlpService.instance.getVideoInfo(id);
      return result;
    } catch (e) {
      Logger.root.severe('Error while getting video from id', e);
      return null;
    }
  }

  Future<Map?> formatVideoFromId({
    required String id,
    Map? data,
    bool? getUrl,
  }) async {
    final Map? vid = await getVideoFromId(id);
    if (vid == null) {
      return null;
    }
    final Map? response = await formatVideo(
      video: vid,
      quality: 'High', // FORCE HIGH QUALITY TEST (128 kbps MP4)
      data: data,
      getUrl: getUrl ?? true,
    );
    return response;
  }

  Future<Map?> refreshLink(String id, {bool useYTM = false}) async {
    // Get quality setting from Hive
    String quality;
    try {
      quality = Hive.box('settings').get('streamingQuality', defaultValue: 'High').toString();
      // Convert kbps format to High/Low
      if (quality.contains('320') || quality.contains('256')) {
        quality = 'High';
      } else {
        quality = 'Low';
      }
    } catch (e) {
      Logger.root.warning('Failed to get quality setting: $e');
      quality = 'High'; // Default to high quality
    }
    
    try {
      // Use yt-dlp first (bypasses POTOKEN authentication)
      Logger.root.info('Refreshing link using yt-dlp for $id (quality: $quality)');
      final ytdlpData = await YtDlpService.instance.getAudioStream(id);
      
      if (ytdlpData != null && ytdlpData['url'] != null) {
        // Get basic video info for metadata
        Map? videoInfo;
        try {
          videoInfo = await getVideoFromId(id);
        } catch (e) {
          Logger.root.warning('Failed to get video metadata: $e');
        }
        
        // Build response with yt-dlp URL and metadata
        final result = {
          'id': id,
          'url': ytdlpData['url'],
          'expire_at': ytdlpData['expire_at']?.toString() ?? '0',
          'genre': 'YouTube',
          'language': 'YouTube',
        };
        
        // Add metadata if available
        if (videoInfo != null) {
          final String thumbnailUrl = videoInfo['thumbnail']?.toString() ?? 
                                     (videoInfo['thumbnails'] is List && (videoInfo['thumbnails'] as List).isNotEmpty 
                                        ? (videoInfo['thumbnails'] as List).last['url'].toString() 
                                        : 'https://i.ytimg.com/vi/$id/maxresdefault.jpg');
          result.addAll({
            'title': videoInfo['title'],
            'artist': videoInfo['uploader'].toString().replaceAll('- Topic', '').trim(),
            'album': videoInfo['uploader'].toString().replaceAll('- Topic', '').trim(),
            'duration': videoInfo['duration'].toString(),
            'image': thumbnailUrl,
            'secondImage': thumbnailUrl,
          });
        }
        
        Logger.root.info('Successfully refreshed link for $id via yt-dlp');
        return result;
      }
      
      Logger.root.warning('yt-dlp failed for $id, trying YTMusic as fallback');
      
      // youtube_explode_dart REMOVED - Try YTMusic as fallback
      if (!useYTM) {
        final Map res = await YtMusicService().getSongData(
          videoId: id,
          quality: quality,
        );
        if (res.isNotEmpty) {
          Logger.root.info('Successfully refreshed link for $id via YTMusic');
          return res;
        }
      }
      
      Logger.root.severe('All methods failed to refresh link for $id');
      return null;
    } catch (e) {
      Logger.root.severe('Error refreshing link for $id: $e');
      return null;
    }
  }

  Future<Map?> getPlaylistDetails(String id) async {
    final Map<String, dynamic>? metadata = await YtDlpService.instance.getPlaylistInfo(id);
    return metadata;
  }

  Future<Map<String, dynamic>> getMusicHome() async {
    final appState = locator<AppStateService>();

    try {
      Logger.root.info('Fetching YouTube Music home using InnerTube API');
      appState.updateHomeData([], isLoading: true);

      // Try InnerTube API first
      final innerTubeResult = await InnerTubeService.instance.getMusicHome();
      final List<Map> sections = [];
      
      if (innerTubeResult != null && innerTubeResult['body'] is List) {
        sections.addAll((innerTubeResult['body'] as List).whereType<Map>());
        Logger.root.info('Loaded ${sections.length} sections from InnerTube API');
      }

      final result = {
        'body': sections, 
        'head': innerTubeResult?['head'] ?? [],
      };
      
      appState.updateHomeData(sections);
      
      return result;

    } catch (e, stackTrace) {
      final errorMessage = locator<ErrorService>().getErrorMessage(e);
      Logger.root.severe('Error in getMusicHome: $e\n$stackTrace');

      appState.updateHomeData([], error: errorMessage);
      locator<ErrorService>().reportError('YouTubeServices.getMusicHome', e, stackTrace);

      return {'body': [], 'head': []};
    }
  }

  Future<List> getSearchSuggestions({required String query}) async {
    const baseUrl =
        'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=';
    // 'https://invidious.snopyta.org/api/v1/search/suggestions?q=';
    final Uri link = Uri.parse(baseUrl + query);
    try {
      final Response response = await get(link, headers: headers);
      if (response.statusCode != 200) {
        return [];
      }
      final unescape = HtmlUnescape();
      // final Map res = jsonDecode(response.body) as Map;
      final List res = (jsonDecode(response.body) as List)[1] as List;
      // return (res['suggestions'] as List).map((e) => unescape.convert(e.toString())).toList();
      return res.map((e) => unescape.convert(e.toString())).toList();
    } catch (e) {
      Logger.root.severe('Error in getSearchSuggestions: $e');
      return [];
    }
  }

  List formatVideoItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['gridVideoRenderer']['title']['simpleText'],
          'type': 'video',
          'description': e['gridVideoRenderer']['shortBylineText']['runs'][0]
              ['text'],
          'count': e['gridVideoRenderer']['shortViewCountText']['simpleText'],
          'videoId': e['gridVideoRenderer']['videoId'],
          'firstItemId': e['gridVideoRenderer']['videoId'],
          'image':
              e['gridVideoRenderer']['thumbnail']['thumbnails'].last['url'],
          'imageMin': e['gridVideoRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['gridVideoRenderer']['thumbnail']['thumbnails'][1]
              ['url'],
          'imageStandard': e['gridVideoRenderer']['thumbnail']['thumbnails'][2]
              ['url'],
          'imageMax':
              e['gridVideoRenderer']['thumbnail']['thumbnails'].last['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatVideoItems: $e');
      return List.empty();
    }
  }

  List formatChartItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['gridPlaylistRenderer']['title']['runs'][0]['text'],
          'type': 'chart',
          'description': e['gridPlaylistRenderer']['shortBylineText']['runs'][0]
              ['text'],
          'count': e['gridPlaylistRenderer']['videoCountText']['runs'][0]
              ['text'],
          'playlistId': e['gridPlaylistRenderer']['navigationEndpoint']
              ['watchEndpoint']['playlistId'],
          'firstItemId': e['gridPlaylistRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageStandard': e['gridPlaylistRenderer']['thumbnail']['thumbnails']
              [0]['url'],
          'imageMax': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatChartItems: $e');
      return List.empty();
    }
  }

  List formatItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['compactStationRenderer']['title']['simpleText'],
          'type': 'playlist',
          'description': e['compactStationRenderer']['description']
              ['simpleText'],
          'count': e['compactStationRenderer']['videoCountText']['runs'][0]
              ['text'],
          'playlistId': e['compactStationRenderer']['navigationEndpoint']
              ['watchEndpoint']['playlistId'],
          'firstItemId': e['compactStationRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['compactStationRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['compactStationRenderer']['thumbnail']['thumbnails']
              [0]['url'],
          'imageStandard': e['compactStationRenderer']['thumbnail']
              ['thumbnails'][1]['url'],
          'imageMax': e['compactStationRenderer']['thumbnail']['thumbnails'][2]
              ['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatItems: $e');
      return List.empty();
    }
  }

  List formatHeadItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['defaultPromoPanelRenderer']['title']['runs'][0]['text'],
          'type': 'video',
          'description':
              (e['defaultPromoPanelRenderer']['description']['runs'] as List)
                  .map((e) => e['text'])
                  .toList()
                  .join(),
          'videoId': e['defaultPromoPanelRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'firstItemId': e['defaultPromoPanelRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['defaultPromoPanelRenderer']
                          ['largeFormFactorBackgroundThumbnail']
                      ['thumbnailLandscapePortraitRenderer']['landscape']
                  ['thumbnails']
              .last['url'],
          'imageMedium': e['defaultPromoPanelRenderer']
                      ['largeFormFactorBackgroundThumbnail']
                  ['thumbnailLandscapePortraitRenderer']['landscape']
              ['thumbnails'][1]['url'],
          'imageStandard': e['defaultPromoPanelRenderer']
                      ['largeFormFactorBackgroundThumbnail']
                  ['thumbnailLandscapePortraitRenderer']['landscape']
              ['thumbnails'][2]['url'],
          'imageMax': e['defaultPromoPanelRenderer']
                          ['largeFormFactorBackgroundThumbnail']
                      ['thumbnailLandscapePortraitRenderer']['landscape']
                  ['thumbnails']
              .last['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatHeadItems: $e');
      return List.empty();
    }
  }

  Future<Map?> formatVideo({
    required Map video,
    required String quality,
    Map? data,
    bool getUrl = true,
  }) async {
    try {
      if (video['duration'] == null) {
        Logger.root.warning('Video duration is null for ${video['id']}');
        return null;
      }
      
      List<String> allUrls = [];
      List<Map> urlsData = [];
      String finalUrl = '';
      String expireAt = '0';
      
      if (getUrl) {
        try {
          // Try yt-dlp first for authenticated URLs that bypass 403 errors
          final ytdlpData = await YtDlpService.instance.getAudioStream(video['id'].toString());
          
          if (ytdlpData != null && ytdlpData['url'] != null) {
            // yt-dlp success - use its URL
            finalUrl = ytdlpData['url'] as String;
            expireAt = ytdlpData['expire_at']?.toString() ?? '0';
            
            // Create urlsData in expected format for compatibility
            urlsData = [{
              'url': finalUrl,
              'expireAt': expireAt,
              'bitrate': ytdlpData['bitrate'] ?? 0,
              'codec': ytdlpData['codec'] ?? 'mp4',
              'size': ytdlpData['size'] ?? '0 MB',
              'quality': ytdlpData['quality'] ?? '',
            }];
            allUrls = [finalUrl];
            
            Logger.root.info('yt-dlp fetched URL for ${video['id']}');
          } else {
            Logger.root.severe('No URLs available for ${video['id']} - yt-dlp failed');
            return null;
          }
        } catch (e) {
          Logger.root.severe('Error fetching URLs for ${video['id']}: $e');
          // Return partial data without URLs if fetching fails
          finalUrl = '';
          expireAt = '0';
        }
      }
      
      // Helper to extract high quality thumbnail
      String extractThumbnail(Map video) {
        if (video['thumbnail'] != null && video['thumbnail'].toString().isNotEmpty) {
          return video['thumbnail'].toString();
        }
        if (video['thumbnails'] is List && (video['thumbnails'] as List).isNotEmpty) {
          return (video['thumbnails'] as List).last['url'].toString();
        }
        final id = video['id']?.toString() ?? video['videoId']?.toString();
        if (id != null && id.isNotEmpty) {
          return 'https://i.ytimg.com/vi/$id/maxresdefault.jpg';
        }
        return '';
      }

      final String thumbnailUrl = extractThumbnail(video);

      return {
        'id': video['id'],
        'album': (data?['album'] ?? '') != ''
            ? data!['album']
            : video['uploader'].toString().replaceAll('- Topic', '').trim(),
        'duration': video['duration'].toString(),
        'title':
            (data?['title'] ?? '') != '' ? data!['title'] : video['title'].toString().trim(),
        'artist': (data?['artist'] ?? '') != ''
            ? data!['artist']
            : video['uploader'].toString().replaceAll('- Topic', '').trim(),
        'image': thumbnailUrl,
        'secondImage': thumbnailUrl,
        'language': 'YouTube',
        'genre': 'YouTube',
        'expire_at': expireAt,
        'url': finalUrl,
        'allUrls': allUrls,
        'urlsData': urlsData,
        'year': '',
        '320kbps': 'false',
        'has_lyrics': 'false',
        'release_date': '',
        'album_id': '',
        'subtitle':
            (data?['subtitle'] ?? '') != '' ? data!['subtitle'] : video['uploader'],
        'perma_url': 'https://www.youtube.com/watch?v=${video['id']}',
      };
    } catch (e) {
      Logger.root.severe('Error formatting video ${video['id']}: $e');
      return null;
    }
  }

  Future<List<Map>> fetchSearchResults(String query) async {
    try {
      Logger.root.info('Searching YouTube for: $query');
      final List<Map<String, dynamic>> searchResults = await YtDlpService.instance.searchVideos(query);
      
      if (searchResults.isEmpty) {
        Logger.root.warning('No search results found for: $query');
        return [];
      }
      
      Logger.root.info('Found ${searchResults.length} search results');
      final List<Map> videoResult = [];
      
      for (final Map vid in searchResults) {
        try {
          final res = await formatVideo(
            video: vid, 
            quality: 'High', 
            getUrl: false,
          );
          if (res != null) {
            videoResult.add(res);
          }
        } catch (e) {
          Logger.root.warning('Failed to format video ${vid['id']}: $e');
          // Continue with other results even if one fails
          continue;
        }
      }
      
      return [
        {
          'title': 'Videos',
          'items': videoResult,
          'allowViewAll': false,
        }
      ];
    } catch (e) {
      Logger.root.severe('Error in fetchSearchResults for "$query": $e');
      return [];
    }
  }

  String getExpireAt(String url) {
    try {
      final match = RegExp(r'expire=(\d+)').firstMatch(url);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    } catch (e) {
      Logger.root.warning('Failed to extract expire time from URL: $e');
    }
    // Default to 5.5 hours from now if extraction fails
    final defaultExpire = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600 * 5.5;
    Logger.root.info('Using default expire time: $defaultExpire');
    return defaultExpire.toString();
  }
}
