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

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:universe/APIs/spotify_api.dart';
import 'package:universe/Helpers/extensions.dart';
import 'package:universe/Helpers/matcher.dart';
import 'package:universe/Helpers/spotify_helper.dart';

// ignore: avoid_classes_with_only_static_members
class Lyrics {
  static Future<Map<String, String>> getLyrics({
    required String id,
    required String title,
    required String artist,
    required bool saavnHas,
  }) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'text',
      'source': '',
      'id': id,
    };

    Logger.root.info('Getting Lyrics from LRCLIB');
    final Map<String, String> lrcLibRes =
        await getLrcLibLyrics(title, artist);
    if (lrcLibRes['lyrics'] != '') {
      result['lyrics'] = lrcLibRes['lyrics']!;
      result['type'] = lrcLibRes['type']!;
      result['source'] = lrcLibRes['source']!;
      return result;
    }

    Logger.root.info('LRCLIB Lyrics not found. Getting Synced Lyrics from Spotify');
    final res = await getSpotifyLyrics(title, artist);
    result['lyrics'] = res['lyrics']!;
    result['type'] = res['type']!;
    result['source'] = res['source']!;
    if (result['lyrics'] == '') {
      Logger.root.info('Synced Lyrics, not found. Getting text lyrics');
      if (saavnHas) {
        Logger.root.info('Getting Lyrics from Saavn');
        result['lyrics'] = await getSaavnLyrics(id);
        result['type'] = 'text';
        result['source'] = 'Jiosaavn';
        if (result['lyrics'] == '') {
          final res = await getLyrics(
            id: id,
            title: title,
            artist: artist,
            saavnHas: false,
          );
          result['lyrics'] = res['lyrics']!;
          result['type'] = res['type']!;
          result['source'] = res['source']!;
        }
      } else {
        Logger.root
            .info('Lyrics not available on Saavn, finding on Musixmatch');
        result['lyrics'] =
            await getMusixMatchLyrics(title: title, artist: artist);
        result['type'] = 'text';
        result['source'] = 'Musixmatch';
        if (result['lyrics'] == '') {
          Logger.root
              .info('Lyrics not found on Musixmatch, searching on Google');
          result['lyrics'] =
              await getGoogleLyrics(title: title, artist: artist);
          result['type'] = 'text';
          result['source'] = 'Google';
        }
      }
    }
    return result;
  }

  static Future<Map<String, String>> getLrcLibLyrics(
    String title,
    String artist,
  ) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'text',
      'source': 'LRCLIB',
    };
    try {
      final Uri lyricsUrl = Uri.https('lrclib.net', '/api/get', {
        'artist_name': artist,
        'track_name': title,
      });
      final Response res = await get(lyricsUrl);
      if (res.statusCode == 200) {
        final Map lyricsData = json.decode(utf8.decode(res.bodyBytes)) as Map;
        if (lyricsData['syncedLyrics'] != null &&
            lyricsData['syncedLyrics'] != '') {
          result['lyrics'] = lyricsData['syncedLyrics'].toString().unescape();
          result['type'] = 'lrc';
        } else if (lyricsData['plainLyrics'] != null &&
            lyricsData['plainLyrics'] != '') {
          result['lyrics'] = lyricsData['plainLyrics'].toString().unescape();
          result['type'] = 'text';
        }
      }
    } catch (e) {
      Logger.root.severe('Error in getLrcLibLyrics', e);
    }
    return result;
  }

  static Future<String> getSaavnLyrics(String id) async {
    try {
      final Uri lyricsUrl = Uri.https(
        'www.jiosaavn.com',
        '/api.php?__call=lyrics.getLyrics&lyrics_id=$id&ctx=web6dot0&api_version=4&_format=json',
      );
      final Response res =
          await get(lyricsUrl, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final String decodedBody = utf8.decode(res.bodyBytes);
        final List<String> rawLyrics = decodedBody.split('-->');
        Map fetchedLyrics = {};
        try {
          if (rawLyrics.length > 1) {
            fetchedLyrics = json.decode(rawLyrics[1]) as Map;
          } else {
            fetchedLyrics = json.decode(rawLyrics[0]) as Map;
          }
          if (fetchedLyrics.containsKey('lyrics')) {
            final String lyrics =
                fetchedLyrics['lyrics'].toString().replaceAll('<br>', '\n');
            return lyrics.unescape();
          }
        } catch (e) {
          Logger.root.severe('Error decoding Saavn lyrics JSON', e);
        }
      }
      return '';
    } catch (e) {
      Logger.root.severe('Error in getSaavnLyrics', e);
      return '';
    }
  }

  static Future<Map<String, String>> getSpotifyLyrics(
    String title,
    String artist,
  ) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'text',
      'source': 'Spotify',
    };
    await callSpotifyFunction(
      function: (String accessToken) async {
        final value = await SpotifyApi().searchTrack(
          accessToken: accessToken,
          query: '$title - $artist',
          limit: 1,
        );
        try {
          // Logger.root.info(jsonEncode(value['tracks']['items'][0]));
          if (value['tracks']['items'].length == 0) {
            Logger.root.info('No song found');
            return result;
          }
          String title2 = '';
          String artist2 = '';
          try {
            title2 = value['tracks']['items'][0]['name'].toString();
            artist2 =
                value['tracks']['items'][0]['artists'][0]['name'].toString();
          } catch (e) {
            Logger.root.severe(
              'Error in extracting artist/title in getSpotifyLyrics for $title - $artist',
              e,
            );
          }
          final trackId = value['tracks']['items'][0]['id'].toString();
          if (matchSongs(
            title: title,
            artist: artist,
            title2: title2,
            artist2: artist2,
          ).matched) {
            final Map<String, String> res =
                await getSpotifyLyricsFromId(trackId);
            result['lyrics'] = res['lyrics']!;
            result['type'] = res['type']!;
            result['source'] = res['source']!;
          } else {
            Logger.root.info('Song not matched');
          }
        } catch (e) {
          Logger.root.severe('Error in getSpotifyLyrics', e);
        }
      },
      forceSign: false,
    );
    return result;
  }

  static Future<Map<String, String>> getSpotifyLyricsFromId(
    String trackId,
  ) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'text',
      'source': 'Spotify',
    };
    try {
      final Uri lyricsUrl =
          Uri.https('spotify-lyric-api-984e7b4face0.herokuapp.com', '/', {
        'trackid': trackId,
        'format': 'lrc',
      });
      final Response res =
          await get(lyricsUrl, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final Map lyricsData = json.decode(utf8.decode(res.bodyBytes)) as Map;
        if (lyricsData['error'] == false) {
          final List lines = lyricsData['lines'] as List;
          if (lyricsData['syncType'] == 'LINE_SYNCED') {
            result['lyrics'] = lines
                .map((e) => '[${e["timeTag"]}]${e["words"]}')
                .toList()
                .join('\n')
                .unescape();
            result['type'] = 'lrc';
          } else {
            result['lyrics'] = lines
                .map((e) => e['words'])
                .toList()
                .join('\n')
                .unescape();
            result['type'] = 'text';
          }
        }
      } else {
        Logger.root.severe(
          'getSpotifyLyricsFromId returned ${res.statusCode}',
          res.body,
        );
      }
      return result;
    } catch (e) {
      Logger.root.severe('Error in getSpotifyLyrics', e);
      return result;
    }
  }

  static Future<String> getGoogleLyrics({
    required String title,
    required String artist,
  }) async {
    const String url =
        'https://www.google.com/search?client=safari&rls=en&ie=UTF-8&oe=UTF-8&q=';
    const List<String> delimiter1List = [
      '</div></div></div></div><div class="hwc"><div class="BNeawe tAd8D AP7Wnd"><div><div class="BNeawe tAd8D AP7Wnd">',
      '</div></div></div></div><div class="hwc"><div class="BNeawe tAd8D AP7Wnd"><div><div class="BNeawe tAd8D AP7Wnd">',
    ];
    const String delimiter2 =
        '</div></div></div></div></div><div><span class="hwc"><div class="BNeawe uEec3 AP7Wnd">';

    for (final String querySuffix in [' lyrics', ' song lyrics']) {
      try {
        final String searchUrl = Uri.encodeFull('$url$title by $artist$querySuffix');
        final Response res = await get(Uri.parse(searchUrl), headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        });
        final String body = utf8.decode(res.bodyBytes);

        for (final String d1 in delimiter1List) {
          if (body.contains(d1)) {
            String lyrics = body.split(d1).last.split(delimiter2).first;
            if (lyrics.isNotEmpty && !lyrics.contains('<meta charset="UTF-8">')) {
              return lyrics.trim().replaceAll('<br>', '\n').unescape();
            }
          }
        }
      } catch (e) {
        Logger.root.warning('Google lyrics search failed for $querySuffix', e);
      }
    }
    return '';
  }

  static Future<String> getOffLyrics(String path) async {
    try {
      final metadata = readMetadata(File(path));
      return metadata.lyrics ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<String> getLyricsLink(String song, String artist) async {
    const String authority = 'www.musixmatch.com';
    final String unencodedPath = '/search/$song $artist';
    final Response res = await get(Uri.https(authority, unencodedPath), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    });
    if (res.statusCode != 200) return '';
    final String body = utf8.decode(res.bodyBytes);
    final RegExpMatch? result =
        RegExp(r'href=\"(\/lyrics\/.*?)\"').firstMatch(body);
    return result == null ? '' : result[1]!;
  }

  static Future<String> scrapLink(String unencodedPath) async {
    Logger.root.info('Trying to scrap lyrics from $unencodedPath');
    const String authority = 'www.musixmatch.com';
    final Response res = await get(Uri.https(authority, unencodedPath), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    });
    if (res.statusCode != 200) return '';
    final String body = utf8.decode(res.bodyBytes);
    final List<String?> lyrics = RegExp(
      r'<span class=\"lyrics__content__ok\">(.*?)<\/span>',
      dotAll: true,
    ).allMatches(body).map((m) => m[1]).toList();

    return lyrics.isEmpty ? '' : lyrics.join('\n').unescape();
  }

  static Future<String> getMusixMatchLyrics({
    required String title,
    required String artist,
  }) async {
    try {
      final String link = await getLyricsLink(title, artist);
      Logger.root.info('Found Musixmatch Lyrics Link: $link');
      final String lyrics = await scrapLink(link);
      return lyrics;
    } catch (e) {
      Logger.root.severe('Error in getMusixMatchLyrics', e);
      return '';
    }
  }
}
