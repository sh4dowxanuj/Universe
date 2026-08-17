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

import 'package:logging/logging.dart';
import 'package:universe/Services/player_service.dart';
import 'package:universe/Services/youtube_services.dart';

Future<void> createRadioItems({
  required List<String> stationNames,
  String stationType = 'entity',
  int count = 20,
}) async {
  Logger.root
      .info('Creating Radio Station with $stationNames');
  final query = stationNames.join(' ');
  final searchResults = await YouTubeServices.instance.fetchSearchResults(query);
  final songs = searchResults.firstWhere(
    (element) => element['title'] == 'Songs',
    orElse: () => {},
  )['items'] as List?;

  if (songs == null || songs.isEmpty) return;

  PlayerInvoke.init(
    songsList: songs,
    index: 0,
    isOffline: false,
    shuffle: true,
  );
}
