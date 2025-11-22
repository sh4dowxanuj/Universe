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
import 'dart:io';
import 'dart:math';

import 'package:blackhole/Services/yt_music.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Innertube API minimal wrapper for Music + Web/Android fallback
/// This avoids any HTML scraping and uses the 2024-2025 endpoints.
class _InnertubeClient {
  static final Logger _log = Logger('_InnertubeClient');

  // Cached values
  static String? _apiKeyMusic; // WEB_REMIX key
  static String? _apiKeyWeb; // WEB key (fallback)
  static String? _visitorData; // X-Goog-Visitor-Id
  static DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _refreshInterval = Duration(hours: 6);

  static const _musicBase = 'https://music.youtube.com/youtubei/v1';
  static const _webBase = 'https://www.youtube.com/youtubei/v1';

  final Client _http;

  _InnertubeClient(this._http);

  Future<void> _ensureKeys({String region = 'IN', String language = 'en'}) async {
    if (_apiKeyMusic != null &&
        DateTime.now().difference(_lastFetch) < _refreshInterval) return;
    try {
      final resp = await _http.get(Uri.parse('https://music.youtube.com'));
      if (resp.statusCode == 200) {
        _apiKeyMusic = RegExp('"INNERTUBE_API_KEY":"(.*?)"')
            .firstMatch(resp.body)
            ?.group(1);
        _visitorData = RegExp('"VISITOR_DATA":"(.*?)"')
            .firstMatch(resp.body)
            ?.group(1);
        _apiKeyWeb = _apiKeyMusic; // Often identical; fallback if needed
        _lastFetch = DateTime.now();
        _log.info('Fetched Innertube keys (music=${_apiKeyMusic?.length})');
      } else {
        _log.severe('Failed initial music.youtube.com fetch: ${resp.statusCode}');
      }
    } catch (e) {
      _log.severe('Error fetching Innertube keys: $e');
    }
  }

  Map<String, dynamic> _clientContext({
    String client = 'WEB_REMIX',
    String region = 'IN',
    String language = 'en',
  }) {
    // version may change; keep overridable
    final versions = {
      'WEB_REMIX': '1.20241117.01.00',
      'ANDROID': '19.42.34',
      'WEB': '1.20241117.01.00',
    };
    return {
      'client': {
        'hl': language,
        'gl': region,
        'clientName': client,
        'clientVersion': versions[client] ?? versions['WEB_REMIX'],
        if (client == 'ANDROID') 'androidSdkVersion': 34,
      },
    };
  }

