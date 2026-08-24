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
import 'package:universe/Services/ytmusic/nav.dart';
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

  static const String cacheKey = 'ytHomeInnerTubeV2';
  static const Duration cacheTTL = Duration(hours: 1);

  Future<Map<String, dynamic>?> getMusicHome() async {
    // Check cache first
    final cachedData = locator<CacheService>().get<dynamic>(cacheKey);
    if (cachedData is Map) {
      try {
        final Map<String, dynamic> result = Map<String, dynamic>.from(cachedData);
        bool hasValidData = false;
        final body = result['body'];
        if (body is List) {
          for (final section in body) {
            if (section is Map && section['playlists'] is List) {
              final items = section['playlists'] as List;
              // Validate that at least one item has an 'id' and 'artist'
              if (!hasValidData && items.isNotEmpty && items.first is Map) {
                final first = items.first as Map;
                if (first.containsKey('id') && first.containsKey('artist')) {
                  hasValidData = true;
                }
              }
            }
          }
        }
        
        if (hasValidData) {
          Logger.root.info('Returning cached InnerTube home data');
          return result;
        } else {
          Logger.root.info('Cached InnerTube data is invalid/legacy, forcing refresh');
          await locator<CacheService>().remove(cacheKey);
        }
      } catch (e) {
        Logger.root.warning('Failed to parse cached InnerTube home data: $e');
      }
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

        final sectionList = NavClass.nav(data, ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer']) ??
                          NavClass.nav(data, ['continuationContents', 'sectionListContinuation']) ??
                          NavClass.nav(data, ['contents', 'twoColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer']);

        final contents = sectionList?['contents'];

        if (contents != null && contents is List) {
          for (final section in contents) {
            final sectionRenderer = section['musicCarouselShelfRenderer'] ?? 
                                   section['musicShelfRenderer'] ?? 
                                   section['musicGridRenderer'] ??
                                   section['musicImmersiveCarouselShelfRenderer'];
            
            if (sectionRenderer != null) {
              final title = sectionRenderer['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs']?[0]?['text'] ??
                          sectionRenderer['header']?['musicGridHeaderRenderer']?['title']?['runs']?[0]?['text'] ??
                          sectionRenderer['title']?['runs']?[0]?['text'] ?? 
                          sectionRenderer['header']?['musicImmersiveHeaderRenderer']?['title']?['runs']?[0]?['text'] ??
                          'Discover';

              final List<Map> items = [];

              final dynamic sectionContents = sectionRenderer['contents'] ?? sectionRenderer['items'] ?? [];
              if (sectionContents is List) {
                for (final item in sectionContents) {
                  final renderer = item['musicTwoRowItemRenderer'] ??
                                 item['musicResponsiveListItemRenderer'];

                  if (renderer != null) {
                    final String title = renderer['title']?['runs']?[0]?['text']?.toString() ?? 
                                         renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text']?.toString() ?? '';
                    final String subtitle = renderer['subtitle']?['runs']?[0]?['text']?.toString() ?? 
                                            renderer['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text']?.toString() ?? '';
                    
                    String? videoId;
                    String? browseId;
                    
                    // Try to find videoId or browseId in various renderer spots
                    final navigationEndpoint = renderer['navigationEndpoint'] ?? 
                                             renderer['title']?['runs']?[0]?['navigationEndpoint'] ??
                                             renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['navigationEndpoint'];

                    if (navigationEndpoint != null) {
                      videoId = navigationEndpoint['watchEndpoint']?['videoId']?.toString();
                      browseId = navigationEndpoint['browseEndpoint']?['browseId']?.toString();
                    }

                    final List? thumbnails = NavClass.nav(renderer, NavClass.thumbnails) as List? ??
                                           NavClass.nav(renderer, NavClass.thumbnailRenderer) as List? ??
                                           (renderer['thumbnail']?['thumbnails'] as List?);
                    
                    String thumbnail = thumbnails != null && thumbnails.isNotEmpty 
                        ? thumbnails.last['url']?.toString() ?? '' 
                        : '';
                    
                    // Fallback to official YouTube i.ytimg.com URL if thumbnail is missing or looks like a song
                    if (thumbnail.isEmpty && videoId != null) {
                      thumbnail = 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
                    }

                    if (title.isNotEmpty && (videoId != null || browseId != null)) {
                      // If it has a videoId, we treat it as a video/song.
                      // browseId is only used as the primary ID if videoId is missing.
                      final bool isVideo = videoId != null;
                      final id = videoId ?? browseId!;
                      
                      items.add({
                        'id': id,
                        'title': title,
                        'type': isVideo ? 'video' : 'playlist',
                        'artist': subtitle,
                        'album': subtitle,
                        'description': subtitle,
                        'duration': isVideo ? '3:00' : '',
                        'count': '',
                        'videoId': videoId,
                        'playlistId': isVideo ? null : browseId,
                        'firstItemId': videoId,
                        'image': thumbnail,
                        'imageMin': thumbnail,
                        'imageMedium': thumbnail,
                        'imageStandard': thumbnail,
                        'imageMax': thumbnail,
                        'perma_url': isVideo ? 'https://youtube.com/watch?v=$videoId' : 'https://music.youtube.com/browse/$browseId',
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
          final result = {
            'body': sections, 
            'head': [],
          };
          // Cache the result
          await locator<CacheService>().set(cacheKey, result, ttl: cacheTTL);
          Logger.root.info('Successfully fetched ${sections.length} sections from InnerTube API');
          return result;
        } else {
          Logger.root.warning('No sections found in InnerTube response');
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
