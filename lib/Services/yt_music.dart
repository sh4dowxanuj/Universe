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

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:universe/Models/song_item.dart';
import 'package:universe/Services/ytdlp_service.dart';
import 'package:universe/Services/ytmusic/nav.dart';
import 'package:universe/Services/ytmusic/playlist.dart';

class YtMusicService {
  static const ytmDomain = 'music.youtube.com';
  static const httpsYtmDomain = 'https://music.youtube.com';
  static const baseApiEndpoint = '/youtubei/v1/';
  static const ytmParams = {
    'alt': 'json',
    'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
  };
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0';
  static const Map<String, String> endpoints = {
    'search': 'search',
    'browse': 'browse',
    'get_song': 'player',
    'get_playlist': 'playlist',
    'get_album': 'album',
    'get_artist': 'artist',
    'get_video': 'video',
    'get_channel': 'channel',
    'get_lyrics': 'lyrics',
    'search_suggestions': 'music/get_search_suggestions',
    'next': 'next',
  };
  static const filters = [
    'albums',
    'artists',
    'playlists',
    'community_playlists',
    'featured_playlists',
    'songs',
    'videos',
  ];
  static const scopes = ['library', 'uploads'];

  Map<String, String>? headers;
  int? signatureTimestamp;
  Map<String, dynamic>? context;

  static final YtMusicService _singleton = YtMusicService._internal();

  factory YtMusicService() {
    return _singleton;
  }

  YtMusicService._internal();

  Map<String, String> initializeHeaders() {
    return {
      'user-agent': userAgent,
      'accept': '*/*',
      'accept-encoding': 'gzip, deflate',
      'content-type': 'application/json',
      'content-encoding': 'gzip',
      'origin': httpsYtmDomain,
      'cookie': 'CONSENT=YES+1',
    };
  }

