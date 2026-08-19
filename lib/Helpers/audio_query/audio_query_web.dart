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

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class OfflineAudioQuery {
  static final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');

  Future<void> requestPermission() async {}

  Future<List<SongModel>> getSongs({
    SongSortType? sortType,
    OrderType? orderType,
    String? path,
  }) async {
    return [];
  }

  Future<List<PlaylistModel>> getPlaylists() async {
    return [];
  }

  Future<bool> createPlaylist({required String name}) async {
    return false;
  }

  Future<bool> removePlaylist({required int playlistId}) async {
    return false;
  }

  Future<bool> addToPlaylist({
    required int playlistId,
    required int audioId,
  }) async {
    return false;
  }

  Future<bool> removeFromPlaylist({
    required int playlistId,
    required int audioId,
  }) async {
    return false;
  }

  Future<bool> renamePlaylist({
    required int playlistId,
    required String newName,
  }) async {
    return false;
  }

  Future<List<SongModel>> getPlaylistSongs(
    int playlistId, {
    SongSortType? sortType,
    OrderType? orderType,
    String? path,
  }) async {
    return [];
  }

  Future<List<AlbumModel>> getAlbums({
    AlbumSortType? sortType,
    OrderType? orderType,
  }) async {
    return [];
  }

  Future<List<ArtistModel>> getArtists({
    ArtistSortType? sortType,
    OrderType? orderType,
  }) async {
    return [];
  }

  Future<List<GenreModel>> getGenres({
    GenreSortType? sortType,
    OrderType? orderType,
  }) async {
    return [];
  }

  static Future<String> queryNSave({
    required int id,
    required ArtworkType type,
    required String tempPath,
    required String fileName,
    int size = 500,
    int quality = 100,
    ArtworkFormat format = ArtworkFormat.PNG,
  }) async {
    return '';
  }

  static Widget offlineArtworkWidget({
    required int id,
    required ArtworkType type,
    required String tempPath,
    required String fileName,
    int size = 500,
    int quality = 100,
    ArtworkFormat format = ArtworkFormat.PNG,
    ArtworkType artworkType = ArtworkType.AUDIO,
    BorderRadius? borderRadius,
    Clip clipBehavior = Clip.antiAlias,
    BoxFit fit = BoxFit.cover,
    FilterQuality filterQuality = FilterQuality.low,
    double height = 50.0,
    double width = 50.0,
    double elevation = 5,
    ImageRepeat imageRepeat = ImageRepeat.noRepeat,
    bool gaplessPlayback = true,
    Widget? errorWidget,
    Widget? placeholder,
  }) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(7.0),
      ),
      clipBehavior: clipBehavior,
      child: placeholder ??
          Image(
            fit: fit,
            height: height,
            width: width,
            image: const AssetImage('assets/cover.jpg'),
          ),
    );
  }
}
