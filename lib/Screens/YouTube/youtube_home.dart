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

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:universe/CustomWidgets/drawer.dart';
import 'package:universe/CustomWidgets/on_hover.dart';
import 'package:universe/Screens/Search/search.dart';
import 'package:universe/Screens/YouTube/youtube_playlist.dart';
import 'package:universe/Services/error_service.dart';
import 'package:universe/Services/player_service.dart';
import 'package:universe/Services/youtube_services.dart';
import 'package:universe/Services/yt_music.dart';
import 'package:universe/main.dart';

// Refactor: local per-section state replaces globals and app-wide flags.
class HomeSection {
  final String id;
  final String title;
  final String cacheKey;
  List<Map<String, dynamic>> items;
  bool isLoading;
  String? error;

  HomeSection({
    required this.id,
    required this.title,
    required this.cacheKey,
    List<Map<String, dynamic>>? items,
    this.isLoading = false,
    this.error,
  }) : items = items ?? <Map<String, dynamic>>[];
}


class YouTube extends StatefulWidget {
  const YouTube({super.key});

  // UI-only normalized shelf titles for a premium feel.
  static String normalizedUiTitle(String title) {
    final t = title.trim().toLowerCase();
    String key = '';
    
    if (t.contains('popular')) {
      key = 'popular';
    } else if (t.contains('trending')) {
      key = 'trending';
    } else if (t.contains('top')) {
      key = 'top_hits';
    } else if (t.contains('new release') || t.contains('new')) {
      key = 'new_releases';
    } else if (t.contains('discover')) {
      key = 'discover';
    } else if (t.contains('recommended') || t.contains('for you')) {
      key = 'recommended';
    } else if (t.contains('mix')) {
      key = 'mixes';
    } else if (t.contains('chart')) {
      key = 'charts';
    } else if (t.contains('editor')) {
      key = 'editors_picks';
    }
    
    switch (key) {
      case 'popular': return 'Popular Picks';
      case 'trending': return 'Trending Now';
      case 'top_hits': return 'Top Hits';
      case 'new_releases': return 'New Releases';
      case 'discover': return 'Discover';
      case 'recommended': return 'Recommended For You';
      case 'mixes': return 'Your Mixes';
      case 'charts': return 'Top Charts';
      case 'editors_picks': return 'Editor’s Picks';
      default: return title;
    }
  }

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube>
    with AutomaticKeepAliveClientMixin<YouTube>, TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final List<HomeSection> _sections = [];
  List<Map<String, dynamic>> _headItems = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bootstrapFromCache();
    _refreshAllSections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Seed UI from cache and create default sections.
  void _bootstrapFromCache() {
    try {
      // Safely hydrate head carousel from cache (defensive against shape issues).
      _headItems = _safeReadCacheMapList('ytHomeHead');

      // Safely hydrate legacy single-list home cache to bootstrap sections.
      final cachedHome = _safeReadCacheMapList('ytHome');

      if (cachedHome.isNotEmpty) {
        for (int i = 0; i < cachedHome.length; i++) {
          final sec = cachedHome[i];
          final title = (sec['title'] ?? 'Discover').toString();
          final stableKey = _sectionKeyForTitle(title);
          final newCacheKey = 'ytHome.section.$stableKey';

          // Prefer well-formed playlists from cached body, fall back to per-section cache.
          List<Map<String, dynamic>> items = [];
          if (sec['playlists'] is List) {
            items = (sec['playlists'] as List)
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList();
          }
          if (items.isEmpty) {
            items = _safeReadSectionCache(title);
          }
          _sections.add(
            HomeSection(
              id: 'cached-$i',
              title: title,
              cacheKey: newCacheKey,
              items: items,
            ),
          );
          if (items.isNotEmpty) {
            // Persist in stable-key cache; migration of old keys happens lazily in readers.
            _writeSectionCache(title, items);
          }
        }
      } else {
        const defaults = [
          'Popular Music', 
          'Trending Songs', 
          'Top Hits', 
          'New Releases',
          'Mood Mixes',
          'Top Charts',
          'Workout Music',
          'Chill Hits',
        ];
        for (int i = 0; i < defaults.length; i++) {
          final title = defaults[i];
          final stableKey = _sectionKeyForTitle(title);
          final newCacheKey = 'ytHome.section.$stableKey';
          // Read existing per-section cache, migrating any legacy title-keyed data.
          final items = _safeReadSectionCache(title);
          _sections.add(
            HomeSection(
              id: 'default-$i',
              title: title,
              cacheKey: newCacheKey,
              items: items,
            ),
          );
        }
      }

      // Personalization: Continue Listening from local recent history
      final continueItems = _getContinueListeningItems();
      if (continueItems.isNotEmpty) {
        _sections.add(
          HomeSection(
            id: 'continue',
            title: 'Continue Listening',
            cacheKey: 'ytHome.section.continue_listening',
            items: continueItems,
          ),
        );
      }
    } catch (e, st) {
      Logger.root.warning('Bootstrap cache failed: $e');
      locator<ErrorService>().reportError('YouTubeHome._bootstrapFromCache', e, st);
    }
  }