  Future<Response> sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    final Uri uri = Uri.https(url);
    final Response response = await get(uri, headers: headers);
    return response;
  }

  Future<String?> getVisitorId(Map<String, String>? headers) async {
    final response = await sendGetRequest(ytmDomain, headers);
    final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
    final matches = reg.firstMatch(response.body);
    String? visitorId;
    if (matches != null) {
      final ytcfg = json.decode(matches.group(1).toString());
      visitorId = ytcfg['VISITOR_DATA']?.toString();
    }
    return visitorId;
  }

  Map<String, dynamic> initializeContext() {
    final DateTime now = DateTime.now();
    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String date = year + month + day;
    return {
      'context': {
        'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.$date.01.00'},
        'user': {},
      },
    };
  }

  Future<Map> sendRequest(
    String endpoint,
    Map body,
    Map<String, String>? headers,
  ) async {
    final Uri uri = Uri.https(ytmDomain, baseApiEndpoint + endpoint, ytmParams);
    final response = await post(uri, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map;
    } else {
      Logger.root
          .severe('YtMusic returned ${response.statusCode}', response.body);
      Logger.root.info('Requested endpoint: $uri');
      return {};
    }
  }

  String? getParam2(String filter) {
    final filterParams = {
      'songs': 'I',
      'videos': 'Q',
      'albums': 'Y',
      'artists': 'g',
      'playlists': 'o',
    };
    return filterParams[filter];
  }

  String? getSearchParams({
    String? filter,
    String? scope,
    bool ignoreSpelling = false,
  }) {
    String? params;
    String? param1;
    String? param2;
    String? param3;
    if (!ignoreSpelling && filter == null && scope == null) {
      return params;
    }

    if (scope == 'uploads') {
      params = 'agIYAw%3D%3D';
    }

    if (scope == 'library') {
      if (filter != null) {
        param1 = 'EgWKAQI';
        param2 = getParam2(filter);
        param3 = 'AWoKEAUQCRADEAoYBA%3D%3D';
      } else {
        params = 'agIYBA%3D%3D';
      }
    }

    if (scope == null && filter != null) {
      if (filter == 'playlists') {
        params = 'Eg-KAQwIABAAGAAgACgB';
        if (!ignoreSpelling) {
          params += 'MABqChAEEAMQCRAFEAo%3D';
        } else {
          params += 'MABCAggBagoQBBADEAkQBRAK';
        }
      } else {
        if (filter.contains('playlists')) {
          param1 = 'EgeKAQQoA';
          if (filter == 'featured_playlists') {
            param2 = 'Dg';
          } else {
            // community_playlists
            param2 = 'EA';
          }

          if (!ignoreSpelling) {
            param3 = 'BagwQDhAKEAMQBBAJEAU%3D';
          } else {
            param3 = 'BQgIIAWoMEA4QChADEAQQCRAF';
          }
        } else {
          param1 = 'EgWKAQI';
          param2 = getParam2(filter);
          if (!ignoreSpelling) {
            param3 = 'AWoMEA4QChADEAQQCRAF';
          } else {
            param3 = 'AUICCAFqDBAOEAoQAxAEEAkQBQ%3D%3D';
          }
        }
      }
    }

    if (scope == null && filter == null && ignoreSpelling) {
      params = 'EhGKAQ4IARABGAEgASgAOAFAAUICCAE%3D';
    }

    if (params != null) {
      return params;
    } else {
      if (param1 == null && param2 == null && param3 == null) {
        return null;
      }
      return '${param1 ?? ""}${param2 ?? ""}${param3 ?? ""}';
    }
  }

  Future<void> init() async {
    headers = initializeHeaders();
    if (!headers!.containsKey('X-Goog-Visitor-Id')) {
      headers!['X-Goog-Visitor-Id'] = await getVisitorId(headers) ?? '';
    }
    context = initializeContext();
    context!['context']['client']['hl'] = 'en';
  }

  Future<List<Map>> search(
    String query, {
    String? scope,
    bool ignoreSpelling = false,
    String? filter,
  }) async {
    if (headers == null) {
      await init();
    }
    try {
      final body = Map.from(context!);
      body['query'] = query;
      final params = getSearchParams(
        filter: filter,
        scope: scope,
        ignoreSpelling: ignoreSpelling,
      );
      if (params != null) {
        body['params'] = params;
      }
      final List<Map> searchResults = [];
      final res = await sendRequest(endpoints['search']!, body, headers);
      if (!res.containsKey('contents')) {
        Logger.root.info('YtMusic returned no contents');
        return List.empty();
      }

      Map<String, dynamic> results = {};

      if ((res['contents'] as Map).containsKey('tabbedSearchResultsRenderer')) {
        final tabIndex =
            (scope == null || filter != null) ? 0 : scopes.indexOf(scope) + 1;
        results = NavClass.nav(res, [
          'contents',
          'tabbedSearchResultsRenderer',
          'tabs',
          tabIndex,
          'tabRenderer',
          'content',
        ]) as Map<String, dynamic>;
      } else {
        Logger.root.info('tabbedSearchResultsRenderer not found');
        results = res['contents'] as Map<String, dynamic>;
      }

      final List finalResults =
          NavClass.nav(results, ['sectionListRenderer', 'contents']) as List? ??
              [];
      for (final sectionItem in finalResults) {
        final bool containsHeader =
            (sectionItem as Map).containsKey('musicCardShelfRenderer');
        final sectionSearchResults = [];
        final String sectionSelfRenderer =
            containsHeader ? 'musicCardShelfRenderer' : 'musicShelfRenderer';

        final String sectionTitle = NavClass.joinRunTexts(
          NavClass.nav(sectionItem, [
            sectionSelfRenderer,
            ...NavClass.titleRuns,
          ]) as List?,
        );

        final String sectionHeader = NavClass.joinRunTexts(
          NavClass.nav(sectionItem, [
            sectionSelfRenderer,
            ...NavClass.headerCardShelf,
            ...NavClass.titleRuns,
          ]) as List?,
        );

        if (containsHeader) {
          Logger.root.info('This search contains header');
          final res = parseInfoFromSubtitle(
            sectionItem,
            titleNavPath: [sectionSelfRenderer, ...NavClass.titleRuns],
            subtitleNavPath: [sectionSelfRenderer, ...NavClass.subtitleRuns],
            imageNavPath: [sectionSelfRenderer, ...NavClass.thumbnails],
            idNavPath: [
              sectionSelfRenderer,
              ...NavClass.titleRun,
              ...NavClass.navigationVideoId,
            ],
            idNavPath2: [
              sectionSelfRenderer,
              ...NavClass.titleRun,
              ...NavClass.navigationBrowseId,
            ],
          );
          if (res != null) sectionSearchResults.add(res);
        }

        final List sectionChildItems =
            NavClass.nav(sectionItem, [sectionSelfRenderer, 'contents'])
                    as List? ??
                [];

        for (final childItem in sectionChildItems) {
          final res = parseInfoFromSubtitle(childItem as Map);
          if (res != null) sectionSearchResults.add(res);
        }
        if (sectionSearchResults.isNotEmpty) {
          searchResults.add({
            'title': sectionHeader != '' ? sectionHeader : sectionTitle,
            'items': sectionSearchResults,
          });
        }
      }
      return searchResults;
    } catch (e) {
      Logger.root.severe('Error in yt search', e);
      return List.empty();
    }
  }

  Future<List<SongItem>> searchSongs(
    String query, {
    bool ignoreSpelling = false,
  }) async {
    if (headers == null) {
      await init();
    }
    try {
      final searchResults = await search(
        query,
        ignoreSpelling: ignoreSpelling,
        filter: 'songs',
      );
      final List<SongItem> songs = [];
      for (final section in searchResults) {
        if (section['title'] != 'Songs') {
          continue;
        }
        final dynamic items = section['items'];
        if (items is List) {
          for (final item in items) {
            item['permaUrl'] = 'https://youtube.com/watch?v=${item["id"]}';
            final songItem = SongItem.fromMap(item as Map);
            songs.add(songItem);
          }
        }
      }
      return songs;
    } catch (e) {
      Logger.root.severe('Error in yt song search', e);
      return List.empty();
    }
  }

  Future<List<String>> getSearchSuggestions({
    required String query,
    String? scope,
    bool ignoreSpelling = false,
    String? filter = 'songs',
  }) async {
    if (headers == null) {
      await init();
    }
    try {
      final body = Map.from(context!);
      body['input'] = query;
      final Map response =
          await sendRequest(endpoints['search_suggestions']!, body, headers);
      final List finalResult = NavClass.nav(response, [
            'contents',
            0,
            'searchSuggestionsSectionRenderer',
            'contents',
          ]) as List? ??
          [];
      final List<String> results = [];
      for (final item in finalResult) {
        results.add(
          NavClass.nav(item, [
            'searchSuggestionRenderer',
            'NavClass.navigationEndpoint',
            'searchEndpoint',
            'query',
          ]).toString(),
        );
      }
      return results;
    } catch (e) {
      Logger.root.severe('Error in yt search suggestions', e);
      return List.empty();
    }
  }

  Map? parseInfoFromSubtitle(
    Map childItem, {
    List? idNavPath,
    List? idNavPath2,
    List? imageNavPath,
    List? titleNavPath,
    List? subtitleNavPath,
  }) {
    final List images = NavClass.runUrls(
      NavClass.nav(
        childItem,
        imageNavPath ?? [NavClass.mRLIR, ...NavClass.thumbnails],
      ) as List?,
    );
    final String title = NavClass.joinRunTexts(
      NavClass.nav(
        childItem,
        titleNavPath ??
            [...NavClass.mRLIRFlex, 0, NavClass.mRLIFCR, ...NavClass.textRuns],
      ) as List?,
    );
    final String subtitle = NavClass.joinRunTexts(
      NavClass.nav(
        childItem,
        subtitleNavPath ??
            [...NavClass.mRLIRFlex, 1, NavClass.mRLIFCR, ...NavClass.textRuns],
      ) as List?,
    );

    if (title == '' && subtitle == '') return null;

    final List<String> subtitleList = subtitle.split('•');
    String type = subtitleList.first.trim();
    if (![
      'song',
      'video',
      'single',
      'album',
      'playlist',
      'artist',
      'profile',
    ].contains(type.toLowerCase())) {
      type = 'Song';
      subtitleList.insert(0, 'Song');
    }

    final List idNav = (type == 'Song' || type == 'Video')
        ? NavClass.mrlirPlaylistId
        : NavClass.mrlirBrowseId;
    final String? id =
        NavClass.nav(childItem, idNavPath ?? idNav)?.toString() ??
            NavClass.nav(childItem, idNavPath2 ?? idNav)?.toString();

    if (id == null) {
      Logger.root.info('Unable to get id for $title of type $type');
      Logger.root.info('Child item: $childItem');
    }

    final Map result = {};
    result['id'] = id;
    result['type'] = type;
    result['title'] = title;
    result['images'] = images;
    result['image'] = images.isEmpty ? '' : images.first;
    result['subtitle'] = subtitle;
    final len = subtitleList.length;

    switch (type) {
      case 'Artist':
        if (len > 1) result['subscribers'] = subtitleList[1].trim();
        result['artist'] = title;
      case 'Song':
        if (len > 1) result['artist'] = subtitleList[1].trim();
        if (len > 2) result['album'] = subtitleList[2].trim();
        if (len > 3) result['duration'] = subtitleList[3].trim();
      case 'Video':
        if (len > 1) result['artist'] = subtitleList[1].trim();
        if (len > 2) result['views'] = subtitleList[2].trim();
        if (len > 3) result['duration'] = subtitleList[3].trim();
      case 'Album':
      case 'Single':
        if (len > 1) result['artist'] = subtitleList[1].trim();
        if (len > 2) result['year'] = subtitleList[2].trim();
      case 'Playlist':
        if (len > 1) result['artist'] = subtitleList[1].trim();
        if (len > 2) result['views'] = subtitleList[2].trim();
      default:
        break;
    }

    return result;
  }

  int getDatestamp() {
    final DateTime now = DateTime.now();
    final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final Duration difference = now.difference(epoch);
    final int days = difference.inDays;
    return days;
  }

  Future<Map> getSongData({
    required String videoId,
    Map? data,
    bool getUrl = true,
    String quality = 'Low',
  }) async {
    if (headers == null) {
      await init();
    }
    try {
      signatureTimestamp = signatureTimestamp ?? getDatestamp() - 1;
      final body = Map.from(context!);
      body['playbackContext'] = {
        'contentPlaybackContext': {'signatureTimestamp': signatureTimestamp},
      };
      body['video_id'] = videoId;
      
      Logger.root.info('Fetching song data for video: $videoId');
      final Map response =
          await sendRequest(endpoints['get_song']!, body, headers);
      
      if (response.isEmpty) {
        Logger.root.warning('Empty response from YTMusic for $videoId');
        return {
          'error': 'No data found for this video. Please try another track.',
        };
      }

      final videoDetails =
          await NavClass.nav(response, ['videoDetails']) as Map?;

      if (videoDetails == null) {
        Logger.root.warning('No video details found for $videoId');
        return {
          'error': 'No video details found. The track may be unavailable.',
        };
      }
      
      List<String> urls = [];
      List<Map> urlsData = [];
      String finalUrl = '';
      String expireAt = '0';
      
      if (getUrl) {
        try {
          // Use yt-dlp instead of youtube_explode_dart to avoid 403 errors
          Logger.root.info('YTMusic: Fetching stream URL using yt-dlp for $videoId (quality: $quality)');
          final ytdlpData = await YtDlpService.instance.getAudioStream(videoId, quality: quality);
          
          if (ytdlpData != null && ytdlpData['url'] != null) {
            finalUrl = ytdlpData['url'] as String;
            expireAt = ytdlpData['expire_at']?.toString() ?? '0';
            
            // Create urlsData in expected format
            urlsData = [{
              'url': finalUrl,
              'expireAt': expireAt,
              'bitrate': ytdlpData['bitrate'] ?? 0,
              'codec': ytdlpData['codec'] ?? 'mp4',
            }];
            urls = [finalUrl];
            
            Logger.root.info('YTMusic: yt-dlp SUCCESS - Got stream URL');
          } else {
            Logger.root.warning('YTMusic: yt-dlp failed for $videoId');
          }
          
        } catch (e) {
          Logger.root.severe('YTMusic: Error fetching stream URL for $videoId: $e');
          return {
            'error': 'Failed to fetch stream URL. Please check your connection or try another track.',
          };
        }
      }

      return {
        'id': videoDetails['videoId'],
        'title': videoDetails['title'],
        'album': (data?['album'] ?? '') != ''
            ? data!['album']
            : videoDetails['album'] ?? '',
        'artist': (data?['artist'] ?? '') != ''
            ? data!['artist']
            : videoDetails['author'].replaceAll('- Topic', '').trim(),
        'duration': videoDetails['lengthSeconds'],
        'views': videoDetails['viewCount'],
        'image': videoDetails['thumbnail']['thumbnails'].last['url'],
        'images': videoDetails['thumbnail']['thumbnails'].map((e) => e['url']),
        'language': 'YouTube',
        'genre': 'YouTube',
        'channelId': videoDetails['channelId'],
        'expire_at': expireAt,
        'url': finalUrl,
        'urls': urls,
        'urlsData': urlsData,
        '320kbps': 'false',
        'has_lyrics': 'false',
        'album_id': videoDetails['channelId'],
        'subtitle': (data?['subtitle'] ?? '') != ''
            ? data!['subtitle']
            : videoDetails['author'],
        'perma_url': 'https://youtube.com/watch?v=$videoId',
      };
    } catch (e) {
      Logger.root.severe('Error in yt get song data for $videoId: $e');
      return {
        'error': 'Unexpected error occurred. Please try again.',
      };
    }
  }

  Future<Map> getPlaylistDetails(String playlistId) async {
    if (headers == null) {
      await init();
    }
    try {
      Logger.root.info('YTMusic: Getting playlist details for $playlistId');
      
      final browseId = (playlistId.startsWith('PL') || 
                        playlistId.startsWith('RD') || 
                        playlistId.startsWith('VL') || 
                        playlistId.startsWith('MPRE')) 
                        ? playlistId 
                        : 'VL$playlistId';
      
      final body = Map.from(context!);
      body['browseId'] = browseId;
      
      final Map response = await sendRequest(endpoints['browse']!, body, headers);
      
      if (response.isEmpty) {
        Logger.root.warning('YTMusic: Empty response for playlist $browseId');
        return {};
      }

      // Try various paths for the header
      final header = NavClass.nav(response, ['header', 'musicDetailHeaderRenderer']) ??
                     NavClass.nav(response, ['header', 'musicImmersiveHeaderRenderer']) ??
                     NavClass.nav(response, ['contents', 'twoColumnBrowseResultsRenderer', 'header', 'musicDetailHeaderRenderer']) ??
                     NavClass.nav(response, ['contents', 'singleColumnBrowseResultsRenderer', 'header', 'musicDetailHeaderRenderer']) ??
                     NavClass.nav(response, ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'musicPlaylistShelfRenderer', 'header', 'musicPlaylistShelfHeaderRenderer']);

      String? heading = NavClass.nav(header, ['title', 'runs', 0, 'text'])?.toString() ??
                        NavClass.nav(header, ['title', 'simpleText'])?.toString();
      
      // Fallback: Try top-level response metadata or microformat
      heading ??= NavClass.nav(response, ['metadata', 'playlistMetadataRenderer', 'title'])?.toString() ??
                  NavClass.nav(response, ['microformat', 'microformatDataRenderer', 'title'])?.toString();
      
      final String subtitle = (NavClass.nav(header, ['subtitle', 'runs']) as List? ??
                              NavClass.nav(header, ['description', 'runs']) as List? ??
                              [])
          .map((e) => e['text'])
          .toList()
          .join();
          
      final String? description = NavClass.nav(header, ['description', 'runs', 0, 'text'])?.toString();
      
      final List images = NavClass.runUrls(
        NavClass.nav(header, ['thumbnail', 'croppedSquareThumbnailRenderer', 'thumbnail', 'thumbnails']) as List? ??
        NavClass.nav(header, ['thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails']) as List? ??
        NavClass.nav(header, ['thumbnails']) as List? ??
        NavClass.nav(response, ['metadata', 'playlistMetadataRenderer', 'thumbnail', 'thumbnails']) as List? ??
        NavClass.nav(response, ['microformat', 'microformatDataRenderer', 'thumbnail', 'thumbnails']) as List? ??
        [],
      );

      List? finalResults;
      final List<List<dynamic>> paths = [
        ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents', 0, 'musicPlaylistShelfRenderer', 'contents'],
        ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents', 0, 'musicShelfRenderer', 'contents'],
        ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'musicPlaylistShelfRenderer', 'contents'],
        ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'musicShelfRenderer', 'contents'],
        ['contents', 'sectionListRenderer', 'contents', 0, 'musicPlaylistShelfRenderer', 'contents'],
        ['contents', 'twoColumnBrowseResultsRenderer', 'secondaryContents', 'sectionListRenderer', 'contents', 0, 'musicPlaylistShelfRenderer', 'contents'],
        ['contents', 'twoColumnBrowseResultsRenderer', 'secondaryContents', 'sectionListRenderer', 'contents', 0, 'musicShelfRenderer', 'contents'],
      ];

      for (final path in paths) {
        final res = NavClass.nav(response, path);
        if (res is List && res.isNotEmpty) {
          finalResults = res;
          Logger.root.info('YTMusic: Found ${res.length} songs using path: $path');
          break;
        }
      }
      
      finalResults ??= [];

      final List<Map> songResults = [];
      for (final item in finalResults) {
        final Map? mRLIR = item['musicResponsiveListItemRenderer'] as Map?;
        if (mRLIR == null) continue;

        final String videoId = NavClass.nav(mRLIR, ['playlistItemData', 'videoId'])?.toString() ?? 
                              NavClass.nav(mRLIR, NavClass.navigationVideoId)?.toString() ?? '';
        
        if (videoId.isEmpty || videoId == 'null') continue;

        final String title = NavClass.joinRunTexts(
          NavClass.nav(mRLIR, ['flexColumns', 0, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']) as List?,
        );
        
        final String subtitleText = NavClass.joinRunTexts(
          NavClass.nav(mRLIR, ['flexColumns', 1, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']) as List?,
        );

        final List thumbnails = NavClass.runUrls(
          NavClass.nav(mRLIR, NavClass.thumbnails) as List? ??
          NavClass.nav(mRLIR, NavClass.thumbnailRenderer) as List?,
        );

        final List<String> subtitleList = subtitleText.split('•');
        final String artist = subtitleList.isNotEmpty ? subtitleList[0].trim() : '';
        final String album = subtitleList.length > 1 ? subtitleList[1].trim() : '';
        final String duration = subtitleList.length > 2 ? subtitleList[2].trim() : '';

        songResults.add({
          'id': videoId,
          'type': 'song',
          'title': title,
          'artist': artist,
          'album': album,
          'duration': duration,
          'subtitle': subtitleText,
          'image': thumbnails.isNotEmpty ? thumbnails.last : '',
          'secondImage': thumbnails.isNotEmpty ? thumbnails.last : '',
          'images': thumbnails,
          'perma_url': 'https://youtube.com/watch?v=$videoId',
        });
      }
      
      return {
        'songs': songResults,
        'name': heading ?? 'Unknown Playlist',
        'subtitle': subtitle,
        'description': description,
        'images': images,
        'id': playlistId,
        'type': 'playlist',
      };
    } catch (e, st) {
      Logger.root.severe('Error in ytmusic getPlaylistDetails', e, st);
      return {};
    }
  }

  Future<Map> getAlbumDetails(String albumId) async {
    if (headers == null) {
      await init();
    }
    try {
      Logger.root.info('YTMusic: Getting album details for $albumId');
      final body = Map.from(context!);
      body['browseId'] = albumId;
      final Map response =
          await sendRequest(endpoints['browse']!, body, headers);
          
      if (response.isEmpty) {
        Logger.root.warning('YTMusic: Empty response for album $albumId');
        return {};
      }

      final header = NavClass.nav(response, NavClass.headerDetail) ??
                     NavClass.nav(response, NavClass.immersiveHeaderDetail);

      final String? heading = NavClass.nav(header, NavClass.titleText) as String? ??
                             NavClass.nav(header, ['title', 'runs', 0, 'text']) as String?;

      final String subtitle = NavClass.joinRunTexts(
        NavClass.nav(header, NavClass.subtitleRuns) as List? ?? [],
      );

      final String description = NavClass.joinRunTexts(
        NavClass.nav(header, NavClass.secondSubtitleRuns) as List? ?? [],
      );

      final List images = NavClass.runUrls(
        NavClass.nav(header, NavClass.thumbnailCropped) as List? ??
        NavClass.nav(header, NavClass.thumbnails) as List? ??
        NavClass.nav(response, ['metadata', 'playlistMetadataRenderer', 'thumbnail', 'thumbnails']) as List? ??
        NavClass.nav(response, ['microformat', 'microformatDataRenderer', 'thumbnail', 'thumbnails']) as List? ??
        [],
      );

      List? finalResults;
      final List<List<dynamic>> paths = [
        [...NavClass.singleColumnTab, ...NavClass.sectionListItem, ...NavClass.musicShelf, 'contents'],
        ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents', 0, 'musicShelfRenderer', 'contents'],
        ['contents', 'twoColumnBrowseResultsRenderer', 'secondaryContents', 'sectionListRenderer', 'contents', 0, 'musicShelfRenderer', 'contents'],
      ];

      for (final path in paths) {
        final res = NavClass.nav(response, path);
        if (res is List && res.isNotEmpty) {
          finalResults = res;
          Logger.root.info('YTMusic: Found ${res.length} album tracks using path: $path');
          break;
        }
      }

      finalResults ??= [];

      final List<Map> songResults = [];
      for (final item in finalResults) {
        final Map? mRLIR = item['musicResponsiveListItemRenderer'] as Map?;
        if (mRLIR == null) continue;

        final String id = NavClass.nav(mRLIR, ['playlistItemData', 'videoId'])?.toString() ?? 
                          NavClass.nav(mRLIR, NavClass.navigationVideoId)?.toString() ?? '';
        
        if (id.isEmpty || id == 'null') continue;

        final String title = NavClass.joinRunTexts(
          NavClass.nav(mRLIR, ['flexColumns', 0, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']) as List?,
        );
        
        final List thumbnails = NavClass.runUrls(
          NavClass.nav(mRLIR, NavClass.thumbnails) as List? ??
          NavClass.nav(mRLIR, NavClass.thumbnailRenderer) as List?,
        );
        final String image = thumbnails.isNotEmpty ? thumbnails.first.toString() : '';

        final List subtitleList = NavClass.nav(mRLIR, [
              'flexColumns',
              1,
              'musicResponsiveListItemFlexColumnRenderer',
              'text',
              'runs',
            ]) as List? ??
            [];
            
        String artist = '';
        final String album = heading ?? '';
        String duration = '';
        final subtitleText = StringBuffer();
        int count = 0;

        for (final element in subtitleList) {
          final text = element['text'].toString();
          subtitleText.write(text);
          if (text.trim() == '•') {
            count++;
          } else {
            if (count == 0) {
              if (text.trim() == '&') {
                artist += ', ';
              } else {
                artist += text;
              }
            } else if (count == 1) {
              // Usually the album name is already in the header
            } else if (count == 2) {
              duration += text;
            }
          }
        }

        songResults.add({
          'id': id,
          'type': 'song',
          'title': title,
          'artist': artist.trim(),
          'album': album,
          'duration': duration.trim(),
          'subtitle': subtitleText.toString(),
          'image': image,
          'secondImage': image,
          'perma_url': 'https://www.youtube.com/watch?v=$id',
        });
      }
      return {
        'songs': songResults,
        'name': heading ?? 'Unknown Album',
        'subtitle': subtitle,
        'description': description,
        'images': images,
        'id': albumId,
        'type': 'album',
      };
    } catch (e, st) {
      Logger.root.severe('Error in ytmusic getAlbumDetails', e, st);
      return {};
    }
  }

  Future<Map<String, dynamic>> getArtistDetails(String id) async {
    if (headers == null) {
      await init();
    }
    String artistId = id;
    if (artistId.startsWith('MPLA')) {
      artistId = artistId.substring(4);
    }
    try {
      Logger.root.info('YTMusic: Getting artist details for $artistId');
      final body = Map.from(context!);
      body['browseId'] = artistId;
      final Map response =
          await sendRequest(endpoints['browse']!, body, headers);
          
      if (response.isEmpty) {
        Logger.root.warning('YTMusic: Empty response for artist $artistId');
        return {};
      }

      final header = NavClass.nav(response, NavClass.immersiveHeaderDetail) ??
                     NavClass.nav(response, NavClass.headerDetail);

      final String? heading = NavClass.nav(header, NavClass.titleText) as String? ??
                             NavClass.nav(header, ['title', 'runs', 0, 'text']) as String?;
      
      final String subtitle = NavClass.joinRunTexts(
        NavClass.nav(header, NavClass.subtitleRuns) as List? ?? [],
      );
      
      final String description = NavClass.joinRunTexts(
        NavClass.nav(header, NavClass.secondSubtitleRuns) as List? ?? [],
      );
      
      final List images = NavClass.runUrls(
        NavClass.nav(header, NavClass.thumbnails) as List? ??
        NavClass.nav(header, NavClass.thumbnailCropped) as List? ??
        NavClass.nav(response, ['metadata', 'playlistMetadataRenderer', 'thumbnail', 'thumbnails']) as List? ??
        NavClass.nav(response, ['microformat', 'microformatDataRenderer', 'thumbnail', 'thumbnails']) as List? ??
        [],
      );

      List? finalResults;
      final List<List<dynamic>> paths = [
        [...NavClass.singleColumnTab, ...NavClass.sectionList, 0, ...NavClass.musicShelf, 'contents'],
        [...NavClass.singleColumnTab, ...NavClass.sectionList, 1, ...NavClass.musicShelf, 'contents'],
        ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents', 0, 'musicShelfRenderer', 'contents'],
      ];

      for (final path in paths) {
        final res = NavClass.nav(response, path);
        if (res is List && res.isNotEmpty) {
          finalResults = res;
          Logger.root.info('YTMusic: Found ${res.length} artist songs using path: $path');
          break;
        }
      }

      finalResults ??= [];

      final List<Map> songResults = [];
      for (final item in finalResults) {
        final Map? mRLIR = item['musicResponsiveListItemRenderer'] as Map?;
        if (mRLIR == null) continue;

        final String videoId = NavClass.nav(mRLIR, ['playlistItemData', 'videoId'])?.toString() ?? 
                              NavClass.nav(mRLIR, NavClass.navigationVideoId)?.toString() ?? '';
        
        if (videoId.isEmpty || videoId == 'null') continue;

        final String title = NavClass.joinRunTexts(
          NavClass.nav(mRLIR, ['flexColumns', 0, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']) as List?,
        );
        
        final List thumbnails = NavClass.runUrls(
          NavClass.nav(mRLIR, NavClass.thumbnails) as List? ??
          NavClass.nav(mRLIR, NavClass.thumbnailRenderer) as List?,
        );
        final String image = thumbnails.isNotEmpty ? thumbnails.first.toString() : '';

        final List subtitleList = NavClass.nav(mRLIR, [
              'flexColumns',
              1,
              'musicResponsiveListItemFlexColumnRenderer',
              'text',
              'runs',
            ]) as List? ??
            [];
            
        final String artist = heading ?? '';
        String album = '';
        String duration = '';
        final subtitleText = StringBuffer();
        int count = 0;

        for (final element in subtitleList) {
          final text = element['text'].toString();
          subtitleText.write(text);
          if (text.trim() == '•') {
            count++;
          } else {
            if (count == 0) {
              album = text;
            } else if (count == 1) {
              duration = text;
            }
          }
        }

        songResults.add({
          'id': videoId,
          'type': 'song',
          'title': title,
          'artist': artist,
          'album': album.trim(),
          'duration': duration.trim(),
          'subtitle': subtitleText.toString(),
          'image': image,
          'secondImage': image,
          'perma_url': 'https://www.youtube.com/watch?v=$videoId',
        });
      }
      return {
        'songs': songResults,
        'name': heading ?? 'Unknown Artist',
        'subtitle': subtitle,
        'description': description,
        'images': images,
        'id': artistId,
        'type': 'artist',
      };
    } catch (e, st) {
      Logger.root.severe('Error in ytmusic getArtistDetails', e, st);
      return {};
    }
  }

  Future<List<String>> getWatchPlaylist({
    String? videoId,
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
  }) async {
    if (headers == null) {
      await init();
    }
    try {
      final body = Map.from(context!);
      body['enablePersistentPlaylistPanel'] = true;
      body['isAudioOnly'] = true;
      body['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';

      if (videoId == null && playlistId == null) {
        return [];
      }
      if (videoId != null) {
        body['videoId'] = videoId;
        playlistId ??= 'RDAMVM$videoId';
        if (!(radio || shuffle)) {
          body['watchEndpointMusicSupportedConfigs'] = {
            'watchEndpointMusicConfig': {
              'hasPersistentPlaylistPanel': true,
              'musicVideoType': 'MUSIC_VIDEO_TYPE_ATV;',
            },
          };
        }
      }

      body['playlistId'] = playlistIdTrimmer(playlistId!);

      if (shuffle) body['params'] = 'wAEB8gECKAE%3D';
      if (radio) body['params'] = 'wAEB';
      final Map response = await sendRequest(endpoints['next']!, body, headers);
      final Map results = NavClass.nav(response, [
            'contents',
            'singleColumnMusicWatchNextResultsRenderer',
            'tabbedRenderer',
            'watchNextTabbedResultsRenderer',
            'tabs',
            0,
            'tabRenderer',
            'content',
            'musicQueueRenderer',
            'content',
            'playlistPanelRenderer',
          ]) as Map? ??
          {};
      final List contents = results['contents'] as List? ?? [];
      final playlist = contents.where(
        (x) =>
            NavClass.nav(x, [
              'playlistPanelVideoRenderer',
              ...NavClass.navigationPlaylistId,
            ]) !=
            null,
      );
      int count = 0;
      final List<String> songResults = [];
      for (final item in playlist) {
        if (count > limit) break;
        if (count > 0) {
          final String id =
              NavClass.nav(item, ['playlistPanelVideoRenderer', 'videoId'])
                  .toString();
          songResults.add(id);
        }
        count++;
      }
      return songResults;
    } catch (e) {
      Logger.root.severe('Error in ytmusic getWatchPlaylist', e);
      return [];
    }
  }
}
