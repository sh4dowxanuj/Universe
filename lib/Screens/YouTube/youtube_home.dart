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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:universe/CustomWidgets/drawer.dart';
import 'package:universe/CustomWidgets/on_hover.dart';
import 'package:universe/CustomWidgets/snackbar.dart';
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

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube>
    with AutomaticKeepAliveClientMixin<YouTube>, TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late TabController _tabController;
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
                .map((m) => m.cast<String, dynamic>())
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
        const defaults = ['Popular Music', 'Trending Songs', 'Top Hits', 'New Releases'];
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
        _sections.insert(
          0,
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

    Map<String, List> homeResult = {'body': [], 'head': []};
    try {
      homeResult = await YouTubeServices.instance.getMusicHome();
    } catch (e, st) {
      Logger.root.warning('Home fetch failed; using fallbacks: $e');
      locator<ErrorService>().reportError('YouTubeHome._refreshAllSections', e, st);
    }

    final newHead = homeResult['head']?.cast<Map<String, dynamic>>() ?? [];
    if (newHead.isNotEmpty) {
      _headItems = newHead;
      // Cache head items defensively.
      try {
        Hive.box('cache').put('ytHomeHead', _headItems);
      } catch (e, st) {
        Logger.root.warning('Failed to cache ytHomeHead: $e');
        locator<ErrorService>().reportError('YouTubeHome._refreshAllSections.head', e, st);
      }
    }

    final bodySections = homeResult['body']?.cast<Map<String, dynamic>>() ?? [];
    if (bodySections.isNotEmpty) {
      final List<HomeSection> next = [];
      for (int i = 0; i < bodySections.length; i++) {
        final sec = bodySections[i];
        final title = (sec['title'] ?? 'Discover').toString();
        final stableKey = _sectionKeyForTitle(title);
        final newCacheKey = 'ytHome.section.$stableKey';
        List<Map<String, dynamic>> items = [];
        if (sec['playlists'] is List) {
          items = (sec['playlists'] as List)
              .whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList();
        }
        final existing = _sections.where((s) => s.cacheKey == newCacheKey).toList();
        final section = existing.isNotEmpty
            ? existing.first
            : HomeSection(id: 'server-$i', title: title, cacheKey: newCacheKey);
        section.items = items;
        section.isLoading = false;
        section.error = null;
        next.add(section);
        // Persist sections using stable-key cache; any legacy data is migrated on read.
        if (items.isNotEmpty) {
          _writeSectionCache(title, items);
        }
      }
      final continueSection = _sections.where((s) => s.id == 'continue').toList();
      _sections
        ..clear()
        ..addAll(continueSection)
        ..addAll(_applyDailyOrderVariation(next));
    } else {
      await Future.wait(_sections.where((s) => s.id != 'continue').map(_loadSectionIndependently));
      final continueSection = _sections.where((s) => s.id == 'continue').toList();
      final others = _sections.where((s) => s.id != 'continue').toList();
      _sections
        ..clear()
        ..addAll(continueSection)
        ..addAll(_applyDailyOrderVariation(others));
    }

    if (!mounted) return;
    setState(() {});
  }

  /// Load a section independently using search-based fallback, and cache it.
  Future<void> _loadSectionIndependently(HomeSection section) async {
    try {
      section.isLoading = true;
      final results = await YouTubeServices.instance.fetchSearchResults(section.title);
      List<Map<String, dynamic>> items = [];
      if (results.isNotEmpty && results.first['items'] is List) {
        items = (results.first['items'] as List).cast<Map<String, dynamic>>();
      }
      section.items = items;
      section.error = null;
      if (items.isNotEmpty) {
        // Store into stable-key cache for this section.
        _writeSectionCache(section.title, items);
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

  /// Safely read a list of maps from the 'cache' box, validating shape.
  List<Map<String, dynamic>> _safeReadCacheMapList(String key) {
    try {
      final box = Hive.box('cache');
      final raw = box.get(key);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
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

  // UI-only normalized shelf titles for a premium feel.
  String _normalizedUiTitle(String title) {
    final key = _sectionKeyForTitle(title);
    switch (key) {
      case 'popular':
        return 'Popular Picks';
      case 'trending':
        return 'Trending Now';
      case 'top_hits':
        return 'Top Hits';
      case 'new_releases':
        return 'New Releases';
      case 'discover':
        return 'Discover';
      case 'recommended':
        return 'Recommended For You';
      case 'mixes':
        return 'Your Mixes';
      case 'charts':
        return 'Top Charts';
      case 'editors_picks':
        return 'Editor’s Picks';
      default:
        return title; // Preserve original for unknown sections
    }
  }

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
          .map((e) => e.cast<String, dynamic>())
          .toList();
      if (recent.isEmpty) return [];
      final items = recent.take(maxCount).map((m) {
        return {
          'id': m['id']?.toString() ?? '',
          'title': (m['title'] ?? '').toString(),
          'artist': (m['artist'] ?? '').toString(),
          'album': (m['album'] ?? '').toString(),
          'image': (m['image'] ?? m['secondImage'] ?? '').toString(),
          'secondImage': (m['secondImage'] ?? m['image'] ?? '').toString(),
          'type': 'video',
          'subtitle': (m['artist'] ?? m['album'] ?? '').toString(),
          'genre': (m['genre'] ?? '').toString(),
          'language': (m['language'] ?? '').toString(),
        };
      }).toList();
      return items;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext cntxt) {
    super.build(context);
    // Cache MediaQuery size locally to avoid repeated work.
    final Size screenSize = MediaQuery.sizeOf(context);
    final double screenWidth = screenSize.width;
    final bool rotated = screenSize.height < screenWidth;
    double boxSize = !rotated ? screenSize.width / 2 : screenSize.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Discover Home shelves (non-blocking loaders)
            RefreshIndicator(
              onRefresh: _refreshAllSections,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 70, 10, 0),
                child: Column(
                  children: [
                    // Head carousel or lightweight placeholder
                    if (_headItems.isNotEmpty)
                      CarouselSlider.builder(
                        itemCount: _headItems.length,
                        options: CarouselOptions(
                          height: boxSize + 20,
                          viewportFraction: rotated ? 0.36 : 1.0,
                          autoPlay: true,
                          enlargeCenterPage: true,
                        ),
                        itemBuilder: (
                          BuildContext context,
                          int index,
                          int pageViewIndex,
                        ) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => SearchPage(
                                  query: _headItems[index]['title'].toString(),
                                  searchType: Hive.box('settings').get(
                                    'searchYtMusic',
                                    defaultValue: true,
                                  ) as bool
                                      ? 'ytm'
                                      : 'yt',
                                  fromDirectSearch: true,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              errorWidget: (context, _, __) => const Image(
                                fit: BoxFit.cover,
                                image: AssetImage('assets/ytCover.png'),
                              ),
                              imageUrl: _headItems[index]['image']?.toString() ?? '',
                              placeholder: (context, url) => const Image(
                                fit: BoxFit.cover,
                                image: AssetImage('assets/ytCover.png'),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: boxSize + 20,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Theme.of(context).cardColor.withOpacity(0.15),
                        ),
                      ),

                    // Shelves
                    ListView.builder(
                      key: const PageStorageKey<String>('yt_home_sections'),
                      itemCount: _sections.length,
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 10),
                      itemBuilder: (context, index) {
                        final section = _sections[index];
                        return Column(
                          // Preserve per-section state & scroll position.
                          key: PageStorageKey<String>('yt_section_${section.cacheKey}_${section.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 10, 0, 5),
                                    child: Text(
                                      _normalizedUiTitle(section.title),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (section.isLoading)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final int itemCount = section.items.isNotEmpty
                                    ? section.items.length
                                    : (section.isLoading ? 6 : 0);
                                if (itemCount == 0) {
                                  // Gracefully collapse empty shelves when not loading
                                  return const SizedBox.shrink();
                                }
                                return SizedBox(
                                  height: boxSize + 10,
                                  width: double.infinity,
                                  child: ListView.builder(
                                    key: PageStorageKey<String>('yt_section_list_${section.cacheKey}'),
                                    physics: const BouncingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    itemCount: itemCount,
                                    itemBuilder: (context, idx) {
                                      if (section.items.isEmpty) {
                                        final double tileWidth = (boxSize - 30) * (16 / 9);
                                        return _SkeletonCard(
                                          key: ValueKey<String>('skeleton_${section.cacheKey}_$idx'),
                                          width: tileWidth,
                                          height: boxSize - 10,
                                        );
                                      }
                                  final item = section.items[idx];
                                  final String type = (item['type'] ?? 'video').toString();
                                  final String title = (item['title'] ?? '').toString();
                                  final String image = (item['image'] ?? item['secondImage'] ?? '').toString();
                                  final String subtitle = (
                                    item['subtitle'] ?? (item['artist'] ?? item['album'] ?? '')
                                  ).toString();
                                  final String? playlistId = item['playlistId']?.toString();
                                  return GestureDetector(
                                    key: ValueKey<String>('item_${section.cacheKey}_${item['id'] ?? idx}'),
                                    onTap: () async {
                                      if (type == 'playlist' && playlistId != null && playlistId.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (_, __, ___) => YouTubePlaylist(
                                              playlistId: playlistId,
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final String itemType = type.toLowerCase();
                                      if (itemType == 'song' || itemType == 'video') {
                                        final String id = (item['id'] ?? '').toString();
                                        if (id.isEmpty) {
                                          ShowSnackBar().showSnackBar(
                                            context,
                                            AppLocalizations.of(context)!.ytLiveAlert,
                                          );
                                          return;
                                        }

                                        final Map? response = (itemType == 'video')
                                            ? await YouTubeServices.instance.formatVideoFromId(
                                                id: id,
                                                data: item,
                                              )
                                            : await YtMusicService().getSongData(
                                                videoId: id,
                                                data: item,
                                                quality: Hive.box('settings')
                                                    .get('ytQuality', defaultValue: 'Low')
                                                    .toString(),
                                              );

                                        if (response != null) {
                                          PlayerInvoke.init(
                                            songsList: [response],
                                            index: 0,
                                            isOffline: false,
                                          );
                                        } else {
                                          ShowSnackBar().showSnackBar(
                                            context,
                                            AppLocalizations.of(context)!.ytLiveAlert,
                                          );
                                        }
                                      } else {
                                        // Fallback for non-playlist, non-song/video types: keep current search behavior.
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (_, __, ___) => SearchPage(
                                              query: title,
                                              searchType: _getYoutubeSearchType(),
                                              fromDirectSearch: true,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: _ShelfCard(
                                      boxSize: boxSize,
                                      type: type,
                                      title: title,
                                      subtitle: subtitle,
                                      image: image,
                                      extra: item,
                                    ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Search bar overlay
            GestureDetector(
              child: Container(
                width: screenSize.width,
                height: 55.0,
                padding: const EdgeInsets.all(5.0),
                margin:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                // margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    10.0,
                  ),
                  color: Theme.of(context).cardColor,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5.0,
                      offset: Offset(1.5, 1.5),
                      // shadow direction: bottom right
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    homeDrawer(context: context),
                    const SizedBox(
                      width: 5.0,
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!
                          .searchYt,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Theme.of(context).textTheme.bodySmall!.color,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchPage(
                    query: '',
                    fromHome: true,
                    searchType: _getYoutubeSearchType(),
                    autofocus: true,
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

/// Reusable shelf card widget for item tiles.
class _ShelfCard extends StatelessWidget {
  final double boxSize;
  final String type; // 'playlist', 'video', 'chart', etc.
  final String title;
  final String subtitle;
  final String image;
  final Map<String, dynamic> extra;

  const _ShelfCard({
    required this.boxSize,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaylist = type == 'playlist';
    final isChart = type == 'chart';
    final tileWidth = isPlaylist ? boxSize - 30 : (boxSize - 30) * (16 / 9);

    return SizedBox(
      width: tileWidth,
      child: HoverBox(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        errorWidget: (context, _, __) => Image(
                          fit: BoxFit.cover,
                          image: isPlaylist
                              ? const AssetImage('assets/cover.jpg')
                              : const AssetImage('assets/ytCover.png'),
                        ),
                        imageUrl: image,
                        placeholder: (context, url) => Image(
                          fit: BoxFit.cover,
                          image: isPlaylist
                              ? const AssetImage('assets/cover.jpg')
                              : const AssetImage('assets/ytCover.png'),
                        ),
                      ),
                    ),
                  ),
                  if (isChart)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        color: Colors.black.withOpacity(0.75),
                        width: tileWidth / 2.5,
                        margin: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (extra['count'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const IconButton(
                              onPressed: null,
                              color: Colors.white,
                              disabledColor: Colors.white,
                              icon: Icon(
                                Icons.playlist_play_rounded,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                ],
              ),
            ),
          ],
        ),
        builder: ({
          required BuildContext context,
          required bool isHover,
          Widget? child,
        }) {
          return Card(
            color: isHover ? null : Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
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
  const _SkeletonCard({super.key, required this.width, required this.height});

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
