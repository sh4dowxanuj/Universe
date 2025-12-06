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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universe/APIs/api.dart';
import 'package:universe/CustomWidgets/bouncy_playlist_header_scroll_view.dart';
import 'package:universe/CustomWidgets/copy_clipboard.dart';
import 'package:universe/CustomWidgets/download_button.dart';
import 'package:universe/CustomWidgets/gradient_containers.dart';
import 'package:universe/CustomWidgets/image_card.dart';
import 'package:universe/CustomWidgets/like_button.dart';
import 'package:universe/CustomWidgets/playlist_popupmenu.dart';
import 'package:universe/CustomWidgets/snackbar.dart';
import 'package:universe/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:universe/Helpers/extensions.dart';
import 'package:universe/Models/url_image_generator.dart';
import 'package:universe/Services/player_service.dart';

class SongsListPage extends StatefulWidget {
  final Map listItem;

  const SongsListPage({
    super.key,
    required this.listItem,
  });

  @override
  _SongsListPageState createState() => _SongsListPageState();
}

class _SongsListPageState extends State<SongsListPage> {
  int page = 1;
  bool loading = false;
  List songList = [];
  bool fetched = false;
  bool isSharePopupShown = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSongs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          widget.listItem['type'].toString() == 'songs' &&
          !loading) {
        page += 1;
        _fetchSongs();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _fetchSongs() {
    loading = true;
    try {
      switch (widget.listItem['type'].toString()) {
        case 'songs':
          SaavnAPI()
              .fetchSongSearchResults(
            searchQuery: widget.listItem['id'].toString(),
            page: page,
          )
              .then((value) {
            setState(() {
              songList.addAll(value['songs'] as List);
              fetched = true;
              loading = false;
            });
            if (value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                context,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'album':
          SaavnAPI()
              .fetchAlbumSongs(widget.listItem['id'].toString())
              .then((value) {
            setState(() {
              songList = value['songs'] as List;
              fetched = true;
              loading = false;
            });
            if (value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                context,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'playlist':
          SaavnAPI()
              .fetchPlaylistSongs(widget.listItem['id'].toString())
              .then((value) {
            setState(() {
              songList = value['songs'] as List;
              fetched = true;
              loading = false;
            });
            if (value['error'] != null && value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                context,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'mix':
          SaavnAPI()
              .getSongFromToken(
            widget.listItem['perma_url'].toString().split('/').last,
            'mix',
          )
              .then((value) {
            setState(() {
              songList = value['songs'] as List;
              fetched = true;
              loading = false;
            });

            if (value['error'] != null && value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                context,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'show':
          SaavnAPI()
              .getSongFromToken(
            widget.listItem['perma_url'].toString().split('/').last,
            'show',
          )
              .then((value) {
            setState(() {
              songList = value['songs'] as List;
              fetched = true;
              loading = false;
            });

            if (value['error'] != null && value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                context,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        default:
          setState(() {
            fetched = true;
            loading = false;
          });
          ShowSnackBar().showSnackBar(
            context,
            'Error: Unsupported Type ${widget.listItem['type']}',
            duration: const Duration(seconds: 3),
          );
          break;
      }
    } catch (e) {
      setState(() {
        fetched = true;
        loading = false;
      });
      Logger.root.severe(
        'Error in song_list with type ${widget.listItem["type"]}: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: !fetched
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : BouncyPlaylistHeaderScrollView(
                scrollController: _scrollController,
                actions: [
                  if (songList.isNotEmpty)
                    MultiDownloadButton(
                      data: songList,
                      playlistName:
                          widget.listItem['title']?.toString() ?? 'Songs',
                    ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: AppLocalizations.of(context)!.share,
                    onPressed: () {
                      if (!isSharePopupShown) {
                        isSharePopupShown = true;

                        Share.share(
                          widget.listItem['perma_url'].toString(),
                        ).whenComplete(() {
                          Timer(const Duration(milliseconds: 500), () {
                            isSharePopupShown = false;
                          });
                        });
                      }
                    },
                  ),
                  PlaylistPopupMenu(
                    data: songList,
                    title: widget.listItem['title']?.toString() ?? 'Songs',
                  ),
                ],
                title:
                    widget.listItem['title']?.toString().unescape() ?? 'Songs',
                subtitle: '${songList.length} Songs',
                secondarySubtitle: widget.listItem['subTitle']?.toString() ??
                    widget.listItem['subtitle']?.toString(),
                onPlayTap: () => PlayerInvoke.init(
                  songsList: songList,
                  index: 0,
                  isOffline: false,
                ),
                onShuffleTap: () => PlayerInvoke.init(
                  songsList: songList,
                  index: 0,
                  isOffline: false,
                  shuffle: true,
                ),
                placeholderImage: 'assets/album.png',
                imageUrl: UrlImageGetter([widget.listItem['image']?.toString()])
                    .mediumQuality,
                sliverList: SliverList(
                  delegate: SliverChildListDelegate([
                    if (songList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          top: 5.0,
                          bottom: 5.0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.songs,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ...songList.map((entry) {
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 15.0),
                        title: Text(
                          '${entry["title"]}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onLongPress: () {
                          copyToClipboard(
                            context: context,
                            text: '${entry["title"]}',
                          );
                        },
                        subtitle: Text(
                          '${entry["subtitle"]}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: imageCard(imageUrl: entry['image'].toString()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DownloadButton(
                              data: entry as Map,
                              icon: 'download',
                            ),
                            LikeButton(
                              mediaItem: null,
                              data: entry,
                            ),
                            SongTileTrailingMenu(data: entry),
                          ],
                        ),
                        onTap: () {
                          PlayerInvoke.init(
                            songsList: songList,
                            index: songList.indexWhere(
                              (element) => element == entry,
                            ),
                            isOffline: false,
                          );
                        },
                      );
                    }),
                  ]),
                ),
              ),
      ),
    );
  }
}