  Future<Map<String, dynamic>> browseMusic({
    String region = 'IN',
    String language = 'en',
  }) async {
    await _ensureKeys(region: region, language: language);
    final key = _apiKeyMusic;
    if (key == null) return {};
    final uri = Uri.parse('$_musicBase/browse?key=$key');
    final body = jsonEncode({
      ..._clientContext(region: region, language: language),
      'browseId': 'FEmusic_home',
    });
    final resp = await _http.post(
      uri,
      headers: _stdHeaders(),
      body: body,
    );
    if (resp.statusCode != 200) {
      _log.severe('browseMusic status ${resp.statusCode}');
      return {};
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> playlistBrowse(String playlistId, {
    String region = 'IN',
    String language = 'en',
  }) async {
    await _ensureKeys(region: region, language: language);
    final key = _apiKeyMusic;
    if (key == null) return {};
    final uri = Uri.parse('$_musicBase/browse?key=$key');
    final body = jsonEncode({
      ..._clientContext(region: region, language: language),
      'browseId': 'VL$playlistId',
    });
    final resp = await _http.post(uri, headers: _stdHeaders(), body: body);
    if (resp.statusCode != 200) return {};
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> player(String videoId, {
    String client = 'WEB_REMIX',
    String region = 'IN',
    String language = 'en',
  }) async {
    await _ensureKeys(region: region, language: language);
    final key = client == 'ANDROID' ? _apiKeyWeb : _apiKeyMusic;
    if (key == null) return {};
    final base = client == 'ANDROID' ? _webBase : _musicBase;
    final uri = Uri.parse('$base/player?key=$key');
    final body = jsonEncode({
      ..._clientContext(client: client, region: region, language: language),
      'videoId': videoId,
      'playbackContext': {
        'contentPlaybackContext': {'signatureTimestamp': _signatureTimestamp()},
      },
      'contentCheckOk': true,
      'racyCheckOk': true,
    });
    final resp = await _http.post(uri, headers: _stdHeaders(), body: body);
    if (resp.statusCode != 200) {
      _log.warning('player status ${resp.statusCode}');
      return {};
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<List<String>> suggestions(String query) async {
    final uri = Uri.parse(
      'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeQueryComponent(query)}',
    );
    try {
      final resp = await _http.get(uri, headers: _stdHeaders());
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as List;
      final unescape = HtmlUnescape();
      return (data[1] as List).map((e) => unescape.convert(e.toString())).toList();
    } catch (e) {
      _log.severe('suggestions error: $e');
      return [];
    }
  }

  Map<String, String> _stdHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
      if (_visitorData != null) 'X-Goog-Visitor-Id': _visitorData!,
      'Accept-Language': 'en-US,en;q=0.9',
      'Origin': 'https://music.youtube.com',
    };
  }

  int _signatureTimestamp() {
    // Approximated timestamp (sts) used in Innertube; often derived from player JS.
    final epochDays = DateTime.now().difference(DateTime(1970)).inDays;
    return 170000 + (epochDays % 2000); // heuristic
  }
}

/// Utility for deciphering signatureCipher and n-params (throttling bypass)
class _CipherUtil {
  static final Logger _log = Logger('_CipherUtil');
  static String? _playerJsUrl;
  static DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _refreshEvery = Duration(hours: 6);
  static final RegExp _nFunctionRegex = RegExp(r'n\s*=\s*function\(\s*a\s*\)\s*{([^}]+)}');
  static final RegExp _sigFunctionRegex = RegExp(r'\b[a-zA-Z0-9$]{2}\s*=\s*function\(a\)\{a=a\.split\(""\);([^}]+)return a\.join\(""\)');
  static List<_Op> _nOps = [];
  static List<_Op> _sigOps = [];

  final Client _http;
  _CipherUtil(this._http);

  Future<void> _ensurePlayerJs() async {
    if (_playerJsUrl != null &&
        DateTime.now().difference(_lastUpdate) < _refreshEvery &&
        _nOps.isNotEmpty &&
        _sigOps.isNotEmpty) return;
    try {
      final resp = await _http.get(Uri.parse('https://www.youtube.com'));
      if (resp.statusCode != 200) return;
      final match = RegExp(r'src="(\/s\/player\/[^"]+base\.js)"').firstMatch(resp.body);
      if (match == null) {
        _log.warning('player js url not found');
        return;
      }
      _playerJsUrl = 'https://www.youtube.com${match.group(1)}';
      final js = await _http.get(Uri.parse(_playerJsUrl!));
      if (js.statusCode != 200) return;
      final script = js.body;
      _nOps = _extractOps(script, _nFunctionRegex);
      _sigOps = _extractOps(script, _sigFunctionRegex);
      _lastUpdate = DateTime.now();
      _log.info('Extracted cipher ops: n=${_nOps.length}, sig=${_sigOps.length}');
    } catch (e) {
      _log.severe('ensurePlayerJs error: $e');
    }
  }

  List<_Op> _extractOps(String script, RegExp fnRegex) {
    final m = fnRegex.firstMatch(script);
    if (m == null) return [];
    final body = m.group(1)!;
    final ops = <_Op>[];
    final parts = body.split(';');
    for (final p in parts) {
      if (p.contains('reverse()')) {
        ops.add(_Op(_OpType.reverse));
      } else if (p.contains('slice(')) {
        final n = RegExp(r'slice\((\d+)').firstMatch(p)?.group(1);
        ops.add(_Op(_OpType.slice, int.tryParse(n ?? '0') ?? 0));
      } else if (p.contains('splice(')) {
        final n = RegExp(r'splice\((\d+)').firstMatch(p)?.group(1);
        ops.add(_Op(_OpType.splice, int.tryParse(n ?? '0') ?? 0));
      } else if (RegExp(r'\[(\d+)%').hasMatch(p) || p.contains('var')) {
        // swap like: var c=a[0];a[0]=a[b%a.length];a[b]=c
        final n = RegExp(r'(\d+)').firstMatch(p)?.group(1);
        ops.add(_Op(_OpType.swap, int.tryParse(n ?? '0') ?? 0));
      }
    }
    return ops;
  }

  Future<String> decipherSignature(String s) async {
    await _ensurePlayerJs();
    var chars = s.split('');
    for (final op in _sigOps) {
      chars = op.apply(chars);
    }
    return chars.join();
  }

  Future<String> decipherN(String n) async {
    await _ensurePlayerJs();
    var chars = n.split('');
    for (final op in _nOps) {
      chars = op.apply(chars);
    }
    return chars.join();
  }
}

enum _OpType { reverse, slice, splice, swap }

class _Op {
  final _OpType type;
  final int arg;
  _Op(this.type, [this.arg = 0]);
  List<String> apply(List<String> input) {
    switch (type) {
      case _OpType.reverse:
        return input.reversed.toList();
      case _OpType.slice:
        return input.sublist(arg);
      case _OpType.splice:
        final copy = [...input];
        final remove = min(arg, copy.length);
        copy.removeRange(0, remove);
        return copy;
      case _OpType.swap:
        if (input.isEmpty) return input;
        final copy = [...input];
        final idx = arg % copy.length;
        final first = copy.first;
        copy[0] = copy[idx];
        copy[idx] = first;
        return copy;
    }
  }
}

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
        'Mozilla/5.0 (Windows NT 10.0; rv:96.0) Gecko/20100101 Firefox/96.0',
  };
  final YoutubeExplode yt = YoutubeExplode();

  YouTubeServices._privateConstructor();

  static final YouTubeServices _instance =
      YouTubeServices._privateConstructor();

  static YouTubeServices get instance {
    return _instance;
  }

  Future<List<Video>> getPlaylistSongs(String id) async {
    // Keep youtube_explode for now (stable, Video object compatibility)
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
      quality: Hive.box('settings')
          .get(
            'ytQuality',
            defaultValue: 'Low',
          )
          .toString(),
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

  Future<Map?> refreshLink(String id, {bool useYTM = true}) async {
    String quality;
    try {
      quality =
          Hive.box('settings').get('quality', defaultValue: 'Low').toString();
    } catch (e) {
      quality = 'Low';
    }
    if (useYTM) {
      final Map res = await YtMusicService().getSongData(
        videoId: id,
        quality: quality,
      );
      return res;
    }
    final Video? res = await getVideoFromId(id);
    if (res == null) {
      return null;
    }
    final Map? data = await formatVideo(video: res, quality: quality);
    return data;
  }

  Future<Playlist> getPlaylistDetails(String id) async {
    // Keep youtube_explode for now (stable, Playlist object compatibility)
    final Playlist metadata = await yt.playlists.get(id);
    return metadata;
  }

  Future<Map<String, List>> getMusicHome() async {
    // New Innertube Music API usage
    try {
      final client = _InnertubeClient(Client());
      final data = await client.browseMusic();
      if (data.isEmpty) return {};
      final List bodySections = _extractMusicSections(data);
      final List headSections = _extractHead(data);
      return {
        'body': bodySections.cast(),
        'head': headSections.cast(),
      };
    } catch (e) {
      Logger.root.severe('Error in getMusicHome (Innertube): $e');
      return {};
    }
  }

  Future<List> getSearchSuggestions({required String query}) async {
    try {
      final client = _InnertubeClient(Client());
      final suggestions = await client.suggestions(query);
      return suggestions;
    } catch (e) {
      Logger.root.severe('Error in getSearchSuggestions (Innertube): $e');
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
    if (video.duration?.inSeconds == null) return null;
    List<String> allUrls = [];
    List<Map> urlsData = [];
    String finalUrl = '';
    String expireAt = '0';
    if (getUrl) {
      urlsData = await getYtStreamUrls(video.id.value);
      final Map finalUrlData =
          quality == 'High' ? urlsData.last : urlsData.first;
      finalUrl = finalUrlData['url'].toString();
      expireAt = finalUrlData['expireAt'].toString();
      allUrls = urlsData.map((e) => e['url'].toString()).toList();
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
    final List<Video> searchResults = await yt.search.search(query);
    final List<Map> videoResult = [];
    for (final Video vid in searchResults) {
      final res = await formatVideo(video: vid, quality: 'High', getUrl: false);
      if (res != null) videoResult.add(res);
    }
    return [
      {
        'title': 'Videos',
        'items': videoResult,
        'allowViewAll': false,
      }
    ];
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
    return RegExp('expire=(.*?)&').firstMatch(url)!.group(1) ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600 * 5.5).toString();
  }

  Future<List<Map>> getYtStreamUrls(String videoId) async {
    try {
      List<Map> urlData = [];

      // check cache first
      if (Hive.box('ytlinkcache').containsKey(videoId)) {
        final cachedData = Hive.box('ytlinkcache').get(videoId);
        if (cachedData is List) {
          int minExpiredAt = 0;
          for (final e in cachedData) {
            final int cachedExpiredAt = int.parse(e['expireAt'].toString());
            if (minExpiredAt == 0 || cachedExpiredAt < minExpiredAt) {
              minExpiredAt = cachedExpiredAt;
            }
          }

          if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 >
              minExpiredAt) {
            // cache expired
            urlData = await getUri(videoId);
          } else {
            // giving cache link
            Logger.root.info('cache found for $videoId');
            urlData = cachedData as List<Map>;
          }
        } else {
          // old version cache is present
          urlData = await getUri(videoId);
        }
      } else {
        //cache not present
        urlData = await getUri(videoId);
      }

      // Fallback: if no urls or 403 issues suspected, use Innertube player
      if (urlData.isEmpty) {
        final fallback = await _getInnertubePlayerStreams(videoId);
        if (fallback.isNotEmpty) urlData = fallback;
      }

      try {
        await Hive.box('ytlinkcache')
            .put(
              videoId,
              urlData,
            )
            .onError(
              (error, stackTrace) => Logger.root.severe(
                'Hive Error in formatVideo, you probably forgot to open box.\nError: $error',
              ),
            );
      } catch (e) {
        Logger.root.severe(
          'Hive Error in formatVideo, you probably forgot to open box.\nError: $e',
        );
      }

      return urlData;
    } catch (e) {
      Logger.root.severe('Error in getYtStreamUrls: $e');
      return [];
    }
  }

  Future<List<Map>> getUri(
    String videoId,
    // {bool preferM4a = true}
  ) async {
    final List<AudioOnlyStreamInfo> sortedStreamInfo =
        await getStreamInfo(videoId);
    return sortedStreamInfo
        .map(
          (e) => {
            'bitrate': e.bitrate.kiloBitsPerSecond.round().toString(),
            'codec': e.codec.subtype,
            'qualityLabel': e.qualityLabel,
            'size': e.size.totalMegaBytes.toStringAsFixed(2),
            'url': e.url.toString(),
            'expireAt': getExpireAt(e.url.toString()),
          },
        )
        .toList();
  }

  Future<List<AudioOnlyStreamInfo>> getStreamInfo(
    String videoId, {
    bool onlyMp4 = false,
  }) async {
    final StreamManifest manifest =
        await yt.videos.streamsClient.getManifest(VideoId(videoId));
    final List<AudioOnlyStreamInfo> sortedStreamInfo = manifest.audioOnly
        .toList()
      ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
    if (onlyMp4 || Platform.isIOS || Platform.isMacOS) {
      final List<AudioOnlyStreamInfo> m4aStreams = sortedStreamInfo
          .where((element) => element.audioCodec.contains('mp4'))
          .toList();

      if (m4aStreams.isNotEmpty) {
        return m4aStreams;
      }
    }

    return sortedStreamInfo;
  }

  Stream<List<int>> getStreamClient(
    AudioOnlyStreamInfo streamInfo,
  ) {
    return yt.videos.streamsClient.get(streamInfo);
  }

  // ------------------- Innertube Helpers ------------------- //
  List _extractMusicSections(Map root) {
    final List finalResult = [];
    try {
      final tabs = root['contents']?['singleColumnBrowseResultsRenderer']?['tabs'] ??
          root['contents']?['twoColumnBrowseResultsRenderer']?['tabs'];
      if (tabs is! List || tabs.isEmpty) return finalResult;
      final content = tabs.first['tabRenderer']?['content'];
      final sections = content?['sectionListRenderer']?['contents'];
      if (sections is! List) return finalResult;
      for (final section in sections) {
        final shelf = section['itemSectionRenderer']?['contents']?[0]?['shelfRenderer'];
        if (shelf == null) continue;
        final titleRuns = shelf['title']?['runs'];
        final String title = titleRuns is List && titleRuns.isNotEmpty
          ? (titleRuns[0]['text'] as String? ?? 'Unknown')
          : 'Unknown';
        final items = shelf['content']?['horizontalListRenderer']?['items'];
        if (items is! List) continue;
        List formatted;
        if (title.toLowerCase().contains('chart')) {
          formatted = formatChartItems(items);
        } else if (title.toLowerCase().contains('video')) {
          formatted = formatVideoItems(items);
        } else {
          formatted = formatItems(items);
        }
        if (formatted.isEmpty) continue;
        finalResult.add({'title': title, 'playlists': formatted});
      }
    } catch (e) {
      Logger.root.severe('extractMusicSections error: $e');
    }
    return finalResult;
  }

  List _extractHead(Map root) {
    final List head = [];
    try {
      final header = root['header'];
      final items = header?['carouselHeaderRenderer']?['contents']?[0]?
          ['carouselItemRenderer']?['carouselItems'];
      if (items is! List) return head;
      return formatHeadItems(items);
    } catch (e) {
      Logger.root.severe('extractHead error: $e');
      return head;
    }
  }

  Future<List<Map>> _getInnertubePlayerStreams(String videoId) async {
    final client = _InnertubeClient(Client());
    final cipher = _CipherUtil(Client());
    Map<String, dynamic> playerData = await client.player(videoId);
    if (playerData.isEmpty) {
      // Android fallback
      playerData = await client.player(videoId, client: 'ANDROID');
    }
    final streamingData = playerData['streamingData'];
    if (streamingData == null) return [];
    final List<Map> out = [];
    final adaptiveRaw = streamingData['adaptiveFormats'];
    final formatsRaw = streamingData['formats'];
    final List adaptive = adaptiveRaw is List ? adaptiveRaw : <dynamic>[];
    final List formats = formatsRaw is List ? formatsRaw : <dynamic>[];
    final List all = [...formats, ...adaptive];
    for (final fmt in all) {
      if (fmt is! Map) continue;
      final itag = fmt['itag']?.toString();
      if (itag == '140' || itag == '251' || (fmt['mimeType']?.toString() ?? '').contains('audio')) {
        String? url = fmt['url'] as String?;
        if (url == null && fmt['signatureCipher'] != null) {
          final cipherStr = fmt['signatureCipher'] as String;
          final parts = Uri.splitQueryString(
            cipherStr.startsWith('?') ? cipherStr : '?$cipherStr',
          );
          final baseUrl = parts['url'];
          final s = parts['s'];
          final sp = parts['sp'] ?? 'signature';
          if (baseUrl != null && s != null) {
            final sig = await cipher.decipherSignature(s);
            url = '$baseUrl&$sp=$sig';
          }
        }
        if (url == null) continue;
        // Throttling n param
        if (url.contains('n=')) {
          final nVal = RegExp('[?&]n=([^&]+)').firstMatch(url)?.group(1);
          if (nVal != null) {
            final newN = await cipher.decipherN(nVal);
            url = url.replaceFirst('n=$nVal', 'n=$newN');
          }
        }
        out.add({
          'bitrate': fmt['bitrate']?.toString() ?? '',
          'codec': fmt['mimeType']?.toString().split(';').first ?? '',
          'qualityLabel': fmt['audioQuality']?.toString() ?? fmt['qualityLabel']?.toString() ?? 'audio',
          'size': '0',
          'url': url,
          'expireAt': getExpireAt(url),
        });
      }
    }
    // Sort by bitrate ascending then return
    out.sort((a, b) {
      final ai = int.tryParse(a['bitrate']?.toString() ?? '0') ?? 0;
      final bi = int.tryParse(b['bitrate']?.toString() ?? '0') ?? 0;
      return ai.compareTo(bi);
    });
    return out;
  }
}