  /// Refresh head carousel and all sections. Allows partial failures.
  Future<void> _refreshAllSections() async {
    if (!mounted) return;
    // Mark all sections as loading in a single frame.
    setState(() {});

    for (final s in _sections) {
      s.isLoading = true;
      s.error = null;
    }

    try {
      Map<String, dynamic> homeResult = {'body': [], 'head': []};
      try {
        homeResult = await YouTubeServices.instance.getMusicHome();
      } catch (e, st) {
        Logger.root.warning('Home fetch failed; using fallbacks: $e');
        locator<ErrorService>().reportError('YouTubeHome._refreshAllSections.fetch', e, st);
      }

      final bodySections = (homeResult['body'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      final newHead = (homeResult['head'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      if (newHead.isNotEmpty) {
        _headItems = newHead;
        try {
          Hive.box('cache').put('ytHomeHead', _headItems);
        } catch (e) {
          Logger.root.warning('Failed to cache ytHomeHead: $e');
        }
      }

      if (bodySections.isNotEmpty) {
        final List<HomeSection> next = [];
        final List<Future<void>> fallbacks = [];
        
        for (int i = 0; i < bodySections.length; i++) {
          try {
            final sec = bodySections[i];
            final title = (sec['title'] ?? 'Discover').toString();
            final stableKey = _sectionKeyForTitle(title);
            final newCacheKey = 'ytHome.section.$stableKey';
            
            List<Map<String, dynamic>> items = [];
            if (sec['playlists'] is List) {
              items = (sec['playlists'] as List)
                  .whereType<Map>()
                  .map((m) => Map<String, dynamic>.from(m))
                  .toList();
            }
            
            final existing = _sections.where((s) => s.cacheKey == newCacheKey).toList();
            final section = existing.isNotEmpty
                ? existing.first
                : HomeSection(id: 'server-$i', title: title, cacheKey: newCacheKey);
            
            section.items = _filterAndLimitItems(items);
            section.isLoading = false;
            section.error = null;
            next.add(section);
            
            if (section.items.isEmpty) {
              fallbacks.add(_fillSectionFromFallback(section));
            } else {
              _writeSectionCache(title, section.items);
            }
          } catch (e) {
            Logger.root.warning('Error processing section $i: $e');
          }
        }
        
        _dedupeAndLimitSections(next);
        final continueSection = _sections.where((s) => s.id == 'continue').toList();
        
        if (mounted) {
          setState(() {
            _sections
              ..clear()
              ..addAll(_applyDailyOrderVariation(next))
              ..addAll(continueSection);
          });
        }
        
        if (fallbacks.isNotEmpty) {
          await Future.wait(fallbacks);
        }
      } else {
        await Future.wait(_sections.where((s) => s.id != 'continue').map(_loadSectionIndependently));
        final continueSection = _sections.where((s) => s.id == 'continue').toList();
        final others = _sections.where((s) => s.id != 'continue').toList();
        
        if (mounted) {
          setState(() {
            _sections
              ..clear()
              ..addAll(_applyDailyOrderVariation(others))
              ..addAll(continueSection);
          });
        }
      }
    } catch (e, st) {
      Logger.root.severe('Fatal error in _refreshAllSections: $e');
      locator<ErrorService>().reportError('YouTubeHome._refreshAllSections.fatal', e, st);
    } finally {
      for (final s in _sections) {
        s.isLoading = false;
      }
      if (mounted) setState(() {});
    }
  }

  /// Load a section independently using search-based fallback, and cache it.
  Future<void> _loadSectionIndependently(HomeSection section) async {
    try {
      section.isLoading = true;
      final results = await YouTubeServices.instance.fetchSearchResults(section.title);
      List<Map<String, dynamic>> items = [];
      if (results.isNotEmpty && results.first['items'] is List) {
        items = (results.first['items'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      section.items = items;
      section.error = null;
      if (items.isNotEmpty) {
        // Store into stable-key cache for this section.
        section.items = _filterAndLimitItems(section.items);
        _writeSectionCache(section.title, section.items);
      }
    } catch (e, st) {
      section.error = e.toString();
      Logger.root.warning('Section load failed for "${section.title}": $e');
      locator<ErrorService>().reportError('YouTubeHome._loadSectionIndependently', e, st);
    } finally {
      section.isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Populate a section when the API returns an empty shelf.
  Future<List<Map<String, dynamic>>> _fallbackSearchSection(String title) async {
    try {
      final cached = _readFallbackCache(title);
      if (cached.isNotEmpty) {
        return cached;
      }

      final ytmItems = await _ytMusicFallback(title);
      if (ytmItems.isNotEmpty) {
        _writeFallbackCache(title, ytmItems);
        return ytmItems;
      }

      final results = await YouTubeServices.instance.fetchSearchResults(title);
      if (results.isNotEmpty && results.first['items'] is List) {
        final fresh = (results.first['items'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        final filtered = _filterAndLimitItems(fresh);
        if (filtered.isNotEmpty) {
          _writeFallbackCache(title, filtered);
        }
        return filtered;
      }
    } catch (e, st) {
      Logger.root.warning('Fallback search failed for "$title": $e');
      locator<ErrorService>().reportError('YouTubeHome._fallbackSearchSection', e, st);
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _fillSectionFromFallback(HomeSection section) async {
    final items = await _fallbackSearchSection(section.title);
    section.items = _filterAndLimitItems(items);
    section.isLoading = false;
    if (section.items.isNotEmpty) {
      _writeSectionCache(section.title, section.items);
    }
    if (mounted) setState(() {});
  }

  Future<List<Map<String, dynamic>>> _ytMusicFallback(String title) async {
    try {
      final results = await YtMusicService().search(title, filter: 'songs');
      for (final section in results) {
        if (section['items'] is List) {
          final items = (section['items'] as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .map((m) {
                final id = (m['id'] ?? '').toString();
                final imageList = (m['images'] as List?) ?? [];
                final image = imageList.isNotEmpty ? imageList.first.toString() : (m['image'] ?? '').toString();
                return {
                  'id': id,
                  'title': (m['title'] ?? '').toString(),
                  'artist': (m['artist'] ?? '').toString(),
                  'album': (m['album'] ?? '').toString(),
                  'duration': (m['duration'] ?? '').toString(),
                  'image': image,
                  'secondImage': image,
                  'type': 'song',
                  'perma_url': 'https://youtube.com/watch?v=$id',
                };
              })
              .toList();
          final filtered = _filterAndLimitItems(items);
          if (filtered.isNotEmpty) return filtered;
        }
      }
    } catch (e, st) {
      Logger.root.warning('YT Music fallback failed for "$title": $e');
      locator<ErrorService>().reportError('YouTubeHome._ytMusicFallback', e, st);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _filterAndLimitItems(List<Map<String, dynamic>> items) {
    final List<Map<String, dynamic>> cleaned = [];
    for (final item in items) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final duration = _parseDurationSeconds((item['duration'] ?? '').toString());
      if (duration != null && duration < 25) continue; // skip shorts/live teasers
      cleaned.add(item);
    }
    return cleaned.take(12).toList();
  }

  int? _parseDurationSeconds(String value) {
    if (value.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(value)) return int.tryParse(value);
    final parts = value.split(':').map((e) => e.trim()).toList();
    if (parts.any((e) => e.isEmpty)) return null;
    int seconds = 0;
    for (int i = 0; i < parts.length; i++) {
      final parsed = int.tryParse(parts[parts.length - 1 - i]);
      if (parsed == null) return null;
      seconds += parsed * (pow(60, i) as int);
    }
    return seconds;
  }

  void _dedupeAndLimitSections(List<HomeSection> sections) {
    final Set<String> seen = <String>{};
    for (final section in sections.where((s) => s.id != 'continue')) {
      final List<Map<String, dynamic>> unique = [];
      for (final item in section.items) {
        final id = (item['id'] ?? '').toString();
        final key = id.isEmpty
            ? '${item['title'] ?? ''}-${item['image'] ?? ''}'
            : id;
        if (seen.contains(key)) continue;
        seen.add(key);
        unique.add(item);
        if (unique.length >= 12) break;
      }
      section.items = unique;
    }
  }

  List<Map<String, dynamic>> _readFallbackCache(String title) {
    try {
      final box = Hive.box('cache');
      final stableKey = 'ytHome.section.${_sectionKeyForTitle(title)}.fallback';
      if (!box.containsKey(stableKey)) return <Map<String, dynamic>>[];
      final raw = box.get(stableKey);
      if (raw is Map && raw['ts'] is int && raw['items'] is List) {
        final ts = raw['ts'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - ts < const Duration(minutes: 15).inMilliseconds) {
          return (raw['items'] as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    } catch (e, st) {
      Logger.root.warning('Failed to read fallback cache for "$title": $e');
      locator<ErrorService>().reportError('YouTubeHome._readFallbackCache', e, st);
    }
    return <Map<String, dynamic>>[];
  }

  void _writeFallbackCache(String title, List<Map<String, dynamic>> items) {
    try {
      final box = Hive.box('cache');
      final stableKey = 'ytHome.section.${_sectionKeyForTitle(title)}.fallback';
      box.put(stableKey, {
        'ts': DateTime.now().millisecondsSinceEpoch,
        'items': items,
      });
    } catch (e, st) {
      Logger.root.warning('Failed to write fallback cache for "$title": $e');
      locator<ErrorService>().reportError('YouTubeHome._writeFallbackCache', e, st);
    }
  }

  /// Safely read a list of maps from the 'cache' box, validating shape.
  List<Map<String, dynamic>> _safeReadCacheMapList(String key) {
    try {
      final box = Hive.box('cache');
      final raw = box.get(key);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e, st) {
      Logger.root.warning('Hive cache read failed for key "$key": $e');
      locator<ErrorService>().reportError('YouTubeHome._safeReadCacheMapList.$key', e, st);
    }
    return [];
  }

  /// Read section cache using stable key, migrating any legacy title-based cache once.
  List<Map<String, dynamic>> _safeReadSectionCache(String title) {
    final stableKey = 'ytHome.section.${_sectionKeyForTitle(title)}';
    final legacyKey = _legacyKeyForTitle(title);
    // Try stable key first.
    final stable = _safeReadCacheMapList(stableKey);
    if (stable.isNotEmpty) return stable;

    // Fallback: migrate legacy key into stable key then delete legacy.
    final legacy = _safeReadCacheMapList(legacyKey);
    if (legacy.isNotEmpty) {
      try {
        final box = Hive.box('cache');
        box.put(stableKey, legacy);
        if (box.containsKey(legacyKey)) {
          box.delete(legacyKey);
        }
      } catch (e, st) {
        Logger.root.warning('Failed migrating legacy cache "$legacyKey" to "$stableKey": $e');
        locator<ErrorService>().reportError('YouTubeHome._safeReadSectionCache.migrate', e, st);
      }
      return legacy;
    }
    return [];
  }

  /// Write per-section cache using stable key only.
  void _writeSectionCache(String title, List<Map<String, dynamic>> items) {
    final stableKey = 'ytHome.section.${_sectionKeyForTitle(title)}';
    try {
      Hive.box('cache').put(stableKey, items);
    } catch (e, st) {
      Logger.root.warning('Failed to write section cache for "$stableKey": $e');
      locator<ErrorService>().reportError('YouTubeHome._writeSectionCache', e, st);
    }
  }

  /// Safely resolve the current YouTube search type from settings.
  String _getYoutubeSearchType() {
    try {
      final box = Hive.box('settings');
      final isMusic = box.get('searchYtMusic', defaultValue: true) as bool;
      return isMusic ? 'ytm' : 'yt';
    } catch (e, st) {
      Logger.root.warning('Failed to read searchYtMusic setting: $e');
      locator<ErrorService>().reportError('YouTubeHome._getYoutubeSearchType', e, st);
      return 'ytm';
    }
  }

  // Map variable titles to a stable internal key for cache safety.
  String _sectionKeyForTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.contains('popular')) return 'popular';
    if (t.contains('trending')) return 'trending';
    if (t.contains('top')) return 'top_hits';
    if (t.contains('new release') || t.contains('new')) return 'new_releases';
    if (t.contains('discover')) return 'discover';
    if (t.contains('recommended') || t.contains('for you')) return 'recommended';
    if (t.contains('mix')) return 'mixes';
    if (t.contains('chart')) return 'charts';
    if (t.contains('editor')) return 'editors_picks';
    // Fallback: slugify simplified title
    return t.replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp('_+'), '_');
  }

  // Legacy key used previously derived from raw titles.
  String _legacyKeyForTitle(String title) => 'ytHome.section.${title.toLowerCase()}';

  // Slightly vary shelf order per day (stable within the same day).
  List<HomeSection> _applyDailyOrderVariation(List<HomeSection> sections) {
    if (sections.isEmpty) return sections;
    final now = DateTime.now();
    final offset = (now.year + now.month + now.day) % sections.length;
    return [
      ...sections.sublist(offset),
      ...sections.sublist(0, offset),
    ];
  }

  // Build local personalization shelf using offline Hive history.
  List<Map<String, dynamic>> _getContinueListeningItems({int maxCount = 10}) {
    try {
      final box = Hive.box('cache');
      final recentListRaw = box.get('recentSongs', defaultValue: []);
      if (recentListRaw is! List) return [];
      final recent = recentListRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (recent.isEmpty) return [];
      final items = recent.take(maxCount).map((m) {
        final String artist = (m['artist'] ?? m['album'] ?? '').toString();
        return {
          'id': m['id']?.toString() ?? '',
          'title': (m['title'] ?? '').toString(),
          'artist': artist,
          'album': (m['album'] ?? '').toString(),
          'image': (m['image'] ?? m['secondImage'] ?? '').toString(),
          'secondImage': (m['secondImage'] ?? m['image'] ?? '').toString(),
          'type': 'video',
          'subtitle': artist,
          'genre': (m['genre'] ?? '').toString(),
          'language': (m['language'] ?? '').toString(),
        };
      }).toList();
      return items;
    } catch (_) {
      return [];
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Size screenSize = MediaQuery.sizeOf(context);
    final double screenWidth = screenSize.width;
    final bool rotated = screenSize.height < screenWidth;
    
    // Spotify style sizing
    double boxSize = !rotated ? screenWidth / 2.2 : screenWidth / 4.5;
    if (boxSize > 200) boxSize = 200;

    final continueItems = _getContinueListeningItems(maxCount: 6);
    final otherSections = _sections.where((s) => s.id != 'continue').toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
            RefreshIndicator(
              onRefresh: _refreshAllSections,
              displacement: 80,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 75, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Greeting
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Personalization Grid
                        if (continueItems.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: continueItems.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: rotated ? 3 : 2,
                              childAspectRatio: 3.2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (context, index) {
                              final item = continueItems[index];
                              return _QuickAccessCard(item: item);
                            },
                          ),
                        const SizedBox(height: 24),

                        // Head carousel
                        if (_headItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: CarouselSlider.builder(
                              itemCount: _headItems.length,
                              options: CarouselOptions(
                                height: boxSize * 1.1,
                                viewportFraction: rotated ? 0.4 : 0.92,
                                autoPlay: true,
                                enlargeCenterPage: true,
                                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                              ),
                              itemBuilder: (context, index, _) => _CarouselCard(
                                item: _headItems[index],
                                searchType: _getYoutubeSearchType(),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),

                  // Content Shelves
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final section = otherSections[index];
                          if (section.items.isEmpty && !section.isLoading) {
                            return const SizedBox.shrink();
                          }
                          
                          final isArtistSection = section.title.toLowerCase().contains('artist') || 
                                                 section.title.toLowerCase().contains('for you');

                          return _HomeShelf(
                            section: section,
                            boxSize: boxSize,
                            isArtistSection: isArtistSection,
                            normalizedTitle: YouTube.normalizedUiTitle(section.title),
                          );
                        },
                        childCount: otherSections.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
            
            // Fixed Search Bar
            _TopSearchBar(
              searchType: _getYoutubeSearchType(),
              screenSize: screenSize,
            ),
          ],
        ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _QuickAccessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Map? response = await YouTubeServices.instance.formatVideoFromId(
          id: item['id'].toString(),
          data: item,
        );
        if (response != null) {
          PlayerInvoke.init(songsList: [response], index: 0, isOffline: false);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
  children: [
    AspectRatio(
      aspectRatio: 1,
      child: item['image'].toString().isNotEmpty
          ? CachedNetworkImage(
              imageUrl: item['image'].toString(),
              fit: BoxFit.cover,
              memCacheHeight: 200, // Optimization: constrain memory usage
              errorWidget: (context, _, __) => const ColoredBox( // <-- Added const
                color: Colors.black12,
                child: Icon(Icons.music_note, size: 20),
              ),
            )
          : const ColoredBox( // <-- Added const
              color: Colors.black12,
              child: Icon(Icons.music_note, size: 20),
            ),
    ),
    Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          item['title'].toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  ],
),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String searchType;
  const _CarouselCard({required this.item, required this.searchType});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => SearchPage(
              query: item['title'].toString(),
              searchType: searchType,
              fromDirectSearch: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: item['image']?.toString().isNotEmpty ?? false
            ? CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: item['image']!.toString(),
                placeholder: (context, url) => Container(color: Colors.black12),
                errorWidget: (context, _, __) => Container(color: Colors.black12),
                memCacheWidth: 800, // Optimization
              )
            : Container(color: Colors.black12),
      ),
    );
  }
}

class _HomeShelf extends StatelessWidget {
  final HomeSection section;
  final double boxSize;
  final bool isArtistSection;
  final String normalizedTitle;

  const _HomeShelf({
    required this.section,
    required this.boxSize,
    required this.isArtistSection,
    required this.normalizedTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  normalizedTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (section.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: isArtistSection ? boxSize * 1.3 : boxSize * 1.4,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: section.isLoading ? 6 : section.items.length,
              itemBuilder: (context, idx) {
                if (section.isLoading) {
                  return _SkeletonCard(width: boxSize, height: boxSize);
                }
                final item = section.items[idx];
                return _ShelfCard(
                  boxSize: boxSize,
                  type: isArtistSection ? 'artist' : (item['type'] ?? 'playlist').toString(),
                  title: item['title'].toString(),
                  subtitle: item['subtitle']?.toString() ?? (item['artist'] ?? '').toString(),
                  image: (item['image'] ?? item['secondImage'] ?? '').toString(),
                  extra: item,
                  onTap: () async {
                    final type = (item['type'] ?? 'video').toString().toLowerCase();
                    final id = (item['id'] ?? '').toString();
                    
                    if (type == 'playlist' || (item['playlistId']?.toString().isNotEmpty ?? false)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => YouTubePlaylist(
                            playlistId: item['playlistId']?.toString() ?? id,
                          ),
                        ),
                      );
                      return;
                    }

                    if (id.isNotEmpty) {
                      final Map? response = await YouTubeServices.instance.formatVideoFromId(
                        id: id,
                        data: item,
                      );
                      if (response != null) {
                        PlayerInvoke.init(songsList: [response], index: 0, isOffline: false);
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  final String searchType;
  final Size screenSize;
  const _TopSearchBar({required this.searchType, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(
                query: '',
                fromHome: true,
                searchType: searchType,
                autofocus: true,
              ),
            ),
          ),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                homeDrawer(context: context),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.searchYt,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable shelf card widget for item tiles.
class _ShelfCard extends StatelessWidget {
  final double boxSize;
  final String type;
  final String title;
  final String subtitle;
  final String image;
  final Map<String, dynamic> extra;
  final VoidCallback onTap;

  const _ShelfCard({
    required this.boxSize,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.extra,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArtist = type == 'artist';

    return Container(
      width: boxSize,
      margin: const EdgeInsets.only(right: 16),
      child: HoverBox(
        child: const SizedBox.shrink(),
        builder: ({required context, required isHover, child}) {
          return GestureDetector(
            onTap: onTap,
            child: Column(
              crossAxisAlignment:
                  isArtist ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isArtist ? null : BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: isHover
                              ? Colors.black.withOpacity(0.4)
                              : Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            memCacheWidth:
                                (boxSize * MediaQuery.of(context).devicePixelRatio)
                                    .round(),
                            memCacheHeight:
                                (boxSize * MediaQuery.of(context).devicePixelRatio)
                                    .round(),
                            errorWidget: (context, _, __) => const ColoredBox(
                              color: Colors.black12,
                              child: Icon(Icons.music_note, size: 40),
                            ),
                          )
                        : const ColoredBox(
                            color: Colors.black12,
                            child: Icon(Icons.music_note, size: 40),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isArtist ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArtist ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .color!
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Lightweight animated skeleton placeholder used while shelves load.
class _SkeletonCard extends StatefulWidget {
  final double width;
  final double height;
  const _SkeletonCard({required this.width, required this.height});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).cardColor.withOpacity(0.10);
    final highlightColor = Theme.of(context).cardColor.withOpacity(0.20);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = Curves.easeInOut.transform(_controller.value);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              gradient: LinearGradient(
                begin: Alignment(-1 + value * 2, 0),
                end: Alignment(1 + value * 2, 0),
                colors: [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
