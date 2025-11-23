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

import 'package:blackhole/Services/ytmusic/nav.dart';
import 'package:logging/logging.dart';

class InnertubeParser {
  static Map<String, List> parseMusicHome(Map<String, dynamic> response) {
    try {
      final contents = NavClass.nav(response, [
        'contents',
        'singleColumnBrowseResultsRenderer',
        'tabs',
        0,
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
      ]) as List?;
      
      if (contents == null) {
        Logger.root.warning('No contents found in music home response');
        return {'body': [], 'head': []};
      }
      
      final List<Map> bodyItems = [];
      final List<Map> headItems = [];
      
      for (final section in contents) {
        try {
          // Parse different shelf types
          final musicCarouselShelf = section['musicCarouselShelfRenderer'];
          final musicShelfRenderer = section['musicShelfRenderer'];
          final gridRenderer = section['gridRenderer'];
          final richGridRenderer = section['richGridRenderer'];
          final itemSection = section['itemSectionRenderer'];
          
          if (musicCarouselShelf != null) {
            final parsed = _parseMusicCarouselShelf(musicCarouselShelf);
            if (parsed != null && parsed['playlists'].isNotEmpty) {
              bodyItems.add(parsed);
            }
          } else if (musicShelfRenderer != null) {
            final parsed = _parseMusicShelf(musicShelfRenderer);
            if (parsed != null && parsed['playlists'].isNotEmpty) {
              bodyItems.add(parsed);
            }
          } else if (gridRenderer != null) {
            final parsed = _parseGrid(gridRenderer);
            if (parsed != null && parsed['playlists'].isNotEmpty) {
              bodyItems.add(parsed);
            }
          } else if (richGridRenderer != null) {
            final parsed = _parseRichGrid(richGridRenderer);
            if (parsed != null && parsed['playlists'].isNotEmpty) {
              bodyItems.add(parsed);
            }
          } else if (itemSection != null) {
            // Handle itemSectionRenderer which may contain Music Insights or other sections
            final parsed = _parseItemSection(itemSection);
            if (parsed != null && parsed['playlists'].isNotEmpty) {
              bodyItems.add(parsed);
            }
          }
        } catch (e) {
          Logger.root.warning('Error parsing section in music home: $e');
          // Continue with next section instead of failing completely
          continue;
        }
      }
      
      // Parse header carousel if present
      try {
        final header = NavClass.nav(response, [
          'header',
          'carouselHeaderRenderer',
          'contents',
        ]) as List?;
        
        if (header != null && header.isNotEmpty) {
          for (final item in header) {
            final carouselItem = item['carouselItemRenderer'];
            if (carouselItem != null) {
              final carouselItems = carouselItem['carouselItems'] as List?;
              if (carouselItems != null) {
                for (final ci in carouselItems) {
                  final parsed = _parseDefaultPromoPanel(ci);
                  if (parsed != null) {
                    headItems.add(parsed);
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        Logger.root.warning('Error parsing header carousel: $e');
        // Continue without header items
      }
      
      return {'body': bodyItems, 'head': headItems};
    } catch (e) {
      Logger.root.severe('Error parsing music home: $e');
      return {'body': [], 'head': []};
    }
  }
  
  static Map? _parseMusicCarouselShelf(Map shelf) {
    try {
      final title = NavClass.nav(shelf, [
        'header',
        'musicCarouselShelfBasicHeaderRenderer',
        'title',
        'runs',
        0,
        'text',
      ]) as String?;
      
      if (title == null) return null;
      
      final contents = shelf['contents'] as List?;
      if (contents == null) return null;
      
      final List items = [];
      
      for (final item in contents) {
        final twoRowItem = item['musicTwoRowItemRenderer'];
        final responsiveItem = item['musicResponsiveListItemRenderer'];
        
        if (twoRowItem != null) {
          final parsed = _parseTwoRowItem(twoRowItem);
          if (parsed != null) items.add(parsed);
        } else if (responsiveItem != null) {
          final parsed = _parseResponsiveItem(responsiveItem);
          if (parsed != null) items.add(parsed);
        }
      }
      
      return {
        'title': title,
        'playlists': items,
      };
    } catch (e) {
      Logger.root.warning('Error parsing music carousel shelf: $e');
      return null;
    }
  }
  
  static Map? _parseMusicShelf(Map shelf) {
    try {
      final title = NavClass.nav(shelf, ['title', 'runs', 0, 'text']) as String?;
      if (title == null) return null;
      
      final contents = shelf['contents'] as List?;
      if (contents == null) return null;
      
      final List items = [];
      
      for (final item in contents) {
        final responsiveItem = item['musicResponsiveListItemRenderer'];
        if (responsiveItem != null) {
          final parsed = _parseResponsiveItem(responsiveItem);
          if (parsed != null) items.add(parsed);
        }
      }
      
      return {
        'title': title,
        'playlists': items,
      };
    } catch (e) {
      Logger.root.warning('Error parsing music shelf: $e');
      return null;
    }
  }
  
  static Map? _parseGrid(Map grid) {
    try {
      final header = grid['header'];
      String? title;
      
      if (header != null) {
        title = NavClass.nav(header, [
          'gridHeaderRenderer',
          'title',
          'runs',
          0,
          'text',
        ]) as String?;
      }
      
      final items = grid['items'] as List?;
      if (items == null) return null;
      
      final List parsedItems = [];
      
      for (final item in items) {
        final videoRenderer = item['gridVideoRenderer'];
        final playlistRenderer = item['gridPlaylistRenderer'];
        
        if (videoRenderer != null) {
          final parsed = _parseGridVideo(videoRenderer);
          if (parsed != null) parsedItems.add(parsed);
        } else if (playlistRenderer != null) {
          final parsed = _parseGridPlaylist(playlistRenderer);
          if (parsed != null) parsedItems.add(parsed);
        }
      }
      
      return {
        'title': title ?? 'Grid',
        'playlists': parsedItems,
      };
    } catch (e) {
      Logger.root.warning('Error parsing grid: $e');
      return null;
    }
  }
  
  static Map? _parseTwoRowItem(Map item) {
    try {
      final title = NavClass.nav(item, ['title', 'runs', 0, 'text']) as String?;
      if (title == null) return null;
      
      final subtitle = NavClass.joinRunTexts(
        NavClass.nav(item, ['subtitle', 'runs']) as List?,
      );
      
      final thumbnails = NavClass.nav(item, [
        'thumbnailRenderer',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]) as List?;
      
      final navigationEndpoint = item['navigationEndpoint'] as Map?;
      String? playlistId;
      String? videoId;
      String type = 'playlist';
      
      if (navigationEndpoint != null) {
        final watchEndpoint = navigationEndpoint['watchEndpoint'];
        final browseEndpoint = navigationEndpoint['browseEndpoint'];
        
        if (watchEndpoint != null) {
          playlistId = watchEndpoint['playlistId'] as String?;
          videoId = watchEndpoint['videoId'] as String?;
          type = playlistId != null ? 'playlist' : 'video';
        } else if (browseEndpoint != null) {
          playlistId = browseEndpoint['browseId'] as String?;
          type = 'playlist';
        }
      }
      
      return {
        'title': title,
        'type': type,
        'description': subtitle,
        'count': '',
        'playlistId': playlistId ?? '',
        'videoId': videoId ?? '',
        'firstItemId': videoId ?? playlistId ?? '',
        'image': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails[0]['url'] 
            : '',
        'imageMedium': thumbnails != null && thumbnails.length > 1 
            ? thumbnails[1]['url'] 
            : '',
        'imageStandard': thumbnails != null && thumbnails.length > 2 
            ? thumbnails[2]['url'] 
            : '',
        'imageMax': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
      };
    } catch (e) {
      Logger.root.warning('Error parsing two row item: $e');
      return null;
    }
  }
  
  static Map? _parseResponsiveItem(Map item) {
    try {
      final flexColumns = item['flexColumns'] as List?;
      if (flexColumns == null || flexColumns.isEmpty) return null;
      
      final title = NavClass.nav(flexColumns[0], [
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        0,
        'text',
      ]) as String?;
      
      if (title == null) return null;
      
      String subtitle = '';
      if (flexColumns.length > 1) {
        subtitle = NavClass.joinRunTexts(
          NavClass.nav(flexColumns[1], [
            'musicResponsiveListItemFlexColumnRenderer',
            'text',
            'runs',
          ]) as List?,
        );
      }
      
      final thumbnails = NavClass.nav(item, [
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]) as List?;
      
      final playlistItemData = item['playlistItemData'];
      String? videoId = playlistItemData?['videoId'] as String?;
      
      final navigationEndpoint = NavClass.nav(item, [
        'overlay',
        'musicItemThumbnailOverlayRenderer',
        'content',
        'musicPlayButtonRenderer',
        'playNavigationEndpoint',
      ]) as Map?;
      
      String? playlistId;
      if (navigationEndpoint != null) {
        final watchEndpoint = navigationEndpoint['watchEndpoint'];
        if (watchEndpoint != null) {
          playlistId = watchEndpoint['playlistId'] as String?;
          videoId ??= watchEndpoint['videoId'] as String?;
        }
      }
      
      return {
        'title': title,
        'type': 'playlist',
        'description': subtitle,
        'count': '',
        'playlistId': playlistId ?? '',
        'videoId': videoId ?? '',
        'firstItemId': videoId ?? playlistId ?? '',
        'image': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails[0]['url'] 
            : '',
        'imageMedium': thumbnails != null && thumbnails.length > 1 
            ? thumbnails[1]['url'] 
            : '',
        'imageStandard': thumbnails != null && thumbnails.length > 2 
            ? thumbnails[2]['url'] 
            : '',
        'imageMax': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
      };
    } catch (e) {
      Logger.root.warning('Error parsing responsive item: $e');
      return null;
    }
  }
  
  static Map? _parseGridVideo(Map item) {
    try {
      final title = NavClass.nav(item, ['title', 'simpleText']) as String?;
      if (title == null) return null;
      
      final videoId = item['videoId'] as String?;
      if (videoId == null) return null;
      
      final shortByline = NavClass.nav(item, [
        'shortBylineText',
        'runs',
        0,
        'text',
      ]) as String?;
      
      final viewCount = NavClass.nav(item, [
        'shortViewCountText',
        'simpleText',
      ]) as String?;
      
      final thumbnails = NavClass.nav(item, [
        'thumbnail',
        'thumbnails',
      ]) as List?;
      
      return {
        'title': title,
        'type': 'video',
        'description': shortByline ?? '',
        'count': viewCount ?? '',
        'videoId': videoId,
        'firstItemId': videoId,
        'image': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
        'imageMin': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails[0]['url'] 
            : '',
        'imageMedium': thumbnails != null && thumbnails.length > 1 
            ? thumbnails[1]['url'] 
            : '',
        'imageStandard': thumbnails != null && thumbnails.length > 2 
            ? thumbnails[2]['url'] 
            : '',
        'imageMax': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
      };
    } catch (e) {
      Logger.root.warning('Error parsing grid video: $e');
      return null;
    }
  }
  
  static Map? _parseGridPlaylist(Map item) {
    try {
      final title = NavClass.nav(item, ['title', 'runs', 0, 'text']) as String?;
      if (title == null) return null;
      
      final shortByline = NavClass.nav(item, [
        'shortBylineText',
        'runs',
        0,
        'text',
      ]) as String?;
      
      final videoCount = NavClass.nav(item, [
        'videoCountText',
        'runs',
        0,
        'text',
      ]) as String?;
      
      final navigationEndpoint = item['navigationEndpoint'] as Map?;
      String? playlistId;
      String? videoId;
      
      if (navigationEndpoint != null) {
        final watchEndpoint = navigationEndpoint['watchEndpoint'];
        if (watchEndpoint != null) {
          playlistId = watchEndpoint['playlistId'] as String?;
          videoId = watchEndpoint['videoId'] as String?;
        }
      }
      
      final thumbnails = NavClass.nav(item, [
        'thumbnail',
        'thumbnails',
      ]) as List?;
      
      return {
        'title': title,
        'type': 'chart',
        'description': shortByline ?? '',
        'count': videoCount ?? '',
        'playlistId': playlistId ?? '',
        'firstItemId': videoId ?? '',
        'image': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails[0]['url'] 
            : '',
        'imageMedium': thumbnails != null && thumbnails.length > 1 
            ? thumbnails[1]['url'] 
            : (thumbnails != null && thumbnails.isNotEmpty ? thumbnails[0]['url'] : ''),
        'imageStandard': thumbnails != null && thumbnails.length > 2 
            ? thumbnails[2]['url'] 
            : (thumbnails != null && thumbnails.isNotEmpty ? thumbnails[0]['url'] : ''),
        'imageMax': thumbnails != null && thumbnails.length > 3 
            ? thumbnails.last['url'] 
            : (thumbnails != null && thumbnails.isNotEmpty ? thumbnails[0]['url'] : ''),
      };
    } catch (e) {
      Logger.root.warning('Error parsing grid playlist: $e');
      return null;
    }
  }
  
  static Map? _parseDefaultPromoPanel(Map item) {
    try {
      final promoPanel = item['defaultPromoPanelRenderer'];
      if (promoPanel == null) return null;
      
      final title = NavClass.nav(promoPanel, ['title', 'runs', 0, 'text']) as String?;
      if (title == null) return null;
      
      final description = NavClass.joinRunTexts(
        NavClass.nav(promoPanel, ['description', 'runs']) as List?,
      );
      
      final videoId = NavClass.nav(promoPanel, [
        'navigationEndpoint',
        'watchEndpoint',
        'videoId',
      ]) as String?;
      
      final thumbnails = NavClass.nav(promoPanel, [
        'largeFormFactorBackgroundThumbnail',
        'thumbnailLandscapePortraitRenderer',
        'landscape',
        'thumbnails',
      ]) as List?;
      
      return {
        'title': title,
        'type': 'video',
        'description': description,
        'videoId': videoId ?? '',
        'firstItemId': videoId ?? '',
        'image': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
        'imageMedium': thumbnails != null && thumbnails.length > 1 
            ? thumbnails[1]['url'] 
            : '',
        'imageStandard': thumbnails != null && thumbnails.length > 2 
            ? thumbnails[2]['url'] 
            : '',
        'imageMax': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
      };
    } catch (e) {
      Logger.root.warning('Error parsing default promo panel: $e');
      return null;
    }
  }
  
  static Map? _parseRichGrid(Map grid) {
    try {
      final header = grid['header'];
      String? title;
      
      if (header != null) {
        title = NavClass.nav(header, [
          'richGridHeaderRenderer',
          'title',
          'runs',
          0,
          'text',
        ]) as String?;
      }
      
      final contents = grid['contents'] as List?;
      if (contents == null) return null;
      
      final List parsedItems = [];
      
      for (final item in contents) {
        try {
          final richItem = item['richItemRenderer'];
          final richSection = item['richSectionRenderer'];
          
          if (richItem != null) {
            final content = richItem['content'];
            if (content != null) {
              final videoRenderer = content['videoRenderer'];
              final playlistRenderer = content['playlistRenderer'];
              
              if (videoRenderer != null) {
                final parsed = _parseRichItemVideo(videoRenderer);
                if (parsed != null) parsedItems.add(parsed);
              } else if (playlistRenderer != null) {
                final parsed = _parseRichItemPlaylist(playlistRenderer);
                if (parsed != null) parsedItems.add(parsed);
              }
            }
          } else if (richSection != null) {
            // Handle rich sections which may contain multiple items
            final sectionContents = richSection['content'];
            if (sectionContents != null) {
              final sectionCarousel = sectionContents['richShelfRenderer'];
              if (sectionCarousel != null) {
                final parsed = _parseRichShelf(sectionCarousel);
                if (parsed != null && parsed is List) {
                  parsedItems.addAll(parsed);
                }
              }
            }
          }
        } catch (e) {
          Logger.root.warning('Error parsing rich grid item: $e');
          continue;
        }
      }
      
      return {
        'title': title ?? 'Grid',
        'playlists': parsedItems,
      };
    } catch (e) {
      Logger.root.warning('Error parsing rich grid: $e');
      return null;
    }
  }
  
  static Map? _parseItemSection(Map section) {
    try {
      final contents = section['contents'] as List?;
      if (contents == null || contents.isEmpty) return null;
      
      final List parsedItems = [];
      String? sectionTitle = 'Music Insights';
      
      for (final item in contents) {
        try {
          // Handle various content types in item section
          final videoRenderer = item['videoRenderer'];
          final playlistRenderer = item['playlistRenderer'];
          final shelfRenderer = item['shelfRenderer'];
          final musicCarousel = item['musicCarouselShelfRenderer'];
          
          if (videoRenderer != null) {
            final parsed = _parseRichItemVideo(videoRenderer);
            if (parsed != null) parsedItems.add(parsed);
          } else if (playlistRenderer != null) {
            final parsed = _parseRichItemPlaylist(playlistRenderer);
            if (parsed != null) parsedItems.add(parsed);
          } else if (shelfRenderer != null) {
            // Extract title from shelf if present
            final title = NavClass.nav(shelfRenderer, ['title', 'runs', 0, 'text']) as String?;
            if (title != null) sectionTitle = title;
            
            final shelfContents = shelfRenderer['content'];
            if (shelfContents != null) {
              final horizontalList = shelfContents['horizontalListRenderer'];
              if (horizontalList != null) {
                final items = horizontalList['items'] as List?;
                if (items != null) {
                  for (final hItem in items) {
                    final parsed = _parseTwoRowItem(hItem['musicTwoRowItemRenderer']);
                    if (parsed != null) parsedItems.add(parsed);
                  }
                }
              }
            }
          } else if (musicCarousel != null) {
            // Nested carousel
            final carouselTitle = NavClass.nav(musicCarousel, [
              'header',
              'musicCarouselShelfBasicHeaderRenderer',
              'title',
              'runs',
              0,
              'text',
            ]) as String?;
            if (carouselTitle != null) sectionTitle = carouselTitle;
            
            final carouselContents = musicCarousel['contents'] as List?;
            if (carouselContents != null) {
              for (final cItem in carouselContents) {
                final parsed = _parseTwoRowItem(cItem['musicTwoRowItemRenderer']);
                if (parsed != null) parsedItems.add(parsed);
              }
            }
          }
        } catch (e) {
          Logger.root.warning('Error parsing item section content: $e');
          continue;
        }
      }
      
      if (parsedItems.isEmpty) return null;
      
      return {
        'title': sectionTitle,
        'playlists': parsedItems,
      };
    } catch (e) {
      Logger.root.warning('Error parsing item section: $e');
      return null;
    }
  }
  
  static List? _parseRichShelf(Map shelf) {
    try {
      final contents = shelf['contents'] as List?;
      if (contents == null) return null;
      
      final List parsedItems = [];
      
      for (final item in contents) {
        try {
          final twoRowItem = item['musicTwoRowItemRenderer'];
          if (twoRowItem != null) {
            final parsed = _parseTwoRowItem(twoRowItem);
            if (parsed != null) parsedItems.add(parsed);
          }
        } catch (e) {
          Logger.root.warning('Error parsing rich shelf item: $e');
          continue;
        }
      }
      
      return parsedItems;
    } catch (e) {
      Logger.root.warning('Error parsing rich shelf: $e');
      return null;
    }
  }
  
  static Map? _parseRichItemVideo(Map renderer) {
    try {
      final title = NavClass.nav(renderer, ['title', 'runs', 0, 'text']) as String?;
      if (title == null) return null;
      
      final videoId = renderer['videoId'] as String?;
      if (videoId == null) return null;
      
      final viewCount = NavClass.nav(renderer, [
        'shortViewCountText',
        'simpleText',
      ]) as String?;
      
      final ownerText = NavClass.nav(renderer, [
        'ownerText',
        'runs',
        0,
        'text',
      ]) as String?;
      
      final thumbnails = NavClass.nav(renderer, [
        'thumbnail',
        'thumbnails',
      ]) as List?;
      
      return {
        'title': title,
        'type': 'video',
        'description': ownerText ?? '',
        'count': viewCount ?? '',
        'videoId': videoId,
        'firstItemId': videoId,
        'image': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
        'imageMin': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails[0]['url'] 
            : '',
        'imageMedium': thumbnails != null && thumbnails.length > 1 
            ? thumbnails[1]['url'] 
            : '',
        'imageStandard': thumbnails != null && thumbnails.length > 2 
            ? thumbnails[2]['url'] 
            : '',
        'imageMax': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
      };
    } catch (e) {
      Logger.root.warning('Error parsing rich item video: $e');
      return null;
    }
  }
  
  static Map? _parseRichItemPlaylist(Map renderer) {
    try {
      final title = NavClass.nav(renderer, ['title', 'simpleText']) as String?;
      if (title == null) return null;
      
      final playlistId = renderer['playlistId'] as String?;
      if (playlistId == null) return null;
      
      final videoCount = NavClass.nav(renderer, [
        'videoCountShortText',
        'simpleText',
      ]) as String?;
      
      final ownerText = NavClass.nav(renderer, [
        'shortBylineText',
        'runs',
        0,
        'text',
      ]) as String?;
      
      final thumbnails = NavClass.nav(renderer, [
        'thumbnailRenderer',
        'playlistVideoThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]) as List?;
      
      return {
        'title': title,
        'type': 'playlist',
        'description': ownerText ?? '',
        'count': videoCount ?? '',
        'playlistId': playlistId,
        'firstItemId': playlistId,
        'image': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails[0]['url'] 
            : '',
        'imageMedium': thumbnails != null && thumbnails.length > 1 
            ? thumbnails[1]['url'] 
            : '',
        'imageStandard': thumbnails != null && thumbnails.length > 2 
            ? thumbnails[2]['url'] 
            : '',
        'imageMax': thumbnails != null && thumbnails.isNotEmpty 
            ? thumbnails.last['url'] 
            : '',
      };
    } catch (e) {
      Logger.root.warning('Error parsing rich item playlist: $e');
      return null;
    }
  }
}
