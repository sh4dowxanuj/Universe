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
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:universe/CustomWidgets/snackbar.dart';
import 'package:universe/Helpers/lyrics.dart';
import 'package:universe/Helpers/platform_check.dart';
import 'package:universe/Services/download/download_platform_helper.dart';
import 'package:universe/Services/ext_storage_provider.dart';
import 'package:universe/Services/ytdlp_service.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:universe/src/gen_l10n/app_localizations.dart';

class Download with ChangeNotifier {
  static final Map<String, Download> _instances = {};
  final String id;

  factory Download(String id) {
    if (_instances.containsKey(id)) {
      return _instances[id]!;
    } else {
      final instance = Download._internal(id);
      _instances[id] = instance;
      return instance;
    }
  }

  Download._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  String preferredDownloadQuality = Hive.box('settings')
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String preferredYtDownloadQuality = Hive.box('settings')
      .get('ytDownloadQuality', defaultValue: 'High') as String;
  String downloadFormat = Hive.box('settings')
      .get('downloadFormat', defaultValue: 'm4a')
      .toString();
  bool createDownloadFolder = Hive.box('settings')
      .get('createDownloadFolder', defaultValue: false) as bool;
  bool createYoutubeFolder = Hive.box('settings')
      .get('createYoutubeFolder', defaultValue: false) as bool;
  double? progress = 0.0;
  String lastDownloadId = '';
  bool downloadLyrics =
      Hive.box('settings').get('downloadLyrics', defaultValue: false) as bool;
  bool download = true;

  Future<void> prepareDownload(
    BuildContext context,
    Map data, {
    bool createFolder = false,
    String? folderName,
  }) async {
    Logger.root.info('Preparing download for ${data['title']}');
    download = true;
    await DownloadPlatformHelper.requestStoragePermission();
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split('(From')[0].trim();

    String filename = '';
    final int downFilename =
        Hive.box('settings').get('downFilename', defaultValue: 0) as int;
    if (downFilename == 0) {
      filename = '${data["title"]} - ${data["artist"]}';
    } else if (downFilename == 1) {
      filename = '${data["artist"]} - ${data["title"]}';
    } else {
      filename = '${data["title"]}';
    }
    // String filename = '${data["title"]} - ${data["artist"]}';
    String dlPath =
        Hive.box('settings').get('downloadPath', defaultValue: '') as String;
    Logger.root.info('Cached Download path: $dlPath');
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(avoid, "").replaceAll("  ", " ")}.m4a';
    if (dlPath == '') {
      Logger.root.info('Cached Download path is empty, getting new path');
      final String? temp = await ExtStorageProvider.getExtStorage(
        dirName: 'Music',
        writeAccess: true,
      );
      dlPath = temp!;
    }
    Logger.root.info('New Download path: $dlPath');
    if (data['url'].toString().contains('google') && createYoutubeFolder) {
      Logger.root.info('Youtube audio detected, creating Youtube folder');
      dlPath = '$dlPath/YouTube';
      if (!await DownloadPlatformHelper.directoryExists(dlPath)) {
        Logger.root.info('Creating Youtube folder');
        await DownloadPlatformHelper.createDirectory(dlPath);
      }
    }

    if (createFolder && createDownloadFolder && folderName != null) {
      final String foldername = folderName.replaceAll(avoid, '');
      dlPath = '$dlPath/$foldername';
      if (!await DownloadPlatformHelper.directoryExists(dlPath)) {
        Logger.root.info('Creating folder $foldername');
        await DownloadPlatformHelper.createDirectory(dlPath);
      }
    }

