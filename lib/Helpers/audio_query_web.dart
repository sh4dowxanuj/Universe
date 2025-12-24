import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Web stub for OfflineAudioQuery; returns empty collections and placeholders.
class OfflineAudioQuery {
  static OnAudioQuery audioQuery = OnAudioQuery();
  static final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');

  Future<void> requestPermission() async {}

  Future<List<SongModel>> getSongs({
    SongSortType? sortType,
    OrderType? orderType,
    String? path,
  }) async {
    return [];
  }

  Future<List<PlaylistModel>> getPlaylists() async => [];
  Future<bool> createPlaylist({required String name}) async => false;
  Future<bool> removePlaylist({required int playlistId}) async => false;
  Future<bool> addToPlaylist({required int playlistId, required int audioId})
      async => false;
  Future<bool> removeFromPlaylist({required int playlistId, required int audioId})
      async => false;
  Future<bool> renamePlaylist({required int playlistId, required String newName})
      async => false;
  Future<List<SongModel>> getPlaylistSongs(
    int playlistId, {
    SongSortType? sortType,
    OrderType? orderType,
    String? path,
  }) async => [];
  Future<List<AlbumModel>> getAlbums({
    AlbumSortType? sortType,
    OrderType? orderType,
  }) async => [];
  Future<List<ArtistModel>> getArtists({
    ArtistSortType? sortType,
    OrderType? orderType,
  }) async => [];
  Future<List<GenreModel>> getGenres({
    GenreSortType? sortType,
    OrderType? orderType,
  }) async => [];

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
    return placeholder ?? errorWidget ?? const SizedBox();
  }
}
