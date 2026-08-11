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
import 'package:logging/logging.dart';
import 'package:universe/Services/cache_service.dart';
import 'package:universe/Services/error_service.dart';
import 'package:universe/Services/network_service.dart';
import 'package:universe/main.dart';

class InnerTubeService {
  static const String baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String apiKey = 'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'X-Goog-Api-Key': 'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI',
  };

  static Map<String, dynamic> get _context => {
    'context': {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20241209.01.00',
        'hl': 'en',
        'gl': 'US',
      },
      'user': {
        'lockedSafetyMode': false,
      },
    },
  };

  InnerTubeService._privateConstructor();

  static final InnerTubeService _instance = InnerTubeService._privateConstructor();

  static InnerTubeService get instance => _instance;

  Future<Map<String, List>?> getMusicHome() async {
    const String cacheKey = 'innertube_home';
    const Duration cacheTTL = Duration(minutes: 15);

    // Check cache first
    final cached = locator<CacheService>().get<Map<String, List>>(cacheKey);
    if (cached != null) {
      Logger.root.info('Returning cached InnerTube home data');
      return cached;
    }

    try {
      Logger.root.info('Fetching YouTube Music home using InnerTube API');

      final Uri url = Uri.parse('$baseUrl/browse');

      final Map<String, dynamic> body = {
        ..._context,
        'browseId': 'FEmusic_home',
      };

      final response = await locator<NetworkService>().post(
        url,
        headers: headers,
        body: jsonEncode(body),
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<Map> sections = [];

        final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

        if (contents != null && contents is List) {
          for (final section in contents) {
            final sectionRenderer = section['musicCarouselShelfRenderer'] ?? section['musicShelfRenderer'];
            if (sectionRenderer != null) {
              final title = sectionRenderer['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs']?[0]?['text'] ??
                          sectionRenderer['title']?['runs']?[0]?['text'] ?? 'Unknown';

              final List<Map> items = [];

              final dynamic sectionContents = sectionRenderer['contents'] ?? [];
              if (sectionContents is List) {
                for (final item in sectionContents) {
                  final renderer = item['musicTwoRowItemRenderer'] ??
                                 item['musicResponsiveListItemRenderer'];

                  if (renderer != null) {
                    final String title = renderer['title']?['runs']?[0]?['text']?.toString() ?? '';
                    final String subtitle = renderer['subtitle']?['runs']?[0]?['text']?.toString() ?? '';
                    final String thumbnail = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?[0]?['url']?.toString() ?? '';

                    String? videoId;
                    final navigationEndpoint = renderer['title']?['runs']?[0]?['navigationEndpoint'] ??
                                             renderer['navigationEndpoint'];

                    if (navigationEndpoint != null) {
                      videoId = navigationEndpoint['watchEndpoint']?['videoId']?.toString() ??
                               navigationEndpoint['browseEndpoint']?['browseId']?.toString();
                    }

                    if ((videoId?.isNotEmpty ?? false) && title.isNotEmpty) {
                      items.add({
                        'title': title,
                        'type': 'video',
                        'description': subtitle,
                        'count': '',
                        'videoId': videoId,
                        'firstItemId': videoId,
                        'image': thumbnail,
                        'imageMin': thumbnail,
                        'imageMedium': thumbnail,
                        'imageStandard': thumbnail,
                        'imageMax': thumbnail,
                      });
                    }
                  }
                }
              }

              if (items.isNotEmpty) {
                sections.add({
                  'title': title,
                  'playlists': items,
                });
              }
            }
          }
        }

        if (sections.isNotEmpty) {
          final result = {'body': sections, 'head': []};
          // Cache the result
          await locator<CacheService>().set(cacheKey, result, ttl: cacheTTL);
          Logger.root.info('Successfully fetched ${sections.length} sections from InnerTube API');
          return result;
        } else {
          Logger.root.warning('No sections found in InnerTube response, falling back to search-based approach');
          return null;
        }
      } else {
        Logger.root.severe('InnerTube API request failed with status: ${response.statusCode}');
        Logger.root.severe('Response: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      Logger.root.severe('Error in InnerTube getMusicHome: $e\n$stackTrace');
      locator<ErrorService>().reportError('InnerTube.getMusicHome', e, stackTrace);
      return null;
    }
  }
}