    final bool exists = await DownloadPlatformHelper.fileExists('$dlPath/$filename');
    if (exists) {
      Logger.root.info('File already exists');
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = data['id'].toString();
          case 1:
            downloadSong(context, dlPath, filename, data);
          case 2:
            while (await DownloadPlatformHelper.fileExists('$dlPath/$filename')) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
          default:
            lastDownloadId = data['id'].toString();
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text(
                AppLocalizations.of(context)!.alreadyExists,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${data['title']}" ${AppLocalizations.of(context)!.downAgain}',
                    softWrap: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: [
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: remember,
                      builder: (
                        BuildContext context,
                        bool rememberValue,
                        Widget? child,
                      ) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                value: rememberValue,
                                onChanged: (bool? value) {
                                  remember.value = value ?? false;
                                },
                              ),
                              Text(
                                AppLocalizations.of(context)!.rememberChoice,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = data['id'].toString();
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: Text(
                              AppLocalizations.of(context)!.no,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              Hive.box('downloads').delete(data['id']);
                              downloadSong(context, dlPath, filename, data);
                              rememberOption = 1;
                            },
                            child:
                                Text(AppLocalizations.of(context)!.yesReplace),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await DownloadPlatformHelper.fileExists('$dlPath/$filename')) {
                                filename =
                                    filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadSong(context, dlPath, filename, data);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.yes,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      downloadSong(context, dlPath, filename, data);
    }
  }

  Future<void> downloadSong(
    BuildContext context,
    String? dlPath,
    String fileName,
    Map data,
  ) async {
    Logger.root.info('processing download');
    progress = null;
    notifyListeners();
    String? filepath;
    late String filepath2;
    String? appPath;
    final List<int> bytes = [];
    String lyrics = '';
    final artname = fileName.replaceAll('.m4a', '.jpg');
    if (!PlatformCheck.isWindows) {
      Logger.root.info('Getting App Path for storing image');
      appPath = Hive.box('settings').get('tempDirPath')?.toString();
      appPath ??= await DownloadPlatformHelper.getTempDir();
    } else {
      appPath = await DownloadPlatformHelper.getDownloadsDir();
    }

    try {
      Logger.root.info('Creating audio file $dlPath/$fileName');
      filepath = await DownloadPlatformHelper.createFile('$dlPath/$fileName');
      Logger.root.info('Creating image file $appPath/$artname');
      filepath2 = await DownloadPlatformHelper.createFile('$appPath/$artname');
    } catch (e) {
      Logger.root
          .info('Error creating files, requesting additional permission');
      await DownloadPlatformHelper.requestManageExternalStoragePermission();

      Logger.root.info('Retrying to create audio file');
      filepath = await DownloadPlatformHelper.createFile('$dlPath/$fileName');

      Logger.root.info('Retrying to create image file');
      filepath2 = await DownloadPlatformHelper.createFile('$appPath/$artname');
    }
    String kUrl = data['url'].toString();

    if (!data['url'].toString().contains('google')) {
      Logger.root.info('Fetching jiosaavn download url with preferred quality');
      kUrl = kUrl.replaceAll(
        '_96.',
        "_${preferredDownloadQuality.replaceAll(' kbps', '')}.",
      );
    }

    int total = 0;
    int recieved = 0;
    Client? client;
    Stream<List<int>> stream;
    // Download from yt
    if (data['url'].toString().contains('google')) {
      Logger.root.info('Downloading from YouTube: ${data['id']}');
      try {
        Logger.root.info('Fetching stream URL using yt-dlp for download');

        // Use yt-dlp to get authenticated stream URL
        final ytDownloadQuality = Hive.box('settings')
            .get('ytDownloadQuality', defaultValue: 'High') as String;
        final ytdlpData = await YtDlpService.instance
            .getAudioStream(data['id'].toString(), quality: ytDownloadQuality);

        if (ytdlpData == null || ytdlpData['url'] == null) {
          Logger.root
              .severe('yt-dlp failed to get stream URL for ${data['id']}');
          ShowSnackBar().showSnackBar(
            context,
            'Failed to download: Could not get stream URL',
          );
          throw Exception('yt-dlp failed to get stream URL');
        }

        final String streamUrl = ytdlpData['url'] as String;
        final int bitrate = (ytdlpData['bitrate'] ?? 0) as int;
        final String codec = (ytdlpData['codec'] ?? 'unknown') as String;

        Logger.root
            .info('✅ yt-dlp SUCCESS: Got download URL ($bitrate kbps, $codec)');

        // Download from the authenticated URL
        Logger.root.info('Starting HTTP download from authenticated URL');
        client = Client();
        final response =
            await client.send(Request('GET', Uri.parse(streamUrl)));
        total = response.contentLength ?? 0;

        Logger.root.info(
            'Download size: ${(total / 1024 / 1024).toStringAsFixed(2)} MB',);

        stream = response.stream.asBroadcastStream();

        // youtube_explode_dart REMOVED - causes 403 errors
        // Old code using getStreamInfo() and getStreamClient() commented out
      } catch (e, stackTrace) {
        Logger.root.severe('Error fetching YouTube stream: $e\n$stackTrace');
        ShowSnackBar().showSnackBar(
          context,
          'Download failed: $e',
        );
        rethrow;
      }
    } else {
      Logger.root.info('Connecting to Client');
      client = Client();
      final response = await client.send(Request('GET', Uri.parse(kUrl)));
      total = response.contentLength ?? 0;
      stream = response.stream.asBroadcastStream();
    }
    Logger.root.info('Client connected, Starting download');
    stream.listen((value) {
      bytes.addAll(value);
      try {
        recieved += value.length;
        progress = recieved / total;
        notifyListeners();
        if (!download && client != null) {
          client.close();
          // need to add for yt as well
        }
      } catch (e) {
        Logger.root.severe('Error in download: $e');
      }
    }).onDone(() async {
      if (download) {
        Logger.root.info('Download complete, modifying file');
        await DownloadPlatformHelper.writeFileBytes(filepath!, bytes);

        final bytes2 = await DownloadPlatformHelper.fetchImageBytes(data['image'].toString());
        await DownloadPlatformHelper.writeFileBytes(filepath2, bytes2);
        try {
          Logger.root.info('Checking if lyrics required');
          if (downloadLyrics) {
            Logger.root.info('downloading lyrics');
            final Map res = await Lyrics.getLyrics(
              id: data['id'].toString(),
              title: data['title'].toString(),
              artist: data['artist'].toString(),
              saavnHas: data['has_lyrics'] == 'true',
            );
            lyrics = res['lyrics'].toString();
          }
        } catch (e) {
          Logger.root.severe('Error fetching lyrics: $e');
          lyrics = '';
        }
        
        Logger.root.info('Getting audio tags');
        await DownloadPlatformHelper.writeTags(
          filePath: filepath ?? '',
          data: data,
          imagePath: filepath2,
          lyrics: lyrics,
          imageBytes: bytes2,
        );

        Logger.root.info('Closing connection & notifying listeners');
        client?.close();
        lastDownloadId = data['id'].toString();
        progress = 0.0;
        notifyListeners();

        Logger.root.info('Putting data to downloads database');
        final songData = {
          'id': data['id'].toString(),
          'title': data['title'].toString(),
          'subtitle': data['subtitle'].toString(),
          'artist': data['artist'].toString(),
          'albumArtist': data['album_artist']?.toString() ??
              data['artist']?.toString().split(', ')[0],
          'album': data['album'].toString(),
          'genre': data['language'].toString(),
          'year': data['year'].toString(),
          'lyrics': lyrics,
          'duration': data['duration'],
          'release_date': data['release_date'].toString(),
          'album_id': data['album_id'].toString(),
          'perma_url': data['perma_url'].toString(),
          'quality': preferredDownloadQuality,
          'path': filepath,
          'image': filepath2,
          'image_url': data['image'].toString(),
          'from_yt': data['language'].toString() == 'YouTube',
          'dateAdded': DateTime.now().toString(),
        };
        Hive.box('downloads').put(songData['id'].toString(), songData);

        Logger.root.info('Everything done, showing snackbar');
        ShowSnackBar().showSnackBar(
          context,
          '"${data['title']}" ${AppLocalizations.of(context)!.downed}',
        );
      } else {
        download = true;
        progress = 0.0;
        DownloadPlatformHelper.deleteFile(filepath!);
        DownloadPlatformHelper.deleteFile(filepath2);
      }
    });
  }
}
