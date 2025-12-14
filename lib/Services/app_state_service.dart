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

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized application state management
class AppStateService {
  final Logger _logger = Logger('AppStateService');

  // Home screen state
  final ValueNotifier<bool> isHomeLoading = ValueNotifier(false);
  final ValueNotifier<List<Map>> homeData = ValueNotifier([]);
  final ValueNotifier<String?> homeError = ValueNotifier(null);

  // Search state
  final ValueNotifier<bool> isSearching = ValueNotifier(false);
  final ValueNotifier<List<Map>> searchResults = ValueNotifier([]);
  final ValueNotifier<String?> searchError = ValueNotifier(null);

  // Player state
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> totalDuration = ValueNotifier(null);
  final ValueNotifier<Map?> currentSong = ValueNotifier(null);

  // Navigation state
  final ValueNotifier<String> currentRoute = ValueNotifier('/');
  final ValueNotifier<Map<String, dynamic>> navigationState = ValueNotifier({});

  // Connectivity state
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  // Initialization state
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final Completer<void> _initializationCompleter = Completer();

  Future<void> get initializationComplete => _initializationCompleter.future;

  /// Initialize app state
  Future<void> initialize() async {
    try {
      _logger.info('Initializing app state service');

      // Mark as initialized
      isInitialized.value = true;
      _initializationCompleter.complete();

      _logger.info('App state service initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize app state service', e, stackTrace);
      _initializationCompleter.completeError(e, stackTrace);
    }
  }

  /// Update home screen data
  void updateHomeData(List<Map> data, {bool isLoading = false, String? error}) {
    homeData.value = data;
    isHomeLoading.value = isLoading;
    homeError.value = error;
  }

  /// Update search results
  void updateSearchResults(List<Map> results, {bool isSearching = false, String? error}) {
    searchResults.value = results;
    this.isSearching.value = isSearching;
    searchError.value = error;
  }

  /// Update player state
  void updatePlayerState({
    bool? playing,
    Duration? position,
    Duration? duration,
    Map? song,
  }) {
    if (playing != null) isPlaying.value = playing;
    if (position != null) currentPosition.value = position;
    if (duration != null) totalDuration.value = duration;
    if (song != null) currentSong.value = song;
  }

  /// Update navigation state
  void updateNavigation(String route, [Map<String, dynamic>? state]) {
    currentRoute.value = route;
    if (state != null) {
      navigationState.value = state;
    }
  }

  /// Update connectivity status
  void updateConnectivity(bool online) {
    isOnline.value = online;
  }

  /// Reset all state to initial values
  void reset() {
    isHomeLoading.value = false;
    homeData.value = [];
    homeError.value = null;

    isSearching.value = false;
    searchResults.value = [];
    searchError.value = null;

    isPlaying.value = false;
    currentPosition.value = Duration.zero;
    totalDuration.value = null;
    currentSong.value = null;

    currentRoute.value = '/';
    navigationState.value = {};

    isOnline.value = true;
  }

  /// Dispose of all notifiers
  void dispose() {
    isHomeLoading.dispose();
    homeData.dispose();
    homeError.dispose();

    isSearching.dispose();
    searchResults.dispose();
    searchError.dispose();

    isPlaying.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
    currentSong.dispose();

    currentRoute.dispose();
    navigationState.dispose();

    isOnline.dispose();
    isInitialized.dispose();
  }
}
