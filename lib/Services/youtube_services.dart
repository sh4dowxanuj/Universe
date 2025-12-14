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
import 'dart:io';

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
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

  final YoutubeExplode yt = YoutubeExplode();

  YouTubeServices._privateConstructor();

  factory YouTubeServices() {
    return _instance;
  }

  static final YouTubeServices _instance =
      YouTubeServices._privateConstructor();

  static YouTubeServices get instance {
    return _instance;
  }

  Future<List<Video>> getPlaylistSongs(String id) async {
    final List<Video> results = await yt.playlists.getVideos(id).toList();
    return results;
  }

  Future<Video?> getVideoFromId(String id) async {
    try {
      final Video result = await yt.videos.get(id);
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
    final Video? vid = await getVideoFromId(id);
    if (vid == null) {
      return null;
    }
    final Map? response = await formatVideo(
      video: vid,
      quality: 'High', // FORCE HIGH QUALITY TEST (128 kbps MP4)
      // quality: Hive.box('settings')
      //     .get(
      //       'ytQuality',
      //       defaultValue: 'Low',
      //     )
      //     .toString(),
      data: data,
      getUrl: getUrl ?? true,
      // preferM4a: Hive.box(
      //         'settings')
      //     .get('preferM4a',
      //         defaultValue:
      //             true) as bool
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
        Video? videoInfo;
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
          result.addAll({
            'title': videoInfo.title,
            'artist': videoInfo.author.replaceAll('- Topic', '').trim(),
            'album': videoInfo.author.replaceAll('- Topic', '').trim(),
            'duration': videoInfo.duration?.inSeconds.toString() ?? '0',
            'image': videoInfo.thumbnails.maxResUrl,
            'secondImage': videoInfo.thumbnails.highResUrl,
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

  Future<Playlist> getPlaylistDetails(String id) async {
    final Playlist metadata = await yt.playlists.get(id);
    return metadata;
  }

  Future<Map<String, List>> getMusicHome() async {
    final appState = locator<AppStateService>();

    try {
      Logger.root.info('Fetching YouTube Music home using InnerTube API');

      // Update loading state
      appState.updateHomeData([], isLoading: true);

      // Try InnerTube API first
      final innerTubeResult = await InnerTubeService.instance.getMusicHome();
      if (innerTubeResult != null && innerTubeResult.isNotEmpty) {
        Logger.root.info('Successfully loaded YouTube Music home from InnerTube API');
        appState.updateHomeData((innerTubeResult['body'] as List<Map<dynamic, dynamic>>?) ?? []);
        return innerTubeResult;
      }

      Logger.root.info('InnerTube API failed, falling back to search-based approach');

      // Fallback to search-based approach
      final List<Map> sections = [];

      // Define popular music queries for fallback
      final queries = [
        'popular music',
        'trending songs',
        'top hits',
        'new releases',
      ];

      for (final query in queries.take(3)) {  // Limit to 3 sections for performance
        try {
          final searchResults = await fetchSearchResults(query);
          if (searchResults.isNotEmpty && searchResults[0]['items'] != null) {
            final items = searchResults[0]['items'] as List;
            if (items.isNotEmpty) {
              sections.add({
                'title': query,
                'playlists': items.take(10).toList(),
              });
            }
          }
        } catch (e) {
          Logger.root.warning('Failed to fetch section for query: $query', e);
        }
      }

      final result = {'body': sections, 'head': []};
      appState.updateHomeData(sections);
      return result;

    } catch (e, stackTrace) {
      final errorMessage = locator<ErrorService>().getErrorMessage(e);
      Logger.root.severe('Error in getMusicHome: $e\n$stackTrace');

      appState.updateHomeData([], error: errorMessage);
      locator<ErrorService>().reportError('YouTubeServices.getMusicHome', e, stackTrace);

      // Return empty result to prevent crashes
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
    required Video video,
    required String quality,
    Map? data,
    bool getUrl = true,
    // bool preferM4a = true,
  }) async {
    try {
      if (video.duration?.inSeconds == null) {
        Logger.root.warning('Video duration is null for ${video.id.value}');
        return null;
      }
      
      List<String> allUrls = [];
      List<Map> urlsData = [];
      String finalUrl = '';
      String expireAt = '0';
      
      if (getUrl) {
        try {
          // Try yt-dlp first for authenticated URLs that bypass 403 errors
          final ytdlpData = await YtDlpService.instance.getAudioStream(video.id.value);
          
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
            
            Logger.root.info('yt-dlp fetched URL for ${video.id.value}');
          } else {
            // yt-dlp failed - youtube_explode_dart is commented out (causes 403 errors)
            Logger.root.severe('No URLs available for ${video.id.value} - yt-dlp failed');
            return null;
            
            /* COMMENTED OUT - youtube_explode_dart causes 403 errors
            // yt-dlp failed, fallback to youtube_explode_dart
            print('⚠️ Search: yt-dlp failed, trying youtube_explode_dart fallback');
            urlsData = await getYtStreamUrls(video.id.value);
            
            if (urlsData.isEmpty) {
              Logger.root.severe('No URLs available for ${video.id.value}');
              return null;
            }
            
            // Select appropriate stream based on quality
            Map? finalUrlData;
            if (quality == 'High') {
              final mp4Streams = urlsData.where((s) => s['codec'] == 'mp4').toList();
              if (mp4Streams.isNotEmpty) {
                finalUrlData = mp4Streams.last;
                print('Selected HIGH quality MP4: ${finalUrlData['bitrate']} kbps, ${finalUrlData['size']} MB');
              } else {
                finalUrlData = urlsData.last;
                print('Selected HIGH quality (no MP4): ${finalUrlData['bitrate']} kbps, ${finalUrlData['size']} MB');
              }
            } else {
              final mp4Streams = urlsData.where((s) => s['codec'] == 'mp4').toList();
              if (mp4Streams.length > 1) {
                finalUrlData = mp4Streams[mp4Streams.length ~/ 2];
                print('Selected MEDIUM quality MP4: ${finalUrlData['bitrate']} kbps, ${finalUrlData['size']} MB');
              } else if (mp4Streams.isNotEmpty) {
                finalUrlData = mp4Streams.first;
                print('Selected LOW quality MP4: ${finalUrlData['bitrate']} kbps, ${finalUrlData['size']} MB');
              } else {
                finalUrlData = urlsData.first;
                print('Selected fallback stream: ${finalUrlData['bitrate']} kbps, ${finalUrlData['size']} MB');
              }
            }
            
            finalUrl = finalUrlData['url'].toString();
            expireAt = finalUrlData['expireAt'].toString();
            allUrls = urlsData.map((e) => e['url'].toString()).toList();
            
            Logger.root.info('youtube_explode_dart fetched ${urlsData.length} URLs for ${video.id.value}');
            */
          }
        } catch (e) {
          Logger.root.severe('Error fetching URLs for ${video.id.value}: $e');
          // Return partial data without URLs if fetching fails
          finalUrl = '';
          expireAt = '0';
        }
      }
      
      return {
        'id': video.id.value,
        'album': (data?['album'] ?? '') != ''
            ? data!['album']
            : video.author.replaceAll('- Topic', '').trim(),
        'duration': video.duration?.inSeconds.toString(),
        'title':
            (data?['title'] ?? '') != '' ? data!['title'] : video.title.trim(),
        'artist': (data?['artist'] ?? '') != ''
            ? data!['artist']
            : video.author.replaceAll('- Topic', '').trim(),
        'image': video.thumbnails.maxResUrl,
        'secondImage': video.thumbnails.highResUrl,
        'language': 'YouTube',
        'genre': 'YouTube',
        'expire_at': expireAt,
        'url': finalUrl,
        'allUrls': allUrls,
        'urlsData': urlsData,
        'year': video.uploadDate?.year.toString(),
        '320kbps': 'false',
        'has_lyrics': 'false',
        'release_date': video.publishDate.toString(),
        'album_id': video.channelId.value,
        'subtitle':
            (data?['subtitle'] ?? '') != '' ? data!['subtitle'] : video.author,
        'perma_url': video.url,
      };
    } catch (e) {
      Logger.root.severe('Error formatting video ${video.id.value}: $e');
      return null;
    }
    // For invidous
    // if (video['liveNow'] == true) return null;
    // try {
    //   final Uri link = Uri.https(
    //     'invidious.snopyta.org',
    //     'api/v1/videos/${video["videoId"]}',
    //   );
    //   final Response response = await get(link, headers: headers);
    //   if (response.statusCode != 200) {
    //     return {};
    //   }
    //   final jsonData = jsonDecode(response.body) as Map;
    //   final urls = (jsonData['adaptiveFormats'] as List)
    //       .where((e) => e['container'] == 'm4a');

    //   return {
    //     'id': jsonData['videoId'],
    //     'album': jsonData['author'],
    //     'duration': jsonData['lengthSeconds'],
    //     'title': jsonData['title'],
    //     'artist': jsonData['author'],
    //     'image': jsonData['videoThumbnails'][0]['url'],
    //     'secondImage': jsonData['videoThumbnails'][2]?['url'],
    //     'language': 'YouTube',
    //     'genre': 'YouTube',
    //     'url':
    //         'https://yewtu.be/latest_version?id=${video["videoId"]}&itag=${quality == "High" ? 140 : 139}&local=true&listen=1',
    //     'lowUrl':
    //         'https://yewtu.be/latest_version?id=09cZRYupO4s&itag=139&local=true&listen=1',
    //     'highUrl':
    //         'https://yewtu.be/latest_version?id=09cZRYupO4s&itag=140&local=true&listen=1',
    //     'year': jsonData['published'].toString().yearFromEpoch,
    //     '320kbps': 'false',
    //     'has_lyrics': 'false',
    //     'release_date': jsonData['published'].toString().dateFromEpoch,
    //     'album_id': jsonData['authorId'].toString(),
    //     'artist_id': jsonData['authorId'].toString(),
    //     'subtitle': jsonData['author'],
    //     'perma_url': 'https://youtube.com/watch?v=${jsonData["videoId"]}',
    //   };
    // } catch (e) {
    //   return {};
    // }
  }

  Future<List<Map>> fetchSearchResults(String query) async {
    try {
      Logger.root.info('Searching YouTube for: $query');
      final List<Video> searchResults = await yt.search.search(query);
      
      if (searchResults.isEmpty) {
        Logger.root.warning('No search results found for: $query');
        return [];
      }
      
      Logger.root.info('Found ${searchResults.length} search results');
      final List<Map> videoResult = [];
      
      for (final Video vid in searchResults) {
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
          Logger.root.warning('Failed to format video ${vid.id.value}: $e');
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
    // return searchResults;

    // For parsing html
    // Uri link = Uri.https(searchAuthority, searchPath, {"search_query": query});
    // final Response response = await get(link);
    // if (response.statusCode != 200) {
    // return [];
    // }
    // List searchResults = RegExp(
    // r'\"videoId\"\:\"(.*?)\",\"thumbnail\"\:\{\"thumbnails\"\:\[\{\"url\"\:\"(.*?)".*?\"title\"\:\{\"runs\"\:\[\{\"text\"\:\"(.*?)\"\}\].*?\"longBylineText\"\:\{\"runs\"\:\[\{\"text\"\:\"(.*?)\",.*?\"lengthText\"\:\{\"accessibility\"\:\{\"accessibilityData\"\:\{\"label\"\:\"(.*?)\"\}\},\"simpleText\"\:\"(.*?)\"\},\"viewCountText\"\:\{\"simpleText\"\:\"(.*?) views\"\}.*?\"commandMetadata\"\:\{\"webCommandMetadata\"\:\{\"url\"\:\"(/watch?.*?)\".*?\"shortViewCountText\"\:\{\"accessibility\"\:\{\"accessibilityData\"\:\{\"label\"\:\"(.*?) views\"\}\},\"simpleText\"\:\"(.*?) views\"\}.*?\"channelThumbnailSupportedRenderers\"\:\{\"channelThumbnailWithLinkRenderer\"\:\{\"thumbnail\"\:\{\"thumbnails\"\:\[\{\"url\"\:\"(.*?)\"')
    // .allMatches(response.body)
    // .map((m) {
    // List<String> parts = m[6].toString().split(':');
    // int dur;
    // if (parts.length == 3)
    // dur = int.parse(parts[0]) * 60 * 60 +
    // int.parse(parts[1]) * 60 +
    // int.parse(parts[2]);
    // if (parts.length == 2)
    // dur = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    // if (parts.length == 1) dur = int.parse(parts[0]);

    // return {
    //   'id': m[1],
    //   'image': m[2],
    //   'title': m[3],
    //     'longLength': m[5],
    //     'length': m[6],
    //     'totalViewsCount': m[7],
    //     'url': 'https://www.youtube.com' + m[8],
    //     'album': '',
    //     'channelName': m[4],
    //     'channelImage': m[11],
    //     'duration': dur.toString(),
    //     'longViews': m[9] + ' views',
    //     'views': m[10] + ' views',
    //     'artist': '',
    //     "year": '',
    //     "language": '',
    //     "320kbps": '',
    //     "has_lyrics": '',
    //     "release_date": '',
    //     "album_id": '',
    //     'subtitle': '',
    //   };
    // }).toList();
    // For invidous
    // try {
    //   final Uri link =
    //       Uri.https('invidious.snopyta.org', 'api/v1/search', {'q': query});
    //   final Response response = await get(link, headers: headers);
    //   if (response.statusCode != 200) {
    //     return [];
    //   }
    //   return jsonDecode(response.body) as List;
    // } catch (e) {
    //   return [];
    // }
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

  Future<List<Map>> getYtStreamUrls(String videoId) async {
    try {
      List<Map> urlData = [];

      // ALWAYS fetch fresh URLs (don't use cache) to avoid 403 errors
      // YouTube URLs expire quickly and cached URLs often fail
      Logger.root.info('Fetching FRESH stream URLs for $videoId (bypassing cache)');
      urlData = await getUri(videoId);

      if (urlData.isEmpty) {
        Logger.root.warning('No URLs fetched for $videoId, checking cache as fallback');
        // Only use cache if fresh fetch completely fails
        if (Hive.box('ytlinkcache').containsKey(videoId)) {
          final cachedData = Hive.box('ytlinkcache').get(videoId);
          if (cachedData is List && cachedData.isNotEmpty) {
            Logger.root.info('Using cached URLs for $videoId as fallback');
            urlData = cachedData as List<Map>;
          }
        }
      }

      // Update cache with fresh URLs for future fallback use
      if (urlData.isNotEmpty) {
        try {
          await Hive.box('ytlinkcache')
              .put(videoId, urlData)
              .onError(
                (error, stackTrace) => Logger.root.severe(
                  'Hive Error updating cache for $videoId: $error',
                ),
              );
          Logger.root.info('Cache updated with ${urlData.length} fresh URLs for $videoId');
        } catch (e) {
          Logger.root.severe('Error updating cache for $videoId: $e');
        }
      }

      return urlData;
    } catch (e) {
      Logger.root.severe('Error in getYtStreamUrls for $videoId: $e');
      return [];
    }
  }

  Future<List<Map>> getUri(
    String videoId,
    // {bool preferM4a = true}
  ) async {
    final List<AudioOnlyStreamInfo> sortedStreamInfo =
        await getStreamInfo(videoId);
    
    
    final result = sortedStreamInfo
        .map(
          (e) {
            return {
              'bitrate': e.bitrate.kiloBitsPerSecond.round().toString(),
              'codec': e.codec.subtype,
              'qualityLabel': e.qualityLabel,
              'size': e.size.totalMegaBytes.toStringAsFixed(2),
              'url': e.url.toString(),
              'expireAt': getExpireAt(e.url.toString()),
            };
          },
        )
        .toList();
    
    return result;
  }

  Future<List<AudioOnlyStreamInfo>> getStreamInfo(
    String videoId, {
    bool onlyMp4 = false,
  }) async {
    try {
      Logger.root.info('Fetching stream manifest for video: $videoId');
      final StreamManifest manifest =
          await yt.videos.streamsClient.getManifest(VideoId(videoId));
      
      if (manifest.audioOnly.isEmpty) {
        Logger.root.severe('No audio streams available for $videoId');
        throw Exception('No audio streams available for this video');
      }
      
      final List<AudioOnlyStreamInfo> sortedStreamInfo = manifest.audioOnly
          .toList()
        ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
      
      Logger.root.info(
        'Found ${sortedStreamInfo.length} audio streams for $videoId',
      );
      
      // Prefer M4A/MP4 codec for iOS/macOS for better compatibility
      if (onlyMp4 || Platform.isIOS || Platform.isMacOS) {
        final List<AudioOnlyStreamInfo> m4aStreams = sortedStreamInfo
            .where((element) => 
              element.audioCodec.contains('mp4') || 
              element.audioCodec.contains('m4a'),
            )
            .toList();

        if (m4aStreams.isNotEmpty) {
          Logger.root.info(
            'Using ${m4aStreams.length} M4A streams for compatibility',
          );
          return m4aStreams;
        }
      }

      return sortedStreamInfo;
    } catch (e) {
      Logger.root.severe('Error fetching stream info for $videoId: $e');
      rethrow;
    }
  }

  Stream<List<int>> getStreamClient(
    AudioOnlyStreamInfo streamInfo,
  ) {
    return yt.videos.streamsClient.get(streamInfo);
  }
}
