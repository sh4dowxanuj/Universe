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
import 'package:universe/CustomWidgets/drawer.dart';
import 'package:universe/CustomWidgets/on_hover.dart';
import 'package:universe/Screens/Search/search.dart';
import 'package:universe/Screens/YouTube/youtube_playlist.dart';
import 'package:universe/Services/youtube_services.dart';

bool status = false;
List searchedList = Hive.box('cache').get('ytHome', defaultValue: []) as List;
List headList = Hive.box('cache').get('ytHomeHead', defaultValue: []) as List;

class YouTube extends StatefulWidget {
  const YouTube({super.key});

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube>
    with AutomaticKeepAliveClientMixin<YouTube> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!status && searchedList.isEmpty) {
      _loadYouTubeMusicHome();
    }
  }

  Future<void> _loadYouTubeMusicHome() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final value = await YouTubeServices.instance.getMusicHome();
      status = true;
      if (value.isNotEmpty) {
        setState(() {
          searchedList = value['body'] ?? [];
          headList = value['head'] ?? [];
          _isLoading = false;
        });
        // Cache the results
        await Hive.box('cache').put('ytHome', value['body']);
        await Hive.box('cache').put('ytHomeHead', value['head']);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'No content available. Please try again.';
          _isLoading = false;
        });
        status = false;
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load YouTube Music. Please check your connection and try again.';
        _isLoading = false;
      });
      status = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext cntxt) {
    super.build(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool rotated = MediaQuery.sizeOf(context).height < screenWidth;
    double boxSize = !rotated
        ? MediaQuery.sizeOf(context).width / 2
        : MediaQuery.sizeOf(context).height / 2.5;
    if (boxSize > 250) boxSize = 250;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Loading state
            if (_isLoading && searchedList.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              )
            // Error state
            else if (_hasError && searchedList.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadYouTubeMusicHome,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            // Content loaded
            else if (searchedList.isNotEmpty)
              RefreshIndicator(
                onRefresh: _loadYouTubeMusicHome,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 70, 10, 0),
                  child: Column(
                    children: [
                      if (headList.isNotEmpty)
                        CarouselSlider.builder(
                          itemCount: headList.length,
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
                          ) =>
                              GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => SearchPage(
                                    query: headList[index]['title'].toString(),
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
                                image: AssetImage(
                                  'assets/ytCover.png',
                                ),
                              ),
                              imageUrl: headList[index]['image'].toString(),
                              placeholder: (context, url) => const Image(
                                fit: BoxFit.cover,
                                image: AssetImage('assets/ytCover.png'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ListView.builder(
                      itemCount: searchedList.length,
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 10),
                      itemBuilder: (context, index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 10, 0, 5),
                                    child: Text(
                                      '${searchedList[index]["title"]}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: boxSize + 10,
                              width: double.infinity,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                itemCount:
                                    (searchedList[index]['playlists'] as List)
                                        .length,
                                itemBuilder: (context, idx) {
                                  final item =
                                      searchedList[index]['playlists'][idx];
                                  item['subtitle'] = item['type'] != 'video'
                                      ? '${item["count"]} Tracks | ${item["description"]}'
                                      : '${item["count"]} | ${item["description"]}';
                                  return GestureDetector(
                                    onTap: () {
                                      item['type'] == 'video'
                                          ? Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                opaque: false,
                                                pageBuilder: (_, __, ___) =>
                                                    SearchPage(
                                                  query:
                                                      item['title'].toString(),
                                                  searchType:
                                                      Hive.box('settings').get(
                                                    'searchYtMusic',
                                                    defaultValue: true,
                                                  ) as bool
                                                          ? 'ytm'
                                                          : 'yt',
                                                  fromDirectSearch: true,
                                                ),
                                              ),
                                            )
                                          : Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                opaque: false,
                                                pageBuilder: (_, __, ___) =>
                                                    YouTubePlaylist(
                                                  playlistId: item['playlistId']
                                                      .toString(),
                                                  // playlistImage:
                                                  //     item['imageStandard']
                                                  //         .toString(),
                                                  // playlistName:
                                                  //     item['title'].toString(),
                                                  // playlistSubtitle:
                                                  //     '${item['count']} Songs',
                                                  // playlistSecondarySubtitle:
                                                  //     item['description']
                                                  //         ?.toString(),
                                                ),
                                              ),
                                            );
                                    },
                                    child: SizedBox(
                                      width: item['type'] != 'playlist'
                                          ? (boxSize - 30) * (16 / 9)
                                          : boxSize - 30,
                                      child: HoverBox(
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: Card(
                                                      elevation: 5,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10.0,
                                                        ),
                                                      ),
                                                      clipBehavior:
                                                          Clip.antiAlias,
                                                      child: CachedNetworkImage(
                                                        fit: BoxFit.cover,
                                                        errorWidget:
                                                            (context, _, __) =>
                                                                Image(
                                                          fit: BoxFit.cover,
                                                          image: item['type'] !=
                                                                  'playlist'
                                                              ? const AssetImage(
                                                                  'assets/ytCover.png',
                                                                )
                                                              : const AssetImage(
                                                                  'assets/cover.jpg',
                                                                ),
                                                        ),
                                                        imageUrl: item['image']
                                                            .toString(),
                                                        placeholder:
                                                            (context, url) =>
                                                                Image(
                                                          fit: BoxFit.cover,
                                                          image: item['type'] !=
                                                                  'playlist'
                                                              ? const AssetImage(
                                                                  'assets/ytCover.png',
                                                                )
                                                              : const AssetImage(
                                                                  'assets/cover.jpg',
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (item['type'] == 'chart')
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Container(
                                                        color: Colors.black
                                                            .withOpacity(0.75),
                                                        width: (boxSize - 30) *
                                                            (16 / 9) /
                                                            2.5,
                                                        margin: const EdgeInsets
                                                            .all(
                                                          4.0,
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              item['count']
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const IconButton(
                                                              onPressed: null,
                                                              color:
                                                                  Colors.white,
                                                              disabledColor:
                                                                  Colors.white,
                                                              icon: Icon(
                                                                Icons
                                                                    .playlist_play_rounded,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    '${item["title"]}',
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    item['subtitle'].toString(),
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .color,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 5.0,
                                                  ),
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
                                            color: isHover
                                                ? null
                                                : Colors.transparent,
                                            elevation: 0,
                                            margin: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                10.0,
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: child,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                width: MediaQuery.sizeOf(context).width,
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
                    searchType: Hive.box('settings')
                            .get('searchYtMusic', defaultValue: true) as bool
                        ? 'ytm'
                        : 'yt',
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
